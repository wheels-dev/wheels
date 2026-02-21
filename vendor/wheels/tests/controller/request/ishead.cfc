component extends="wheels.tests.Test" {

	function setup() {
		include "setup.cfm";
	}

	function teardown() {
		include "teardown.cfm";
	}

	function test_isHead_with_head_request() {
		request.cgi.request_method = "head";
		assert("_controller.isHead()");
	}

	function test_isHead_with_get_request() {
		request.cgi.request_method = "get";
		assert("not _controller.isHead()");
	}

}
