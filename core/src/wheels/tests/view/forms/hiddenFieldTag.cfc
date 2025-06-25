component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
	}

	function test_x_hiddenFieldTag_valid() {
		_controller.hiddenFieldTag(name = "userId", value = "tony");
	}

}
