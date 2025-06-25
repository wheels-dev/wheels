component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
		_controller.$clearCachableActions();
	}

	function test_checking_cachable_action() {
		result = _controller.$hasCachableActions();
		assert("result IS false");
		_controller.caches("dummy1");
		result = _controller.$hasCachableActions();
		assert("result IS true");
	}

}
