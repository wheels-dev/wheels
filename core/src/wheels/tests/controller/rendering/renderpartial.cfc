component extends="wheels.tests.Test" {

	function setup() {
		include "setup.cfm";
		params = {controller = "test", action = "test"};
		_controller = controller("test", params);
	}

	function teardown() {
		include "teardown.cfm";
	}

	function test_rendering_partial() {
		result = _controller.renderPartial(partial = "partialTemplate");
		assert("_controller.response() Contains 'partial template content'");
	}

	function test_rendering_partial_and_returning_as_string() {
		result = _controller.renderPartial(partial = "partialTemplate", returnAs = "string");
		assert("NOT StructKeyExists(request.wheels, 'response') AND result Contains 'partial template content'");
	}

	function test_rendering_partial_with_status() {
		_controller.renderPartial(partial = "partialTemplate", status = 418);
		actual = $statusCode();
		expected = 418;
		assert("actual eq expected");
	}

}
