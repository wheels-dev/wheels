component extends="wheels.tests.Test" {

	function setup() {
		include "setup.cfm";
	}

	function teardown() {
		include "teardown.cfm";
	}

	function test_flash_key_exists() {
		run_flash_key_exists();
		_controller.$setFlashStorage("cookie");
		run_flash_key_exists();
	}

	/**
	 * HELPERS
	 */

	function run_flash_key_exists() {
		_controller.flashInsert(success = "Congrats!");
		r = _controller.flashKeyExists("success");
		assert("r IS true");
	}

}
