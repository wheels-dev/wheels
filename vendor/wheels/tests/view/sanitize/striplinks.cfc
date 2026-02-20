component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
		args = {};
		args.html = 'this <a href="http://www.google.com" title="google">is</a> a <a href="mailto:someone@example.com" title="invalid email">test</a> to <a name="anchortag">see</a> if this works or not.';
	}

	function test_all_links_should_be_stripped() {
		e = _controller.striplinks(argumentcollection = args);
		r = "this is a test to see if this works or not.";
		assert("e eq r");
	}

}
