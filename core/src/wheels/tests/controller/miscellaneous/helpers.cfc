component extends="wheels.tests.Test" {

	function setup() {
		if (StructKeyExists(request, "test")) {
			StructDelete(request, "test");
		}
		oldViewPath = application.wheels.viewPath;
		application.wheels.viewPath = "/wheels/tests/_assets/views";
		application.wheels.existingHelperFiles = "test";
		params = {controller = "test", action = "helperCaller"};
		_controller = controller("test", params);
	}

	function test_inclusion_of_global_helper_file() {
		_controller.renderView();
		assert("StructKeyExists(request.test, 'globalHelperFunctionWasCalled')");
	}

	function test_inclusion_of_controller_helper_file() {
		_controller.renderView();
		assert("StructKeyExists(request.test, 'controllerHelperFunctionWasCalled')");
	}

	function teardown() {
		application.wheels.viewPath = oldViewPath;
		application.wheels.existingHelperFiles = "";
	}

}
