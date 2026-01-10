component extends="wheels.tests.Test" {

	private boolean function isDbCompatible() {
		switch (migration.adapter.adapterName()) {
			case "MicrosoftSQLServer":
				return true;
			default:
				return false;
		}
	}

	private string function getUniqueIdentifierType() {
		switch (migration.adapter.adapterName()) {
			case "MicrosoftSQLServer":
				return "UNIQUEIDENTIFIER";
			default:
				return "`adduniqueidentifier()` not supported for " & migration.adapter.adapterName();
		}
	}

	function setup() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
		originalMigratorObjectCase = Duplicate(application.wheels.migratorObjectCase);
	}

	function teardown() {
		application.wheels.migratorObjectCase = originalMigratorObjectCase;
	}

	function test_add_a_uniqueidentifier_column() {
		if (!isDbCompatible()) {
			return;
		}

		tableName = "dbm_add_uniqueidentifier_tests";
		columnName = "uniqueidentifierCOLUMN";
		t = migration.createTable(name = tableName, force = true);
		t.uniqueidentifier(columnName = columnName);
		t.create();

		info = $dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
		actual = ListToArray(ValueList(info.TYPE_NAME))[2];
		migration.dropTable(tableName);

		expected = getUniqueIdentifierType();

		assert("actual eq expected");
	}

	function test_add_multiple_uniqueidentifier_columns() {
		if (!isDbCompatible()) {
			return;
		}

		tableName = "dbm_add_uniqueidentifier_tests";
		columnNames = "uniqueidentifierA,uniqueidentifierB";
		t = migration.createTable(name = tableName, force = true);
		t.uniqueidentifier(columnNames = columnNames);
		t.create();

		info = $dbinfo(datasource = application.wheels.dataSourceName, table = tableName, type = "columns");
		actual = ListToArray(ValueList(info.TYPE_NAME));
		migration.dropTable(tableName);

		expected = getUniqueIdentifierType();

		assert("actual[2] eq expected");
		assert("actual[3] eq expected");
	}

}
