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
				if (_isCockroachDB) return;
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
				if (_isCockroachDB) return;
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
				if (_isCockroachDB) return;
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
				if (_isCockroachDB) return;
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
				if (_isCockroachDB) return;
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
				if (_isCockroachDB) return;
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
				if (_isCockroachDB) return;
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
				if (_isCockroachDB) return;
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

	}

}
