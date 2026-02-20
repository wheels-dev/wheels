component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
	}

	function test_getting_cache_settings_for_action() {
		_controller.caches(action = "dummy1", time = 100);
		r = _controller.$cacheSettingsForAction("dummy1");
		assert("r.time IS 100");
	}

}
