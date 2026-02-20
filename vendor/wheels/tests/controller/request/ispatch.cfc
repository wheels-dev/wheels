component extends="wheels.tests.Test" {

	function setup() {
		include "setup.cfm";
	}

	function teardown() {
		include "teardown.cfm";
	}

	function test_isPatch_with_head_request() {
		request.cgi.request_method = "patch";
		assert("_controller.isPatch()");
	}

	function test_isPatch_with_get_request() {
		request.cgi.request_method = "get";
		assert("not _controller.isPatch()");
	}

}
