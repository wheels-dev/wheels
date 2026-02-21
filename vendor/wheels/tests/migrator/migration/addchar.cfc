component extends="wheels.tests.Test" {

	private boolean function isDbCompatible() {
		switch (migration.adapter.adapterName()) {
			case "MicrosoftSQLServer":
				return true;
			default:
				return false;
		}
	}

	private string function getCharType() {
		switch (migration.adapter.adapterName()) {
			case "MicrosoftSQLServer":
				return "CHAR";
			default:
				return "`addchar()` not supported for " & migration.adapter.adapterName();
		}
	}

	function setup() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
		originalMigratorObjectCase = Duplicate(application.wheels.migratorObjectCase);
	}

	function teardown() {
		application.wheels.migratorObjectCase = originalMigratorObjectCase;
	}

	function test_add_a_char_column() {
		if (!isDbCompatible()) {
			return;
		}

		tableName = "dbm_add_char_tests";
		columnName = "charCOLUMN";
		t = migration.createTable(name = tableName, force = true);
		t.char(columnName = columnName);
		t.create();

		info = $dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
		actual = ListToArray(ValueList(info.TYPE_NAME))[2];
		migration.dropTable(tableName);

		expected = getCharType();

		assert("actual eq expected");
	}

	function test_add_multiple_char_columns() {
		if (!isDbCompatible()) {
			return;
		}

		tableName = "dbm_add_char_tests";
		columnNames = "charA,charB";
		t = migration.createTable(name = tableName, force = true);
		t.char(columnNames = columnNames);
		t.create();

		info = $dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
		actual = ListToArray(ValueList(info.TYPE_NAME));
		migration.dropTable(tableName);

		expected = getCharType();

		assert("actual[2] eq expected");
		assert("actual[3] eq expected");
	}

}
