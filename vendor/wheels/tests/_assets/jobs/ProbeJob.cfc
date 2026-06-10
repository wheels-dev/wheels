/**
 * Test-only job that records what perform() actually received so specs can verify
 * payload delivery, tenant restoration, and internal-key stripping on both the
 * Job.$processJob and JobWorker.$executeJob processing paths.
 */
component extends="wheels.Job" {

	public void function perform(struct data = {}) {
		request.$wheelsJobProbe = {
			data = Duplicate(arguments.data),
			sawInternalKey = StructKeyExists(arguments.data, "$wheelsTenantContext"),
			tenantRestored = false,
			tenantDataSource = "",
			tenantId = ""
		};
		if (IsDefined("request.wheels.tenant.dataSource")) {
			request.$wheelsJobProbe.tenantRestored = true;
			request.$wheelsJobProbe.tenantDataSource = request.wheels.tenant.dataSource;
			request.$wheelsJobProbe.tenantId = request.wheels.tenant.id;
		}
	}
}
