component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
		args = {};
		args.text = "this is a test to see if this works or not.";
		args.length = "20";
		args.truncateString = "[more]";
	}

	function test_phrase_should_truncate() {
		e = _controller.truncate(argumentcollection = args);
		r = "this is a test[more]";
		assert("e eq r");
	}

	function test_phrase_is_blank() {
		args.text = "";
		e = _controller.truncate(argumentcollection = args);
		r = "";
		assert("e eq r");
	}

	function test_truncateString_argument_is_missing() {
		StructDelete(args, "truncateString");
		e = _controller.truncate(argumentcollection = args);
		r = "this is a test to...";
		assert("e eq r");
	}

}
