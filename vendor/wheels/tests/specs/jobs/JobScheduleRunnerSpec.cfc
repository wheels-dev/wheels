/**
 * Schedules run from the normal job processing: every worker poll (wheels jobs work,
 * processQueue()) and JobRunner.tick() enqueue due schedule slots, at most once every
 * jobsScheduleCheckSeconds per application. No separate scheduler process is needed.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("schedules from the job runner", function() {

			beforeEach(function() {
				new wheels.Job().$ensureJobTable();
				new wheels.JobScheduler().$ensureSchedulesTable();
				$cleanup();
				application.wheels.jobsScheduleCheckSeconds = 15;
				StructDelete(application.wheels, "$jobsScheduleCheckedAt");
			});

			afterEach(function() {
				$cleanup();
				application.wheels.jobsScheduleCheckSeconds = 15;
				StructDelete(application.wheels, "$jobsScheduleCheckedAt");
			});

			it("enqueues a due schedule from a worker poll", function() {
				$insertDueSchedule("spec_runner_poll");
				new wheels.JobWorker().processNext(queues = "test_srun_poll", timeout = 300);
				expect($jobsFor("spec_runner_poll")).toBe(1, "the poll enqueued the due slot");
			});

			it("reports the slots it enqueued in a tick", function() {
				$insertDueSchedule("spec_runner_tick");
				var result = new wheels.JobRunner().tick(queues = "test_srun_poll");
				expect(result.scheduled).toBe(1);
				expect($jobsFor("spec_runner_tick")).toBe(1);
			});

			it("checks at most once per jobsScheduleCheckSeconds", function() {
				application.wheels.jobsScheduleCheckSeconds = 3600;
				$insertDueSchedule("spec_runner_throttle");
				var job = new wheels.Job();
				expect(job.$enqueueDueSchedules().enqueued).toBe(1);
				$insertDueSchedule("spec_runner_throttle_2");
				expect(job.$enqueueDueSchedules().checked).toBe(0, "the next check waits for the interval");
				expect($jobsFor("spec_runner_throttle_2")).toBe(0);
			});

			it("never checks with jobsScheduleCheckSeconds = 0", function() {
				application.wheels.jobsScheduleCheckSeconds = 0;
				$insertDueSchedule("spec_runner_off");
				new wheels.JobWorker().processNext(queues = "test_srun_poll", timeout = 300);
				expect($jobsFor("spec_runner_off")).toBe(0);
			});

		});
	}

	private void function $cleanup() {
		try {
			queryExecute("DELETE FROM wheels_job_schedules WHERE name LIKE 'spec_runner_%'", {}, {datasource = application.wheels.dataSourceName});
		} catch (any e) {
		}
		try {
			queryExecute("DELETE FROM wheels_jobs WHERE queue = 'test_srun_jobs' OR queue = 'test_srun_poll'", {}, {datasource = application.wheels.dataSourceName});
		} catch (any e) {
		}
	}

	/**
	 * An every-minute schedule whose last slot was five minutes ago, so a slot is due now. Its
	 * jobs go to their own queue, not the one the polls process, so they stay to be counted.
	 */
	private void function $insertDueSchedule(required string name) {
		var now = new wheels.JobScheduler().$nowMs();
		queryExecute(
			"INSERT INTO wheels_job_schedules (name, jobClass, data, queue, kind, spec, timezone, catchUp, catchUpWindowSeconds, enabled, source, lastEnqueuedFor)
			VALUES (:name, 'wheels.tests._assets.jobs.ProcessOrdersJob', '{}', 'test_srun_jobs', 'interval', '60', 'UTC', 'latest', 3600, 1, 'db', :last)",
			{
				name = {value = arguments.name, cfsqltype = "cf_sql_varchar"},
				last = {value = now - 300000, cfsqltype = "cf_sql_bigint"}
			},
			{datasource = application.wheels.dataSourceName}
		);
	}

	private numeric function $jobsFor(required string scheduleName) {
		return queryExecute(
			"SELECT id FROM wheels_jobs WHERE queue = 'test_srun_jobs' AND uniqueKey LIKE :prefix",
			{prefix = {value = arguments.scheduleName & ":%", cfsqltype = "cf_sql_varchar"}},
			{datasource = application.wheels.dataSourceName}
		).recordCount;
	}

}
