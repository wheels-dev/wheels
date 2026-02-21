component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "ControllerWithModel");
	}

	function test_x_textArea_valid() {
		_controller.textArea(objectName = "user", property = "firstname");
	}

}
