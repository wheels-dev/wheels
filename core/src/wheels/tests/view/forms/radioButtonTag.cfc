component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
	}

	function test_radioButtonTag_value_not_blank() {
		e = _controller.radioButtonTag(
			name = "gender",
			value = "m",
			label = "Male",
			checked = true
		);
		r = '<label for="gender-m">Male<input checked="checked" id="gender-m" name="gender" type="radio" value="m"></label>';
		debug(expression = 'e', display = false, format = "text");
		assert('e eq r');
	}

	function test_radioButtonTag_value_blank() {
		e = _controller.radioButtonTag(
			name = "gender",
			value = "",
			label = "Male",
			checked = true
		);
		r = '<label for="gender">Male<input checked="checked" id="gender" name="gender" type="radio" value=""></label>';
		debug(expression = 'htmleditformat(e)', display = false, format = "text");
		assert('e eq r');
	}

	function test_radioButtonTag_value_blank_and_not_checked() {
		e = _controller.radioButtonTag(
			name = "gender",
			value = "",
			label = "Male",
			checked = false
		);
		r = '<label for="gender">Male<input id="gender" name="gender" type="radio" value=""></label>';
		assert('e eq r');
	}

}
