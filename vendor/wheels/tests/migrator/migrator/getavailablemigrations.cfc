component extends="wheels.tests.Test" {

	function setup() {
		migrator = CreateObject("component", "wheels.Migrator").init(
			migratePath = "/wheels/tests/_assets/migrator/migrations/"
		);
	}

	function test_getAvailableMigrations_returns_expected_value() {
		available = migrator.getAvailableMigrations();
		actual = "";
		for (local.i in available) {
			actual = ListAppend(actual, local.i.version);
		};
		expected = "001,002,003";
		assert("actual eq expected");
	}

}
