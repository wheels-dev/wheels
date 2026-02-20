component extends="wheels.tests.Test" {

	function setup() {
		include "setup.cfm";
	}

	function teardown() {
		include "teardown.cfm";
	}

	function test_key_exists() {
		run_key_exists();
		_controller.$setFlashStorage("cookie");
		run_key_exists();
	}

	function run_key_exists() {
		_controller.flashInsert(success = "Congrats!");
		result = _controller.flash("success");
		assert("result IS 'Congrats!'");
	}

	function test_key_does_not_exist() {
		run_key_does_not_exist();
		_controller.$setFlashStorage("cookie");
		run_key_does_not_exist();
	}

	function run_key_does_not_exist() {
		_controller.flashInsert(success = "Congrats!");
		result = _controller.flash("invalidkey");
		assert("result IS ''");
	}

	function test_key_is_blank() {
		run_key_is_blank();
		_controller.$setFlashStorage("cookie");
		run_key_is_blank();
	}

	function run_key_is_blank() {
		_controller.flashInsert(success = "Congrats!");
		result = _controller.flash("");
		assert("result IS ''");
	}

	function test_key_provided_flash_empty() {
		run_key_provided_flash_empty();
		_controller.$setFlashStorage("cookie");
		run_key_provided_flash_empty();
	}

	function run_key_provided_flash_empty() {
		_controller.flashInsert(success = "Congrats!");
		_controller.flashClear();
		result = _controller.flash("invalidkey");
		assert("result IS ''");
	}

	function test_no_key_provided_flash_not_empty() {
		run_no_key_provided_flash_not_empty();
		_controller.$setFlashStorage("cookie");
		run_no_key_provided_flash_not_empty();
	}

	/**
	 * HELPERS
	 */

	function run_no_key_provided_flash_not_empty() {
		_controller.flashInsert(success = "Congrats!");
		result = _controller.flash();
		assert("IsStruct(result) AND StructKeyExists(result, 'success')");
	}

	function test_no_key_provided_flash_empty() {
		run_no_key_provided_flash_empty();
		_controller.$setFlashStorage("cookie");
		run_no_key_provided_flash_empty();
	}

	function run_no_key_provided_flash_empty() {
		_controller.flashInsert(success = "Congrats!");
		_controller.flashClear();
		result = _controller.flash();
		assert("IsStruct(result) AND StructIsEmpty(result)");
	}

}
