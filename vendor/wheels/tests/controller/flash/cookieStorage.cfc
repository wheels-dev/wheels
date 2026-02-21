component extends="wheels.tests.Test" {

	function setup() {
		include "setup.cfm";
	}

	function teardown() {
		include "teardown.cfm";
	}

	function test_cookie_storage_should_be_enabled() {
		_controller.$setFlashStorage("cookie");
		assert('_controller.$getFlashStorage() eq "cookie"');
		_controller.$setFlashStorage("session");
		assert('_controller.$getFlashStorage() eq "session"');
	}

}
