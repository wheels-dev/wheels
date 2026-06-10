component extends="wheels.WheelsTest" {

	include "helperFunctions.cfm";

	function beforeAll() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
		migrator = CreateObject("component", "wheels.Migrator").init(
			migratePath = "/wheels/tests/_assets/migrator/migrations/",
			sqlPath = "/wheels/tests/_assets/migrator/sql/"
		);
		errorPathMigrator = CreateObject("component", "wheels.Migrator").init(
			migratePath = "/wheels/tests/_assets/migrator-error-path/migrations/",
			sqlPath = "/wheels/tests/_assets/migrator-error-path/sql/"
		);
		wrapperMigrator = CreateObject("component", "wheels.Migrator").init(
			migratePath = "/wheels/tests/_assets/migrator/migrations_2789/",
			sqlPath = "/wheels/tests/_assets/migrator/sql_2789/"
		);
	}

	function run() {

		var _isCockroachDB = CreateObject("component", "wheels.migrator.Migration").init().adapter.adapterName() == "CockroachDB";

		// The missingMigFlag path used to delete the current version's tracking
		// row before the loop and re-insert it (without a migration name) after
		// — non-transactionally. A crash between the two lost the row, and the
		// nameless re-insert nulled the enriched name/applied_at columns.
		describe("missing-migration runs preserve the current version row", () => {

			beforeEach(() => {
				for (local.table in ["c_o_r_e_bunyips", "c_o_r_e_dropbears", "c_o_r_e_hoopsnakes"]) {
					try { migration.dropTable(local.table); } catch (any e) {}
				}
				deleteMigratorVersions(2);
				$cleanSqlDirectory();
			});

			afterEach(() => {
				for (local.table in ["c_o_r_e_bunyips", "c_o_r_e_dropbears", "c_o_r_e_hoopsnakes"]) {
					try { migration.dropTable(local.table); } catch (any e) {}
				}
				deleteMigratorVersions(2);
				$cleanSqlDirectory();
			});

			it("keeps the enriched name on the top version row after a missingMigFlag run", () => {
				if (_isCockroachDB) return;
				migrator.migrateTo("003");
				// Simulate a "missing" gap migration: remove 002's tracking row
				// and its table so the file counts as pending again.
				queryExecute(
					"DELETE FROM #application.wheels.migratorTableName# WHERE version = '002'",
					{},
					{ datasource = application.wheels.dataSourceName }
				);
				try { migration.dropTable("c_o_r_e_dropbears"); } catch (any e) {}
				migrator.migrateTo("002", true);
				var rows = queryExecute(
					"SELECT version, name FROM #application.wheels.migratorTableName# WHERE version = '003'",
					{},
					{ datasource = application.wheels.dataSourceName }
				);
				expect(rows.recordCount).toBe(
					1,
					"The current version row (003) must survive a missing-migration run untouched."
				);
				expect(rows.name).notToBeEmpty(
					"The enriched name column on the current version row must be preserved — "
					& "the old delete/re-insert pair re-inserted the row without a name."
				);
			});

			it("does not insert a bogus '0' row when run against an empty tracking table", () => {
				if (_isCockroachDB) return;
				migrator.migrateTo("001", true);
				var rows = queryExecute(
					"SELECT version FROM #application.wheels.migratorTableName# WHERE version = '0'",
					{},
					{ datasource = application.wheels.dataSourceName }
				);
				expect(rows.recordCount).toBe(
					0,
					"The old re-insert wrote the '0' empty-table sentinel into the tracking table."
				);
			});

		});

		// redoMigration() previously ran down()+up() with no transaction and
		// without request.$wheelsTransactionWrapper — a failed up() left DML
		// half-applied and migrations opened their own nested transactions.
		describe("redoMigration runs inside the shared transaction wrapper", () => {

			beforeEach(() => {
				deleteMigratorVersions(2);
				try {
					queryExecute(
						"DELETE FROM c_o_r_e_tags WHERE name IN ('issue2789_via_model_create', 'redo_rollback_probe')",
						{},
						{ datasource = application.wheels.dataSourceName }
					);
				} catch (any e) {}
				StructDelete(request, "$issue2789FlagDuringUp");
				StructDelete(request, "$wheelsTransactionWrapper");
				for (local.path in [errorPathMigrator.paths.sql, wrapperMigrator.paths.sql]) {
					if (DirectoryExists(local.path)) {
						DirectoryDelete(local.path, true);
					}
				}
			});

			afterEach(() => {
				deleteMigratorVersions(2);
				try {
					queryExecute(
						"DELETE FROM c_o_r_e_tags WHERE name IN ('issue2789_via_model_create', 'redo_rollback_probe')",
						{},
						{ datasource = application.wheels.dataSourceName }
					);
				} catch (any e) {}
				StructDelete(request, "$issue2789FlagDuringUp");
				StructDelete(request, "$wheelsTransactionWrapper");
				for (local.path in [errorPathMigrator.paths.sql, wrapperMigrator.paths.sql]) {
					if (DirectoryExists(local.path)) {
						DirectoryDelete(local.path, true);
					}
				}
			});

			it("sets request.$wheelsTransactionWrapper for the duration of up()", () => {
				if (_isCockroachDB) return;
				wrapperMigrator.redoMigration("001");
				expect(request.$issue2789FlagDuringUp).toBeTrue(
					"redoMigration() must set request.$wheelsTransactionWrapper while the "
					& "migration runs (issue ##2789), like every other migration path."
				);
			});

			it("rolls back DML written by up() when the redo fails", () => {
				if (_isCockroachDB) return;
				var output = errorPathMigrator.redoMigration("005");
				expect(output).toInclude("Error re-running 005");
				expect(output).toInclude("synthetic failure after DML");
				var found = queryExecute(
					"SELECT id FROM c_o_r_e_tags WHERE name = 'redo_rollback_probe'",
					{},
					{ datasource = application.wheels.dataSourceName }
				);
				expect(found.recordCount).toBe(
					0,
					"The tag written by up() before the failure must be rolled back — "
					& "redoMigration() used to run without any transaction, leaving it behind."
				);
				expect(StructKeyExists(request, "$wheelsTransactionWrapper")).toBeFalse();
			});

		});

		// $getVersionsPreviouslyMigrated() used to bootstrap the system tables
		// (CREATE TABLE + ALTERs) from every read path via catch-as-control-flow,
		// which made doctor()'s "pure read" docstring false.
		describe("read paths do not create the migrator system tables", () => {

			beforeEach(() => {
				for (local.table in ["c_o_r_e_bunyips", "c_o_r_e_dropbears", "c_o_r_e_hoopsnakes"]) {
					try { migration.dropTable(local.table); } catch (any e) {}
				}
				// Drop both naming families, child tables before the levels
				// parent (mirrors migratorSpec.cfc's ##2664 pattern).
				for (local.table in ["wheels_migrator_versions", "c_o_r_e_migrator_versions", "wheels_levels", "c_o_r_e_levels"]) {
					try { migration.dropTable(local.table); } catch (any e) {}
				}
				$cleanSqlDirectory();
			});

			afterEach(() => {
				for (local.table in ["c_o_r_e_bunyips", "c_o_r_e_dropbears", "c_o_r_e_hoopsnakes"]) {
					try { migration.dropTable(local.table); } catch (any e) {}
				}
				// Leave the suite with freshly bootstrapped (empty) system
				// tables so later specs find them in the expected state.
				for (local.table in ["wheels_migrator_versions", "c_o_r_e_migrator_versions", "wheels_levels", "c_o_r_e_levels"]) {
					try { migration.dropTable(local.table); } catch (any e) {}
				}
				migrator.migrateTo("0");
				$cleanSqlDirectory();
			});

			it("doctor() reports state without bootstrapping the tracking table", () => {
				if (_isCockroachDB) return;
				var report = migrator.doctor();
				expect(report.healthy).toBeFalse();
				expect(report.summary.pending).toBe(3);
				expect(ArrayLen(report.orphans)).toBe(0);
				var info = application.wo.$dbinfo(
					datasource = application.wheels.dataSourceName,
					type = "tables",
					pattern = application.wheels.migratorTableName
				);
				expect(ListFindNoCase(ValueList(info.table_name), application.wheels.migratorTableName)).toBeFalse(
					"doctor() is documented as a pure read — it must not create #application.wheels.migratorTableName#."
				);
			});

			it("getCurrentMigrationVersion() reports 0 without bootstrapping", () => {
				if (_isCockroachDB) return;
				expect(migrator.getCurrentMigrationVersion()).toBe("0");
				var info = application.wo.$dbinfo(
					datasource = application.wheels.dataSourceName,
					type = "tables",
					pattern = application.wheels.migratorTableName
				);
				expect(ListFindNoCase(ValueList(info.table_name), application.wheels.migratorTableName)).toBeFalse();
			});

			it("migrateTo() still bootstraps the tables that reads left alone", () => {
				if (_isCockroachDB) return;
				migrator.doctor();
				migrator.migrateTo("001");
				var info = application.wo.$dbinfo(
					datasource = application.wheels.dataSourceName,
					type = "tables",
					pattern = application.wheels.migratorTableName
				);
				expect(ListFindNoCase(ValueList(info.table_name), application.wheels.migratorTableName)).toBeTrue();
				expect(migrator.getCurrentMigrationVersion()).toBe("001");
			});

		});

		// doctor()/info/migrateTo() now compute the applied-versions list and
		// the migrations array once and thread them through the helpers.
		describe("precomputed inputs are honored by the read helpers", () => {

			it("getAvailableMigrations honors a caller-supplied previousMigrationList", () => {
				var migs = migrator.getAvailableMigrations(previousMigrationList = "001,003");
				expect(ArrayLen(migs)).toBe(3);
				expect(migs[1].status).toBe("migrated");
				expect(migs[2].status).toBe("");
				expect(migs[3].status).toBe("migrated");
			});

			it("$getOrphanVersions honors supplied appliedList and migrations", () => {
				var migs = migrator.getAvailableMigrations(previousMigrationList = "001,999");
				var orphans = migrator.$getOrphanVersions(appliedList = "001,999", migrations = migs);
				expect(ArrayLen(orphans)).toBe(1);
				expect(orphans[1]).toBe("999");
			});

		});

	}

}
