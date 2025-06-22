component extends="wheels.tests.Test" {

	function setup() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
	}

	function test_execute_runs_query() {
		tableName = "dbm_execute_tests";

		t = migration.createTable(name = tableName, force = true);
		t.string(columnNames = "film");
		t.timeStamps();
		t.create();

		migration.addRecord(table = tableName, film = "The Phantom Menace");
		migration.addRecord(table = tableName, film = "The Clone Wars");
		migration.addRecord(table = tableName, film = "Revenge of the Sith");

		migration.execute("DELETE FROM #tableName#");

		actual = $query(datasource = application.wheels.dataSourceName, sql = "SELECT * FROM #tableName#");
		expected = 0;

		migration.dropTable(tableName);
		assert("actual.RecordCount eq expected");
	}

}
