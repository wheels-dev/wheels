component extends="testbox.system.BaseSpec" {

	include "helperFunctions.cfm"

	function beforeAll() {
		migration = CreateObject("component", "wheels.migrator.Migration").init()
		migrator = CreateObject("component", "wheels.Migrator").init(
			migratePath = "/wheels/core_tests/_assets/migrator/migrations/",
			sqlPath = "/wheels/core_tests/_assets/migrator/sql/"
		)
	}

	function run() {

		g = application.wo

		describe("Tests that adapter", () => {

			it("is returned in the test environment", () => {
				expect(migration.$getDBType()).toBeGT(0)
			})
		})

		describe("Tests that getAvailableMigrations", () => {

			it("is returning expected value", () => {
				available = migrator.getAvailableMigrations()
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
				for (local.table in ["_c_o_r_e_bunyips", "_c_o_r_e_dropbears", "_c_o_r_e_hoopsnakes"]) {
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
				for (local.table in ["_c_o_r_e_bunyips", "_c_o_r_e_dropbears", "_c_o_r_e_hoopsnakes", "migrations"]) {
					migration.dropTable(local.table)
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
				migrator.migrateTo(001)
				info = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables", pattern = "_c_o_r_e_bunyips")

				actual = ValueList(info.table_name)
				expected = "_c_o_r_e_bunyips"

				expect(listFindNoCase(actual, expected)).toBeTrue()
			})

			it("is migrating up from 0 to 003", () => {
				migrator.migrateTo(003)
				info1 = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables", pattern = "_c_o_r_e_bunyips")
				info2 = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables", pattern = "_c_o_r_e_dropbears")
				info3 = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables", pattern = "_c_o_r_e_hoopsnakes")
				actual1 = ValueList(info1.table_name)
				actual2 = ValueList(info2.table_name)
				actual3 = ValueList(info3.table_name)

				expect(listFindNoCase(actual1, "_c_o_r_e_bunyips")).toBeTrue()
				expect(listFindNoCase(actual2, "_c_o_r_e_dropbears")).toBeTrue()
				expect(listFindNoCase(actual3, "_c_o_r_e_hoopsnakes")).toBeTrue()
			})

			it("is migrating down from 003 to 001", () => {
				migrator.migrateTo(003)
				migrator.migrateTo(001)
				info1 = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables", pattern = "_c_o_r_e_bunyips")
				info2 = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables", pattern = "_c_o_r_e_dropbears")
				info3 = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables", pattern = "_c_o_r_e_hoopsnakes")
				actual1 = ValueList(info1.table_name)
				actual2 = ValueList(info2.table_name)
				actual3 = ValueList(info3.table_name)

				expect(listFindNoCase(actual1, "_c_o_r_e_bunyips")).toBeTrue()
				expect(listFindNoCase(actual2, "_c_o_r_e_dropbears")).toBeFalse()
				expect(listFindNoCase(actual3, "_c_o_r_e_hoopsnakes")).toBeFalse()
			})

			it("generates sql files", () => {
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
				tableName = "_c_o_r_e_migrator_versions"
				application.wheels.migratorTableName = tableName

				migrator.migrateTo(001)

				actual = g.$dbinfo(datasource = application.wheels.dataSourceName, type = "columns", table = tableName)
				expected = "version"

				expect(actual.column_name).toBe(expected)
			})
		})

		describe("Tests that redomigration", () => {

			beforeEach(() => {
				tableName = "_c_o_r_e_bunyips"

				migration.dropTable(tableName)
				t = migration.createTable(name = tableName)
				t.string(columnNames = "name", default = "", null = true, limit = 255)
				t.create()
				migration.removeRecord(table = "_c_o_r_e_migrator_versions")
				migration.addRecord(table = "_c_o_r_e_migrator_versions", version = "001")

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
				local.path = ExpandPath("/wheels/core_tests/_assets/migrator/migrations/001_create_bunyips_table.cfc");
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
