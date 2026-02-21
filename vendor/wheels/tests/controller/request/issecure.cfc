component extends="wheels.tests.Test" {

	function setup() {
		include "setup.cfm";
	}

	function teardown() {
		include "teardown.cfm";
	}

	function test_isSecure_valid() {
		request.cgi.server_port_secure = "yes";
		assert("_controller.isSecure() eq true");
	}

	function test_isSecure_invalid() {
		request.cgi.server_port_secure = "";
		assert("_controller.isSecure() eq false");
		request.cgi.server_port_secure = "no";
		assert("_controller.isSecure() eq false");
	}

}
