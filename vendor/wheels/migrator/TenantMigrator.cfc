/**
 * Runs database migrations across multiple tenant datasources.
 * Wraps the standard Wheels migrator to iterate over tenants.
 *
 * Usage:
 *   var tm = new wheels.migrator.TenantMigrator();
 *   var results = tm.migrateAll(
 *     action = "latest",
 *     tenants = [
 *       {id: "acme", dataSource: "acme_ds"},
 *       {id: "globex", dataSource: "globex_ds"}
 *     ]
 *   );
 *
 * Or with a dynamic provider:
 *   var results = tm.migrateAll(
 *     action = "latest",
 *     tenantProvider = function() {
 *       return model("Tenant").findAll(returnAs="structs");
 *     }
 *   );
 *
 * [section: Migrator]
 * [category: Multi-Tenancy]
 */
component {

	/**
	 * Constructor.
	 */
	public TenantMigrator function init() {
		return this;
	}

	/**
	 * Run migrations against all tenant datasources.
	 *
	 * @action Migration action: "latest", "up", "down", or "info".
	 * @tenants Array of tenant structs, each with at minimum a `dataSource` key. Optional: `id`.
	 * @tenantProvider Closure that returns an array of tenant structs. Used when tenants is empty.
	 * @stopOnError If true (default), stops on the first tenant that fails. If false, collects errors and continues.
	 */
	public struct function migrateAll(
		string action = "latest",
		array tenants = [],
		any tenantProvider,
		boolean stopOnError = true
	) {
		local.results = {
			success: [],
			failed: [],
			total: 0
		};

		// Resolve tenants from provider if no static list given
		local.tenantList = arguments.tenants;
		if (ArrayIsEmpty(local.tenantList) && StructKeyExists(arguments, "tenantProvider") && IsClosure(arguments.tenantProvider)) {
			local.tenantList = arguments.tenantProvider();
		}

		if (!IsArray(local.tenantList) || ArrayIsEmpty(local.tenantList)) {
			return local.results;
		}

		local.results.total = ArrayLen(local.tenantList);

		for (local.tenant in local.tenantList) {
			if (!IsStruct(local.tenant) || !StructKeyExists(local.tenant, "dataSource") || !Len(local.tenant.dataSource)) {
				ArrayAppend(local.results.failed, {
					tenant: local.tenant,
					error: "Tenant struct missing required 'dataSource' key"
				});
				if (arguments.stopOnError) break;
				continue;
			}

			local.tenantId = StructKeyExists(local.tenant, "id") ? local.tenant.id : local.tenant.dataSource;

			try {
				// Set the tenant context so migrations use the correct datasource
				if (!StructKeyExists(request, "wheels")) {
					request.wheels = {};
				}
				request.wheels.tenant = {
					id: local.tenantId,
					dataSource: local.tenant.dataSource,
					config: StructKeyExists(local.tenant, "config") ? local.tenant.config : {}
				};

				// Run the standard migrator with the tenant's datasource
				local.migrator = $createMigrator(local.tenant.dataSource);
				local.output = local.migrator.migrate(arguments.action);

				ArrayAppend(local.results.success, {
					tenant: local.tenantId,
					dataSource: local.tenant.dataSource,
					output: local.output
				});
			} catch (any e) {
				ArrayAppend(local.results.failed, {
					tenant: local.tenantId,
					dataSource: local.tenant.dataSource,
					error: e.message
				});
				if (arguments.stopOnError) break;
			} finally {
				// Clean up tenant context
				StructDelete(request.wheels, "tenant");
			}
		}

		return local.results;
	}

	/**
	 * Create a migrator instance configured for a specific datasource.
	 * Temporarily overrides the application datasource for the migration run.
	 */
	private any function $createMigrator(required string dataSource) {
		local.appKey = "wheels";
		local.originalDS = application[local.appKey].dataSourceName;

		// Temporarily set the application datasource to the tenant's
		application[local.appKey].dataSourceName = arguments.dataSource;

		try {
			local.migrator = new wheels.migrator.Migrator();
		} finally {
			// Restore original datasource
			application[local.appKey].dataSourceName = local.originalDS;
		}

		return local.migrator;
	}

}
