component extends="wheels.tests.Test" {

	private boolean function isDbCompatible() {
		switch (migration.adapter.adapterName()) {
			case "H2":
				return true;
			case "MicrosoftSQLServer":
				return true;
			case "MySQL":
			case "PostgreSQL":
				return true;
			default:
				return false;
		}
	}

	private array function getTextType() {
		switch (migration.adapter.adapterName()) {
			case "H2":
				return ["CLOB"];
			case "MySQL":
			case "PostgreSQL":
				return ["TEXT"];
			case "MicrosoftSQLServer":
				return ["NVARCHAR", "NVARCHAR(MAX)"];
			default:
				return "`addtext()` not supported for " & migration.adapter.adapterName();
		}
	}

	function setup() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
		originalMigratorObjectCase = Duplicate(application.wheels.migratorObjectCase);
	}

	function teardown() {
		application.wheels.migratorObjectCase = originalMigratorObjectCase;
	}

	function test_add_a_text_column() {
		if (!isDbCompatible()) {
			return;
		}

		tableName = "dbm_add_text_tests";
		columnName = "textCOLUMN";
		t = migration.createTable(name = tableName, force = true);
		t.text(columnName = columnName);
		t.create();

		info = $dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
		actual = ListToArray(ValueList(info.TYPE_NAME))[2];
		migration.dropTable(tableName);

		expected = getTextType();

		debug("expected");
		debug("actual");

		assert("ArrayContainsNoCase(expected, actual)");
	}

	function test_add_multiple_text_columns() {
		if (!isDbCompatible()) {
			return;
		}

		tableName = "dbm_add_text_tests";
		columnNames = "textA,textB";
		t = migration.createTable(name = tableName, force = true);
		t.text(columnNames = columnNames);
		t.create();

		info = $dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
		actual = ListToArray(ValueList(info.TYPE_NAME));
		migration.dropTable(tableName);

		expected = getTextType();

		assert("ArrayContainsNoCase(expected, actual[2])");
		assert("ArrayContainsNoCase(expected, actual[3])");
	}

}