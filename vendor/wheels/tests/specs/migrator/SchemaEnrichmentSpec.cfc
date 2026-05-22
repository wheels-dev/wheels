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

			// CockroachDB skip mirrors the pattern in migratorSpec.cfc,
			// OrphanDetectionSpec.cfc and MigratorInfoSpec.cfc. The
			// numeric-version test fixtures (001/002/003) are exercised
			// against CockroachDB in compat-matrix.yml only as soft-fail
			// (SOFT_FAIL_DBS includes cockroachdb). Keep the guard so the
			// suite stays consistent with the rest of the migrator specs.
			beforeEach(() => {
				for (local.table in ["c_o_r_e_bunyips", "c_o_r_e_dropbears", "c_o_r_e_hoopsnakes"]) {
					try { migration.dropTable(local.table); } catch (any e) {}
				}
				// Wipe the tracking-columns cache so each test sees a fresh state
				StructDelete(application.wheels, "$trackingColumnsEnsured");
				StructDelete(application.wheels, "$migratorDbType");
				deleteMigratorVersions(2);
				$cleanSqlDirectory();
			});

			afterEach(() => {
				deleteMigratorVersions(2);
				StructDelete(application.wheels, "$trackingColumnsEnsured");
				StructDelete(application.wheels, "$migratorDbType");
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
				// Assert directly on the value so a failure shows the actual
				// name in the message — not just "Expected [false] to be [true]"
				// which would happen if we collapsed Len(...) > 0 to a boolean
				// before the matcher saw it.
				expect(rows.name).notToBeEmpty();
			});

			it("populates applied_at for newly applied migrations", () => {
				if (_isCockroachDB) return;
				migrator.migrateTo("001");
				// applied_at is the column-DEFAULT CURRENT_TIMESTAMP on most
				// engines; SQLite gets an explicit CFML-side Now() because it
				// can't DEFAULT a column on ADD COLUMN. Either way the value
				// should be a parseable date string after migration.
				var rows = queryExecute(
					"SELECT applied_at FROM #application.wheels.migratorTableName# WHERE version = '001'",
					{},
					{datasource = application.wheels.dataSourceName}
				);
				expect(rows.recordCount).toBe(1);
				expect(IsDate(rows.applied_at)).toBeTrue();
			});

			it("populates applied_at across app restarts (regression for round-2 C2)", () => {
				if (_isCockroachDB) return;
				// First "app run": migrate 001, which adds the enriched
				// columns and caches $migratorDbType + $trackingColumnsEnsured.
				migrator.migrateTo("001");
				// Simulate an app restart: wipe both app-scope caches but
				// leave the schema in place. The columns are already present
				// in the DB; the next $ensureTrackingColumns() call must
				// repopulate $migratorDbType BEFORE the early-return fires,
				// otherwise SQLite would write NULL into applied_at on the
				// next $setVersionAsMigrated insert (no DEFAULT on SQLite).
				StructDelete(application.wheels, "$trackingColumnsEnsured");
				StructDelete(application.wheels, "$migratorDbType");
				// Second "app run": apply another migration.
				migrator.migrateTo("002");
				var rows = queryExecute(
					"SELECT applied_at FROM #application.wheels.migratorTableName# WHERE version = '002'",
					{},
					{datasource = application.wheels.dataSourceName}
				);
				expect(rows.recordCount).toBe(1);
				expect(IsDate(rows.applied_at)).toBeTrue();
			});

		});

	}

}
