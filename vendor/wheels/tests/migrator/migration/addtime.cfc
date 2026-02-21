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

	private string function getTimeType() {
		switch (migration.adapter.adapterName()) {
			case "MicrosoftSQLServer":
				return "time";
			case "MySQL":
			case "H2":
			case "PostgreSQL":
				return "TIME";
			default:
				return "`addtime()` not supported for " & migration.adapter.adapterName();
		}
	}

	function setup() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
		originalMigratorObjectCase = Duplicate(application.wheels.migratorObjectCase);
	}

	function teardown() {
		application.wheels.migratorObjectCase = originalMigratorObjectCase;
	}

	function test_add_a_time_column() {
		if (!isDbCompatible()) {
			return;
		}

		tableName = "dbm_add_time_tests";
		columnName = "timeCOLUMN";
		t = migration.createTable(name = tableName, force = true);
		t.time(columnName = columnName);
		t.create();

		info = $dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
		actual = ListToArray(ValueList(info.TYPE_NAME))[2];
		migration.dropTable(tableName);

		expected = getTimeType();

		assert("actual eq expected");
	}

	function test_add_multiple_time_columns() {
		if (!isDbCompatible()) {
			return;
		}

		tableName = "dbm_add_time_tests";
		columnNames = "timeA,timeB";
		t = migration.createTable(name = tableName, force = true);
		t.time(columnNames = columnNames);
		t.create();

		info = $dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
		actual = ListToArray(ValueList(info.TYPE_NAME));
		migration.dropTable(tableName);

		expected = getTimeType();

		assert("actual[2] eq expected");
		assert("actual[3] eq expected");
	}

}
