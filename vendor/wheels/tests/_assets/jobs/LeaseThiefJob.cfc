/**
 * An exclusive job whose lease is taken over while it runs (core-suite fixture), as happens when
 * a run outlives its lease and another server takes the lease over.
 */
component extends="wheels.Job" {

	function config() {
		super.config();
		this.exclusive = true;
	}

	public void function perform(struct data = {}) {
		queryExecute(
			"UPDATE wheels_job_locks SET lockowner = 'spec-thief' WHERE lockname = :name",
			{name = {value = "job:wheels.tests._assets.jobs.LeaseThiefJob", cfsqltype = "cf_sql_varchar"}},
			{datasource = application.wheels.dataSourceName}
		);
	}

}
