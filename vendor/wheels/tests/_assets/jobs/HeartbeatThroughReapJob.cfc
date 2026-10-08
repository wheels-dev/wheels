/**
 * A long-running job that stays alive by heartbeating. perform() ages its own row past every
 * reap window, calls heartbeat(), then runs the real reaper: a job that heartbeats on time
 * must not be reaped. The reaper's result goes to the server scope for the spec to read (the
 * perform() thread can see a different application scope under the test runner).
 */
component extends="wheels.Job" {

	public void function perform(struct data = {}) {
		queryExecute(
			"UPDATE wheels_jobs SET updatedAt = :stale WHERE id = :id",
			{
				stale = {value = DateAdd("h", -2, Now()), cfsqltype = "cf_sql_timestamp"},
				id = {value = arguments.data.jobId, cfsqltype = "cf_sql_varchar"}
			},
			{datasource = application.wheels.dataSourceName}
		);
		heartbeat();
		var reaper = new wheels.JobWorker();
		server["$wheelsHeartbeatSpec_" & arguments.data.jobId] = {reaped = reaper.checkTimeouts(timeout = 300, queues = arguments.data.queue)};
	}

}
