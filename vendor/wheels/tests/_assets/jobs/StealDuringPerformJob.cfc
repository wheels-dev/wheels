/**
 * Marks its own row completed, then throws. Reproduces the B1 race:
 * checkTimeouts / a second worker finished the job while this worker
 * still holds the in-memory claim and is about to write fail/retry.
 */
component extends="wheels.Job" {

	public void function perform(struct data = {}) {
		local.now = Now();
		queryExecute(
			"UPDATE wheels_jobs
			SET status = 'completed', completedAt = :completedAt, updatedAt = :updatedAt
			WHERE id = :id",
			{
				id = {value = arguments.data.jobId, cfsqltype = "cf_sql_varchar"},
				completedAt = {value = local.now, cfsqltype = "cf_sql_timestamp"},
				updatedAt = {value = local.now, cfsqltype = "cf_sql_timestamp"}
			},
			{datasource = application.wheels.dataSourceName}
		);
		throw(type = "Wheels.Tests.JobFailure", message = "original worker failed after steal");
	}

}
