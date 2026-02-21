component extends="wheels.tests.Test" {

	function setup() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
	}

	function test_createTable_generates_table() {
		tableName = "dbm_droptable_tests";

		t = migration.createTable(name = tableName, force = true);
		t.string(columnNames = "foo");
		t.timeStamps();
		t.create();

		migration.dropTable(name = tableName);
		try {
			actual = $query(datasource = application.wheels.dataSourceName, sql = "SELECT * FROM #tableName#");
			assert("false");
		} catch (any e) {
			raised("database");
		}
	}

}
