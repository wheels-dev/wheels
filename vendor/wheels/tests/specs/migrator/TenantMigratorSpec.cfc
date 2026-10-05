component extends="wheels.WheelsTest" {

	include "helperFunctions.cfm";

	function beforeAll() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
		migrator = CreateObject("component", "wheels.Migrator").init(
			migratePath = "/wheels/tests/_assets/migrator/migrations/",
			sqlPath = "/wheels/tests/_assets/migrator/sql/"
		);
		tenantMigrator = CreateObject("component", "wheels.migrator.TenantMigrator").init();
		fixtureMigratePath = "/wheels/tests/_assets/migrator/migrations/";
		fixtureSqlPath = "/wheels/tests/_assets/migrator/sql/";
	}

	function run() {

		var _isCockroachDB = CreateObject("component", "wheels.migrator.Migration").init().adapter.adapterName() == "CockroachDB";

		describe("TenantMigrator migrateAll", () => {

			beforeEach(() => {
				for (local.table in ["c_o_r_e_bunyips", "c_o_r_e_dropbears", "c_o_r_e_hoopsnakes"]) {
					try { migration.dropTable(local.table); } catch (any e) {}
				}
				deleteMigratorVersions(2);
			});

			afterEach(() => {
				for (local.table in ["c_o_r_e_bunyips", "c_o_r_e_dropbears", "c_o_r_e_hoopsnakes"]) {
					try { migration.dropTable(local.table); } catch (any e) {}
				}
				deleteMigratorVersions(2);
				// The suite shares a request scope across specs — never leak a
				// tenant context set by one of the tests below.
				if (StructKeyExists(request, "wheels")) {
					StructDelete(request.wheels, "tenant");
				}
			});

			it("action=latest migrates the tenant datasource to the latest fixture version", () => {
				if (_isCockroachDB) {
					skip("CockroachDB is skipped for this migrator assertion; a bare return would mark it green.");
					return;
				}
				var results = tenantMigrator.migrateAll(
					action = "latest",
					tenants = [{id = "t1", dataSource = application.wheels.dataSourceName}],
					migratePath = fixtureMigratePath,
					sqlPath = fixtureSqlPath
				);
				expect(results.total).toBe(1);
				expect(ArrayLen(results.failed)).toBe(0);
				expect(ArrayLen(results.success)).toBe(1);
				expect(migrator.getCurrentMigrationVersion()).toBe("003");
			});

			it("action=up applies exactly one pending migration", () => {
				if (_isCockroachDB) {
					skip("CockroachDB is skipped for this migrator assertion; a bare return would mark it green.");
					return;
				}
				var results = tenantMigrator.migrateAll(
					action = "up",
					tenants = [{id = "t1", dataSource = application.wheels.dataSourceName}],
					migratePath = fixtureMigratePath,
					sqlPath = fixtureSqlPath
				);
				expect(ArrayLen(results.failed)).toBe(0);
				expect(ArrayLen(results.success)).toBe(1);
				expect(migrator.getCurrentMigrationVersion()).toBe("001");
			});

			it("action=down rolls back one version", () => {
				if (_isCockroachDB) {
					skip("CockroachDB is skipped for this migrator assertion; a bare return would mark it green.");
					return;
				}
				migrator.migrateTo("002");
				var results = tenantMigrator.migrateAll(
					action = "down",
					tenants = [{id = "t1", dataSource = application.wheels.dataSourceName}],
					migratePath = fixtureMigratePath,
					sqlPath = fixtureSqlPath
				);
				expect(ArrayLen(results.failed)).toBe(0);
				expect(ArrayLen(results.success)).toBe(1);
				expect(migrator.getCurrentMigrationVersion()).toBe("001");
			});

			it("action=info returns output without mutating the version", () => {
				if (_isCockroachDB) {
					skip("CockroachDB is skipped for this migrator assertion; a bare return would mark it green.");
					return;
				}
				migrator.migrateTo("001");
				var results = tenantMigrator.migrateAll(
					action = "info",
					tenants = [{id = "t1", dataSource = application.wheels.dataSourceName}],
					migratePath = fixtureMigratePath,
					sqlPath = fixtureSqlPath
				);
				expect(ArrayLen(results.failed)).toBe(0);
				expect(ArrayLen(results.success)).toBe(1);
				expect(results.success[1].output).toInclude("Current version:");
				expect(migrator.getCurrentMigrationVersion()).toBe("001");
			});

			it("restores the application datasource and a pre-existing request tenant context", () => {
				if (_isCockroachDB) {
					skip("CockroachDB is skipped for this migrator assertion; a bare return would mark it green.");
					return;
				}
				var originalDataSourceName = application.wheels.dataSourceName;
				if (!StructKeyExists(request, "wheels")) {
					request.wheels = {};
				}
				request.wheels.tenant = {id = "preexisting", dataSource = originalDataSourceName, config = {}};
				var results = tenantMigrator.migrateAll(
					action = "info",
					tenants = [{id = "t1", dataSource = originalDataSourceName}],
					migratePath = fixtureMigratePath,
					sqlPath = fixtureSqlPath
				);
				expect(ArrayLen(results.success)).toBe(1);
				expect(application.wheels.dataSourceName).toBe(originalDataSourceName);
				expect(StructKeyExists(request.wheels, "tenant")).toBeTrue();
				expect(request.wheels.tenant.id).toBe("preexisting");
			});

			it("records the failure and continues when stopOnError=false", () => {
				if (_isCockroachDB) {
					skip("CockroachDB is skipped for this migrator assertion; a bare return would mark it green.");
					return;
				}
				var results = tenantMigrator.migrateAll(
					action = "info",
					tenants = [
						{id = "bad", dataSource = "wheels_no_such_ds_xyz"},
						{id = "good", dataSource = application.wheels.dataSourceName}
					],
					stopOnError = false,
					migratePath = fixtureMigratePath,
					sqlPath = fixtureSqlPath
				);
				expect(results.total).toBe(2);
				expect(ArrayLen(results.failed)).toBe(1);
				expect(ArrayLen(results.success)).toBe(1);
				expect(results.failed[1].tenant).toBe("bad");
				expect(results.success[1].tenant).toBe("good");
			});

			it("stops after the first failure when stopOnError=true", () => {
				if (_isCockroachDB) {
					skip("CockroachDB is skipped for this migrator assertion; a bare return would mark it green.");
					return;
				}
				var results = tenantMigrator.migrateAll(
					action = "info",
					tenants = [
						{id = "bad", dataSource = "wheels_no_such_ds_xyz"},
						{id = "good", dataSource = application.wheels.dataSourceName}
					],
					stopOnError = true,
					migratePath = fixtureMigratePath,
					sqlPath = fixtureSqlPath
				);
				expect(results.total).toBe(2);
				expect(ArrayLen(results.failed)).toBe(1);
				expect(ArrayLen(results.success)).toBe(0);
				expect(results.failed[1].tenant).toBe("bad");
			});

			it("throws Wheels.TenantMigrator.InvalidAction for an unknown action", () => {
				expect(() => {
					tenantMigrator.migrateAll(
						action = "sideways",
						tenants = [{id = "t1", dataSource = application.wheels.dataSourceName}],
						migratePath = fixtureMigratePath,
						sqlPath = fixtureSqlPath
					);
				}).toThrow("Wheels.TenantMigrator.InvalidAction");
			});

			it("resolves tenants from a tenantProvider closure", () => {
				if (_isCockroachDB) {
					skip("CockroachDB is skipped for this migrator assertion; a bare return would mark it green.");
					return;
				}
				// Hoisted before the named-arg call (Adobe CF chokes on inline
				// closures passed as named arguments). Reads the application
				// scope directly rather than capturing an outer local var.
				var provider = function() {
					return [{id = "fromProvider", dataSource = application.wheels.dataSourceName}];
				};
				var results = tenantMigrator.migrateAll(
					action = "info",
					tenantProvider = provider,
					migratePath = fixtureMigratePath,
					sqlPath = fixtureSqlPath
				);
				expect(results.total).toBe(1);
				expect(ArrayLen(results.success)).toBe(1);
				expect(results.success[1].tenant).toBe("fromProvider");
			});

		});

		// A failed up()/down() is caught by the migrator and RETURNED in the
		// step's output rather than thrown. migrateAll() used to classify tenants
		// only by thrown exceptions, so a tenant whose migration failed was listed
		// under `success` with the error buried in its output text.
		describe("TenantMigrator migrateAll with a failing migration step", () => {

			var errorMigratePath = "/wheels/tests/_assets/migrator-error-path/migrations/";
			var errorSqlPath = "/wheels/tests/_assets/migrator-error-path/sql/";
			var noTxMigratePath = "/wheels/tests/_assets/migrator/notransaction_fail/";
			var noTxSqlPath = "/wheels/tests/_assets/migrator/sql_tenant_notransaction_fail/";

			beforeEach(() => {
				$clearPlantedVersions();
			});

			afterEach(() => {
				$clearPlantedVersions();
				if (StructKeyExists(request, "wheels")) {
					StructDelete(request.wheels, "tenant");
				}
			});

			it("lists the tenant under failed, with the error and the full output", () => {
				if (_isCockroachDB) {
					skip("CockroachDB is skipped for this migrator assertion; a bare return would mark it green.");
					return;
				}
				var results = tenantMigrator.migrateAll(
					action = "latest",
					tenants = [{id = "t1", dataSource = application.wheels.dataSourceName}],
					migratePath = errorMigratePath,
					sqlPath = errorSqlPath
				);
				expect(results.total).toBe(1);
				expect(ArrayLen(results.success)).toBe(0, "a tenant whose migration failed must not be reported as a success");
				expect(ArrayLen(results.failed)).toBe(1);
				expect(results.failed[1].tenant).toBe("t1");
				expect(results.failed[1].dataSource).toBe(application.wheels.dataSourceName);
				expect(results.failed[1].error).toInclude("synthetic failure");
				expect(results.failed[1].version).toBe("004");
				expect(results.failed[1].output).toInclude("Error migrating to 004");
			});

			it("lists a tenant whose no-transaction step failed under failed, keeping the not-rolled-back note", () => {
				if (_isCockroachDB) {
					skip("CockroachDB is skipped for this migrator assertion; a bare return would mark it green.");
					return;
				}
				var results = tenantMigrator.migrateAll(
					action = "latest",
					tenants = [{id = "t1", dataSource = application.wheels.dataSourceName}],
					migratePath = noTxMigratePath,
					sqlPath = noTxSqlPath
				);
				expect(ArrayLen(results.success)).toBe(0);
				expect(ArrayLen(results.failed)).toBe(1);
				expect(results.failed[1].error).toInclude("deliberate failure after the step started");
				expect(results.failed[1].output).toInclude("were not rolled back");
			});

			it("stops after the first failed tenant when stopOnError=true", () => {
				if (_isCockroachDB) {
					skip("CockroachDB is skipped for this migrator assertion; a bare return would mark it green.");
					return;
				}
				var results = tenantMigrator.migrateAll(
					action = "latest",
					tenants = [
						{id = "first", dataSource = application.wheels.dataSourceName},
						{id = "second", dataSource = application.wheels.dataSourceName}
					],
					migratePath = errorMigratePath,
					sqlPath = errorSqlPath
				);
				expect(results.total).toBe(2);
				expect(ArrayLen(results.failed)).toBe(1);
				expect(ArrayLen(results.success)).toBe(0);
				expect(results.failed[1].tenant).toBe("first");
			});

			it("records every failed tenant and continues when stopOnError=false", () => {
				if (_isCockroachDB) {
					skip("CockroachDB is skipped for this migrator assertion; a bare return would mark it green.");
					return;
				}
				var results = tenantMigrator.migrateAll(
					action = "latest",
					tenants = [
						{id = "first", dataSource = application.wheels.dataSourceName},
						{id = "second", dataSource = application.wheels.dataSourceName}
					],
					stopOnError = false,
					migratePath = errorMigratePath,
					sqlPath = errorSqlPath
				);
				expect(ArrayLen(results.failed)).toBe(2);
				expect(ArrayLen(results.success)).toBe(0);
				expect(results.failed[2].tenant).toBe("second");
			});

			it("reports action=up and action=down failures the same way", () => {
				if (_isCockroachDB) {
					skip("CockroachDB is skipped for this migrator assertion; a bare return would mark it green.");
					return;
				}
				var results = tenantMigrator.migrateAll(
					action = "up",
					tenants = [{id = "t1", dataSource = application.wheels.dataSourceName}],
					migratePath = errorMigratePath,
					sqlPath = errorSqlPath
				);
				expect(ArrayLen(results.success)).toBe(0);
				expect(ArrayLen(results.failed)).toBe(1);
				expect(results.failed[1].version).toBe("004");
			});
		});

		describe("Migrator.$lastStepFailure()", () => {

			beforeEach(() => {
				$clearPlantedVersions();
			});

			afterEach(() => {
				$clearPlantedVersions();
			});

			it("describes the failed step after migrateTo() returns a failure, and resets on the next run", () => {
				if (_isCockroachDB) {
					skip("CockroachDB is skipped for this migrator assertion; a bare return would mark it green.");
					return;
				}
				var failing = CreateObject("component", "wheels.Migrator").init(
					migratePath = "/wheels/tests/_assets/migrator-error-path/migrations/",
					sqlPath = "/wheels/tests/_assets/migrator-error-path/sql/"
				);
				var output = failing.migrateToLatest();
				// The returned text is unchanged: callers that read it keep working.
				expect(output).toInclude("Error migrating to 004");
				var failure = failing.$lastStepFailure();
				expect(failure.failed).toBeTrue();
				expect(failure.version).toBe("004");
				expect(failure.direction).toBe("up");
				expect(failure.error).toInclude("synthetic failure");

				// A clean run on the same instance clears it.
				failing.migrateTo("0");
				expect(failing.$lastStepFailure().failed).toBeFalse();
			});

			it("reports no failure after a successful run", () => {
				if (_isCockroachDB) {
					skip("CockroachDB is skipped for this migrator assertion; a bare return would mark it green.");
					return;
				}
				var ok = CreateObject("component", "wheels.Migrator").init(
					migratePath = fixtureMigratePath,
					sqlPath = fixtureSqlPath
				);
				ok.migrateTo("001");
				expect(ok.$lastStepFailure().failed).toBeFalse();
				ok.migrateTo("0");
			});
		});

	}

	/** Clears every version the failing fixtures could record, so a run starts from nothing. */
	private void function $clearPlantedVersions() {
		deleteMigratorVersions(2);
		for (var v in ["001", "002", "003", "004", "005", "90000000000012"]) {
			try {
				queryExecute(
					"DELETE FROM #application.wheels.migratorTableName# WHERE version = :v",
					{v = {value = v, cfsqltype = "cf_sql_varchar"}},
					{datasource = application.wheels.dataSourceName}
				);
			} catch (any e) {
				// Table not bootstrapped yet on a first run: nothing to clear.
			}
		}
		for (var t in ["c_o_r_e_bunyips", "c_o_r_e_dropbears", "c_o_r_e_hoopsnakes"]) {
			try { migration.dropTable(t); } catch (any e) {}
		}
	}

}
