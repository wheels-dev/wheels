component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
		args = {};
		args.values = "1,2,3,4,5,6";
		args.name = "cycle_test";
		container = ListToArray(args.values);
	}

	function test_named() {
		for (r in container) {
			e = _controller.cycle(argumentcollection = args);
			assert("e eq r");
		};
	}

	function test_not_named() {
		StructDelete(args, "name");
		for (r in container) {
			e = _controller.cycle(argumentcollection = args);
			assert("e eq r");
		}
	}

}
