component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
		args = {};
		args.name = "textarea";
		args.attributes = {};
		args.attributes.rows = 10;
		args.attributes.cols = 40;
		args.attributes.name = "textareatest";
		args.content = "this is a test to see if textarea renders";
	}

	function test_with_all_options() {
		e = _controller.$element(argumentcollection = args);
		r = '<textarea cols="40" name="textareatest" rows="10">this is a test to see if textarea renders</textarea>';
		assert("e eq r");
	}

}
