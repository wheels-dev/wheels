component extends="wheels.tests.Test" {

	function setup() {
		include "setup.cfm";
		params = {controller = "test", action = "test"};
		cfheader(statuscode=200); // start with a fresh status code
	}

	function teardown() {
		include "teardown.cfm";
		$header(name = "content-type", value = "text/html", charset = "utf-8");
	}

	/* function test_json_integer() {
		params = {controller="dummy", action="dummy", format = "json"};
		_controller = controller("dummy", params);
		_controller.provides("json");
		user = model("user").findAll(where="username = 'tonyp'", returnAs="structs");
		result = _controller.renderWith(data=user, zipCode="integer", returnAs="string");
		assert("result Contains ':11111,'");
	} */

	/* function test_json_string() {
		params = {controller="dummy", action="dummy", format = "json"};
		_controller = controller("dummy", params);
		_controller.provides("json");
		user = model("user").findAll(where="username = 'tonyp'", returnAs="structs");
		result = _controller.renderWith(data=user, phone="string", returnAs="string");
		assert("result Contains '1235551212'");
	} */

	function test_throws_error_without_data_argument() {
		_controller = controller("test", params);
		try {
			result = _controller.renderWith();
		} catch (any e) {
			assert('true eq true');
		}
	}

	function test_current_action_as_xml_with_template_returning_string_to_controller() {
		params.format = "xml";
		_controller = controller("test", params);
		_controller.provides("xml");
		user = model("user").findOne(where = "username = 'tonyp'");
		data = _controller.renderWith(data = user, layout = false, returnAs = "string");
		assert("data Contains 'xml template content'");
	}

	function test_current_action_as_xml_with_template() {
		params.format = "xml";
		_controller = controller("test", params);
		_controller.provides("xml");
		user = model("user").findOne(where = "username = 'tonyp'");
		_controller.renderWith(data = user, layout = false);
		assert("_controller.response() Contains 'xml template content'");
	}

	function test_current_action_as_xml_without_template() {
		params.action = "test2";
		params.format = "xml";
		_controller = controller("test", params);
		_controller.provides("xml");
		user = model("user").findOne(where = "username = 'tonyp'");
		_controller.renderWith(data = user);
		assert("IsXml(_controller.response()) eq true");
	}

	function test_current_action_as_xml_without_template_returning_string_to_controller() {
		params.action = "test2";
		params.format = "xml";
		_controller = controller("test", params);
		_controller.provides("xml");
		user = model("user").findOne(where = "username = 'tonyp'");
		data = _controller.renderWith(data = user, returnAs = "string");
		assert("IsXml(data) eq true");
	}

	function test_current_action_as_json_with_template() {
		params.format = "json";
		_controller = controller("test", params);
		_controller.provides("json");
		user = model("user").findOne(where = "username = 'tonyp'");
		_controller.renderWith(data = user, layout = false);
		assert("_controller.response() Contains 'json template content'");
	}

	function test_current_action_as_json_without_template() {
		params.action = "test2";
		params.format = "json";
		_controller = controller("test", params);
		_controller.provides("json");
		user = model("user").findOne(where = "username = 'tonyp'");
		_controller.renderWith(data = user);
		assert("IsJSON(_controller.response()) eq true");
	}

	function test_current_action_as_json_without_template_returning_string_to_controller() {
		params.action = "test2";
		params.format = "json";
		_controller = controller("test", params);
		_controller.provides("json");
		user = model("user").findOne(where = "username = 'tonyp'");
		data = _controller.renderWith(data = user, returnAs = "string");
		assert("IsJSON(data) eq true");
	}

	function test_current_action_as_pdf_with_template_throws_error() {
		params.format = "pdf";
		_controller = controller("test", params);
		_controller.provides("pdf");
		user = model("user").findOne(where = "username = 'tonyp'");
		try {
			_controller.renderWith(data = user, layout = false);
			fail(message = "Error did not occur.");
		} catch (any e) {
			assert("true eq true");
		}
	}

	function test_renderingError_raised_when_template_is_not_found_for_format() {
		params.format = "xls";
		params.action = "notfound";
		_controller = controller("test", params);
		_controller.provides("xml");
		user = model("user").findOne(where = "username = 'tonyp'");
		actual = raised('_controller.renderWith(data=user, layout=false, returnAs="string")');
		expected = "Wheels.renderingError";
		assert("actual eq expected");
	}

	/* Custom Status Codes; probably no need to test all 75 odd */
	function test_custom_status_codes_no_argument_passed() {
		params.format = "json";
		params.action = "test2";
		_controller = controller("test", params);
		_controller.provides("json");
		user = model("user").findOne(where = "username = 'tonyp'");
		_controller.renderWith(data = user, layout = false, returnAs = "string");
		assert("$statusCode() EQ 200");
	}

	function test_custom_status_codes_403() {
		params.format = "json";
		params.action = "test2";
		_controller = controller("test", params);
		_controller.provides("json");
		user = model("user").findOne(where = "username = 'tonyp'");
		_controller.renderWith(
			data = user,
			layout = false,
			returnAs = "string",
			status = 403
		);
		assert("$statusCode() EQ 403");
	}

	function test_custom_status_codes_404() {
		params.format = "json";
		params.action = "test2";
		_controller = controller("test", params);
		_controller.provides("json");
		user = model("user").findOne(where = "username = 'tonyp'");
		_controller.renderWith(
			data = user,
			layout = false,
			returnAs = "string",
			status = 404
		);
		assert("$statusCode() EQ 404");
	}

	function test_custom_status_codes_with_html() {
		params.action = "test2";
		_controller = controller("test", params);
		_controller.renderWith(data = "the rain in spain", layout = false, status = 403);
		assert("$statusCode() EQ 403");
	}

	function test_custom_status_codes_OK() {
		params.format = "json";
		params.action = "test2";
		_controller = controller("test", params);
		_controller.provides("json");
		user = model("user").findOne(where = "username = 'tonyp'");
		_controller.renderWith(
			data = user,
			layout = false,
			returnAs = "string",
			status = "OK"
		);
		assert("$statusCode() EQ 200");
	}
	function test_custom_status_codes_Not_Found() {
		GetPageContext().getResponse().setStatus("100");
		params.format = "json";
		params.action = "test2";
		_controller = controller("test", params);
		_controller.provides("json");
		user = model("user").findOne(where = "username = 'tonyp'");
		_controller.renderWith(
			data = user,
			layout = false,
			returnAs = "string",
			status = "Not Found"
		);
		assert("$statusCode() EQ 404");
	}
	function test_custom_status_codes_Method_Not_Allowed() {
		GetPageContext().getResponse().setStatus("100");
		params.format = "json";
		params.action = "test2";
		_controller = controller("test", params);
		_controller.provides("json");
		user = model("user").findOne(where = "username = 'tonyp'");
		_controller.renderWith(
			data = user,
			layout = false,
			returnAs = "string",
			status = "Method Not Allowed"
		);
		assert("$statusCode() EQ 405");
	}

	function test_custom_status_codes_Method_Not_Allowed_case() {
		GetPageContext().getResponse().setStatus("100");
		params.format = "json";
		params.action = "test2";
		_controller = controller("test", params);
		_controller.provides("json");
		user = model("user").findOne(where = "username = 'tonyp'");
		_controller.renderWith(
			data = user,
			layout = false,
			returnAs = "string",
			status = "method not allowed"
		);
		assert("$statusCode() EQ 405");
	}

	function test_custom_status_codes_bad_numeric() {
		params.format = "json";
		params.action = "test2";
		_controller = controller("test", params);
		_controller.provides("json");
		user = model("user").findOne(where = "username = 'tonyp'");
		actual = raised('_controller.renderWith(data=user, layout=false, returnAs="string", status=987654321)');
		expected = "Wheels.renderingError";
		assert("actual EQ expected");
	}

	function test_custom_status_codes_bad_text() {
		params.format = "json";
		params.action = "test2";
		_controller = controller("test", params);
		_controller.provides("json");
		user = model("user").findOne(where = "username = 'tonyp'");
		actual = raised('_controller.renderWith(data=user, layout=false, returnAs="string", status="THECAKEISALIE")');
		expected = "Wheels.renderingError";
		assert("actual EQ expected");
	}

	// Test renderWith doesn't require view for JSON when auto-generating
	function test_render_with_json_no_view_required() {
		params = {controller = "ApiTest", action = "renderWithJson", format = "json"};
		_controller = controller("ApiTest", params);
		local.data = {test = true, message = "No view needed"};
		// This should work without throwing ViewNotFound
		_controller.renderWith(data = local.data);
		assert("IsJSON(_controller.response()) eq true");
		assert("_controller.response() Contains 'No view needed'");
	}

	// Test renderWith doesn't require view for XML when auto-generating
	function test_render_with_xml_no_view_required() {
		params = {controller = "ApiTest", action = "renderWithXml", format = "xml"};
		_controller = controller("ApiTest", params);
		local.data = {test = true, message = "XML without view"};
		// This should work without throwing ViewNotFound
		_controller.renderWith(data = local.data);
		assert("IsXML(_controller.response()) eq true");
	}

	// Test renderWith respects onlyProvides
	function test_render_with_only_provides() {
		params = {controller = "ApiTest", action = "renderWithJson", format = "json"};
		_controller = controller("ApiTest", params);
		// ApiTest controller uses onlyProvides("json,xml")
		local.data = {restricted = true};
		_controller.renderWith(data = local.data);
		assert("IsJSON(_controller.response()) eq true");
	}

	// Test renderWith sets response properly (addressing bug fix)
	function test_render_with_sets_response() {
		params = {controller = "test", action = "test2", format = "json"};
		_controller = controller("test", params);
		_controller.provides("json");
		local.data = {verified = true, timestamp = Now()};
		_controller.renderWith(data = local.data);
		// Verify response is set (not just returned)
		assert("Len(_controller.response()) gt 0");
		assert("IsJSON(_controller.response()) eq true");
	}

}
