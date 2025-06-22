component extends="wheels.tests.Test" {

	function test_automatic_label_for_id_property() {
		_controller = controller(name = "Galleries");
		textField = _controller.textField(objectName = "gallery", property = "id", labelPlacement = "before");
		assert('textField contains "<label for=""gallery-id"">ID</label>"');
	}

	function test_automatic_label_ending_with_id() {
		_controller = controller(name = "Galleries");
		textField = _controller.textField(objectName = "gallery", property = "userId", labelPlacement = "before");
		assert('textField contains "<label for=""gallery-userId"">User</label>"');
	}

	function test_override_value() {
		_controller = controller(name = "ControllerWithModel");
		textField = _controller.textField(
			label = "First Name",
			objectName = "user",
			property = "firstName",
			value = "override"
		);
		foundValue = YesNoFormat(FindNoCase('value="override"', textField));
		assert('foundValue eq true');
	}

	function test_maxlength_textfield_valid() {
		_controller = controller(name = "ControllerWithModel");
		textField = _controller.textField(label = "First Name", objectName = "user", property = "firstName");
		foundMaxLength = YesNoFormat(FindNoCase('maxlength="50"', textField));
		assert('foundMaxLength eq true');
	}

}
