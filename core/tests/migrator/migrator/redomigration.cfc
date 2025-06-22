component extends="wheels.tests.Test" {

	include "helpers.cfm";

	function setup() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
		migrator = CreateObject("component", "wheels.migrator").init(
			migratePath = "/wheels/tests/_assets/migrator/migrations/",
			sqlPath = "/wheels/tests/_assets/migrator/sql/"
		);
		tableName = "bunyips";

		migration.dropTable(tableName);
		t = migration.createTable(name = tableName);
		t.string(
			columnNames = "name",
			default = "",
			null = true,
			limit = 255
		);
		t.create();
		migration.removeRecord(table = "migratorversions");
		migration.addRecord(table = "migratorversions", version = "001");

		$cleanSqlDirectory();
	}

	function teardown() {
		migration.dropTable(tableName);
		$cleanSqlDirectory();
	}

	// add a new column and redo the migration
	// NOTE: this test passes when run individually, but new column is not created when run
	// as part of the migrator test packing
	function _test_redomigration_001() {
		local.path = ExpandPath("/wheels/tests/_assets/migrator/migrations/001_create_bunyips_table.cfc");
		local.originalColumnNames = 'columnNames="name"';
		local.newColumnNames = 'columnNames="name,hobbies"';
		local.originalContent = FileRead(local.path);
		local.newContent = ReplaceNoCase(
			local.originalContent,
			local.originalColumnNames,
			local.newColumnNames,
			"one"
		);

		FileDelete(local.path);
		FileWrite(local.path, local.newContent);

		migrator.redoMigration(001);
		info = $dbinfo(datasource = application.wheels.dataSourceName, type = "columns", table = tableName);

		FileDelete(local.path);
		FileWrite(local.path, local.originalContent);

		actual = ValueList(info.column_name);
		assert("ListFindNoCase(actual, 'name')", "actual");
		assert("ListFindNoCase(actual, 'hobbies')", "actual");
	}

}
