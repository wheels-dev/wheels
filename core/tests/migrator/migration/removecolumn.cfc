component extends="wheels.tests.Test" {

	function setup() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
	}

	function test_removeColumn_drops_column_from_table() {
		tableName = "dbm_removecolumn_tests";
		t = migration.createTable(name = tableName, force = true);
		t.string(columnNames = "stringcolumn");
		t.date(columnNames = "datecolumn");
		t.create();

		migration.removeColumn(table = tableName, columnName = 'datecolumn');
		info = $dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
		actual = ValueList(info.column_name);
		expected = "datecolumn";
		migration.dropTable(tableName);

		assert("ListFindNoCase(actual, expected) eq 0", "expected", "actual");
	}

}
