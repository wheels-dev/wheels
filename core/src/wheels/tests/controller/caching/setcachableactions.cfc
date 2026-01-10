component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
	}

	function test_setting_cachable_actions() {
		arr = [];
		arr[1] = {};
		arr[1].action = "dummy1";
		arr[1].time = 10;
		arr[1].static = true;
		arr[2] = {};
		arr[2].action = "dummy2";
		arr[2].time = 10;
		arr[2].static = true;
		_controller.$setCachableActions(arr);
		r = _controller.$cachableActions();
		assert("ArrayLen(r) IS 2 AND r[2].action IS 'dummy2'");
	}

}
