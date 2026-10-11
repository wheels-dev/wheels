/**
 * A job whose claim is reaped and re-claimed while it runs, then heartbeats. The heartbeat
 * must throw Wheels.Job.Fenced: the row now belongs to another attempt. The caught type goes
 * to the server scope for the spec to read.
 */
component extends="wheels.Job" {

	public void function perform(struct data = {}) {
		$jobClock().query(
			"UPDATE wheels_jobs SET updatedAt = :stale WHERE id = :id",
			{
				stale = {value = $jobClock().nowEpoch() - 7200, cfsqltype = "wheels_epoch"},
				id = {value = arguments.data.jobId, cfsqltype = "cf_sql_varchar"}
			},
			{datasource = application.wheels.dataSourceName}
		);
		var reaper = new wheels.JobWorker();
		reaper.checkTimeouts(timeout = 300, queues = arguments.data.queue);
		var rival = new wheels.JobWorker();
		rival.$claimJob(arguments.data.jobId, 300);
		var outcome = {type = "none"};
		try {
			heartbeat();
		} catch (any e) {
			outcome.type = e.type;
		}
		server["$wheelsHeartbeatSpec_" & arguments.data.jobId] = outcome;
	}

}
