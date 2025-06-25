component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
	}

	function test_with_struct() {
		args.objectname = {firstname = "tony", lastname = "petruzzi"};
		args.property = "lastname";

		e = _controller.$tagid(argumentcollection = args);
		r = "lastname";
		assert("e eq r");

		e = _controller.$tagname(argumentcollection = args);
		assert("e eq r");
	}

	function test_with_string() {
		args.objectname = "wheels.Test.view.miscellaneous";
		args.property = "lastname";

		e = _controller.$tagid(argumentcollection = args);
		r = "miscellaneous-lastname";
		assert("e eq r");

		e = _controller.$tagname(argumentcollection = args);
		r = "miscellaneous[lastname]";
		assert("e eq r");
	}

	function test_with_array() {
		args.objectname = [1, 2, 3, 4];
		args.property = "lastname";

		e = _controller.$tagid(argumentcollection = args);
		r = "lastname";
		assert("e eq r");

		e = _controller.$tagname(argumentcollection = args);
		assert("e eq r");
	}

}
