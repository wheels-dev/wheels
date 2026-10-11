/**
 * Stalls past its claim, gets reaped and re-claimed, then finishes anyway. Reproduces the
 * zombie-completion race: while this attempt is still inside perform(), the real reaper
 * (JobWorker.checkTimeouts) requeues the row and a second worker claims it. When perform()
 * returns, the original worker's completion/retry/fail UPDATE runs against attempt 2's live
 * claim. data.mode = "fail" throws after the re-claim so the retry/fail path is exercised.
 */
component extends="wheels.Job" {

	public void function perform(struct data = {}) {
		// Age the row past every grace window so the reaper treats this attempt as stalled.
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
		if (StructKeyExists(arguments.data, "mode") && arguments.data.mode == "fail") {
			throw(type = "Wheels.Tests.JobFailure", message = "original attempt failed after being reaped");
		}
	}

}
