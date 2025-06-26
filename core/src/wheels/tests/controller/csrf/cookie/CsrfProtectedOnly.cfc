component extends="wheels.tests.Test" {

	function setup() {
		super.setup();
		include "setup.cfm";
	}

	function teardown() {
		super.teardown();
		include "teardown.cfm";
	}

	function test_csrf_protection_with_valid_authenticityToken_on_post_request() {
		request.cgi.request_method = "POST";
		params = {controller = "csrfProtectedOnly", action = "create", authenticityToken = csrfToken};
		_controller = controller("csrfProtectedOnly", params);

		_controller.processAction("create", params);
		assert('_controller.response() eq "Create ran."');
	}

	function test_csrf_protection_with_no_authenticityToken_on_post_request() {
		request.cgi.request_method = "POST";
		params = {controller = "csrfProtectedOnly", action = "create"};
		_controller = controller("csrfProtectedOnly", params);

		try {
			_controller.processAction("create", params);
			fail("Wheels.InvalidAuthenticityToken error did not occur.");
		} catch (any e) {
			type = e.Type;
			assert("type is 'Wheels.InvalidAuthenticityToken'");
		}
	}

	function test_csrf_protection_with_invalid_authenticityToken_on_post_request() {
		request.cgi.request_method = "POST";
		params = {controller = "csrfProtectedOnly", action = "create", authenticityToken = "#csrfToken#1"};
		_controller = controller("csrfProtectedOnly", params);

		try {
			_controller.processAction("create", params);
			fail("Wheels.InvalidAuthenticityToken error did not occur.");
		} catch (any e) {
			type = e.Type;
			assert("type is 'Wheels.InvalidAuthenticityToken'");
		}
	}

	function test_csrf_protection_with_valid_x_csrf_token_header_on_ajax_post_request() {
		request.$wheelsHeaders["X-CSRF-TOKEN"] = csrfToken;
		request.cgi.request_method = "POST";
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		params = {controller = "csrfProtectedOnly", action = "create", authenticityToken = csrfToken};
		_controller = controller("csrfProtectedOnly", params);

		_controller.processAction("create", params);
		assert('_controller.response() eq "Create ran."');
	}

	function test_csrf_protection_with_no_x_csrf_token_header_on_ajax_post_request() {
		request.cgi.request_method = "POST";
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		params = {controller = "csrfProtectedOnly", action = "create"};
		_controller = controller("csrfProtectedOnly", params);

		try {
			_controller.processAction("create", params);
			fail("Wheels.InvalidAuthenticityToken error did not occur.");
		} catch (any e) {
			type = e.Type;
			assert("type is 'Wheels.InvalidAuthenticityToken'");
		}
	}

	function test_csrf_protection_with_invalid_x_csrf_token_header_on_ajax_post_request() {
		request.$wheelsHeaders["X-CSRF-TOKEN"] = "#csrfToken#1";
		request.cgi.request_method = "POST";
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		params = {controller = "csrfProtectedOnly", action = "create", authenticityToken = "#csrfToken#1"};
		_controller = controller("csrfProtectedOnly", params);

		try {
			_controller.processAction("create", params);
			fail("Wheels.InvalidAuthenticityToken error did not occur.");
		} catch (any e) {
			type = e.Type;
			assert("type is 'Wheels.InvalidAuthenticityToken'");
		}
	}

	function test_skipped_csrf_protection_on_post_request_with_valid_authenticityToken() {
		request.cgi.request_method = "POST";
		params = {controller = "csrfProtectedOnly", action = "index", authenticityToken = csrfToken};
		_controller = controller("csrfProtectedOnly", params);

		_controller.processAction("create", params);
		assert('_controller.response() eq "Index ran."');
	}

	function test_skipped_csrf_protection_on_post_request_with_no_authenticityToken() {
		request.cgi.request_method = "POST";
		params = {controller = "csrfProtectedOnly", action = "index"};
		_controller = controller("csrfProtectedOnly", params);

		_controller.processAction("create", params);
		assert('_controller.response() eq "Index ran."');
	}

	function test_skipped_csrf_protection_on_post_request_with_invalid_authenticityToken() {
		request.cgi.request_method = "POST";
		params = {controller = "csrfProtectedOnly", action = "index", authenticityToken = "#csrfToken#1"};
		_controller = controller("csrfProtectedOnly", params);

		_controller.processAction("create", params);
		assert('_controller.response() eq "Index ran."');
	}

	function test_skipped_csrf_protection_on_ajax_post_request_with_valid_x_csrf_token_header() {
		request.$wheelsHeaders["X-CSRF-TOKEN"] = csrfToken;
		request.cgi.request_method = "POST";
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		params = {controller = "csrfProtectedOnly", action = "index"};
		_controller = controller("csrfProtectedOnly", params);

		_controller.processAction("create", params);
		assert('_controller.response() eq "Index ran."');
	}

	function test_skipped_csrf_protection_on_ajax_post_request_with_no_x_csrf_token_header() {
		request.cgi.request_method = "POST";
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		params = {controller = "csrfProtectedOnly", action = "index"};
		_controller = controller("csrfProtectedOnly", params);

		_controller.processAction("create", params);
		assert('_controller.response() eq "Index ran."');
	}

	function test_skipped_csrf_protection_on_ajax_post_request_with_invalid_x_csrf_token_header() {
		request.$wheelsHeaders["X-CSRF-TOKEN"] = "#csrfToken#1";
		request.cgi.request_method = "POST";
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		params = {controller = "csrfProtectedOnly", action = "index", authenticityToken = "#csrfToken#1"};
		_controller = controller("csrfProtectedOnly", params);

		_controller.processAction("create", params);
		assert('_controller.response() eq "Index ran."');
	}

}
