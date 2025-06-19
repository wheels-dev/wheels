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
		cfheader(statustext="Leave me be", statuscode=403);
		_controller.renderText(text = "OMG!");
		actual = $statusCode();
		expected = 403;
		assert("actual eq expected");
	}

	// Test renderText with JSON format
	function test_render_text_json_format() {
		params.format = "json";
		_controller = controller("dummy", params);
		_controller.provides("json");
		_controller.renderText('{"message":"JSON response"}');
		assert("_controller.response() IS '{"message":"JSON response"}'");
	}

	// Test renderText with XML format
	function test_render_text_xml_format() {
		params.format = "xml";
		_controller = controller("dummy", params);
		_controller.provides("xml");
		_controller.renderText('<response><message>XML response</message></response>');
		assert("_controller.response() Contains '<message>XML response</message>'");
	}

	// Test renderText doesn't require view for non-HTML formats
	function test_render_text_no_view_required() {
		params = {controller = "ApiTest", action = "renderTextJson", format = "json"};
		_controller = controller("ApiTest", params);
		// This should work without throwing ViewNotFound
		_controller.renderText('{"test":true}');
		assert("_controller.response() eq '{"test":true}'");
	}

}
