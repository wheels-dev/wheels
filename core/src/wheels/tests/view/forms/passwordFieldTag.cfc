component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
	}

	function test_x_passwordFieldTag_valid() {
		_controller.passwordFieldTag(name = "password");
	}

}
