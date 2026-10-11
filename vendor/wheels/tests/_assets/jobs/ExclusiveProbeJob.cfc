/**
 * An exclusive job (core-suite fixture). perform() counts its runs and records who held its
 * lease while it ran, so the lease specs can see both.
 */
component extends="wheels.Job" {

	function config() {
		super.config();
		this.exclusive = true;
	}

	public void function perform(struct data = {}) {
		if (!StructKeyExists(application, "$leaseSpecRuns")) {
			application["$leaseSpecRuns"] = 0;
		}
		application["$leaseSpecRuns"] = application["$leaseSpecRuns"] + 1;
		local.rows = queryExecute(
			"SELECT lockowner FROM wheels_job_locks WHERE lockname = :name",
			{name = {value = "job:wheels.tests._assets.jobs.ExclusiveProbeJob", cfsqltype = "cf_sql_varchar"}},
			{datasource = application.wheels.dataSourceName}
		);
		application["$leaseSpecHolder"] = local.rows.recordCount ? local.rows.lockowner : "";
	}

}
