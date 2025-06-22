component extends="wheels.tests.Test" {

	include "../migrator/helpers.cfm";
	function setup() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
	}

	// more tests needed.. changing datatypes.. etc

	function test_changeColumn_changes_column() {
		tableName = "dbm_changecolumn_tests";
		columnName = "stringcolumn";

		t = migration.createTable(name = tableName, force = true);
		t.string(columnNames = columnName, limit = 10, null = true);
		t.create();

		migration.changeColumn(
			table = tableName,
			columnName = columnName,
			columnType = 'string',
			limit = 50,
			null = false,
			default = "foo"
		);

		info = $dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
		migration.dropTable(tableName);
		sql = "SELECT * FROM query WHERE column_name = '#columnName#'";
		actual = $query(query = info, dbtype = "query", sql = sql);

		assert("actual.column_size eq 50");
		if (ListFindNoCase(actual.columnList, "is_nullable")) {
			assert("!actual.is_nullable");
		} else {
			assert("!actual.nullable");
		}
		if (ListFindNoCase(actual.columnList, "default_value")) {
			assert("actual.default_value contains 'bar'");
		} else {
			assert("actual.column_default_value contains 'foo'");
		}
	}

}
