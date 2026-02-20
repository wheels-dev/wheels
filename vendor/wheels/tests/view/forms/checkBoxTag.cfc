component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
	}

	function test_not_checked() {
		e = _controller.checkBoxTag(
			name = "subscribe",
			value = "1",
			label = "Subscribe to our newsletter",
			checked = false
		);
		r = '<label for="subscribe-1">Subscribe to our newsletter<input id="subscribe-1" name="subscribe" type="checkbox" value="1"></label>';
		assert('e eq r');
	}

	function test_checked() {
		e = _controller.checkBoxTag(
			name = "subscribe",
			value = "1",
			label = "Subscribe to our newsletter",
			checked = true
		);
		r = '<label for="subscribe-1">Subscribe to our newsletter<input checked="checked" id="subscribe-1" name="subscribe" type="checkbox" value="1"></label>';
		assert('e eq r');
	}

	function test_value_blank_and_not_checked() {
		e = _controller.checkBoxTag(name = "gender", value = "", checked = false);
		r = '<input id="gender" name="gender" type="checkbox" value="">';
		assert('e eq r');
	}

	function test_encoding_attributes() {
		e = _controller.checkBoxTag(
			name = "gender",
			value = "",
			checked = false,
			uncheckedvalue = 1,
			encode = "attributes"
		);
		r = '<input id="gender" name="gender" type="checkbox" value=""><input id="gender-checkbox" name="gender&##x28;&##x24;checkbox&##x29;" type="hidden" value="1">';
		assert('e eq r');
	}

}
