component extends="wheels.tests.Test" {

	include "helpers.cfm";

	function setup() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
		migrator = CreateObject("component", "wheels.Migrator").init(
			migratePath = "/wheels/tests/_assets/migrator/migrations/",
			sqlPath = "/wheels/tests/_assets/migrator/sql/"
		);
		for (
			local.table in [
				"bunyips",
				"dropbears",
				"hoopsnakes",
				"migratorversions"
			]
		) {
			migration.dropTable(local.table);
		};
	}

	function teardown() {
		$cleanSqlDirectory();
	}

	function test_getCurrentMigrationVersion_returns_expected_value() {
		expected = "002";
		migrator.migrateTo(expected);
		actual = migrator.getCurrentMigrationVersion();
		assert("actual eq expected");
	}

}
