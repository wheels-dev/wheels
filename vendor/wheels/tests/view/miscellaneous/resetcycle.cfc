component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
		args = {};
		args.values = "1,2,3,4,5,6";
		args.name = "cycle_test_2";
		container = ListToArray(args.values);
	}

	function test_named() {
		for (r in container) {
			_controller.cycle(argumentcollection = args);
		};
		assert("request.wheels.cycle[args.name] eq 6");
		_controller.resetcycle(args.name);
		assert("not structkeyexists(request.wheels.cycle, args.name)");
	}

	function test_not_named() {
		StructDelete(args, "name");
		for (r in container) {
			_controller.cycle(argumentcollection = args);
		};
		assert("request.wheels.cycle['default'] eq 6");
		_controller.resetcycle();
		assert("not isdefined('request.wheels.cycle.default')");
	}

}
