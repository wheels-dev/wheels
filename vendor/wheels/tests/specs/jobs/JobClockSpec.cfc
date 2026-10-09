/**
 * The jobs clock (wheels.JobClock): UTC epoch seconds on the database's clock, read through a
 * skew cached for 60 seconds. Timestamps are built by the database from integers, so a UTC time
 * that doesn't exist in the server's local time zone (the hour skipped when daylight saving
 * starts) is stored and read back exactly. The CFML-facing API stays in app-local time.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("the jobs clock", function() {

			beforeEach(function() {
				new wheels.Job().$ensureJobTable();
			});

			afterEach(function() {
				if (StructKeyExists(application.wheels, "$jobsClock")) {
					StructDelete(application.wheels["$jobsClock"], "spec_clock_missing_ds");
				}
				queryExecute("DELETE FROM wheels_jobs WHERE queue = 'test_job_clock'", {}, {datasource = application.wheels.dataSourceName});
			});

			it("builds each database's timestamp from whole days and seconds, past 2038 too", function() {
				var clock = new wheels.Job().$jobClock();
				var params = {};
				var sql = clock.timestampSql(name = "t", epochSeconds = 2208988800 + 3723, params = params, dbType = "sqlserver");
				expect(sql).toBe("DATEADD(second, :t_s, DATEADD(day, :t_d, CAST('1970-01-01' AS DATETIME)))");
				expect(params.t_d.value).toBe(25567);
				expect(params.t_s.value).toBe(3723);
				expect(clock.timestampSql(name = "t", epochSeconds = 0, params = {}, dbType = "mysql")).toInclude("INTERVAL :t_d DAY");
				expect(clock.timestampSql(name = "t", epochSeconds = 0, params = {}, dbType = "postgresql")).toInclude(":t_d * INTERVAL '1 day'");
				expect(clock.timestampSql(name = "t", epochSeconds = 0, params = {}, dbType = "oracle")).toInclude("NUMTODSINTERVAL(:t_s, 'SECOND')");
				expect(clock.timestampSql(name = "t", epochSeconds = 0, params = {}, dbType = "h2")).toInclude("DATEADD('DAY', :t_d");
				var sqliteParams = {};
				expect(clock.timestampSql(name = "t", epochSeconds = 1772937000, params = sqliteParams, dbType = "sqlite")).toBe(":t");
				expect(sqliteParams.t.value).toBe(1772937000000);
			});

			it("reads UTC from each database's own clock, and none for single-host databases", function() {
				var clock = new wheels.Job().$jobClock();
				expect(clock.utcNowSql("sqlserver")).toInclude("SYSUTCDATETIME()");
				expect(clock.utcNowSql("mysql")).toInclude("UTC_TIMESTAMP()");
				expect(clock.utcNowSql("postgresql")).toInclude("clock_timestamp()");
				expect(clock.utcNowSql("oracle")).toInclude("SYS_EXTRACT_UTC(SYSTIMESTAMP)");
				expect(clock.utcNowSql("h2")).toBe("");
				expect(clock.utcNowSql("sqlite")).toBe("");
			});

			it("stores and reads back UTC times local time can't represent, on this database", function() {
				var clock = new wheels.Job().$jobClock();
				for (var c in $dstCases()) {
					var id = $insertAt(clock, c.epoch);
					var row = queryExecute(
						"SELECT " & clock.epochSql("runAt") & " AS e FROM wheels_jobs WHERE id = :id",
						{id = {value = id, cfsqltype = "cf_sql_varchar"}},
						{datasource = application.wheels.dataSourceName}
					);
					expect(row.e[1]).toBe(c.epoch, c.wall);
				}
			});

			it("stores those times as their UTC wall time, checked with the database's own literal", function() {
				var clock = new wheels.Job().$jobClock();
				if (clock.$dbType() == "h2" && GetTimeZoneInfo().utcTotalOffset != 0) {
					skip("H2 1.4 does timestamp arithmetic in the JVM's time zone, so it requires the JVM to run on UTC.");
				}
				for (var c in $dstCases()) {
					var id = $insertAt(clock, c.epoch);
					// Independently of the clock's helpers: the stored value equals the UTC wall time.
					var match = queryExecute(
						"SELECT id FROM wheels_jobs WHERE id = :id AND runAt = " & $literalSql(c.wall, c.epoch, clock.$dbType()),
						{id = {value = id, cfsqltype = "cf_sql_varchar"}},
						{datasource = application.wheels.dataSourceName}
					);
					expect(match.recordCount).toBe(1, "stored as " & c.wall & " UTC");
				}
			});

			it("is this server's epoch seconds plus a small skew", function() {
				var clock = new wheels.Job().$jobClock();
				clock.refresh();
				expect(Abs(clock.nowEpoch() - clock.$appEpoch())).toBeLTE(3);
			});

			it("converts app-local time to the jobs clock and back", function() {
				var clock = new wheels.Job().$jobClock();
				var localTime = CreateDateTime(2026, 7, 1, 9, 30, 15);
				var epoch = clock.fromLocal(localTime);
				expect(epoch - clock.skewSeconds()).toBe(clock.$floorDiv(localTime.getTime(), 1000));
				expect(DateDiff("s", localTime, clock.toLocal(epoch))).toBe(0);
				expect(clock.toLocal("")).toBe("");
			});

			it("reuses a read for 60 seconds", function() {
				var clock = new wheels.JobClock(datasource = "spec_clock_missing_ds", job = new wheels.Job());
				application.wheels["$jobsClock"]["spec_clock_missing_ds"] = {skew = 7, anchored = true, failureLogged = false, dbType = "mysql", checkedTick = clock.$appMillis()};
				expect(clock.skewSeconds()).toBe(7);
			});

			it("keeps the last good skew when a read fails", function() {
				application.wheels["$jobsClock"]["spec_clock_missing_ds"] = {skew = 5, anchored = true, failureLogged = false, dbType = "mysql", checkedTick = 0};
				var clock = new wheels.JobClock(datasource = "spec_clock_missing_ds", job = new wheels.Job());
				expect(clock.skewSeconds()).toBe(5);
				expect(application.wheels["$jobsClock"]["spec_clock_missing_ds"].failureLogged).toBeTrue();
			});

			it("runs on this server's own clock until a read succeeds", function() {
				application.wheels["$jobsClock"]["spec_clock_missing_ds"] = {skew = 0, anchored = false, failureLogged = false, dbType = "mysql", checkedTick = 0};
				var clock = new wheels.JobClock(datasource = "spec_clock_missing_ds", job = new wheels.Job());
				expect(clock.skewSeconds()).toBe(0);
				expect(Abs(clock.nowEpoch() - clock.$appEpoch())).toBeLTE(1);
			});

			it("stores enqueueAt()'s app-local time as UTC on the jobs clock", function() {
				var job = new wheels.Job();
				var localRunAt = DateAdd("h", 3, Now());
				var result = job.enqueueAt(runAt = localRunAt, queue = "test_job_clock");
				var row = queryExecute(
					"SELECT " & job.$jobClock().epochSql("runAt") & " AS e FROM wheels_jobs WHERE id = :id",
					{id = {value = result.id, cfsqltype = "cf_sql_varchar"}},
					{datasource = application.wheels.dataSourceName}
				);
				expect(Abs(row.e[1] - job.$jobClock().fromLocal(localRunAt))).toBeLTE(1);
			});

			it("holds a delayed job until its time on the jobs clock, then runs it", function() {
				var job = new wheels.tests._assets.jobs.ProcessOrdersJob();
				var clock = job.$jobClock();
				var enqueued = job.enqueueIn(seconds = 3600, queue = "test_job_clock");
				var worker = new wheels.JobWorker();
				expect(worker.processNext(queues = "test_job_clock").jobId).toBe("", "not due for an hour");
				clock.query(
					"UPDATE wheels_jobs SET runAt = :due WHERE id = :id",
					{due = {value = clock.nowEpoch() - 1, cfsqltype = "wheels_epoch"}, id = {value = enqueued.id, cfsqltype = "cf_sql_varchar"}}
				);
				expect(worker.processNext(queues = "test_job_clock").jobId).toBe(enqueued.id);
			});

		});
	}

	/**
	 * The spring-forward gap in America/New_York and Europe/London, both instants of the November
	 * fold in America/New_York, and a time past 2038, as epoch seconds and UTC wall time.
	 */
	private array function $dstCases() {
		return [
			{epoch = 1772937000, wall = "2026-03-08 02:30:00"},
			{epoch = 1774747800, wall = "2026-03-29 01:30:00"},
			{epoch = 1793511000, wall = "2026-11-01 05:30:00"},
			{epoch = 1793514600, wall = "2026-11-01 06:30:00"},
			{epoch = 2208992523, wall = "2040-01-01 01:02:03"}
		];
	}

	/**
	 * A completed job row whose timestamps are the given epoch, written as the jobs code writes them.
	 */
	private string function $insertAt(required any clock, required numeric epoch) {
		var id = CreateUUID();
		arguments.clock.query(
			"INSERT INTO wheels_jobs (id, jobClass, queue, data, priority, status, attempts, maxRetries, runAt, createdAt, updatedAt)
			VALUES (:id, 'wheels.Job', 'test_job_clock', '{}', 0, 'completed', 0, 3, :t, :t, :t)",
			{id = {value = id, cfsqltype = "cf_sql_varchar"}, t = {value = arguments.epoch, cfsqltype = "wheels_epoch"}}
		);
		return id;
	}

	/**
	 * A UTC wall time as a timestamp literal in the database's own syntax (SQLite: epoch ms), so
	 * a stored value can be checked without the clock's helpers.
	 */
	private string function $literalSql(required string wall, required numeric epoch, required string dbType) {
		switch (arguments.dbType) {
			case "sqlserver":
				return "CAST('" & Replace(arguments.wall, " ", "T") & "' AS DATETIME)";
			case "sqlite":
				return arguments.epoch & "000";
			case "oracle":
				return "TO_TIMESTAMP('" & arguments.wall & "', 'YYYY-MM-DD HH24:MI:SS')";
		}
		return "TIMESTAMP '" & arguments.wall & "'";
	}

}
