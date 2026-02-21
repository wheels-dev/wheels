component extends="wheels.tests.Test" {

	private boolean function isDbCompatible() {
		switch (migration.adapter.adapterName()) {
			case "H2":
			case "MySQL":
				return true;
			default:
				return false;
		}
	}

	private string function getBigIntegerType() {
		switch (migration.adapter.adapterName()) {
			case "H2":
				return "BIGINT";
			case "MySQL":
				return "BIGINT UNSIGNED";
			default:
				return "`addbiginteger()` not supported for " & migration.adapter.adapterName();
		}
	}

	function setup() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
		originalMigratorObjectCase = Duplicate(application.wheels.migratorObjectCase);
	}

	function teardown() {
		application.wheels.migratorObjectCase = originalMigratorObjectCase;
	}

	function test_add_a_big_integer_column() {
		if (!isDbCompatible()) {
			return;
		}

		tableName = "dbm_add_big_integer_tests";
		columnName = "bigIntegerCOLUMN";
		t = migration.createTable(name = tableName, force = true);
		t.bigInteger(columnName = columnName);
		t.create();

		info = $dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
		actual = ListToArray(ValueList(info.TYPE_NAME))[2];
		migration.dropTable(tableName);

		expected = getBigIntegerType();

		assert("actual eq expected");
	}

	function test_add_multiple_big_integer_columns() {
		if (!isDbCompatible()) {
			return;
		}

		tableName = "dbm_add_big_integer_tests";
		columnNames = "bigIntegerA,bigIntegerB";
		t = migration.createTable(name = tableName, force = true);
		t.bigInteger(columnNames = columnNames);
		t.create();

		info = $dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
		actual = ListToArray(ValueList(info.TYPE_NAME));
		migration.dropTable(tableName);

		expected = getBigIntegerType();

		assert("actual[2] eq expected");
		assert("actual[3] eq expected");
	}

}