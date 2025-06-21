component extends="wheels.tests.Test" {

	function setup() {
		include "setup.cfm";
		// Start with fresh status code
		cfheader(statustext = "OK", statuscode = 200);
	}

	function teardown() {
		include "teardown.cfm";
		// Reset content type to HTML
		$header(name = "content-type", value = "text/html", charset = "utf-8");
	}

	// Test renderText with JSON format - no view file should be required
	function test_renderText_json_without_view() {
		params = {controller = "ApiTest", action = "renderTextJson", format = "json"};
		_controller = controller("ApiTest", params);
		
		// This should NOT throw ViewNotFound error
		try {
			$callAction(action = "renderTextJson");
			actual = _controller.response();
			expected = '{"success":true,"message":"renderText JSON works!"}';
			assert("actual eq expected");
		} catch (any e) {
			fail("renderText with JSON format should not throw error when no view exists. Error: #e.message#");
		}
	}

	// Test renderText with XML format - no view file should be required
	function test_renderText_xml_without_view() {
		params = {controller = "ApiTest", action = "renderTextXml", format = "xml"};
		_controller = controller("ApiTest", params);
		
		try {
			$callAction(action = "renderTextXml");
			actual = _controller.response();
			assert("actual Contains 'renderText XML works!'");
		} catch (any e) {
			fail("renderText with XML format should not throw error when no view exists. Error: #e.message#");
		}
	}

	// Test renderWith with JSON format - should auto-generate JSON
	function test_renderWith_json_autogenerate() {
		params = {controller = "ApiTest", action = "renderWithJson", format = "json"};
		_controller = controller("ApiTest", params);
		
		try {
			$callAction(action = "renderWithJson");
			actual = _controller.response();
			assert("IsJSON(actual) eq true");
			assert("actual Contains 'renderWith JSON works!'");
		} catch (any e) {
			fail("renderWith with JSON format should auto-generate content. Error: #e.message#");
		}
	}

	// Test renderWith with XML format - should auto-generate XML
	function test_renderWith_xml_autogenerate() {
		params = {controller = "ApiTest", action = "renderWithXml", format = "xml"};
		_controller = controller("ApiTest", params);
		
		try {
			$callAction(action = "renderWithXml");
			actual = _controller.response();
			assert("IsXML(actual) eq true");
			assert("actual Contains 'renderWith XML works!'");
		} catch (any e) {
			fail("renderWith with XML format should auto-generate content. Error: #e.message#");
		}
	}

	// Test action with no render - should not throw error for JSON format
	function test_no_render_json_format() {
		params = {controller = "ApiTest", action = "noRender", format = "json"};
		_controller = controller("ApiTest", params);
		
		try {
			$callAction(action = "noRender");
			// Should complete without error, even though nothing was rendered
			assert("true eq true");
		} catch (any e) {
			// Check if it's the expected ViewNotFound error
			if (e.type == "Wheels.ViewNotFound") {
				fail("Action with JSON format should not throw ViewNotFound when using onlyProvides. Error: #e.message#");
			} else {
				// Re-throw unexpected errors
				throw(object = e);
			}
		}
	}

	// Test renderText with custom status code
	function test_renderText_with_status_json() {
		params = {controller = "ApiTest", action = "renderWithStatus", format = "json"};
		_controller = controller("ApiTest", params);
		
		try {
			$callAction(action = "renderWithStatus");
			actual = _controller.response();
			assert('actual eq ''{"error":"Not Found"}''');
			assert("$statusCode() eq 404");
		} catch (any e) {
			fail("renderText with status should work without view. Error: #e.message#");
		}
	}

	// Test mixed format controller - HTML should still require view
	function test_mixed_format_html_requires_view() {
		params = {controller = "MixedFormatTest", action = "htmlAction", format = "html"};
		_controller = controller("MixedFormatTest", params);
		
		try {
			$callAction(action = "htmlAction");
			fail("HTML action without view should throw ViewNotFound error");
		} catch (any e) {
			assert("e.type eq 'Wheels.ViewNotFound'");
		}
	}

	// Test mixed format controller - JSON with renderText
	function test_mixed_format_json_renderText() {
		params = {controller = "MixedFormatTest", action = "jsonWithRenderText", format = "json"};
		_controller = controller("MixedFormatTest", params);
		
		try {
			$callAction(action = "jsonWithRenderText");
			actual = _controller.response();
			assert('actual eq ''{"source":"renderText"}''');
		} catch (any e) {
			fail("Mixed format controller should handle JSON renderText. Error: #e.message#");
		}
	}

	// Test mixed format controller - JSON with renderWith
	function test_mixed_format_json_renderWith() {
		params = {controller = "MixedFormatTest", action = "jsonWithRenderWith", format = "json"};
		_controller = controller("MixedFormatTest", params);
		
		try {
			$callAction(action = "jsonWithRenderWith");
			actual = _controller.response();
			assert("IsJSON(actual) eq true");
			assert("actual Contains 'renderWith'");
		} catch (any e) {
			fail("Mixed format controller should handle JSON renderWith. Error: #e.message#");
		}
	}

	// Test format-aware action
	function test_format_aware_json() {
		params = {controller = "MixedFormatTest", action = "formatAware", format = "json"};
		_controller = controller("MixedFormatTest", params);
		
		try {
			$callAction(action = "formatAware");
			actual = _controller.response();
			assert('actual eq ''{"format":"json"}''');
		} catch (any e) {
			fail("Format-aware action should handle JSON. Error: #e.message#");
		}
	}

	// Test restricted formats with onlyProvides
	function test_restricted_formats_json() {
		params = {controller = "MixedFormatTest", action = "restrictedFormats", format = "json"};
		_controller = controller("MixedFormatTest", params);
		
		try {
			$callAction(action = "restrictedFormats");
			actual = _controller.response();
			assert("IsJSON(actual) eq true");
		} catch (any e) {
			fail("Restricted formats should work with JSON. Error: #e.message#");
		}
	}

	// Test that HTML format is rejected when using onlyProvides
	function test_restricted_formats_html_rejected() {
		params = {controller = "MixedFormatTest", action = "restrictedFormats", format = "html"};
		_controller = controller("MixedFormatTest", params);
		
		try {
			$callAction(action = "restrictedFormats");
			// HTML should be rejected and default to first available format
			actual = _controller.response();
			// Should have rendered as JSON (first in the onlyProvides list)
			assert("IsJSON(actual) eq true");
		} catch (any e) {
			fail("Restricted formats should handle HTML rejection gracefully. Error: #e.message#");
		}
	}

}