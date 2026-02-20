component extends="wheels.tests.Test" {

	function setup() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
	}

	function test_removeRecord_deletes_rows_from_table() {
		tableName = "dbm_removerecord_tests";

		t = migration.createTable(name = tableName, force = true);
		t.string(columnNames = "beatle");
		t.timeStamps();
		t.create();

		migration.addRecord(table = tableName, beatle = "John");
		migration.addRecord(table = tableName, beatle = "Paul");
		migration.addRecord(table = tableName, beatle = "George");
		migration.addRecord(table = tableName, beatle = "Ringo");

		migration.removeRecord(table = tableName, where = "beatle IN ('John','George')");

		actual = $query(datasource = application.wheels.dataSourceName, sql = "SELECT * FROM #tableName#");
		expected = 2;

		migration.dropTable(tableName);
		assert("actual.RecordCount eq expected");
	}

}
