component extends="wheels.tests.Test" {

	function setup() {
		include "setup.cfm";
	}

	function teardown() {
		include "teardown.cfm";
	}

	function test_isAjax_valid() {
		request.cgi.http_x_requested_with = "XMLHTTPRequest";
		assert("_controller.isAjax() eq true");
	}

	function test_isAjax_invalid() {
		request.cgi.http_x_requested_with = "";
		assert("_controller.isAjax() eq false");
	}

}
