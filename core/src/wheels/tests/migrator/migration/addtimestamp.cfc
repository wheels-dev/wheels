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

	private string function getTimestampType() {
		switch (migration.adapter.adapterName()) {
			case "MicrosoftSQLServer":
				return "DATETIME";
			case "H2":
				return "TIMESTAMP";
			case "MySQL":
				return "DATETIME";
			case "PostgreSQL":
				return "TIMESTAMP";
			default:
				return "`addtimestamp()` not supported for " & migration.adapter.adapterName();
		}
	}

	function setup() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
		originalMigratorObjectCase = Duplicate(application.wheels.migratorObjectCase);
	}

	function teardown() {
		application.wheels.migratorObjectCase = originalMigratorObjectCase;
	}

	function test_add_a_timestamp_column() {
		if (!isDbCompatible()) {
			return;
		}

		tableName = "dbm_add_timestamp_tests";
		columnName = "timestampCOLUMN";
		t = migration.createTable(name = tableName, force = true);
		t.timestamp(columnName = columnName);
		t.create();

		info = $dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
		actual = ListToArray(ValueList(info.TYPE_NAME))[2];
		migration.dropTable(tableName);

		expected = getTimestampType();

		assert("actual eq expected");
	}

	function test_add_multiple_timestamp_columns() {
		if (!isDbCompatible()) {
			return;
		}

		tableName = "dbm_add_timestamp_tests";
		columnNames = "timestampA,timestampB";
		t = migration.createTable(name = tableName, force = true);
		t.timestamp(columnNames = columnNames);
		t.create();

		info = $dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
		actual = ListToArray(ValueList(info.TYPE_NAME));
		migration.dropTable(tableName);

		expected = getTimestampType();

		assert("actual[2] eq expected");
		assert("actual[3] eq expected");
	}

}