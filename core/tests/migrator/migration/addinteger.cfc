component extends="wheels.tests.Test" {

	private boolean function isDbCompatible() {
		switch (migration.adapter.adapterName()) {
			case "H2":
				return true;
			case "MicrosoftSQLServer":
			case "MySQL":
			case "PostgreSQL":
				return true;
			default:
				return false;
		}
	}

	private string function getIntegerType() {
		switch (migration.adapter.adapterName()) {
			case "H2":
				return "INTEGER";
			case "MicrosoftSQLServer":
			case "MySQL":
				return "INT";
			case "PostgreSQL":
				return "INTEGER,INT4"; // depends on db engine/drivers
			default:
				return "`addinteger()` not supported for " & migration.adapter.adapterName();
		}
	}

	function setup() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
		originalMigratorObjectCase = Duplicate(application.wheels.migratorObjectCase);
	}

	function teardown() {
		application.wheels.migratorObjectCase = originalMigratorObjectCase;
	}

	function test_add_a_integer_column() {
		if (!isDbCompatible()) {
			return;
		}

		tableName = "dbm_add_integer_tests";
		columnName = "integerCOLUMN";
		t = migration.createTable(name = tableName, force = true);
		t.integer(columnName = columnName);
		t.create();

		info = $dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
		actual = ListToArray(ValueList(info.TYPE_NAME))[2];
		migration.dropTable(tableName);

		expected = getIntegerType();

		debug("expected");
		debug("actual");

		assert("ListFindNoCase(expected, actual)");
	}

	function test_add_multiple_integer_columns() {
		if (!isDbCompatible()) {
			return;
		}

		tableName = "dbm_add_integer_tests";
		columnNames = "integerA,integerB";
		t = migration.createTable(name = tableName, force = true);
		t.integer(columnNames = columnNames);
		t.create();

		info = $dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
		actual = ListToArray(ValueList(info.TYPE_NAME));
		migration.dropTable(tableName);

		expected = getIntegerType();

		assert("ListFindNoCase(expected, actual[2])");
		assert("ListFindNoCase(expected, actual[3])");
	}

}