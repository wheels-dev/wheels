component extends="wheels.tests.Test" {

	function setup() {
		include "setup.cfm";
	}

	function teardown() {
		include "teardown.cfm";
	}

	function test_flashCount_valid() {
		run_flashCount_valid();
		_controller.$setFlashStorage("cookie");
		run_flashCount_valid();
	}

	/**
	 * HELPERS
	 */

	function run_flashCount_valid() {
		_controller.flashInsert(success = "Congrats!");
		_controller.flashInsert(anotherKey = "Test!");
		result = _controller.flashCount();
		compare = _controller.flashCount();
		assert("result IS compare");
	}

}
