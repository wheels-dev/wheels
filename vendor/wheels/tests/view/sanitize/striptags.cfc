component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
		args = {};
		args.html = '<h1>this</h1><p><a href="http://www.google.com" title="google">is</a></p><p>a <a href="mailto:someone@example.com" title="invalid email">test</a> to<br><a name="anchortag">see</a> if this works or not.</p>';
	}

	function test_all_tags_should_be_stripped() {
		e = _controller.stripTags(argumentcollection = args);
		r = "thisisa test tosee if this works or not.";
		assert("e eq r");
	}

}
