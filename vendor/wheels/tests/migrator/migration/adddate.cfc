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

	private string function getDateType() {
		switch (migration.adapter.adapterName()) {
			case "H2":
			case "MySQL":
			case "PostgreSQL":
				return "DATE";
			case "MicrosoftSQLServer":
				return "date";
			default:
				return "`adddate()` not supported for " & migration.adapter.adapterName();
		}
	}

	function setup() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
		originalMigratorObjectCase = Duplicate(application.wheels.migratorObjectCase);
	}

	function teardown() {
		application.wheels.migratorObjectCase = originalMigratorObjectCase;
	}

	function test_add_a_date_column() {
		if (!isDbCompatible()) {
			return;
		}

		tableName = "dbm_add_date_tests";
		columnName = "dateCOLUMN";
		t = migration.createTable(name = tableName, force = true);
		t.date(columnName = columnName);
		t.create();

		info = $dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
		actual = ListToArray(ValueList(info.TYPE_NAME))[2];
		migration.dropTable(tableName);

		expected = getDateType();

		assert("actual eq expected");
	}

	function test_add_multiple_date_columns() {
		if (!isDbCompatible()) {
			return;
		}

		tableName = "dbm_add_date_tests";
		columnNames = "dateA,dateB";
		t = migration.createTable(name = tableName, force = true);
		t.date(columnNames = columnNames);
		t.create();

		info = $dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
		actual = ListToArray(ValueList(info.TYPE_NAME));
		migration.dropTable(tableName);

		expected = getDateType();

		assert("actual[2] eq expected");
		assert("actual[3] eq expected");
	}

}
