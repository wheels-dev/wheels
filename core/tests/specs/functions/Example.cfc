/**
 * This is an example file, it can be safely deleted.
 * We recommend using the "functions" folder for testing controller, model and global functions.
 * The test suite is flexible though so you can safely rename folders and files to structure things how you want it.
 */
component extends="tests.Test" {

	/**
	 * Executes once before this package's first test case.
	 *
	 * [section: Test Model Configuration]
	 * [category: Callback Functions]
	 */
	function packageSetup() {
	}

	/**
	 * Executes before every test case.
	 *
	 * [section: Test Model Configuration]
	 * [category: Callback Functions]
	 */
	function setup() {
		super.setup();
	}

	/**
	 * An example test.
	 */
	function testExample() {
		assert("true");
	}

	/**
	 * Executes after every test case.
	 *
	 * [section: Test Model Configuration]
	 * [category: Callback Functions]
	 */
	function teardown() {
		super.teardown();
	}

	/**
	 * Executes once after this package's last test case.
	 *
	 * [section: Test Model Configuration]
	 * [category: Callback Functions]
	 */
	function packageTeardown() {
	}

}
