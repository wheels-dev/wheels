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
				"_c_o_r_e_bunyips",
				"_c_o_r_e_dropbears",
				"_c_o_r_e_hoopsnakes"
			]
		) {
			migration.dropTable(local.table);
		};
		deleteMigratorVersions(2);
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
