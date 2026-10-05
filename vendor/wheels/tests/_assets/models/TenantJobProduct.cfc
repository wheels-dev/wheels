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

}
