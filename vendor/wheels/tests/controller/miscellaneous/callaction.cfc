component extends="wheels.tests.Test" {

	function setup() {
		params = {controller = "test", action = "test"};
		_controller = controller("test", params);
		oldViewPath = application.wheels.viewPath;
		application.wheels.viewPath = "/wheels/tests/_assets/views";
	}

	function teardown() {
		application.wheels.viewPath = oldViewPath;
	}

	function test_setting_variable_for_view() {
		_controller.$callAction(action = "test");
		assert("_controller.response() Contains 'variableForViewContent'");
	}

	function test_implicitly_calling_render_page() {
		_controller.$callAction(action = "test");
		assert("_controller.response() Contains 'view template content'");
	}

}
