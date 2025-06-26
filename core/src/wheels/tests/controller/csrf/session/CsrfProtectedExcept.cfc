component extends="wheels.tests.Test" {

	function setup() {
		super.setup();
		include "setup.cfm";
	}

	function teardown() {
		super.teardown();
		include "teardown.cfm";
	}

	function test_csrf_protection_with_valid_authenticityToken_on_PATCH_request() {
		request.cgi.request_method = "PATCH";
		params = {controller = "csrfProtectedExcept", action = "update", authenticityToken = CsrfGenerateToken()};
		_controller = controller("csrfProtectedExcept", params);

		_controller.processAction("update", params);
		assert('_controller.response() eq "Update ran."');
	}

	function test_csrf_protection_with_no_authenticityToken_on_PATCH_request() {
		request.cgi.request_method = "PATCH";
		params = {controller = "csrfProtectedExcept", action = "update"};
		_controller = controller("csrfProtectedExcept", params);

		try {
			_controller.processAction("update", params);
			fail("Wheels.InvalidAuthenticityToken error did not occur.");
		} catch (any e) {
			type = e.Type;
			assert("type is 'Wheels.InvalidAuthenticityToken'");
		}
	}

	function test_csrf_protection_with_invalid_authenticityToken_on_PATCH_request() {
		request.cgi.request_method = "PATCH";
		params = {controller = "csrfProtectedExcept", action = "update", authenticityToken = "1#CsrfGenerateToken()#"};
		_controller = controller("csrfProtectedExcept", params);

		try {
			_controller.processAction("update", params);
			fail("Wheels.InvalidAuthenticityToken error did not occur.");
		} catch (any e) {
			type = e.Type;
			assert("type is 'Wheels.InvalidAuthenticityToken'");
		}
	}

	function test_csrf_protection_with_valid_x_csrf_token_header_on_ajax_PATCH_request() {
		request.$wheelsHeaders["X-CSRF-TOKEN"] = CsrfGenerateToken();
		request.cgi.request_method = "PATCH";
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		params = {controller = "csrfProtectedExcept", action = "update"};
		_controller = controller("csrfProtectedExcept", params);

		_controller.processAction("update", params);
		assert('_controller.response() eq "Update ran."');
	}

	function test_csrf_protection_with_no_x_csrf_token_header_on_ajax_PATCH_request() {
		request.cgi.request_method = "PATCH";
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		params = {controller = "csrfProtectedExcept", action = "update"};
		_controller = controller("csrfProtectedExcept", params);

		try {
			_controller.processAction("update", params);
			fail("Wheels.InvalidAuthenticityToken error did not occur.");
		} catch (any e) {
			type = e.Type;
			assert("type is 'Wheels.InvalidAuthenticityToken'");
		}
	}

	function test_csrf_protection_with_invalid_x_csrf_token_header_on_ajax_PATCH_request() {
		request.$wheelsHeaders["X-CSRF-TOKEN"] = "1#CsrfGenerateToken()#";
		request.cgi.request_method = "PATCH";
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		params = {controller = "csrfProtectedExcept", action = "update"};
		_controller = controller("csrfProtectedExcept", params);

		try {
			_controller.processAction("update", params);
			fail("Wheels.InvalidAuthenticityToken error did not occur.");
		} catch (any e) {
			type = e.Type;
			assert("type is 'Wheels.InvalidAuthenticityToken'");
		}
	}

	function test_skipped_csrf_protection_on_PATCH_request_with_valid_authenticityToken() {
		request.cgi.request_method = "PATCH";
		params = {controller = "csrfProtectedExcept", action = "show", authenticityToken = CsrfGenerateToken()};
		_controller = controller("csrfProtectedExcept", params);

		_controller.processAction("update", params);
		assert('_controller.response() eq "Show ran."');
	}

	function test_skipped_csrf_protection_on_PATCH_request_with_no_authenticityToken() {
		request.cgi.request_method = "PATCH";
		params = {controller = "csrfProtectedExcept", action = "show"};
		_controller = controller("csrfProtectedExcept", params);

		_controller.processAction("update", params);
		assert('_controller.response() eq "Show ran."');
	}

	function test_skipped_csrf_protection_on_PATCH_request_with_invalid_authenticityToken() {
		request.cgi.request_method = "PATCH";
		params = {controller = "csrfProtectedExcept", action = "show", authenticityToken = "1#CsrfGenerateToken()#"};
		_controller = controller("csrfProtectedExcept", params);

		_controller.processAction("update", params);
		assert('_controller.response() eq "Show ran."');
	}

	function test_skipped_csrf_protection_on_ajax_PATCH_request_with_valid_x_csrf_token_header() {
		request.$wheelsHeaders["X-CSRF-TOKEN"] = CsrfGenerateToken();
		request.cgi.request_method = "PATCH";
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		params = {controller = "csrfProtectedExcept", action = "show"};
		_controller = controller("csrfProtectedExcept", params);

		_controller.processAction("update", params);
		assert('_controller.response() eq "Show ran."');
	}

	function test_skipped_csrf_protection_on_ajax_PATCH_request_with_no_x_csrf_token_header() {
		request.cgi.request_method = "PATCH";
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		params = {controller = "csrfProtectedExcept", action = "show"};
		_controller = controller("csrfProtectedExcept", params);

		_controller.processAction("update", params);
		assert('_controller.response() eq "Show ran."');
	}

	function test_skipped_csrf_protection_on_ajax_PATCH_request_with_invalid_x_csrf_token_header() {
		request.$wheelsHeaders["X-CSRF-TOKEN"] = "1#CsrfGenerateToken()#";
		request.cgi.request_method = "PATCH";
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		params = {controller = "csrfProtectedExcept", action = "show"};
		_controller = controller("csrfProtectedExcept", params);

		_controller.processAction("update", params);
		assert('_controller.response() eq "Show ran."');
	}

}
