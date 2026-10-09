/**
 * The jobs clock (wheels.JobClock): UTC on the database's clock, read through a skew cached for
 * 60 seconds, so every server sharing the job tables stamps and compares on one clock. The
 * CFML-facing API stays in app-local time.
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
			});

			it("reads UTC from each database's own clock, and none for single-host databases", function() {
				var clock = new wheels.Job().$jobClock();
				expect(clock.utcNowSql("sqlserver")).toInclude("SYSUTCDATETIME()");
				expect(clock.utcNowSql("mysql")).toInclude("UTC_TIMESTAMP(3)");
				expect(clock.utcNowSql("postgresql")).toInclude("clock_timestamp() AT TIME ZONE 'UTC'");
				expect(clock.utcNowSql("oracle")).toInclude("SYS_EXTRACT_UTC(SYSTIMESTAMP)");
				expect(clock.utcNowSql("h2")).toBe("");
				expect(clock.utcNowSql("sqlite")).toBe("");
				expect(clock.utcNowSql("default")).toBe("");
			});

			it("is UTC, within a few seconds of this server's own UTC", function() {
				var clock = new wheels.Job().$jobClock();
				clock.refresh();
				var stamp = clock.utcNow();
				expect(Abs(DateDiff("s", clock.$appUtc(Now()), stamp))).toBeLTE(3);
				expect(Abs(clock.skewSeconds())).toBeLTE(3);
			});

			it("converts app-local time to the jobs clock and back", function() {
				var clock = new wheels.Job().$jobClock();
				var localTime = CreateDateTime(2026, 7, 1, 9, 30, 15);
				var utc = clock.toUtc(localTime);
				expect(DateDiff("s", DateAdd("s", clock.skewSeconds(), clock.$appUtc(localTime)), utc)).toBe(0);
				expect(DateDiff("s", localTime, clock.toLocal(utc))).toBe(0);
				expect(clock.toLocal("")).toBe("");
			});

			it("reuses a read for 60 seconds", function() {
				application.wheels["$jobsClock"]["spec_clock_missing_ds"] = {skew = 7, anchored = true, failureLogged = false, dbType = "mysql", checkedTick = GetTickCount()};
				var clock = new wheels.JobClock(datasource = "spec_clock_missing_ds", job = new wheels.Job());
				expect(clock.skewSeconds()).toBe(7);
			});

			it("keeps the last good skew when a read fails", function() {
				application.wheels["$jobsClock"]["spec_clock_missing_ds"] = {skew = 5, anchored = true, failureLogged = false, dbType = "mysql", checkedTick = 0};
				var clock = new wheels.JobClock(datasource = "spec_clock_missing_ds", job = new wheels.Job());
				expect(clock.skewSeconds()).toBe(5);
				expect(application.wheels["$jobsClock"]["spec_clock_missing_ds"].failureLogged).toBeTrue();
			});

			it("runs on this server's own UTC until a read succeeds", function() {
				application.wheels["$jobsClock"]["spec_clock_missing_ds"] = {skew = 0, anchored = false, failureLogged = false, dbType = "mysql", checkedTick = 0};
				var clock = new wheels.JobClock(datasource = "spec_clock_missing_ds", job = new wheels.Job());
				expect(clock.skewSeconds()).toBe(0);
				expect(Abs(DateDiff("s", clock.$appUtc(Now()), clock.utcNow()))).toBeLTE(1);
			});

			it("stores enqueueAt()'s app-local time as UTC on the jobs clock", function() {
				var job = new wheels.Job();
				var localRunAt = DateAdd("h", 3, Now());
				var result = job.enqueueAt(runAt = localRunAt, queue = "test_job_clock");
				var row = queryExecute(
					"SELECT runAt FROM wheels_jobs WHERE id = :id",
					{id = {value = result.id, cfsqltype = "cf_sql_varchar"}},
					{datasource = application.wheels.dataSourceName}
				);
				var stored = application.wo.$normalizeDbTimestamp(row.runAt[1]);
				expect(Abs(DateDiff("s", job.$jobClock().toUtc(localRunAt), stored))).toBeLTE(1);
				queryExecute(
					"DELETE FROM wheels_jobs WHERE queue = 'test_job_clock'",
					{},
					{datasource = application.wheels.dataSourceName}
				);
			});

		});
	}

}
