component extends="wheels.tests.Test" {

	function setup() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
		oldTableName = "dbm_renametable_tests";
		newTableName = "dbm_new_renametable_tests";
		try {
			migration.dropTable(newTableName);
		} catch (any e) {
		}
	}

	function test_renameTable_renames_table() {
		t = migration.createTable(name = oldTableName, force = true);
		t.string(columnNames = "stringcolumn");
		t.create();
		migration.renameTable(oldName = oldTableName, newName = newTableName);
		try {
			model(newTableName).findAll();
			migration.dropTable(newTableName);
			assert("true");
		} catch (any e) {
			assert("false");
		}
	}

}
