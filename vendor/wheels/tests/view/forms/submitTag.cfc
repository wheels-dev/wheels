component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "ControllerWithModel");
		set(functionName = "submitTag", encode = false);
	}

	function teardown() {
		set(functionName = "submitTag", encode = true);
	}

	function test_defaults() {
		actual = _controller.submitTag();
		expected = '<input type="submit" value="Save changes">';
		assert('actual eq expected');
	}

	function test_submittag_arguments() {
		actual = _controller.submitTag(disable = "disable-value");
		expected = '<input disable="disable-value" type="submit" value="Save changes">';
		assert('actual eq expected');
	}

	function test_append_prepend() {
		actual = _controller.submitTag(append = "a", prepend = "p");
		expected = 'p<input type="submit" value="Save changes">a';
		assert('actual eq expected');
	}

}
