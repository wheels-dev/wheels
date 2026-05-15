component extends="wheels.WheelsTest" {

	include "helperFunctions.cfm"

	function beforeAll() {
		migration = CreateObject("component", "wheels.migrator.Migration").init()
		migrator = CreateObject("component", "wheels.Migrator").init(
			migratePath = "/wheels/tests/_assets/migrator/migrations/",
			sqlPath = "/wheels/tests/_assets/migrator/sql/"
		)
	}

	function run() {

		g = application.wo
		var _isCockroachDB = CreateObject("component", "wheels.migrator.Migration").init().adapter.adapterName() == "CockroachDB";

		describe("Tests that adapter", () => {

			it("is returned in the test environment", () => {
				expect(migration.$getDBType()).toBeGT(0)
			})
		})

		describe("Tests that getAvailableMigrations", () => {

			it("is returning expected value", () => {
				available = migrator.getAvailableMigrations();
				actual = ""
				for (local.i in available) {
					actual = ListAppend(actual, local.i.version)
				}
				expected = "001,002,003"

				expect(actual).toBe(expected)
			})
		})

		describe("Tests that getCurrentMigrationVersion", () => {

			it("is returning expected value", () => {
				if (_isCockroachDB) return;
				for (local.table in ["c_o_r_e_bunyips", "c_o_r_e_dropbears", "c_o_r_e_hoopsnakes"]) {
					migration.dropTable(local.table)
				}
				deleteMigratorVersions(2);
				expected = "002"
				migrator.migrateTo(expected)
				actual = migrator.getCurrentMigrationVersion()

				expect(actual).toBe(expected)

				$cleanSqlDirectory()
			})
		})

		describe("Tests that migrateTo", () => {

			beforeEach(() => {
				for (local.table in ["c_o_r_e_bunyips", "c_o_r_e_dropbears", "c_o_r_e_hoopsnakes", "migrations"]) {
					migration.dropTable(local.table)
				}
				// Drop both FK-bearing tables — MySQL/H2/SQLServer/Oracle scope FK names per-schema so fk_wheels_level collides otherwise.
				for (local.table in ["c_o_r_e_migrator_versions", "wheels_migrator_versions"]) {
					try { migration.dropTable(local.table); } catch (any e) {}
				}
				deleteMigratorVersions(2);
				$cleanSqlDirectory()
				originalWriteMigratorSQLFiles = Duplicate(application.wheels.writeMigratorSQLFiles)
				originalMigratorTableName = Duplicate(application.wheels.migratorTableName)
			})

			afterEach(() => {
				$cleanSqlDirectory()
				// revert to orginal values
				application.wheels.writeMigratorSQLFiles = originalWriteMigratorSQLFiles
				application.wheels.migratorTableName = originalMigratorTableName
			})

			it("is migrating up from 0 to 001", () => {
				if (_isCockroachDB) return;
				migrator.migrateTo(001)
				info = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables", pattern = "c_o_r_e_bunyips")

				actual = ValueList(info.table_name)
				expected = "c_o_r_e_bunyips"

				expect(listFindNoCase(actual, expected)).toBeTrue()
			})

			it("is migrating up from 0 to 003", () => {
				if (_isCockroachDB) return;
				migrator.migrateTo(003)
				info1 = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables", pattern = "c_o_r_e_bunyips")
				info2 = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables", pattern = "c_o_r_e_dropbears")
				info3 = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables", pattern = "c_o_r_e_hoopsnakes")
				actual1 = ValueList(info1.table_name)
				actual2 = ValueList(info2.table_name)
				actual3 = ValueList(info3.table_name)

				expect(listFindNoCase(actual1, "c_o_r_e_bunyips")).toBeTrue()
				expect(listFindNoCase(actual2, "c_o_r_e_dropbears")).toBeTrue()
				expect(listFindNoCase(actual3, "c_o_r_e_hoopsnakes")).toBeTrue()
			})

			it("is migrating down from 003 to 001", () => {
				if (_isCockroachDB) return;
				migrator.migrateTo(003)
				migrator.migrateTo(001)
				info1 = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables", pattern = "c_o_r_e_bunyips")
				info2 = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables", pattern = "c_o_r_e_dropbears")
				info3 = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables", pattern = "c_o_r_e_hoopsnakes")
				actual1 = ValueList(info1.table_name)
				actual2 = ValueList(info2.table_name)
				actual3 = ValueList(info3.table_name)

				expect(listFindNoCase(actual1, "c_o_r_e_bunyips")).toBeTrue()
				expect(listFindNoCase(actual2, "c_o_r_e_dropbears")).toBeFalse()
				expect(listFindNoCase(actual3, "c_o_r_e_hoopsnakes")).toBeFalse()
			})

			it("generates sql files", () => {
				if (_isCockroachDB) return;
				application.wheels.writeMigratorSQLFiles = true

				migrator.migrateTo(002)
				migrator.migrateTo(001)

				for (
					i in [
						"001_create_bunyips_table_up.sql",
						"002_create_dropbears_table_up.sql",
						"002_create_dropbears_table_down.sql"
					]
				) {
					actual = FileRead(migrator.paths.sql & i)
					if (i contains "_up.sql") {
						expected = "CREATE TABLE"
					} else {
						expected = "DROP TABLE"
					}

					expect(actual).toInclude(expected)
				}
			})

			it("does not generate sql files for migrate up", () => {
				migrator.migrateTo(001)
				expect(DirectoryExists(migrator.paths.sql)).toBeFalse()
			})

			it("uses specified versions table name", () => {
				tableName = "c_o_r_e_migrator_versions"
				application.wheels.migratorTableName = tableName

				migrator.migrateTo(001)

				actual = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "columns", table = tableName)
				expected = "version"

				expect(actual.column_name).toBe(expected)
			})
		})

		describe("F15 Phase 1: system-table naming + legacy detection", () => {

			beforeEach(() => {
				origMigratorTableName_F15 = Duplicate(application.wheels.migratorTableName);
				origLevelsTableName_F15 = StructKeyExists(application.wheels, "levelsTableName")
					? Duplicate(application.wheels.levelsTableName)
					: "wheels_levels";
				origCreateMigratorTable_F15 = Duplicate(application.wheels.createMigratorTable);
				// Wipe both naming families so detection runs from scratch.
				for (local.t in ["wheels_migrator_versions", "c_o_r_e_migrator_versions", "wheels_levels", "c_o_r_e_levels"]) {
					try { migration.dropTable(local.t); } catch (any e) {}
				}
			});

			afterEach(() => {
				application.wheels.migratorTableName = origMigratorTableName_F15;
				application.wheels.levelsTableName = origLevelsTableName_F15;
				application.wheels.createMigratorTable = origCreateMigratorTable_F15;
				for (local.t in ["wheels_migrator_versions", "c_o_r_e_migrator_versions", "wheels_levels", "c_o_r_e_levels"]) {
					try { migration.dropTable(local.t); } catch (any e) {}
				}
			});

			it("creates wheels_levels and wheels_migrator_versions on a fresh DB", () => {
				if (_isCockroachDB) return;
				application.wheels.migratorTableName = "wheels_migrator_versions";
				application.wheels.levelsTableName = "wheels_levels";
				application.wheels.createMigratorTable = true;

				// Trigger the migrator's bootstrap path (it lazy-creates the
				// system tables when neither variant exists).
				migrator.getCurrentMigrationVersion();

				var info = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables");
				var tables = ValueList(info.table_name);

				expect(ListFindNoCase(tables, "wheels_levels")).toBeGT(0);
				expect(ListFindNoCase(tables, "wheels_migrator_versions")).toBeGT(0);
				expect(ListFindNoCase(tables, "c_o_r_e_levels")).toBe(0);
				expect(ListFindNoCase(tables, "c_o_r_e_migrator_versions")).toBe(0);
			});

			it("falls back to c_o_r_e_levels when only legacy tables exist", () => {
				if (_isCockroachDB) return;
				application.wheels.migratorTableName = "wheels_migrator_versions";
				application.wheels.levelsTableName = "wheels_levels";
				application.wheels.createMigratorTable = true;

				// Pre-create the legacy table to simulate an existing 4.0-SNAPSHOT
				// install. The framework's own bootstrap (Migrator.cfc:433) uses
				// raw SQL with the same shape across adapters.
				queryExecute(
					"CREATE TABLE c_o_r_e_levels (id INT PRIMARY KEY, name VARCHAR(50) NOT NULL, description VARCHAR(255))",
					{},
					{ datasource = application.wheels.dataSourceName }
				);
				queryExecute(
					"INSERT INTO c_o_r_e_levels (id, name, description) VALUES (1, 'App', 'Application level migrations')",
					{},
					{ datasource = application.wheels.dataSourceName }
				);

				migrator.getCurrentMigrationVersion();

				// The detection helper should have flipped the application
				// settings back to the legacy names.
				expect(application.wheels.levelsTableName).toBe("c_o_r_e_levels");
				expect(application.wheels.migratorTableName).toBe("c_o_r_e_migrator_versions");

				// The new wheels_levels table should NOT have been created
				// alongside the existing legacy table.
				var info = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables");
				var tables = ValueList(info.table_name);
				expect(ListFindNoCase(tables, "wheels_levels")).toBe(0);
			});
		})

		describe("F15 Phase 2: renameSystemTables() opt-in rename", () => {

			beforeEach(() => {
				origMigratorTableName_F15P2 = Duplicate(application.wheels.migratorTableName);
				origLevelsTableName_F15P2 = StructKeyExists(application.wheels, "levelsTableName")
					? Duplicate(application.wheels.levelsTableName)
					: "wheels_levels";
				for (local.t in ["wheels_migrator_versions", "c_o_r_e_migrator_versions", "wheels_levels", "c_o_r_e_levels"]) {
					try { migration.dropTable(local.t); } catch (any e) {}
				}
			});

			afterEach(() => {
				application.wheels.migratorTableName = origMigratorTableName_F15P2;
				application.wheels.levelsTableName = origLevelsTableName_F15P2;
				for (local.t in ["wheels_migrator_versions", "c_o_r_e_migrator_versions", "wheels_levels", "c_o_r_e_levels"]) {
					try { migration.dropTable(local.t); } catch (any e) {}
				}
			});

			it("returns a no-op result when neither legacy nor new tables exist", () => {
				if (_isCockroachDB) return;
				application.wheels.levelsTableName = "wheels_levels";
				application.wheels.migratorTableName = "wheels_migrator_versions";

				var result = migrator.renameSystemTables();
				expect(result.success).toBeTrue();
				expect(arrayLen(result.renamed)).toBe(0);
				expect(result.skipped).toInclude("Nothing to rename");
			});

			it("renames c_o_r_e_levels -> wheels_levels and c_o_r_e_migrator_versions -> wheels_migrator_versions", () => {
				if (_isCockroachDB) return;

				// Pre-create both legacy tables so renameSystemTables has work to do.
				queryExecute(
					"CREATE TABLE c_o_r_e_levels (id INT PRIMARY KEY, name VARCHAR(50) NOT NULL, description VARCHAR(255))",
					{},
					{ datasource = application.wheels.dataSourceName }
				);
				queryExecute(
					"INSERT INTO c_o_r_e_levels (id, name, description) VALUES (1, 'App', 'Application level migrations')",
					{},
					{ datasource = application.wheels.dataSourceName }
				);
				queryExecute(
					"CREATE TABLE c_o_r_e_migrator_versions (version VARCHAR(25), core_level INT NOT NULL DEFAULT 1)",
					{},
					{ datasource = application.wheels.dataSourceName }
				);
				application.wheels.levelsTableName = "c_o_r_e_levels";
				application.wheels.migratorTableName = "c_o_r_e_migrator_versions";

				var result = migrator.renameSystemTables();
				expect(result.success).toBeTrue();
				expect(arrayLen(result.renamed)).toBe(2);

				var info = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables");
				var tables = ValueList(info.table_name);
				expect(ListFindNoCase(tables, "wheels_levels")).toBeGT(0);
				expect(ListFindNoCase(tables, "wheels_migrator_versions")).toBeGT(0);
				expect(ListFindNoCase(tables, "c_o_r_e_levels")).toBe(0);
				expect(ListFindNoCase(tables, "c_o_r_e_migrator_versions")).toBe(0);

				// And application settings should now point at the new names.
				expect(application.wheels.levelsTableName).toBe("wheels_levels");
				expect(application.wheels.migratorTableName).toBe("wheels_migrator_versions");
			});

			it("refuses to rename when both legacy and new tables exist (partial-rename safeguard)", () => {
				if (_isCockroachDB) return;

				// Simulate a half-renamed state: both versions of the levels
				// table coexist. This shouldn't happen in practice but guards
				// against silent data loss if a previous rename was interrupted.
				queryExecute(
					"CREATE TABLE c_o_r_e_levels (id INT PRIMARY KEY, name VARCHAR(50))",
					{},
					{ datasource = application.wheels.dataSourceName }
				);
				queryExecute(
					"CREATE TABLE wheels_levels (id INT PRIMARY KEY, name VARCHAR(50))",
					{},
					{ datasource = application.wheels.dataSourceName }
				);

				var result = migrator.renameSystemTables();
				expect(result.success).toBeFalse();
				expect(arrayLen(result.errors)).toBeGT(0);
				// Both tables should still exist — no destructive change.
				var info = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables");
				var tables = ValueList(info.table_name);
				expect(ListFindNoCase(tables, "c_o_r_e_levels")).toBeGT(0);
				expect(ListFindNoCase(tables, "wheels_levels")).toBeGT(0);
			});

			it("dryRun=true returns the SQL list without executing", () => {
				if (_isCockroachDB) return;

				queryExecute(
					"CREATE TABLE c_o_r_e_levels (id INT PRIMARY KEY, name VARCHAR(50))",
					{},
					{ datasource = application.wheels.dataSourceName }
				);
				queryExecute(
					"CREATE TABLE c_o_r_e_migrator_versions (version VARCHAR(25), core_level INT)",
					{},
					{ datasource = application.wheels.dataSourceName }
				);

				var result = migrator.renameSystemTables(dryRun = true);
				expect(result.success).toBeTrue();
				expect(arrayLen(result.sql)).toBeGT(0);

				// Tables should remain untouched.
				var info = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables");
				var tables = ValueList(info.table_name);
				expect(ListFindNoCase(tables, "c_o_r_e_levels")).toBeGT(0);
				expect(ListFindNoCase(tables, "c_o_r_e_migrator_versions")).toBeGT(0);
				expect(ListFindNoCase(tables, "wheels_levels")).toBe(0);
			});
		})

		describe("Tests that redomigration", () => {

			beforeEach(() => {
				tableName = "c_o_r_e_bunyips"

				migration.dropTable(tableName)
				t = migration.createTable(name = tableName)
				t.string(columnNames = "name", default = "", allowNull = true, limit = 255)
				t.create()
				migration.removeRecord(table = "c_o_r_e_migrator_versions")
				migration.addRecord(table = "c_o_r_e_migrator_versions", version = "001")

				$cleanSqlDirectory()
			})

			afterEach(() => {
				migration.dropTable(tableName)
				$cleanSqlDirectory()
			})

			// add a new column and redo the migration
			// NOTE: this test passes when run individually, but new column is not created when run
			// as part of the migrator test packing
			// Skipped as it is also skipped in RocketUnit
			xit("redomigration 001", () => {
				local.path = ExpandPath("/wheels/tests/_assets/migrator/migrations/001_create_bunyips_table.cfc");
				local.originalColumnNames = 'columnNames="name"';
				local.newColumnNames = 'columnNames="name,hobbies"';
				local.originalContent = FileRead(local.path);
				local.newContent = ReplaceNoCase(local.originalContent, local.originalColumnNames, local.newColumnNames, "one");

				FileDelete(local.path);
				FileWrite(local.path, local.newContent);

				migrator.redoMigration(001);
				info = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "columns", table = tableName);

				FileDelete(local.path);
				FileWrite(local.path, local.originalContent);

				actual = ValueList(info.column_name);

				expect(ListFindNoCase(actual, 'name')).toBeTrue()
				expect(ListFindNoCase(actual, 'hobbies')).toBeTrue()
			})
		})
	}
}