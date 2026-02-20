component extends="wheels.tests.Test" {

	function setup() {
		include "setup.cfm";
	}

	function teardown() {
		include "teardown.cfm";
	}

	function test_flashInsert_valid() {
		run_flashInsert_valid();
		_controller.$setFlashStorage("cookie");
		run_flashInsert_valid();
	}

	function run_flashInsert_valid() {
		_controller.flashInsert(success = "Congrats!");
		assert("_controller.flash('success') IS 'Congrats!'");
	}

	function test_flashInsert_mulitple() {
		run_flashInsert_mulitple();
		_controller.$setFlashStorage("cookie");
		run_flashInsert_mulitple();
	}

	/**
	 * HELPERS
	 */

	function run_flashInsert_mulitple() {
		_controller.flashInsert(success = "Hooray!!!", error = "WTF!");
		assert("_controller.flash('success') IS 'Hooray!!!'");
		assert("_controller.flash('error') IS 'WTF!'");
	}

}
