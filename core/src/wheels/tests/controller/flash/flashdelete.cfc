component extends="wheels.tests.Test" {

	function setup() {
		include "setup.cfm";
	}

	function teardown() {
		include "teardown.cfm";
	}

	function test_flashDelete_invalid() {
		run_flashDelete_invalid();
		application.wheels.flashStorage = "cookie";
		run_flashDelete_invalid();
	}

	function run_flashDelete_invalid() {
		_controller.flashClear();
		result = _controller.flashDelete(key = "success");
		assert("result IS false");
	}

	function test_flashDelete_valid() {
		run_flashDelete_valid();
		application.wheels.flashStorage = "cookie";
		run_flashDelete_valid();
	}

	/**
	 * HELPERS
	 */

	function run_flashDelete_valid() {
		_controller.flashClear();
		_controller.flashInsert(success = "Congrats!");
		result = _controller.flashDelete(key = "success");
		assert("result IS true");
	}

}
