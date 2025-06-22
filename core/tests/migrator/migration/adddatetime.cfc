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

	private string function getDatetimeType() {
		switch (migration.adapter.adapterName()) {
			case "H2":
				return "TIMESTAMP";
			case "MicrosoftSQLServer":
			case "MySQL":
				return "DATETIME";
			case "PostgreSQL":
				return "TIMESTAMP";
			default:
				return "`adddatetime()` not supported for " & migration.adapter.adapterName();
		}
	}

	function setup() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
		originalMigratorObjectCase = Duplicate(application.wheels.migratorObjectCase);
	}

	function teardown() {
		application.wheels.migratorObjectCase = originalMigratorObjectCase;
	}

	function test_add_a_datetime_column() {
		if (!isDbCompatible()) {
			return;
		}

		tableName = "dbm_add_datetime_tests";
		columnName = "datetimeCOLUMN";
		t = migration.createTable(name = tableName, force = true);
		t.datetime(columnName = columnName);
		t.create();

		info = $dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
		actual = ListToArray(ValueList(info.TYPE_NAME))[2];
		migration.dropTable(tableName);

		expected = getDatetimeType();

		assert("actual eq expected");
	}

	function test_add_multiple_datetime_columns() {
		if (!isDbCompatible()) {
			return;
		}

		tableName = "dbm_add_datetime_tests";
		columnNames = "datetimeA,datetimeB";
		t = migration.createTable(name = tableName, force = true);
		t.datetime(columnNames = columnNames);
		t.create();

		info = $dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
		actual = ListToArray(ValueList(info.TYPE_NAME));
		migration.dropTable(tableName);

		expected = getDatetimeType();

		assert("actual[2] eq expected");
		assert("actual[3] eq expected");
	}

}