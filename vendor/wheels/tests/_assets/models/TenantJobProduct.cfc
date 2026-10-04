component extends="Model" {

	/*
	 * Backs JobDeferredEnqueueSpec: saving a product enqueues a job from an afterCreate
	 * callback, inside the save's transaction. The spec creates `tenant_job_products` on
	 * the default test datasource and on wheelstestdb_sqlite_tenant_b.
	 */
	function config() {
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
		model("TenantJobProduct").create(name = "kept", transaction = "none");
		model("TenantJobProduct").invokeWithTransaction(method = "txnFailingUnit", transaction = "savepoint");
		return true;
	}

	public boolean function txnFailingUnit() {
		request.tenantJobQueue = "deferred_unit";
		model("TenantJobProduct").create(name = "unit", transaction = "none");
		return false;
	}

}
