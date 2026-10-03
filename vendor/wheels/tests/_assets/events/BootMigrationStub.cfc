/**
 * Stand-in migrator for BootMigrationSpec (#4063): migrateToLatest() returns
 * a fixed output and getAvailableMigrations() reports one migration per entry
 * in `statuses` ("migrated" or "" for pending), versions numbered from 1.
 */
component {

	public any function init(string output = "", array statuses = []) {
		variables.output = arguments.output;
		variables.statuses = arguments.statuses;
		variables.state = {migrateCalls = 0};
		return this;
	}

	public string function migrateToLatest() {
		variables.state.migrateCalls++;
		return variables.output;
	}

	public array function getAvailableMigrations() {
		var migrations = [];
		var i = 0;
		for (i = 1; i <= ArrayLen(variables.statuses); i++) {
			ArrayAppend(migrations, {version = ToString(i), status = variables.statuses[i]});
		}
		return migrations;
	}

	public numeric function migrateCalls() {
		return variables.state.migrateCalls;
	}

}
