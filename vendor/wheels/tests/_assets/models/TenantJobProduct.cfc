component extends="Model" {

	/*
	 * Backs JobDeferredEnqueueSpec: saving a product enqueues a job from an afterCreate
	 * callback, inside the save's transaction. The spec creates `qc_products` in both
	 * the default test datasource and wheelstestdb_sqlite_tenant_b.
	 */
	function config() {
		table("qc_products");
		afterCreate("enqueueProbeJob");
	}

	private boolean function enqueueProbeJob() {
		request.tenantJobResult = new wheels.tests._assets.jobs.ProbeJob().enqueue(data = {}, queue = request.tenantJobQueue);
		return true;
	}

}
