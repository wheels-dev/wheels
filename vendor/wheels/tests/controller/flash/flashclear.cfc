component extends="wheels.tests.Test" {

	function setup() {
		include "setup.cfm";
	}

	function teardown() {
		include "teardown.cfm";
	}

	function test_flashClear_valid() {
		run_flashClear_valid();
		_controller.$setFlashStorage("cookie");
		run_flashClear_valid();
	}

	/**
	 * HELPERS
	 */

	function run_flashClear_valid() {
		_controller.flashInsert(success = "Congrats!");
		_controller.flashClear();
		result = StructKeyList(_controller.flash());
		assert("result IS ''");
	}

}
