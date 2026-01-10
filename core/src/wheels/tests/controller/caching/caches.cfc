component extends="wheels.tests.Test" {

	function setup() {
		params = {controller = "test", action = "test"};
		_controller = controller("test", params);
		_controller.$clearCachableActions();
	}

	function test_specifying_one_action_to_cache() {
		_controller.caches(action = "dummy");
		r = _controller.$cacheSettingsForAction("dummy");
		assert("r.time IS 60");
	}

	function test_specifying_one_action_to_cache_and_running_it() {
		$$oldViewPath = application.wheels.viewPath;
		application.wheels.viewPath = "/wheels/tests/_assets/views";
		_controller.caches(action = "test");
		result = _controller.processAction("test", params);
		application.wheels.viewPath = $$oldViewPath;
		assert("result IS true");
	}

	function test_specifying_multiple_actions_to_cache() {
		_controller.caches(actions = "dummy1,dummy2");
		r = _controller.$cachableActions();
		assert("ArrayLen(r) IS 2 AND r[2].time IS 60");
	}

	function test_specifying_actions_to_cache_with_options() {
		_controller.caches(actions = "dummy1,dummy2", time = 5, static = true);
		r = _controller.$cachableActions();
		assert("ArrayLen(r) IS 2 AND r[2].time IS 5 AND r[2].static IS true");
	}

	function test_specifying_caching_all_actions() {
		_controller.caches(static = true);
		r = _controller.$cacheSettingsForAction("dummy");
		assert("r.static IS true");
	}

}
