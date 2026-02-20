component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "ControllerWithModel");
	}

	function test_x_fileField_valid() {
		_controller.fileField(objectName = "user", property = "firstname");
	}

}
