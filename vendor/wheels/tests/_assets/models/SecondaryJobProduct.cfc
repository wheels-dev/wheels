component extends="Model" {

	/*
	 * Backs JobDeferredEnqueueSpec: a model whose own datasource is not the job store's
	 * (wheelstestdb_sqlite_tenant_b, which every engine's test config has). Its transactions
	 * are on another datasource whatever the primary database is, so a job enqueued inside
	 * one is deferred to the commit. Its adapter comes from its own datasource (SQLite).
	 */
	function config() {
		dataSource("wheelstestdb_sqlite_tenant_b");
		table("tenant_job_products");
		afterCreate("enqueueProbeJob");
	}

	private boolean function enqueueProbeJob() {
		var jobClass = request.tenantJobClass ?: "wheels.tests._assets.jobs.ProbeJob";
		request.tenantJobResult = CreateObject("component", jobClass).init().enqueue(data = {}, queue = request.tenantJobQueue);
		return true;
	}

	// Outer unit: one product (and job) kept, then a savepoint unit that rolls back.
	public boolean function txnKeepThenFailingUnit() {
		request.tenantJobQueue = "deferred_kept";
		model("SecondaryJobProduct").create(name = "kept", transaction = "none");
		model("SecondaryJobProduct").invokeWithTransaction(method = "txnFailingUnit", transaction = "savepoint");
		return true;
	}

	public boolean function txnFailingUnit() {
		request.tenantJobQueue = "deferred_unit";
		model("SecondaryJobProduct").create(name = "unit", transaction = "none");
		return false;
	}

}
