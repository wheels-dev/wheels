component extends="wheels.tests.Test" {

	function test_$cleantestcase_returns_expected_value() {
		basePath = "wheels.tests.testframework";
		actual = $cleanTestCase("wheels.tests.testframework.foo.bar", basePath);
		expected = "foo.bar";
		assert("actual eq expected");
	}

}
