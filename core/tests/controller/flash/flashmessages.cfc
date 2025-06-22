component extends="wheels.tests.Test" {

	function setup() {
		include "setup.cfm";
		set(functionName = "flashMessages", encode = false);
	}

	function teardown() {
		include "teardown.cfm";
		set(functionName = "flashMessages", encode = true);
	}

	function test_normal_output() {
		run_normal_output();
		_controller.$setFlashStorage("cookie");
		run_normal_output();
	}

	function test_specific_key_only() {
		run_specific_key_only();
		_controller.$setFlashStorage("cookie");
		run_specific_key_only();
	}

	function test_passing_through_id() {
		run_passing_through_id();
		_controller.$setFlashStorage("cookie");
		run_passing_through_id();
	}

	function test_empty_flash() {
		run_empty_flash();
		_controller.$setFlashStorage("cookie");
		run_empty_flash();
	}

	function test_empty_flash_includeEmptyContainer() {
		run_empty_flash_includeEmptyContainer();
		_controller.$setFlashStorage("cookie");
		run_empty_flash_includeEmptyContainer();
	}

	function test_allow_complex_values() {
		run_allow_complex_values();
		_controller.$setFlashStorage("cookie");
		run_allow_complex_values();
	}

	function test_appends_if_allowed() {
		run_appends_if_allowed();
		_controller.$setFlashStorage("cookie");
		run_appends_if_allowed();
	}

	function test_control_order_via_keys_argument() {
		run_control_order_via_keys_argument();
		_controller.$setFlashStorage("cookie");
		run_control_order_via_keys_argument();
	}

	function test_casing_of_class_attribute() {
		run_casing_of_class_attribute();
		_controller.$setFlashStorage("cookie");
		run_casing_of_class_attribute();
	}

	function test_casing_of_class_attribute_mixed() {
		run_casing_of_class_attribute_mixed();
		_controller.$setFlashStorage("cookie");
		run_casing_of_class_attribute_mixed();
	}

	function test_casing_of_class_attribute_upper() {
		run_casing_of_class_attribute_upper();
		_controller.$setFlashStorage("cookie");
		run_casing_of_class_attribute_upper();
	}

	function test_setting_class() {
		run_setting_class();
		_controller.$setFlashStorage("cookie");
		run_setting_class();
	}

	/**
	 * HELPERS
	 */

	function run_normal_output() {
		_controller.flashInsert(success = "Congrats!");
		_controller.flashInsert(alert = "Error!");
		actual = _controller.flashMessages();
		assert(
			"actual IS '<div class=""flash-messages""><p class=""alert-message"">Error!</p><p class=""success-message"">Congrats!</p></div>'"
		);
	}

	function run_specific_key_only() {
		_controller.flashInsert(success = "Congrats!");
		_controller.flashInsert(alert = "Error!");
		actual = _controller.flashMessages(key = "alert");
		assert("actual IS '<div class=""flash-messages""><p class=""alert-message"">Error!</p></div>'");
	}

	function run_passing_through_id() {
		_controller.flashInsert(success = "Congrats!");
		actual = _controller.flashMessages(id = "my-id");
		assert("actual Contains '<p class=""success-message"">Congrats!</p>' AND actual Contains 'id=""my-id""'");
	}

	function run_empty_flash() {
		actual = _controller.flashMessages();
		assert("actual IS ''");
	}

	function run_empty_flash_includeEmptyContainer() {
		actual = _controller.flashMessages(includeEmptyContainer = "true");
		assert("actual IS '<div class=""flash-messages""></div>'");
	}

	function run_appends_if_allowed() {
		_controller.$setFlashAppend(true);
		_controller.flashInsert(success = "Congrats!");
		_controller.flashInsert(success = "Congrats Again!");
		actual = _controller.flashMessages();
		assert(
			"actual IS '<div class=""flash-messages""><p class=""success-message"">Congrats!</p><p class=""success-message"">Congrats Again!</p></div>'"
		);
		_controller.$setFlashAppend(false);
	}

	function run_allow_complex_values() {
		arr = [];
		arr[1] = "Congrats!";
		arr[2] = "Congrats Again!";
		_controller.flashInsert(success = arr);
		actual = _controller.flashMessages();
		assert(
			"actual IS '<div class=""flash-messages""><p class=""success-message"">Congrats!</p><p class=""success-message"">Congrats Again!</p></div>'"
		);
	}

	function run_control_order_via_keys_argument() {
		_controller.flashInsert(success = "Congrats!");
		_controller.flashInsert(alert = "Error!");
		actual = _controller.flashMessages(keys = "success,alert");
		assert(
			"actual IS '<div class=""flash-messages""><p class=""success-message"">Congrats!</p><p class=""alert-message"">Error!</p></div>'"
		);
		actual = _controller.flashMessages(keys = "alert,success");
		assert(
			"actual IS '<div class=""flash-messages""><p class=""alert-message"">Error!</p><p class=""success-message"">Congrats!</p></div>'"
		);
	}

	function run_casing_of_class_attribute() {
		_controller.flashInsert(something = "");
		actual = _controller.flashMessages();
		expected = 'class="something-message"';
		assert('Find(expected, actual)');
		_controller.flashInsert(someThing = "");
	}

	function run_casing_of_class_attribute_mixed() {
		_controller.flashInsert(someThing = "");
		actual = _controller.flashMessages();
		expected = 'class="something-message"';
		assert('Find(expected, actual)');
	}

	function run_casing_of_class_attribute_upper() {
		_controller.flashInsert(SOMETHING = "");
		actual = _controller.flashMessages();
		expected = 'class="something-message"';
		assert('Find(expected, actual)');
	}

	function run_setting_class() {
		_controller.flashInsert(success = "test");
		actual = _controller.flashMessages(class = "custom-class");
		expected = 'class="custom-class"';
		e2 = 'class="success-message"';
		assert('Find(expected, actual) AND Find(e2, actual)');
	}

}
