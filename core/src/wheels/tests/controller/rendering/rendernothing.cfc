component extends="wheels.tests.Test" {

	function setup() {
		include "setup.cfm";
		params = {controller = "dummy", action = "dummy"};
		_controller = controller("dummy", params);
	}

	function teardown() {
		include "teardown.cfm";
	}

	function test_render_nothing() {
		_controller.renderNothing();
		assert("_controller.response() IS ''");
	}

	function test_render_nothing_with_status() {
		_controller.renderNothing(status = 418);
		actual = $statusCode();
		expected = 418;
		assert("actual eq expected");
	}

}
