/**
 * Test double for TenantMigrator hardener B5.
 * Captures application.wheels.dataSourceName (and any request-scoped override)
 * at the start of $executeAction — after $runForTenant has entered its lock.
 */
component extends="wheels.migrator.TenantMigrator" {

	public any function $executeAction(required any migrator, required string action) {
		request.hardenerTenantMigratorAppDs = application.wheels.dataSourceName;
		if (IsDefined("request.wheels.migratorDataSource") && Len(ToString(request.wheels.migratorDataSource))) {
			request.hardenerTenantMigratorOverrideDs = request.wheels.migratorDataSource;
		} else if (IsDefined("request.wheels.tenant.dataSource") && Len(ToString(request.wheels.tenant.dataSource))) {
			request.hardenerTenantMigratorOverrideDs = request.wheels.tenant.dataSource;
		} else {
			request.hardenerTenantMigratorOverrideDs = "";
		}
		if (IsDefined("request.wheels.migratorDataSourceUserName")) {
			request.hardenerTenantMigratorOverrideUser = request.wheels.migratorDataSourceUserName;
		} else {
			request.hardenerTenantMigratorOverrideUser = "";
		}
		return super.$executeAction(argumentCollection = arguments);
	}

}
