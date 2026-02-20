component extends="wheels.tests.Test" {

	function setup() {
		include "setup.cfm";
	}

	function teardown() {
		include "teardown.cfm";
	}

	function test_isPost_valid() {
		request.cgi.request_method = "post";
		assert("_controller.isPost() eq true");
	}

	function test_isPost_invalid() {
		request.cgi.request_method = "";
		assert("_controller.isPost() eq false");
	}

}
