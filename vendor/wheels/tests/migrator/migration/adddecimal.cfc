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

	private string function getDecimalType() {
		switch (migration.adapter.adapterName()) {
			case "H2":
			case "MicrosoftSQLServer":
			case "MySQL":
				return "DECIMAL";
			case "PostgreSQL":
				return "NUMERIC";
			default:
				return "`adddecimal()` not supported for " & migration.adapter.adapterName();
		}
	}

	function setup() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
		originalMigratorObjectCase = Duplicate(application.wheels.migratorObjectCase);
	}

	function teardown() {
		application.wheels.migratorObjectCase = originalMigratorObjectCase;
	}

	function test_add_a_decimal_column() {
		if (!isDbCompatible()) {
			return;
		}

		tableName = "dbm_add_decimal_tests";
		columnName = "decimalCOLUMN";
		t = migration.createTable(name = tableName, force = true);
		t.decimal(columnName = columnName);
		t.create();

		info = $dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
		actual = ListToArray(ValueList(info.TYPE_NAME))[2];
		migration.dropTable(tableName);

		expected = getDecimalType();

		assert("actual eq expected");
	}

	function test_add_multiple_decimal_columns() {
		if (!isDbCompatible()) {
			return;
		}

		tableName = "dbm_add_decimal_tests";
		columnNames = "decimalA,decimalB";
		t = migration.createTable(name = tableName, force = true);
		t.decimal(columnNames = columnNames);
		t.create();

		info = $dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
		actual = ListToArray(ValueList(info.TYPE_NAME));
		migration.dropTable(tableName);

		expected = getDecimalType();

		assert("actual[2] eq expected");
		assert("actual[3] eq expected");
	}

}
