component extends="wheels.tests.Test" {

	function setup() {
		params = {controller = "dummy", action = "dummy"};
		_controller = controller("dummy", params);
	}

	function test_provides_sets_controller_class_data() {
		formats = "json,xml,csv";
		_controller.provides(formats = formats);
		assert('_controller.$getControllerClassData().formats.default eq "html,#formats#"');
	}

	function test_onlyProvides_sets_controller_class_data() {
		formats = "html";
		_controller.onlyProvides(formats = "html");
		assert('_controller.$getControllerClassData().formats.actions.dummy eq formats');
	}

}
