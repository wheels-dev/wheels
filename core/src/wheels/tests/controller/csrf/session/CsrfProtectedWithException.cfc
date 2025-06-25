component extends="wheels.tests.Test" {

	function setup() {
		super.setup();
		include "setup.cfm";
	}

	function teardown() {
		super.teardown();
		include "teardown.cfm";
	}

	function test_csrf_protection_skipped_on_get_request() {
		params = {controller = "csrfProtectedWithException", action = "index"};
		_controller = controller("csrfProtectedWithException", params);

		_controller.processAction("index", params);
		assert('_controller.response() eq "Index ran."');
	}

	function test_csrf_protection_skipped_on_get_ajax_request() {
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		params = {controller = "csrfProtectedWithException", action = "index"};
		_controller = controller("csrfProtectedWithException", params);

		_controller.processAction("index", params);
		assert('_controller.response() eq "Index ran."');
	}

	function test_csrf_protection_skipped_on_options_request() {
		request.cgi.request_method = "OPTIONS";
		params = {controller = "csrfProtectedWithException", action = "index"};
		_controller = controller("csrfProtectedWithException", params);

		_controller.processAction("index", params);
		assert('_controller.response() eq "Index ran."');
	}

	function test_csrf_protection_skipped_on_options_ajax_request() {
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		request.cgi.request_method = "OPTIONS";
		params = {controller = "csrfProtectedWithException", action = "index"};
		_controller = controller("csrfProtectedWithException", params);

		_controller.processAction("index", params);
		assert('_controller.response() eq "Index ran."');
	}

	function test_csrf_protection_skipped_on_head_request() {
		request.cgi.request_method = "HEAD";
		params = {controller = "csrfProtectedWithException", action = "index"};
		_controller = controller("csrfProtectedWithException", params);

		_controller.processAction("index", params);
		assert('_controller.response() eq "Index ran."');
	}

	function test_csrf_protection_skipped_on_head_ajax_request() {
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		request.cgi.request_method = "HEAD";
		params = {controller = "csrfProtectedWithException", action = "index"};
		_controller = controller("csrfProtectedWithException", params);

		_controller.processAction("index", params);
		assert('_controller.response() eq "Index ran."');
	}

	function test_csrf_protection_with_valid_authenticityToken_on_post_request() {
		request.cgi.request_method = "POST";
		params = {controller = "csrfProtectedWithException", action = "create", authenticityToken = CsrfGenerateToken()};
		_controller = controller("csrfProtectedWithException", params);

		_controller.processAction("create", params);
		assert('_controller.response() eq "Create ran."');
	}

	function test_csrf_protection_with_no_authenticityToken_on_post_request() {
		request.cgi.request_method = "POST";
		params = {controller = "csrfProtectedWithException", action = "create"};
		_controller = controller("csrfProtectedWithException", params);

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
		params = {
			controller = "csrfProtectedWithException",
			action = "create",
			authenticityToken = "1#CsrfGenerateToken()#"
		};
		_controller = controller("csrfProtectedWithException", params);

		try {
			_controller.processAction("create", params);
			fail("Wheels.InvalidAuthenticityToken error did not occur.");
		} catch (any e) {
			type = e.Type;
			assert("type is 'Wheels.InvalidAuthenticityToken'");
		}
	}

	function test_csrf_protection_with_valid_authenticityToken_on_patch_request() {
		request.cgi.request_method = "PATCH";
		params = {controller = "csrfProtectedWithException", action = "update", authenticityToken = CsrfGenerateToken()};
		_controller = controller("csrfProtectedWithException", params);

		_controller.processAction("update", params);
		assert('_controller.response() eq "Update ran."');
	}

	function test_csrf_protection_with_no_authenticityToken_on_patch_request() {
		request.cgi.request_method = "PATCH";
		params = {controller = "csrfProtectedWithException", action = "update"};
		_controller = controller("csrfProtectedWithException", params);

		try {
			_controller.processAction("update", params);
			fail("Wheels.InvalidAuthenticityToken error did not occur.");
		} catch (any e) {
			type = e.Type;
			assert("type is 'Wheels.InvalidAuthenticityToken'");
		}
	}

	function test_csrf_protection_with_invalid_authenticityToken_on_patch_request() {
		request.cgi.request_method = "PATCH";
		params = {
			controller = "csrfProtectedWithException",
			action = "update",
			authenticityToken = "1#CsrfGenerateToken()#"
		};
		_controller = controller("csrfProtectedWithException", params);

		try {
			_controller.processAction("update", params);
			fail("Wheels.InvalidAuthenticityToken error did not occur.");
		} catch (any e) {
			type = e.Type;
			assert("type is 'Wheels.InvalidAuthenticityToken'");
		}
	}

	function test_csrf_protection_with_valid_authenticityToken_on_delete_request() {
		request.cgi.request_method = "DELETE";
		params = {controller = "csrfProtectedWithException", action = "delete", authenticityToken = CsrfGenerateToken()};
		_controller = controller("csrfProtectedWithException", params);

		_controller.processAction("delete", params);
		assert('_controller.response() eq "Delete ran."');
	}

	function test_csrf_protection_with_no_authenticityToken_on_delete_request() {
		request.cgi.request_method = "DELETE";
		params = {controller = "csrfProtectedWithException", action = "delete"};
		_controller = controller("csrfProtectedWithException", params);

		try {
			_controller.processAction("delete", params);
			fail("Wheels.InvalidAuthenticityToken error did not occur.");
		} catch (any e) {
			type = e.Type;
			assert("type is 'Wheels.InvalidAuthenticityToken'");
		}
	}

	function test_csrf_protection_with_invalid_authenticityToken_on_delete_request() {
		request.cgi.request_method = "DELETE";
		params = {
			controller = "csrfProtectedWithException",
			action = "delete",
			authenticityToken = "1#CsrfGenerateToken()#"
		};
		_controller = controller("csrfProtectedWithException", params);

		try {
			_controller.processAction("delete", params);
			fail("Wheels.InvalidAuthenticityToken error did not occur.");
		} catch (any e) {
			type = e.Type;
			assert("type is 'Wheels.InvalidAuthenticityToken'");
		}
	}

	function test_csrf_protection_with_valid_x_csrf_token_header_on_ajax_post_request() {
		request.$wheelsHeaders["X-CSRF-TOKEN"] = CsrfGenerateToken();
		request.cgi.request_method = "POST";
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		params = {controller = "csrfProtectedWithException", action = "create"};
		_controller = controller("csrfProtectedWithException", params);

		_controller.processAction("create", params);
		assert('_controller.response() eq "Create ran."');
	}

	function test_csrf_protection_with_no_x_csrf_token_header_on_ajax_post_request() {
		request.cgi.request_method = "POST";
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		params = {controller = "csrfProtectedWithException", action = "create"};
		_controller = controller("csrfProtectedWithException", params);

		try {
			_controller.processAction("create", params);
			fail("Wheels.InvalidAuthenticityToken error did not occur.");
		} catch (any e) {
			type = e.Type;
			assert("type is 'Wheels.InvalidAuthenticityToken'");
		}
	}

	function test_csrf_protection_with_invalid_x_csrf_token_header_on_ajax_post_request() {
		request.$wheelsHeaders["X-CSRF-TOKEN"] = "1#CsrfGenerateToken()#";
		request.cgi.request_method = "POST";
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		params = {controller = "csrfProtectedWithException", action = "create"};
		_controller = controller("csrfProtectedWithException", params);

		try {
			_controller.processAction("create", params);
			fail("Wheels.InvalidAuthenticityToken error did not occur.");
		} catch (any e) {
			type = e.Type;
			assert("type is 'Wheels.InvalidAuthenticityToken'");
		}
	}

	function test_csrf_protection_with_valid_x_csrf_token_header_on_ajax_patch_request() {
		request.$wheelsHeaders["X-CSRF-TOKEN"] = CsrfGenerateToken();
		request.cgi.request_method = "PATCH";
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		params = {controller = "csrfProtectedWithException", action = "update"};
		_controller = controller("csrfProtectedWithException", params);

		_controller.processAction("patch", params);
		assert('_controller.response() eq "Update ran."');
	}

	function test_csrf_protection_with_no_x_csrf_token_header_on_ajax_patch_request() {
		request.cgi.request_method = "PATCH";
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		params = {controller = "csrfProtectedWithException", action = "update"};
		_controller = controller("csrfProtectedWithException", params);

		try {
			_controller.processAction("patch", params);
			fail("Wheels.InvalidAuthenticityToken error did not occur.");
		} catch (any e) {
			type = e.Type;
			assert("type is 'Wheels.InvalidAuthenticityToken'");
		}
	}

	function test_csrf_protection_with_invalid_x_csrf_token_header_on_ajax_patch_request() {
		request.$wheelsHeaders["X-CSRF-TOKEN"] = "1#CsrfGenerateToken()#";
		request.cgi.request_method = "PATCH";
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		params = {controller = "csrfProtectedWithException", action = "update"};
		_controller = controller("csrfProtectedWithException", params);

		try {
			_controller.processAction("patch", params);
			fail("Wheels.InvalidAuthenticityToken error did not occur.");
		} catch (any e) {
			type = e.Type;
			assert("type is 'Wheels.InvalidAuthenticityToken'");
		}
	}

	function test_csrf_protection_with_valid_x_csrf_token_header_on_ajax_delete_request() {
		request.$wheelsHeaders["X-CSRF-TOKEN"] = CsrfGenerateToken();
		request.cgi.request_method = "DELETE";
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		params = {controller = "csrfProtectedWithException", action = "delete"};
		_controller = controller("csrfProtectedWithException", params);

		_controller.processAction("patch", params);
		assert('_controller.response() eq "Delete ran."');
	}

	function test_csrf_protection_with_no_x_csrf_token_header_on_ajax_delete_request() {
		request.cgi.request_method = "DELETE";
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		params = {controller = "csrfProtectedWithException", action = "delete"};
		_controller = controller("csrfProtectedWithException", params);

		try {
			_controller.processAction("patch", params);
			fail("Wheels.InvalidAuthenticityToken error did not occur.");
		} catch (any e) {
			type = e.Type;
			assert("type is 'Wheels.InvalidAuthenticityToken'");
		}
	}

	function test_csrf_protection_with_invalid_x_csrf_token_header_on_ajax_delete_request() {
		request.$wheelsHeaders["X-CSRF-TOKEN"] = "1#CsrfGenerateToken()#";
		request.cgi.request_method = "DELETE";
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		params = {controller = "csrfProtectedWithException", action = "delete"};
		_controller = controller("csrfProtectedWithException", params);

		try {
			_controller.processAction("patch", params);
			fail("Wheels.InvalidAuthenticityToken error did not occur.");
		} catch (any e) {
			type = e.Type;
			assert("type is 'Wheels.InvalidAuthenticityToken'");
		}
	}

}
