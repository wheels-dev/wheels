component extends="wheels.WheelsTest" {

	include "helperFunctions.cfm";

	function beforeAll() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
		migrator = CreateObject("component", "wheels.Migrator").init(
			migratePath = "/wheels/tests/_assets/migrator/migrations/",
			sqlPath = "/wheels/tests/_assets/migrator/sql/"
		);
	}

	function run() {

		var _isCockroachDB = CreateObject("component", "wheels.migrator.Migration").init().adapter.adapterName() == "CockroachDB";

		describe("$ensureTrackingColumns", () => {

			beforeEach(() => {
				for (local.table in ["c_o_r_e_bunyips", "c_o_r_e_dropbears", "c_o_r_e_hoopsnakes"]) {
					try { migration.dropTable(local.table); } catch (any e) {}
				}
				// Wipe the tracking-columns cache so each test sees a fresh state
				StructDelete(application.wheels, "$trackingColumnsEnsured");
				deleteMigratorVersions(2);
				$cleanSqlDirectory();
			});

			afterEach(() => {
				deleteMigratorVersions(2);
				StructDelete(application.wheels, "$trackingColumnsEnsured");
				$cleanSqlDirectory();
			});

			it("adds name and applied_at columns to the tracking table on first call", () => {
				if (_isCockroachDB) return;
				// Force tracking table to be created via migrateTo
				migrator.migrateTo("001");
				// First call should add the columns (the migrator may have already
				// added them via the bootstrap path, but the helper is idempotent)
				var result = migrator.$ensureTrackingColumns();
				expect(result).toBeStruct();
				expect(result.hasName).toBeTrue();
				expect(result.hasAppliedAt).toBeTrue();
				expect(result.errors).toBeArray();
				expect(ArrayLen(result.errors)).toBe(0);
			});

			it("is idempotent — second call adds nothing", () => {
				if (_isCockroachDB) return;
				migrator.migrateTo("001");
				migrator.$ensureTrackingColumns();
				var result = migrator.$ensureTrackingColumns();
				expect(result.hasName).toBeTrue();
				expect(result.hasAppliedAt).toBeTrue();
				expect(ArrayLen(result.added)).toBe(0);
			});

			it("populates the name column for newly applied migrations", () => {
				if (_isCockroachDB) return;
				migrator.migrateTo("001");
				// The name column should now contain "create_bunyips_table" for version 001
				var rows = queryExecute(
					"SELECT version, name FROM #application.wheels.migratorTableName# WHERE version = '001'",
					{},
					{datasource = application.wheels.dataSourceName}
				);
				expect(rows.recordCount).toBe(1);
				// The name should be populated — exact value depends on the test migration filename
				expect(Len(rows.name) > 0).toBeTrue();
			});

		});

	}

}
