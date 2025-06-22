component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "ControllerWithModel");
	}

	function test_x_hiddenField_valid() {
		_controller.hiddenField(objectName = "user", property = "firstname");
	}

}
