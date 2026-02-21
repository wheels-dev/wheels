component extends="wheels.tests.Test" {

	function setup() {
		include "setup.cfm";
	}

	function teardown() {
		include "teardown.cfm";
	}

	function test_isGet_valid() {
		request.cgi.request_method = "get";
		assert("_controller.isGet() eq true");
	}

	function test_isGet_invalid() {
		request.cgi.request_method = "";
		assert("_controller.isGet() eq false");
	}

}
