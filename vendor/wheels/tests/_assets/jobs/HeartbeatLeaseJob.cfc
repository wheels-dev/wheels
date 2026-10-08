/**
 * An exclusive job that heartbeats (core-suite fixture). perform() records its lease's expiry
 * before and after a heartbeat, so the lease specs can see heartbeat() extend it.
 */
component extends="wheels.Job" {

	function config() {
		super.config();
		this.exclusive = true;
	}

	public void function perform(struct data = {}) {
		application["$leaseSpecBefore"] = $leaseExpiry();
		Sleep(50);
		heartbeat();
		application["$leaseSpecAfter"] = $leaseExpiry();
	}

	private numeric function $leaseExpiry() {
		local.rows = queryExecute(
			"SELECT expiresat FROM wheels_job_locks WHERE lockname = :name",
			{name = {value = "job:wheels.tests._assets.jobs.HeartbeatLeaseJob", cfsqltype = "cf_sql_varchar"}},
			{datasource = application.wheels.dataSourceName}
		);
		return local.rows.recordCount ? Val(local.rows.expiresat) : 0;
	}

}
