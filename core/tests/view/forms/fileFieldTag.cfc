component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
	}

	function test_x_fileFieldTag_valid() {
		_controller.fileFieldTag(name = "photo");
	}

}
