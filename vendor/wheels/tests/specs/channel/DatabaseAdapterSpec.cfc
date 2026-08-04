/**
 * Tests for the DatabaseAdapter pub/sub component.
 * Tests publish/poll round-trip, channel filtering, lastEventId filtering,
 * cleanup, and auto-table creation.
 *
 * Note: These tests require a configured datasource (application.wheels.dataSourceName).
 * They will be skipped in environments without a database.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("DatabaseAdapter", function() {

			beforeEach(function() {
				adapter = new wheels.channel.DatabaseAdapter();
				// Clean up test events before each test
				try {
					queryExecute(
						"DELETE FROM wheels_events WHERE channel LIKE :prefix",
						{prefix: {value: "test.%", cfsqltype: "cf_sql_varchar"}},
						{datasource: application.wheels.dataSourceName}
					);
				} catch (any e) {
					// Table may not exist yet — first test will create it
				}
			});

			it("can be instantiated", function() {
				expect(adapter).toBeInstanceOf("wheels.channel.DatabaseAdapter");
			});

			it("publish persists an event and returns result struct", function() {
				var result = adapter.publish(
					channel = "test.db",
					event = "notification",
					data = '{"msg":"hello"}'
				);

				expect(result).toBeStruct();
				expect(result).toHaveKey("id");
				expect(result).toHaveKey("channel");
				expect(result).toHaveKey("event");
				expect(result).toHaveKey("persisted");
				expect(result.channel).toBe("test.db");
				expect(result.event).toBe("notification");
				expect(result.persisted).toBeTrue();
			});

			it("publish uses provided event ID when given", function() {
				var result = adapter.publish(
					channel = "test.db",
					event = "test",
					data = "data",
					id = "custom-event-id"
				);
				expect(result.id).toBe("custom-event-id");
			});

			it("poll returns events for a channel", function() {
				adapter.publish(
					channel = "test.poll",
					event = "notification",
					data = '{"n":1}'
				);
				adapter.publish(
					channel = "test.poll",
					event = "alert",
					data = '{"n":2}'
				);

				var events = adapter.poll(
					channel = "test.poll",
					since = DateAdd("n", -1, Now())
				);

				expect(events).toBeQuery();
				expect(events.recordCount).toBeGTE(2);
			});

			it("poll filters by channel", function() {
				adapter.publish(channel = "test.filterA", event = "e", data = "a");
				adapter.publish(channel = "test.filterB", event = "e", data = "b");

				var eventsA = adapter.poll(
					channel = "test.filterA",
					since = DateAdd("n", -1, Now())
				);
				var eventsB = adapter.poll(
					channel = "test.filterB",
					since = DateAdd("n", -1, Now())
				);

				expect(eventsA.recordCount).toBeGTE(1);
				expect(eventsB.recordCount).toBeGTE(1);

				// All events in A should be for channel test.filterA
				for (var row = 1; row <= eventsA.recordCount; row++) {
					expect(eventsA.channel[row]).toBe("test.filterA");
				}
			});

			it("poll supports lastEventId filtering", function() {
				var first = adapter.publish(
					channel = "test.lastid",
					event = "e",
					data = "first",
					id = "evt-first"
				);

				// Small delay to ensure distinct timestamps
				sleep(50);

				adapter.publish(
					channel = "test.lastid",
					event = "e",
					data = "second",
					id = "evt-second"
				);

				var events = adapter.poll(
					channel = "test.lastid",
					lastEventId = "evt-first"
				);

				expect(events.recordCount).toBeGTE(1);
				// First event should be excluded, second should be present
				var ids = ValueList(events.id);
				expect(ids).notToInclude("evt-first");
				expect(ids).toInclude("evt-second");
			});

			it("cleanup removes old events", function() {
				// Insert an event with a timestamp far in the past
				try {
					queryExecute(
						"INSERT INTO wheels_events (id, channel, event, data, createdAt)
						VALUES (:id, :channel, :event, :data, :createdAt)",
						{
							id: {value: "old-event-cleanup", cfsqltype: "cf_sql_varchar"},
							channel: {value: "test.cleanup", cfsqltype: "cf_sql_varchar"},
							event: {value: "old", cfsqltype: "cf_sql_varchar"},
							data: {value: "stale data", cfsqltype: "cf_sql_longvarchar"},
							createdAt: {value: DateAdd("h", -2, Now()), cfsqltype: "cf_sql_timestamp"}
						},
						{datasource: application.wheels.dataSourceName}
					);
				} catch (any e) {
					// Skip if insert fails
				}

				adapter.cleanup(olderThanMinutes = 60);

				var remaining = queryExecute(
					"SELECT id FROM wheels_events WHERE id = :id",
					{id: {value: "old-event-cleanup", cfsqltype: "cf_sql_varchar"}},
					{datasource: application.wheels.dataSourceName}
				);

				expect(remaining.recordCount).toBe(0);
			});

			it("publish on a fresh instance does not run an immediate retention sweep", function() {
				// Ensure the table exists before inserting directly
				adapter.poll(channel = "test.freshsweep", since = DateAdd("n", -1, Now()));

				// Insert an event older than the retention window
				queryExecute(
					"INSERT INTO wheels_events (id, channel, event, data, createdAt)
					VALUES (:id, :channel, :event, :data, :createdAt)",
					{
						id: {value: "fresh-sweep-guard", cfsqltype: "cf_sql_varchar"},
						channel: {value: "test.freshsweep", cfsqltype: "cf_sql_varchar"},
						event: {value: "old", cfsqltype: "cf_sql_varchar"},
						data: {value: "expired", cfsqltype: "cf_sql_longvarchar"},
						createdAt: {value: DateAdd("h", -2, Now()), cfsqltype: "cf_sql_timestamp"}
					},
					{datasource: application.wheels.dataSourceName}
				);

				// A brand-new adapter's first publish must not block on a retention DELETE
				var freshAdapter = new wheels.channel.DatabaseAdapter();
				freshAdapter.publish(channel = "test.freshsweep", event = "e", data = "d");

				var remaining = queryExecute(
					"SELECT id FROM wheels_events WHERE id = :id",
					{id: {value: "fresh-sweep-guard", cfsqltype: "cf_sql_varchar"}},
					{datasource: application.wheels.dataSourceName}
				);
				expect(remaining.recordCount).toBe(1);
			});

			it("cleanup with maxRows bounds the number of rows deleted per pass", function() {
				// Ensure the table exists and flush any pre-existing expired rows so the
				// bounded pass below only sees the five rows inserted here
				adapter.poll(channel = "test.bounded", since = DateAdd("n", -1, Now()));
				adapter.cleanup();

				for (var i = 1; i <= 5; i++) {
					queryExecute(
						"INSERT INTO wheels_events (id, channel, event, data, createdAt)
						VALUES (:id, :channel, :event, :data, :createdAt)",
						{
							id: {value: "bounded-evt-#i#", cfsqltype: "cf_sql_varchar"},
							channel: {value: "test.bounded", cfsqltype: "cf_sql_varchar"},
							event: {value: "old", cfsqltype: "cf_sql_varchar"},
							data: {value: "expired", cfsqltype: "cf_sql_longvarchar"},
							createdAt: {value: DateAdd("h", -2, Now()), cfsqltype: "cf_sql_timestamp"}
						},
						{datasource: application.wheels.dataSourceName}
					);
				}

				var deleted = adapter.cleanup(olderThanMinutes = 60, maxRows = 2);
				expect(deleted).toBe(2);

				var remaining = queryExecute(
					"SELECT id FROM wheels_events WHERE channel = :channel",
					{channel: {value: "test.bounded", cfsqltype: "cf_sql_varchar"}},
					{datasource: application.wheels.dataSourceName}
				);
				expect(remaining.recordCount).toBe(3);
			});

			it("runs the bounded-pass statements against the live database", function() {
				// The $applyRowBound tests below only compare strings — nothing sends
				// the rewritten SQL to a real database, and nothing exercises the
				// list-parameter DELETE the bounded pass pairs it with. cleanup()
				// catches every error and returns 0, so an engine/database pair that
				// rejects either statement presents only as a wrong row count with no
				// message: "Expected [2] but received [0]" on boxlang + postgres and
				// cockroachdb, with the reason only in the wheels_channels log
				// (#3302). Running both statements here without the catch makes the
				// database's own error the thing the suite reports.
				adapter.cleanup();

				queryExecute(
					"INSERT INTO wheels_events (id, channel, event, data, createdAt)
					VALUES (:id, :channel, :event, :data, :createdAt)",
					{
						id: {value: "livebound-evt-1", cfsqltype: "cf_sql_varchar"},
						channel: {value: "test.livebound", cfsqltype: "cf_sql_varchar"},
						event: {value: "old", cfsqltype: "cf_sql_varchar"},
						data: {value: "expired", cfsqltype: "cf_sql_longvarchar"},
						createdAt: {value: DateAdd("h", -2, Now()), cfsqltype: "cf_sql_timestamp"}
					},
					{datasource: application.wheels.dataSourceName}
				);

				var cutoff = DateAdd("n", -60, Now());
				var dialect = adapter.$detectDatabaseType();
				var candidateSql = adapter.$applyRowBound(
					sqlText = "SELECT id FROM wheels_events WHERE createdAt < :cutoff ORDER BY createdAt ASC",
					dbType = dialect,
					maxRows = 1
				);

				// Mirror cleanup()'s option handling exactly: the driver-level
				// maxrows bound is used only when the dialect rewrite applied none.
				// Setting it unconditionally is what threw on boxlang + pgjdbc.
				var options = {datasource: application.wheels.dataSourceName};
				if (candidateSql == "SELECT id FROM wheels_events WHERE createdAt < :cutoff ORDER BY createdAt ASC") {
					options.maxrows = 1;
				}
				var candidates = queryExecute(
					candidateSql,
					{cutoff: {value: cutoff, cfsqltype: "cf_sql_timestamp"}},
					options
				);
				expect(candidates.recordCount).toBe(
					1,
					"The dialect-bounded SELECT returned no rows on #dialect#. SQL was: #candidateSql#"
				);

				// Assert against the id the bounded SELECT actually returned rather
				// than against the row inserted above: ORDER BY createdAt ASC takes
				// the oldest expired row in the table, which need not be ours if a
				// previous bundle left one behind.
				var targetId = candidates.id[1];

				queryExecute(
					"DELETE FROM wheels_events WHERE createdAt < :cutoff AND id IN (:ids)",
					{
						cutoff: {value: cutoff, cfsqltype: "cf_sql_timestamp"},
						ids: {value: ValueList(candidates.id), cfsqltype: "cf_sql_varchar", list: true}
					},
					{datasource: application.wheels.dataSourceName}
				);

				var survivor = queryExecute(
					"SELECT id FROM wheels_events WHERE id = :id",
					{id: {value: targetId, cfsqltype: "cf_sql_varchar"}},
					{datasource: application.wheels.dataSourceName}
				);
				expect(survivor.recordCount).toBe(
					0,
					"The list-parameter DELETE ran without error on #dialect# but did not "
					& "remove the row the bounded SELECT had just identified."
				);

				queryExecute(
					"DELETE FROM wheels_events WHERE channel = :channel",
					{channel: {value: "test.livebound", cfsqltype: "cf_sql_varchar"}},
					{datasource: application.wheels.dataSourceName}
				);
			});

			it("$applyRowBound rewrites the SELECT with TOP for sqlserver", function() {
				var bounded = adapter.$applyRowBound(
					sqlText = "SELECT id FROM wheels_events WHERE createdAt < :cutoff ORDER BY createdAt ASC",
					dbType = "sqlserver",
					maxRows = 25
				);
				expect(bounded).toBe(
					"SELECT TOP 25 id FROM wheels_events WHERE createdAt < :cutoff ORDER BY createdAt ASC"
				);
			});

			it("$applyRowBound appends FETCH FIRST for oracle", function() {
				var bounded = adapter.$applyRowBound(
					sqlText = "SELECT id FROM wheels_events WHERE createdAt < :cutoff ORDER BY createdAt ASC",
					dbType = "oracle",
					maxRows = 25
				);
				expect(bounded).toBe(
					"SELECT id FROM wheels_events WHERE createdAt < :cutoff ORDER BY createdAt ASC FETCH FIRST 25 ROWS ONLY"
				);
			});

			it("$applyRowBound appends LIMIT for the explicit LIMIT dialects", function() {
				var dialects = ["mysql", "postgresql", "sqlite", "h2"];
				for (var dialect in dialects) {
					var bounded = adapter.$applyRowBound(
						sqlText = "SELECT id FROM wheels_events WHERE createdAt < :cutoff ORDER BY createdAt ASC",
						dbType = dialect,
						maxRows = 25
					);
					expect(bounded).toBe(
						"SELECT id FROM wheels_events WHERE createdAt < :cutoff ORDER BY createdAt ASC LIMIT 25"
					);
				}
			});

			it("$applyRowBound leaves unknown dialects unchanged so driver maxrows stays the bound", function() {
				// "default" is what $detectDatabaseType() returns when cfdbinfo fails —
				// appending LIMIT there would be a syntax error on SQL Server/Oracle,
				// silently breaking cleanup() on the engines that need dialect handling.
				var dialects = ["default", "informix"];
				for (var dialect in dialects) {
					var unchanged = adapter.$applyRowBound(
						sqlText = "SELECT id FROM wheels_events WHERE createdAt < :cutoff ORDER BY createdAt ASC",
						dbType = dialect,
						maxRows = 25
					);
					expect(unchanged).toBe(
						"SELECT id FROM wheels_events WHERE createdAt < :cutoff ORDER BY createdAt ASC"
					);
				}
			});

			it("$applyRowBound hardens the bound to an integer", function() {
				var bounded = adapter.$applyRowBound(
					sqlText = "SELECT id FROM wheels_events",
					dbType = "mysql",
					maxRows = 7.9
				);
				expect(bounded).toBe("SELECT id FROM wheels_events LIMIT 7");
			});

			it("$applyRowBound leaves the statement unchanged for a non-positive bound", function() {
				var unbounded = adapter.$applyRowBound(
					sqlText = "SELECT id FROM wheels_events",
					dbType = "mysql",
					maxRows = 0
				);
				expect(unbounded).toBe("SELECT id FROM wheels_events");
			});

			it("auto-creates wheels_events table on first use", function() {
				// The table should already exist from previous tests,
				// but verify we can query it
				var events = adapter.poll(
					channel = "test.autocreate",
					since = DateAdd("n", -1, Now())
				);
				expect(events).toBeQuery();
			});
		});
	}
}
