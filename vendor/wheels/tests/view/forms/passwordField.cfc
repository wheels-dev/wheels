component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "ControllerWithModel");
	}

	function test_x_passwordField_valid() {
		_controller.passwordField(objectName = "User", property = "password");
	}

}
