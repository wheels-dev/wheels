component extends="wheels.tests.Test" {

	include "helpers.cfm";

	function setup() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
		migrator = CreateObject("component", "wheels.Migrator").init(
			migratePath = "/wheels/tests/_assets/migrator/migrations/",
			sqlPath = "/wheels/tests/_assets/migrator/sql/"
		);
		for (local.table in ["_c_o_r_e_bunyips", "_c_o_r_e_dropbears", "_c_o_r_e_hoopsnakes", "migrations"]) {
			migration.dropTable(local.table);
		};
		deleteMigratorVersions(2);
		$cleanSqlDirectory();
		originalWriteMigratorSQLFiles = Duplicate(application.wheels.writeMigratorSQLFiles);
		originalMigratorTableName = Duplicate(application.wheels.migratorTableName);
	}

	function teardown() {
		$cleanSqlDirectory();
		// revert to original values
		application.wheels.writeMigratorSQLFiles = originalWriteMigratorSQLFiles;
		application.wheels.migratorTableName = originalMigratorTableName;
	}

	function test_migrateto_migrate_up_from_0_to_001() {
		migrator.migrateTo(001);
		info = $dbinfo(datasource = application.wheels.dataSourceName, type = "tables", pattern = "_c_o_r_e_bunyips");

		actual = ValueList(info.table_name);
		expected = "_c_o_r_e_bunyips";
		assert("ListFindNoCase(actual, expected)", "expected", "actual");
	}

	// Adding pattern for speed
	function test_migrateto_migrate_up_from_0_to_003() {
		migrator.migrateTo(003);
		info1 = $dbinfo(datasource = application.wheels.dataSourceName, type = "tables", pattern = "_c_o_r_e_bunyips");
		info2 = $dbinfo(datasource = application.wheels.dataSourceName, type = "tables", pattern = "_c_o_r_e_dropbears");
		info3 = $dbinfo(datasource = application.wheels.dataSourceName, type = "tables", pattern = "_c_o_r_e_hoopsnakes");
		actual1 = ValueList(info1.table_name);
		actual2 = ValueList(info2.table_name);
		actual3 = ValueList(info3.table_name);

		assert("ListFindNoCase(actual1, '_c_o_r_e_bunyips')");
		assert("ListFindNoCase(actual2, '_c_o_r_e_dropbears')");
		assert("ListFindNoCase(actual3, '_c_o_r_e_hoopsnakes')");
	}

	function test_migrateto_migrate_down_from_003_to_001() {
		migrator.migrateTo(003);
		migrator.migrateTo(001);
		info1 = $dbinfo(datasource = application.wheels.dataSourceName, type = "tables", pattern = "_c_o_r_e_bunyips");
		info2 = $dbinfo(datasource = application.wheels.dataSourceName, type = "tables", pattern = "_c_o_r_e_dropbears");
		info3 = $dbinfo(datasource = application.wheels.dataSourceName, type = "tables", pattern = "_c_o_r_e_hoopsnakes");

		actual1 = ValueList(info1.table_name);
		actual2 = ValueList(info2.table_name);
		actual3 = ValueList(info3.table_name);

		assert("ListFindNoCase(actual1, '_c_o_r_e_bunyips')");
		assert("!ListFindNoCase(actual2, '_c_o_r_e_dropbears')");
		assert("!ListFindNoCase(actual3, '_c_o_r_e_hoopsnakes')");
	}

	function test_migrateto_generates_sql_files() {
		application.wheels.writeMigratorSQLFiles = true;

		migrator.migrateTo(002);
		migrator.migrateTo(001);

		for (
			i in [
				"001_create_bunyips_table_up.sql",
				"002_create_dropbears_table_up.sql",
				"002_create_dropbears_table_down.sql"
			]
		) {
			actual = FileRead(migrator.paths.sql & i);
			if (i contains "_up.sql") {
				expected = "CREATE TABLE";
			} else {
				expected = "DROP TABLE";
			}
			assert("actual contains expected");
		};
	}

	function test_migrateto_migrate_up_does_not_generate_sql_file() {
		migrator.migrateTo(001);
		assert("!DirectoryExists(migrator.paths.sql)");
	}

	function test_migrateto_uses_specified_versions_table_name() {
		tableName = "_c_o_r_e_migrator_versions";
		application.wheels.migratorTableName = tableName;

		migrator.migrateTo(001);

		actual = $dbinfo(datasource = application.wheels.dataSourceName, type = "columns", table = tableName);
		expected = "version";

		assert("actual.column_name eq expected");
	}

}
