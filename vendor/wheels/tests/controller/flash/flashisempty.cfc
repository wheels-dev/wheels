component extends="wheels.tests.Test" {

	function setup() {
		include "setup.cfm";
	}

	function teardown() {
		include "teardown.cfm";
	}

	function test_flashIsEmpty_valid() {
		run_flashIsEmpty_valid();
		_controller.$setFlashStorage("cookie");
		run_flashIsEmpty_valid();
	}

	function run_flashIsEmpty_valid() {
		_controller.flashClear();
		result = _controller.flashIsEmpty();
		assert("result IS true");
	}

	function test_flashIsEmpty_invalid() {
		run_flashIsEmpty_invalid();
		_controller.$setFlashStorage("cookie");
		run_flashIsEmpty_invalid();
	}

	/**
	 * HELPERS
	 */

	function run_flashIsEmpty_invalid() {
		_controller.flashInsert(success = "Congrats!");
		result = _controller.flashIsEmpty();
		assert("result IS false");
	}

}
