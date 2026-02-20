component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
		_controller.$clearCachableActions();
	}

	function test_adding_cachable_action() {
		_controller.caches("dummy1");
		str = {};
		str.action = "dummy2";
		str.time = 10;
		str.static = true;
		_controller.$addCachableAction(str);
		r = _controller.$cachableActions();
		assert("ArrayLen(r) IS 2 AND r[2].action IS 'dummy2'");
	}

}
