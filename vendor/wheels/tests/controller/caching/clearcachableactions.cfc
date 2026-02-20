component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
	}

	function test_clearing_cachable_actions() {
		_controller.caches(action = "dummy");
		_controller.$clearCachableActions();
		r = _controller.$cachableActions();
		assert("ArrayLen(r) IS 0");
	}

}
