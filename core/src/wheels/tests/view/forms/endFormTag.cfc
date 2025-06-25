component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
	}

	function test_x_endFormTag_valid() {
		_controller.endFormTag();
	}

}
