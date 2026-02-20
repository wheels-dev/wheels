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

	private string function getBinaryType() {
		switch (migration.adapter.adapterName()) {
			case "H2":
			case "MySQL":
				return "BLOB";
			case "MicrosoftSQLServer":
				return "IMAGE";
			case "PostgreSQL":
				return "BYTEA";
			default:
				return "`addbinary()` not supported for " & migration.adapter.adapterName();
		}
	}

	function setup() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
		originalMigratorObjectCase = Duplicate(application.wheels.migratorObjectCase);
	}

	function teardown() {
		application.wheels.migratorObjectCase = originalMigratorObjectCase;
	}

	function test_add_a_binary_column() {
		if (!isDbCompatible()) {
			return;
		}

		tableName = "dbm_add_binary_tests";
		columnName = "binaryCOLUMN";
		t = migration.createTable(name = tableName, force = true);
		t.binary(columnName = columnName);
		t.create();

		info = $dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
		actual = ListToArray(ValueList(info.TYPE_NAME))[2];
		migration.dropTable(tableName);

		expected = getBinaryType();

		assert("actual eq expected");
	}

	function test_add_multiple_binary_columns() {
		if (!isDbCompatible()) {
			return;
		}

		tableName = "dbm_add_binary_tests";
		columnNames = "binaryA,binaryB";
		t = migration.createTable(name = tableName, force = true);
		t.binary(columnNames = columnNames);
		t.create();

		info = $dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
		actual = ListToArray(ValueList(info.TYPE_NAME));
		migration.dropTable(tableName);

		expected = getBinaryType();

		assert("actual[2] eq expected");
		assert("actual[3] eq expected");
	}

}
