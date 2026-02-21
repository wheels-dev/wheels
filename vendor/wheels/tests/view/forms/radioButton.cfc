component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "ControllerWithModel");
	}

	function test_x_radioButton_valid() {
		_controller.radioButton(
			objectName = "user",
			property = "gender",
			tagValue = "m",
			label = "Male"
		);
	}

}
