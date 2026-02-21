component extends="wheels.tests.Test" {

	private boolean function isDbCompatible() {
		switch (migration.adapter.adapterName()) {
			case "H2":
			case "MicrosoftSQLServer":
			case "MySQL":
			case "PostgreSQL":
				return true;
			default:
				return false;
		}
	}

	private string function getBooleanType() {
		switch (migration.adapter.adapterName()) {
			case "H2":
				return "TINYINT";
			case "MicrosoftSQLServer":
				return "BIT";
			case "MySQL":
				return "BIT,TINYINT";
			case "PostgreSQL":
				return "BOOLEAN";
			default:
				return "`addboolean()` not supported for " & migration.adapter.adapterName();
		}
	}

	function setup() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
		originalMigratorObjectCase = Duplicate(application.wheels.migratorObjectCase);
	}

	function teardown() {
		application.wheels.migratorObjectCase = originalMigratorObjectCase;
	}

	function test_add_a_boolean_column() {
		if (!isDbCompatible()) {
			return;
		}

		tableName = "dbm_add_boolean_tests";
		columnName = "booleanCOLUMN";
		t = migration.createTable(name = tableName, force = true);
		t.boolean(columnName = columnName);
		t.create();

		info = $dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
		actual = ListToArray(ValueList(info.TYPE_NAME))[2];
		migration.dropTable(tableName);

		expected = getBooleanType();

		assert("listContainsNoCase(expected,actual)");
	}

	function test_add_multiple_boolean_columns() {
		if (!isDbCompatible()) {
			return;
		}

		tableName = "dbm_add_boolean_tests";
		columnNames = "booleanA,booleanB";
		t = migration.createTable(name = tableName, force = true);
		t.boolean(columnNames = columnNames);
		t.create();

		info = $dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
		actual = ListToArray(ValueList(info.TYPE_NAME));
		migration.dropTable(tableName);

		expected = getBooleanType();

		assert("listContainsNoCase(expected,actual[2])");
		assert("listContainsNoCase(expected,actual[3])");
	}

}
