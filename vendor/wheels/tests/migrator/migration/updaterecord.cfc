component extends="wheels.tests.Test" {

	function setup() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
	}

	function test_updateRecord_updates_a_table_row() {
		tableName = "dbm_updaterecord_tests";
		oldValue = "All you need is love";
		newValue = "Love is all you need";

		t = migration.createTable(name = tableName, force = true);
		t.string(columnNames = "lyric");
		t.timeStamps();
		t.create();

		migration.addRecord(table = tableName, lyric = oldValue);
		migration.updateRecord(table = tableName, lyric = newValue, where = "lyric = '#oldValue#'");

		actual = $query(datasource = application.wheels.dataSourceName, sql = "SELECT lyric FROM #tableName#");
		expected = newValue;

		migration.dropTable(tableName);
		assert("actual.lyric eq expected");
	}

}
