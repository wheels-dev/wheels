component extends="wheels.tests.Test" {

	public void function test_valid_test_package_passing_test() {
		assert("true");
	}

	public void function test_valid_test_package_failing_test() {
		assert("false");
	}

	public numeric function _a_helper() {
		return 1;
	}

}
