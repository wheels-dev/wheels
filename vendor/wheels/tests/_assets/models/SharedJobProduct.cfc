component extends="Model" {

	/*
	 * Backs JobDeferredEnqueueSpec: a shared model (it ignores the tenant datasource) on the
	 * same table, whose afterCreate enqueues a job. Its transaction is on the job store's
	 * datasource, so the job joins it.
	 */
	function config() {
		table("tenant_job_products");
		sharedModel();
		afterCreate("enqueueProbeJob");
	}

	private boolean function enqueueProbeJob() {
		request.tenantJobResult = new wheels.tests._assets.jobs.ProbeJob().enqueue(data = {}, queue = request.tenantJobQueue);
		return true;
	}

}
