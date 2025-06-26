component extends="wheels.tests.Test" {

	function test_package_is_valid() {
		assert('$isValidTest("wheels.tests._assets.testframework.ValidTestPackage")');
	}

	function test_package_is_invalid() {
		assert('!$isValidTest("wheels.tests._assets.testframework.ValidTestPackage", "Foo")');
	}

	function test_package_named_Test_is_invalid() {
		assert('!$isValidTest("wheels.tests.Test")');
	}

	function test_package_beginning_with_underscore_is_invalid() {
		assert('!$isValidTest("wheels.tests._assets.testframework._UnderscoredPackage")');
	}

}
