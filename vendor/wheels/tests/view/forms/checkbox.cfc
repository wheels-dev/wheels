component extends="wheels.tests.Test" {

	function setup() {
		_controller = application.wirebox.getInstance("wheels.tests._assets.controllers.ControllerWithModel");
		args = {};
		args.objectName = "user";
		args.label = false;
		set(functionName = "checkBox", encode = false);
	}

	function teardown() {
		set(functionName = "checkBox", encode = true);
	}

	function test_checked_when_property_value_equals_checkedValue() {
		args.property = "birthdaymonth";
		args.checkedvalue = "11";
		debug("_controller.checkBox(argumentcollection=args)", false);
		e = '<input checked="checked" id="user-birthdaymonth" name="user[birthdaymonth]" type="checkbox" value="11"><input id="user-birthdaymonth-checkbox" name="user[birthdaymonth]($checkbox)" type="hidden" value="0">';
		r = _controller.checkBox(argumentcollection = args);
		assert("e eq r");
		args.checkedvalue = "12";
		debug("_controller.checkBox(argumentcollection=args)", false);
		e = '<input id="user-birthdaymonth" name="user[birthdaymonth]" type="checkbox" value="12"><input id="user-birthdaymonth-checkbox" name="user[birthdaymonth]($checkbox)" type="hidden" value="0">';
		r = _controller.checkBox(argumentcollection = args);
		assert("e eq r");
	}

	function test_checkbox_is_unchecked_with_checkedvalue_when_property_value_is_1() {
		args.property = "isactive";
		args.checkedvalue = "0";

		actual = _controller.checkBox(argumentcollection = args);
		assert("actual does not contain 'checked'");
	}

	function test_checkbox_is_checked_with_checkedvalue_when_property_value_is_1() {
		args.property = "isactive";
		args.checkedvalue = "1";

		actual = _controller.checkBox(argumentcollection = args);
		assert("actual contains 'checked'");
	}

	function test_checkbox_is_checked_with_default_checkedvalue_when_property_value_is_1() {
		args.property = "isactive";

		actual = _controller.checkBox(argumentcollection = args);
		assert("actual contains 'checked'");
	}

}
