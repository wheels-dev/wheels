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
	 * Returns `{success, failed, total}`. A tenant whose migration step failed is
	 * listed under `failed` as `{tenant, dataSource, error, version, direction, output}`
	 * (the migrator reports a failed step in its output instead of throwing); a tenant
	 * that threw, or has no `dataSource`, is listed as `{tenant, dataSource, error}`.
	 * `success` entries are `{tenant, dataSource, output}`.
	 *
	 * @action Migration action: "latest", "up", "down", or "info".
	 * @tenants Array of tenant structs, each with at minimum a `dataSource` key. Optional: `id`.
	 * @tenantProvider Closure that returns an array of tenant structs. Used when tenants is empty.
	 * @stopOnError If true (default), stops on the first tenant that fails. If false, collects errors and continues.
	 * @migratePath Path to the migration files. Defaults to the standard app location.
	 * @sqlPath Path the migrator writes generated SQL files to (when `writeMigratorSQLFiles` is enabled).
	 */
	public struct function migrateAll(
		string action = "latest",
		array tenants = [],
		any tenantProvider,
		boolean stopOnError = true,
		string migratePath = "/app/migrator/migrations/",
		string sqlPath = "/app/migrator/sql/"
	) {
		if (!ListFindNoCase("latest,up,down,info", arguments.action)) {
			Throw(
				type = "Wheels.TenantMigrator.InvalidAction",
				message = "Invalid migration action `#arguments.action#`. Valid actions are `latest`, `up`, `down` and `info`."
			);
		}

		local.results = {
			success = [],
			failed = [],
			total = 0
		};

		// Resolve tenants from provider if no static list given
		local.tenantList = arguments.tenants;
		if (ArrayIsEmpty(local.tenantList) && StructKeyExists(arguments, "tenantProvider") && (IsCustomFunction(arguments.tenantProvider) || IsClosure(arguments.tenantProvider))) {
			local.tenantList = arguments.tenantProvider();
		}

		if (!IsArray(local.tenantList) || ArrayIsEmpty(local.tenantList)) {
			return local.results;
		}

		local.results.total = ArrayLen(local.tenantList);

		// Snapshot any pre-existing tenant context (e.g. set by TenantResolver
		// middleware) so it can be restored after the run instead of deleted.
		if (!StructKeyExists(request, "wheels")) {
			request.wheels = {};
		}
		local.hadRequestTenant = StructKeyExists(request.wheels, "tenant");
		if (local.hadRequestTenant) {
			local.originalRequestTenant = request.wheels.tenant;
		}

		try {
			for (local.tenant in local.tenantList) {
				if (!IsStruct(local.tenant) || !StructKeyExists(local.tenant, "dataSource") || !Len(local.tenant.dataSource)) {
					ArrayAppend(local.results.failed, {
						tenant = local.tenant,
						error = "Tenant struct missing required 'dataSource' key"
					});
					if (arguments.stopOnError) break;
					continue;
				}

				local.tenantId = StructKeyExists(local.tenant, "id") ? local.tenant.id : local.tenant.dataSource;

				try {
					// Set the tenant context so migrations use the correct datasource
					request.wheels.tenant = {
						id = local.tenantId,
						dataSource = local.tenant.dataSource,
						config = StructKeyExists(local.tenant, "config") ? local.tenant.config : {}
					};

					// Run the standard migrator against the tenant's datasource
					local.run = $runTenantAction(
						action = arguments.action,
						dataSource = local.tenant.dataSource,
						migratePath = arguments.migratePath,
						sqlPath = arguments.sqlPath,
						userName = StructKeyExists(local.tenant, "userName") ? local.tenant.userName : "",
						password = StructKeyExists(local.tenant, "password") ? local.tenant.password : ""
					);

					// The migrator catches a failed up()/down() and reports it in its
					// output instead of throwing, so a failed step never reaches the
					// catch below. Classify the tenant by the migrator's own record.
					if (local.run.failure.failed) {
						ArrayAppend(local.results.failed, {
							tenant = local.tenantId,
							dataSource = local.tenant.dataSource,
							error = local.run.failure.error,
							version = local.run.failure.version,
							direction = local.run.failure.direction,
							output = local.run.output
						});
						if (arguments.stopOnError) break;
					} else {
						ArrayAppend(local.results.success, {
							tenant = local.tenantId,
							dataSource = local.tenant.dataSource,
							output = local.run.output
						});
					}
				} catch (any e) {
					ArrayAppend(local.results.failed, {
						tenant = local.tenantId,
						dataSource = local.tenant.dataSource,
						error = e.message
					});
					if (arguments.stopOnError) break;
				}
			}
		} finally {
			// Restore the pre-existing tenant context (or remove the one we set)
			if (local.hadRequestTenant) {
				request.wheels.tenant = local.originalRequestTenant;
			} else {
				StructDelete(request.wheels, "tenant");
			}
		}

		return local.results;
	}

	/**
	 * Runs a single migration action against one tenant datasource and returns
	 * the migrator's output text. A failed step is in that text but doesn't throw;
	 * use `$runTenantAction()` to get the failure as data.
	 */
	public any function $runForTenant(
		required string action,
		required string dataSource,
		required string migratePath,
		required string sqlPath,
		string userName = "",
		string password = ""
	) {
		return $runTenantAction(argumentCollection = arguments).output;
	}

	/**
	 * Runs a single migration action against one tenant datasource and returns
	 * `{output, failure}`, where `failure` is the migrator's `$lastStepFailure()`
	 * (`{failed, version, direction, error}`).
	 * Isolates the tenant DS on the request (`request.wheels.migratorDataSource`)
	 * instead of mutating `application.wheels.dataSourceName`. Concurrent
	 * requests read the application key without this lock, so swapping it
	 * would route their queries at the tenant. Per-datasource lock serializes
	 * two runs against the same tenant without blocking other tenants.
	 */
	public struct function $runTenantAction(
		required string action,
		required string dataSource,
		required string migratePath,
		required string sqlPath,
		string userName = "",
		string password = ""
	) {
		if (!Len(Trim(arguments.dataSource))) {
			Throw(
				type = "Wheels.TenantMigrator.InvalidDataSource",
				message = "Tenant migration requires a non-empty dataSource."
			);
		}

		if (!StructKeyExists(request, "wheels")) {
			request.wheels = {};
		}
		local.hadOverride = StructKeyExists(request.wheels, "migratorDataSource");
		if (local.hadOverride) {
			local.priorOverride = request.wheels.migratorDataSource;
		}
		request.wheels.migratorDataSource = arguments.dataSource;
		local.hadUser = StructKeyExists(request.wheels, "migratorDataSourceUserName");
		if (local.hadUser) {
			local.priorUser = request.wheels.migratorDataSourceUserName;
			local.priorPassword = StructKeyExists(request.wheels, "migratorDataSourcePassword")
				? request.wheels.migratorDataSourcePassword
				: "";
		}
		if (Len(Trim(arguments.userName))) {
			request.wheels.migratorDataSourceUserName = arguments.userName;
			request.wheels.migratorDataSourcePassword = arguments.password;
		}

		try {
			lock name="wheels_tenant_migrator_#arguments.dataSource#" type="exclusive" timeout="300" {
				local.migrator = $newMigrator(migratePath = arguments.migratePath, sqlPath = arguments.sqlPath);
				local.output = $executeAction(migrator = local.migrator, action = arguments.action);
				local.failure = {failed = false, version = "", direction = "", error = ""};
				if (IsObject(local.migrator) && StructKeyExists(local.migrator, "$lastStepFailure")) {
					local.failure = local.migrator.$lastStepFailure();
				}
				return {output = local.output, failure = local.failure};
			}
		} finally {
			if (local.hadOverride) {
				request.wheels.migratorDataSource = local.priorOverride;
			} else {
				StructDelete(request.wheels, "migratorDataSource");
			}
			if (local.hadUser) {
				request.wheels.migratorDataSourceUserName = local.priorUser;
				request.wheels.migratorDataSourcePassword = local.priorPassword;
			} else {
				StructDelete(request.wheels, "migratorDataSourceUserName");
				StructDelete(request.wheels, "migratorDataSourcePassword");
			}
		}
	}

	/**
	 * Creates a `wheels.Migrator` instance configured for the given paths.
	 */
	public any function $newMigrator(required string migratePath, required string sqlPath) {
		return CreateObject("component", "wheels.Migrator").init(
			migratePath = arguments.migratePath,
			sqlPath = arguments.sqlPath
		);
	}

	/**
	 * Executes one migration action on a migrator instance. Mirrors the
	 * command handling in `vendor/wheels/public/views/cli.cfm`.
	 */
	public any function $executeAction(required any migrator, required string action) {
		switch (arguments.action) {
			case "latest":
				return arguments.migrator.migrateToLatest();
			case "up":
				// Walk the migration list (sorted ascending by version) and
				// migrate to the first pending version after the current one.
				local.currentVersion = arguments.migrator.getCurrentMigrationVersion();
				local.targetVersion = "";
				for (local.migration in arguments.migrator.getAvailableMigrations()) {
					if (local.migration.status != "migrated" && local.migration.version > local.currentVersion) {
						local.targetVersion = local.migration.version;
						break;
					}
				}
				if (Len(local.targetVersion)) {
					return arguments.migrator.migrateTo(local.targetVersion);
				}
				return "No pending migrations. Database is at version #local.currentVersion#.";
			case "down":
				// Walk the list in reverse to find the migration immediately
				// below the current version, then migrate down to it.
				local.currentVersion = arguments.migrator.getCurrentMigrationVersion();
				if (local.currentVersion == "0") {
					return "Database is at version 0; nothing to roll back.";
				}
				local.migrations = arguments.migrator.getAvailableMigrations();
				local.targetVersion = "0";
				for (local.i = ArrayLen(local.migrations); local.i >= 1; local.i--) {
					if (local.migrations[local.i].version < local.currentVersion && local.migrations[local.i].status == "migrated") {
						local.targetVersion = local.migrations[local.i].version;
						break;
					}
				}
				return arguments.migrator.migrateTo(local.targetVersion);
			case "info":
				return ArrayToList(arguments.migrator.$buildInfoOutput(), Chr(10));
		}
		Throw(
			type = "Wheels.TenantMigrator.InvalidAction",
			message = "Invalid migration action `#arguments.action#`. Valid actions are `latest`, `up`, `down` and `info`."
		);
	}

}
