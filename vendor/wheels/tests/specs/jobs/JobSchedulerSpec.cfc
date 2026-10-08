/**
 * Recurring job schedules: cron and interval slot arithmetic (JobCron), time zones and the two
 * DST rules, and JobScheduler — enqueueDue() (one job per slot across servers, catch-up,
 * the never-backwards guard) and the config/schedules.cfm sync.
 * Instants are epoch ms, built from fixed ISO times so every expectation is deterministic.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("JobCron", function() {

			it("finds the next slot for steps, ranges and day names", function() {
				var c = new wheels.JobCron();
				var cron = c.parse("*/15 9-17 * * MON-FRI");
				// 2026-10-12 is a Monday.
				expect(c.isoUtc(c.nextCron(cron, c.msFromIsoUtc("2026-10-12T09:07Z")))).toBe("2026-10-12T09:15:00Z");
				expect(c.isoUtc(c.nextCron(cron, c.msFromIsoUtc("2026-10-12T17:45Z")))).toBe("2026-10-13T09:00:00Z");
				// Saturday 2026-10-17 -> Monday 2026-10-19.
				expect(c.isoUtc(c.nextCron(cron, c.msFromIsoUtc("2026-10-17T10:00Z")))).toBe("2026-10-19T09:00:00Z");
			});

			it("matches day-of-month OR day-of-week when both are restricted", function() {
				var c = new wheels.JobCron();
				// The 13th, or any Friday: from Sunday 2026-02-01 the first match is Friday the 6th.
				var next = c.nextCron(c.parse("0 0 13 * FRI"), c.msFromIsoUtc("2026-02-01T00:00Z"));
				expect(c.isoUtc(next)).toBe("2026-02-06T00:00:00Z");
			});

			it("ANDs the day fields when either is starred (Vixie)", function() {
				var c = new wheels.JobCron();
				// Odd days that are also Mondays: from Tuesday 2026-10-06, Monday the 12th is even,
				// so the next match is Monday the 19th.
				var next = c.nextCron(c.parse("0 0 */2 * MON"), c.msFromIsoUtc("2026-10-06T00:00Z"));
				expect(c.isoUtc(next)).toBe("2026-10-19T00:00:00Z");
			});

			it("supports the @ aliases and month/day names", function() {
				var c = new wheels.JobCron();
				expect(c.isoUtc(c.nextCron(c.parse("@daily"), c.msFromIsoUtc("2026-10-12T07:30Z")))).toBe("2026-10-13T00:00:00Z");
				expect(c.isoUtc(c.nextCron(c.parse("@hourly"), c.msFromIsoUtc("2026-10-12T07:30Z")))).toBe("2026-10-12T08:00:00Z");
				expect(c.isoUtc(c.nextCron(c.parse("0 9 1 JAN *"), c.msFromIsoUtc("2026-10-12T00:00Z")))).toBe("2027-01-01T09:00:00Z");
				expect(c.isoUtc(c.nextCron(c.parse("0 9 * * WED"), c.msFromIsoUtc("2026-10-12T00:00Z")))).toBe("2026-10-14T09:00:00Z");
				// 7 is Sunday too.
				expect(c.isoUtc(c.nextCron(c.parse("0 9 * * 7"), c.msFromIsoUtc("2026-10-12T00:00Z")))).toBe("2026-10-18T09:00:00Z");
			});

			it("reports an expression that never fires", function() {
				var c = new wheels.JobCron();
				expect(c.nextCron(c.parse("0 0 31 2 *"), c.msFromIsoUtc("2026-01-01T00:00Z"))).toBe(-1);
			});

			it("refuses malformed and unsupported expressions", function() {
				var bad = ["0 0 * *", "61 * * * *", "0 25 * * *", "0 0 L * *", "0 0 15W * *", "0 0 ? * MON", "0 0 * * 6##3", "@sometimes", "5-1 * * * *", "*/0 * * * *", "1--5 * * * *", "1-2-3 * * * *", "*/ * * * *", "5/ * * * *"];
				for (var expression in bad) {
					var state = {threw = false};
					try {
						new wheels.JobCron().parse(expression);
					} catch (any e) {
						state.threw = e.type == "Wheels.Job.InvalidSchedule";
					}
					expect(state.threw).toBeTrue("'#expression#' should be refused");
				}
			});

			it("aligns intervals to the epoch", function() {
				var c = new wheels.JobCron();
				expect(c.isoUtc(c.nextInterval(900, c.msFromIsoUtc("2026-10-12T09:07Z")))).toBe("2026-10-12T09:15:00Z");
				expect(c.isoUtc(c.nextInterval(3600, c.msFromIsoUtc("2026-10-12T09:00Z")))).toBe("2026-10-12T10:00:00Z");
			});

			it("reads cron in the schedule's time zone", function() {
				if (!$javaTime()) {
					return;
				}
				var c = new wheels.JobCron();
				// 07:00 in New York in October is 11:00 UTC (EDT).
				var next = c.nextCron(c.parse("0 7 * * *"), c.msFromIsoUtc("2026-10-12T00:00Z"), "America/New_York");
				expect(c.isoUtc(next)).toBe("2026-10-12T11:00:00Z");
			});

			it("runs a nonexistent local time at the next valid instant (spring forward)", function() {
				if (!$javaTime()) {
					return;
				}
				var c = new wheels.JobCron();
				// 2026-03-08 02:30 doesn't exist in New York; clocks jump from 02:00 EST to 03:00 EDT (07:00Z).
				var next = c.nextCron(c.parse("30 2 * * *"), c.msFromIsoUtc("2026-03-08T05:00Z"), "America/New_York");
				expect(c.isoUtc(next)).toBe("2026-03-08T07:00:00Z");
			});

			it("runs a repeated local time once, at its first occurrence (fall back)", function() {
				if (!$javaTime()) {
					return;
				}
				var c = new wheels.JobCron();
				var cron = c.parse("30 1 * * *");
				// 2026-11-01 01:30 happens twice in New York: 05:30Z (EDT) and 06:30Z (EST).
				var first = c.nextCron(cron, c.msFromIsoUtc("2026-11-01T04:00Z"), "America/New_York");
				expect(c.isoUtc(first)).toBe("2026-11-01T05:30:00Z");
				expect(c.isoUtc(c.nextCron(cron, first, "America/New_York"))).toBe("2026-11-02T06:30:00Z", "the second 01:30 must not run");
			});

			it("refuses a non-UTC zone on an engine without java.time", function() {
				if ($javaTime()) {
					return;
				}
				var state = {threw = false};
				try {
					new wheels.JobCron().validateTimeZone("America/New_York");
				} catch (any e) {
					state.threw = e.type == "Wheels.Job.InvalidSchedule";
				}
				expect(state.threw).toBeTrue("without java.time only UTC schedules can be computed");
			});

			it("refuses an unknown time zone", function() {
				var state = {threw = false};
				try {
					new wheels.JobCron().validateTimeZone("Mars/Olympus_Mons");
				} catch (any e) {
					state.threw = e.type == "Wheels.Job.InvalidSchedule";
				}
				expect(state.threw).toBeTrue();
			});

		});

		describe("JobScheduler.enqueueDue", function() {

			it("reads the current time as epoch milliseconds", function() {
				var nowMs = new wheels.JobScheduler().$nowMs();
				var epochDay = Floor(nowMs / 86400000);
				var localDay = DateDiff("d", CreateDate(1970, 1, 1), Now());
				expect(Abs(epochDay - localDay)).toBeLTE(1, "the scheduler's clock must be epoch time, not an uptime counter");
			});

			beforeEach(function() {
				var bootstrapJob = new wheels.Job();
				bootstrapJob.$ensureJobTable();
				new wheels.JobScheduler().$ensureSchedulesTable();
				$cleanup();
			});

			afterEach(function() {
				$cleanup();
			});

			it("enqueues one job per slot, however many servers run it", function() {
				var c = new wheels.JobCron();
				var now = c.msFromIsoUtc("2026-10-12T12:20:10Z");
				$insertSchedule(name = "spec_every", kind = "interval", spec = "60", lastEnqueuedFor = now - 300000);

				var first = new wheels.JobScheduler().enqueueDue(nowMs = now);
				expect(first.enqueued).toBe(1);
				// A second server that read the schedule before the first moved it on.
				$setLastEnqueuedFor("spec_every", now - 300000);
				var second = new wheels.JobScheduler().enqueueDue(nowMs = now);
				expect(second.duplicates).toBe(1);
				expect(second.enqueued).toBe(0);
				expect($jobCount("test_sched_spec")).toBe(1);
				expect($uniqueKeys("test_sched_spec")).toBe("spec_every:2026-10-12T12:20:00Z");
			});

			it("catches up with only the newest missed slot (catchUp latest)", function() {
				var c = new wheels.JobCron();
				var now = c.msFromIsoUtc("2026-10-12T12:20Z");
				$insertSchedule(name = "spec_hourly", kind = "cron", spec = "0 * * * *", lastEnqueuedFor = now - 5 * 3600000);

				expect(new wheels.JobScheduler().enqueueDue(nowMs = now).enqueued).toBe(1);
				expect($uniqueKeys("test_sched_spec")).toBe("spec_hourly:2026-10-12T12:00:00Z");
			});

			it("skips a missed slot older than the catch-up window", function() {
				var c = new wheels.JobCron();
				var now = c.msFromIsoUtc("2026-10-12T12:20Z");
				$insertSchedule(name = "spec_window", kind = "cron", spec = "0 * * * *", lastEnqueuedFor = now - 5 * 3600000, catchUpWindowSeconds = 600);

				expect(new wheels.JobScheduler().enqueueDue(nowMs = now).enqueued).toBe(0);
				expect($jobCount("test_sched_spec")).toBe(0);
				expect($lastEnqueuedFor("spec_window")).toBeGTE(now - 600000 - 1, "skipped slots count as passed");
			});

			it("runs only a current slot with catchUp none", function() {
				var c = new wheels.JobCron();
				var slot = c.msFromIsoUtc("2026-10-12T12:00Z");
				$insertSchedule(name = "spec_none_now", kind = "cron", spec = "0 * * * *", lastEnqueuedFor = slot - 7200000, catchUp = "none");
				$insertSchedule(name = "spec_none_late", kind = "cron", spec = "0 * * * *", lastEnqueuedFor = slot - 7200000, catchUp = "none");

				var scheduler = new wheels.JobScheduler();
				// 30 seconds after the slot: current.
				$disable("spec_none_late");
				expect(scheduler.enqueueDue(nowMs = slot + 30000).enqueued).toBe(1);
				// Ten minutes after the slot: missed, not run.
				$disable("spec_none_now");
				$enable("spec_none_late");
				expect(scheduler.enqueueDue(nowMs = slot + 600000).enqueued).toBe(0);
				expect($jobCount("test_sched_spec")).toBe(1);
			});

			it("never enqueues a slot at or before the last one enqueued", function() {
				var c = new wheels.JobCron();
				var slot = c.msFromIsoUtc("2026-10-12T12:00Z");
				$insertSchedule(name = "spec_done", kind = "cron", spec = "0 * * * *", lastEnqueuedFor = slot);

				expect(new wheels.JobScheduler().enqueueDue(nowMs = slot + 1200000).enqueued).toBe(0);
				expect($jobCount("test_sched_spec")).toBe(0);
			});

			it("starts a schedule it sees for the first time from now", function() {
				var c = new wheels.JobCron();
				var now = c.msFromIsoUtc("2026-10-12T12:20Z");
				$insertSchedule(name = "spec_new", kind = "cron", spec = "0 * * * *");

				expect(new wheels.JobScheduler().enqueueDue(nowMs = now).enqueued).toBe(0, "no slot from before it existed");
				expect($lastEnqueuedFor("spec_new")).toBe(now);
				expect(new wheels.JobScheduler().enqueueDue(nowMs = c.msFromIsoUtc("2026-10-12T13:00:20Z")).enqueued).toBe(1);
			});

			it("records a bad schedule's error and still runs the others", function() {
				var c = new wheels.JobCron();
				var now = c.msFromIsoUtc("2026-10-12T12:20:10Z");
				$insertSchedule(name = "spec_bad", kind = "cron", spec = "not a cron", lastEnqueuedFor = now - 300000);
				$insertSchedule(name = "spec_good", kind = "interval", spec = "60", lastEnqueuedFor = now - 300000);

				var result = new wheels.JobScheduler().enqueueDue(nowMs = now);
				expect(result.enqueued).toBe(1);
				expect(ArrayLen(result.errors)).toBe(1);
				expect(Len($scheduleRow("spec_bad").lastError)).toBeGT(0);
			});

			it("leaves disabled schedules alone", function() {
				var c = new wheels.JobCron();
				var now = c.msFromIsoUtc("2026-10-12T12:20:10Z");
				$insertSchedule(name = "spec_off", kind = "interval", spec = "60", lastEnqueuedFor = now - 300000, enabled = 0);
				expect(new wheels.JobScheduler().enqueueDue(nowMs = now).checked).toBe(0);
			});

		});

		describe("JobScheduler sync", function() {

			beforeEach(function() {
				new wheels.JobScheduler().$ensureSchedulesTable();
				$cleanup();
			});

			afterEach(function() {
				$cleanup();
			});

			it("syncs code schedules, disables removed ones and never touches app rows", function() {
				$insertSchedule(name = "spec_shared", kind = "interval", spec = "300", source = "db");
				var scheduler = new wheels.JobScheduler();
				scheduler.schedule("spec_code_a").job("wheels.tests._assets.jobs.ProcessOrdersJob").cron("0 7 * * *");
				scheduler.schedule("spec_code_b").job("wheels.tests._assets.jobs.ProcessOrdersJob").every(15, "minutes");
				scheduler.schedule("spec_shared").job("wheels.tests._assets.jobs.ProcessOrdersJob").every(5, "minutes");
				var definitions = scheduler.$loadedDefinitions();
				var result = scheduler.$syncDefinitions(definitions);
				expect(result.synced).toBe(2);
				expect(result.skipped).toBe(1, "a db row's name is not taken over");
				expect($scheduleRow("spec_code_a").source).toBe("code");
				expect($scheduleRow("spec_shared").source).toBe("db");
				expect(Val($scheduleRow("spec_shared").spec)).toBe(300);

				var again = new wheels.JobScheduler();
				again.schedule("spec_code_a").job("wheels.tests._assets.jobs.ProcessOrdersJob").cron("0 8 * * *");
				again.$syncDefinitions(again.$loadedDefinitions());
				expect($scheduleRow("spec_code_a").spec).toBe("0 8 * * *");
				expect(Val($scheduleRow("spec_code_b").enabled)).toBe(0, "a schedule removed from the file is disabled, not deleted");
				expect(Val($scheduleRow("spec_shared").enabled)).toBe(1, "app rows are never disabled by the sync");
			});

			it("loads schedules from a schedules file", function() {
				var definitions = new wheels.JobScheduler().$loadDefinitions("/wheels/tests/_assets/config/schedules.cfm");
				expect(ArrayLen(definitions)).toBe(2);
			});

			it("refuses an invalid definition", function() {
				var cases = [
					function(s) { s.schedule("spec_x").job("wheels.tests._assets.jobs.ProcessOrdersJob"); },
					function(s) { s.schedule("spec_x").cron("0 * * * *"); },
					function(s) { s.schedule("spec_x").job("wheels.tests._assets.jobs.ProcessOrdersJob").cron("bad"); },
					function(s) { s.schedule("spec_x").job("wheels.tests._assets.jobs.ProcessOrdersJob").cron("0 * * * *").catchUp("all"); },
					function(s) { s.schedule("spec_x").job("not a class!").cron("0 * * * *"); }
				];
				for (var buildCase in cases) {
					var scheduler = new wheels.JobScheduler();
					buildCase(scheduler);
					var state = {threw = false};
					try {
						scheduler.$syncDefinitions(scheduler.$loadedDefinitions());
					} catch (any e) {
						state.threw = e.type == "Wheels.Job.InvalidSchedule";
					}
					expect(state.threw).toBeTrue();
				}
				var dayState = {threw = false};
				try {
					new wheels.JobSchedule("spec_days").every(1, "days");
				} catch (any e) {
					dayState.threw = e.type == "Wheels.Job.InvalidSchedule";
				}
				expect(dayState.threw).toBeTrue("every() is minutes or hours; days use cron");
			});

		});
	}

	// The same probe the scheduler uses: an engine with a partial java.time counts as without.
	private boolean function $javaTime() {
		return new wheels.JobCron().$javaTimeAvailable();
	}

	private void function $cleanup() {
		try {
			queryExecute("DELETE FROM wheels_job_schedules WHERE name LIKE 'spec_%'", {}, {datasource = application.wheels.dataSourceName});
		} catch (any e) {
		}
		try {
			queryExecute("DELETE FROM wheels_jobs WHERE queue LIKE 'test_sched_%'", {}, {datasource = application.wheels.dataSourceName});
		} catch (any e) {
		}
	}

	private void function $insertSchedule(
		required string name,
		required string kind,
		required string spec,
		any lastEnqueuedFor = "",
		string catchUp = "latest",
		numeric catchUpWindowSeconds = 3600,
		numeric enabled = 1,
		string source = "db"
	) {
		queryExecute(
			"INSERT INTO wheels_job_schedules (name, jobClass, data, queue, kind, spec, timezone, catchUp, catchUpWindowSeconds, enabled, source, lastEnqueuedFor)
			VALUES (:name, 'wheels.tests._assets.jobs.ProcessOrdersJob', '{}', 'test_sched_spec', :kind, :spec, 'UTC', :catchUp, :catchUpWindowSeconds, :enabled, :source, :lastEnqueuedFor)",
			{
				name = {value = arguments.name, cfsqltype = "cf_sql_varchar"},
				kind = {value = arguments.kind, cfsqltype = "cf_sql_varchar"},
				spec = {value = arguments.spec, cfsqltype = "cf_sql_varchar"},
				catchUp = {value = arguments.catchUp, cfsqltype = "cf_sql_varchar"},
				catchUpWindowSeconds = {value = arguments.catchUpWindowSeconds, cfsqltype = "cf_sql_integer"},
				enabled = {value = arguments.enabled, cfsqltype = "cf_sql_integer"},
				source = {value = arguments.source, cfsqltype = "cf_sql_varchar"},
				lastEnqueuedFor = {value = IsNumeric(arguments.lastEnqueuedFor) ? arguments.lastEnqueuedFor : 0, cfsqltype = "cf_sql_bigint", null = !IsNumeric(arguments.lastEnqueuedFor)}
			},
			{datasource = application.wheels.dataSourceName}
		);
	}

	private void function $setLastEnqueuedFor(required string name, required numeric value) {
		queryExecute(
			"UPDATE wheels_job_schedules SET lastEnqueuedFor = :v, nextRunAt = NULL WHERE name = :name",
			{v = {value = arguments.value, cfsqltype = "cf_sql_bigint"}, name = {value = arguments.name, cfsqltype = "cf_sql_varchar"}},
			{datasource = application.wheels.dataSourceName}
		);
	}

	private void function $setNextRunAt(required string name, required numeric value) {
		queryExecute(
			"UPDATE wheels_job_schedules SET nextRunAt = :v WHERE name = :name",
			{v = {value = arguments.value, cfsqltype = "cf_sql_bigint"}, name = {value = arguments.name, cfsqltype = "cf_sql_varchar"}},
			{datasource = application.wheels.dataSourceName}
		);
	}

	private void function $disable(required string name) {
		queryExecute("UPDATE wheels_job_schedules SET enabled = 0 WHERE name = :name", {name = {value = arguments.name, cfsqltype = "cf_sql_varchar"}}, {datasource = application.wheels.dataSourceName});
	}

	private void function $enable(required string name) {
		queryExecute("UPDATE wheels_job_schedules SET enabled = 1 WHERE name = :name", {name = {value = arguments.name, cfsqltype = "cf_sql_varchar"}}, {datasource = application.wheels.dataSourceName});
	}

	private numeric function $lastEnqueuedFor(required string name) {
		return Val($scheduleRow(arguments.name).lastEnqueuedFor);
	}

	private struct function $scheduleRow(required string name) {
		var q = queryExecute(
			"SELECT * FROM wheels_job_schedules WHERE name = :name",
			{name = {value = arguments.name, cfsqltype = "cf_sql_varchar"}},
			{datasource = application.wheels.dataSourceName}
		);
		var rv = {source = "", spec = "", enabled = 0, lastEnqueuedFor = 0, lastError = ""};
		if (!q.recordCount) {
			return rv;
		}
		rv.source = q.source[1];
		rv.spec = q.spec[1];
		rv.enabled = q.enabled[1];
		rv.lastEnqueuedFor = IsNull(q.lastEnqueuedFor[1]) ? 0 : q.lastEnqueuedFor[1];
		rv.lastError = IsNull(q.lastError[1]) ? "" : q.lastError[1];
		return rv;
	}

	private numeric function $jobCount(required string queue) {
		return Val(queryExecute(
			"SELECT COUNT(*) AS cnt FROM wheels_jobs WHERE queue = :queue",
			{queue = {value = arguments.queue, cfsqltype = "cf_sql_varchar"}},
			{datasource = application.wheels.dataSourceName}
		).cnt);
	}

	private string function $uniqueKeys(required string queue) {
		var q = queryExecute(
			"SELECT uniqueKey FROM wheels_jobs WHERE queue = :queue ORDER BY uniqueKey",
			{queue = {value = arguments.queue, cfsqltype = "cf_sql_varchar"}},
			{datasource = application.wheels.dataSourceName}
		);
		return ValueList(q.uniqueKey);
	}

}
