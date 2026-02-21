component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "ControllerWithModel");
		oldBooleanAttributes = application.wheels.booleanAttributes;
	}

	function teardown() {
		application.wheels.booleanAttributes = oldBooleanAttributes;
	}

	function test_tag_with_disabled_and_readonly_set_to_true() {
		textField = _controller.textFieldTag(
			label = "First Name",
			name = "firstName",
			disabled = true,
			readonly = true
		);
		expected = '<label for="firstName">First Name<input disabled id="firstName" name="firstName" readonly type="text" value=""></label>';
		assert('expected eq textField');
	}

	function test_tag_with_disabled_and_readonly_set_to_false() {
		textField = _controller.textFieldTag(
			label = "First Name",
			name = "firstName",
			disabled = false,
			readonly = false
		);
		expected = '<label for="firstName">First Name<input id="firstName" name="firstName" type="text" value=""></label>';
		assert('expected eq textField');
	}

	function test_tag_with_disabled_and_readonly_set_to_string() {
		textField = _controller.textFieldTag(
			label = "First Name",
			name = "firstName",
			disabled = "cheese",
			readonly = "crackers"
		);
		expected = '<label for="firstName">First Name<input disabled="cheese" id="firstName" name="firstName" readonly="crackers" type="text" value=""></label>';
		assert('expected eq textField');
	}

	function test_supported_attributes_should_be_boolean() {
		result = _controller.textFieldTag(name = "num", checked = true, disabled = "true");
		correct = '<input checked disabled id="num" name="num" type="text" value="">';
		assert('result IS correct');
	}

	function test_non_supported_attributes_should_be_non_boolean() {
		result = _controller.textFieldTag(name = "num", class = "true", value = "true");
		correct = '<input class="true" id="num" name="num" type="text" value="true">';
		assert('result IS correct');
	}

	function test_supported_attribute_should_be_omitted_when_false() {
		result = _controller.textFieldTag(name = "num", readonly = false);
		correct = '<input id="num" name="num" type="text" value="">';
		assert('result IS correct');
	}

	function test_supported_attribute_should_be_non_boolean_when_setting_is_off() {
		application.wheels.booleanAttributes = false;
		result = _controller.textFieldTag(name = "num", checked = true);
		correct = '<input checked="true" id="num" name="num" type="text" value="">';
		assert('result IS correct');
	}

	function test_non_supported_attribute_should_be_boolean_when_setting_is_on() {
		application.wheels.booleanAttributes = true;
		result = _controller.textFieldTag(name = "num", whatever = true);
		correct = '<input id="num" name="num" type="text" value="" whatever>';
		assert('result IS correct');
	}

}
