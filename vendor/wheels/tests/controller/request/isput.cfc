component extends="wheels.tests.Test" {

	function setup() {
		include "setup.cfm";
	}

	function teardown() {
		include "teardown.cfm";
	}

	function test_isPut_with_head_request() {
		request.cgi.request_method = "put";
		assert("_controller.isPut()");
	}

	function test_isPut_with_get_request() {
		request.cgi.request_method = "get";
		assert("not _controller.isPut()");
	}

}
