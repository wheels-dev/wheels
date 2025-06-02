component extends="wheels.tests.Test" {

	function setup() {
		include "setup.cfm";
		params = {controller = "dummy", action = "dummy"};
		_controller = controller("dummy", params);
	}

	function teardown() {
		include "teardown.cfm";
	}

	function test_render_text() {
		_controller.renderText("OMG, look what I rendered!");
		assert("_controller.response() IS 'OMG, look what I rendered!'");
	}

	function test_render_text_with_status() {
		_controller.renderText(text = "OMG!", status = 418);
		actual = $statusCode();
		expected = 418;
		assert("actual eq expected");
	}

	function test_render_text_with_doesnt_hijack_status() {
		cfheader(statuscode=403);
		_controller.renderText(text = "OMG!");
		actual = $statusCode();
		expected = 403;
		assert("actual eq expected");
	}

}
