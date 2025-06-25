component extends="wheels.tests.Test" {

	function setup() {
		include "setup.cfm";
	}

	function teardown() {
		include "teardown.cfm";
	}

	function test_flash_none() {
		_controller.$setFlashStorage("none");
		_controller.flashInsert(success = "I should not exist", error = "I should not exist either");
		actual = _controller.flashMessages();
		assert("actual IS ''");
	}
}
