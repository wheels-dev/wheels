/**
 * Marks its own row failed, then returns. Reproduces the B1 complete-path
 * race: another worker already failed the job before this worker's success
 * UPDATE runs.
 */
component extends="wheels.Job" {

	public void function perform(struct data = {}) {
		local.now = $jobClock().nowEpoch();
		$jobClock().query(
			"UPDATE wheels_jobs
			SET status = 'failed', failedAt = :failedAt, updatedAt = :updatedAt
			WHERE id = :id",
			{
				id = {value = arguments.data.jobId, cfsqltype = "cf_sql_varchar"},
				failedAt = {value = local.now, cfsqltype = "wheels_epoch"},
				updatedAt = {value = local.now, cfsqltype = "wheels_epoch"}
			},
			{datasource = application.wheels.dataSourceName}
		);
	}

}
