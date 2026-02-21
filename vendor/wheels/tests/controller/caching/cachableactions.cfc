component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
		_controller.$clearCachableActions();
	}

	function test_getting_cachable_actions() {
		_controller.caches(actions = "dummy1,dummy2");
		r = _controller.$cachableActions();
		assert("ArrayLen(r) IS 2 AND r[1].static IS false");
	}

}
