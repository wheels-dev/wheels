component extends="wheels.tests.Test" {

	function setup() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
	}

	function test_current_test_environment_returns_an_adapter() {
		result = migration.$getDBType();
		assert("len(result)");
	}

}
