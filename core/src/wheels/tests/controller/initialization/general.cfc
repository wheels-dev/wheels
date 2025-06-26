component extends="wheels.tests.Test" {

	function setup() {
		_originalViewPath = get("viewPath");
		application.wheels.viewPath = "/wheels/tests/_assets/views";
	}

	function teardown() {
		application.wheels.viewPath = _originalViewPath;
		StructDelete(variables, "c", false);
	}

	function test_creating_controller_when_file_exists() {
		c = controller(name = "test", params = {controller = "Test", action = "test"});
		assert('isObject(c)');
		name = c.$getControllerClassData().name;
		assert('name eq "Test"');
	}

	function test_initializing_with_nested_controller() {
		c = controller(name = "admin.Admin", params = {controller = "admin.Admin", action = "test"});
		assert('isObject(c)');
		name = c.$getControllerClassData().name;
		assert('name eq "admin.Admin"');
	}

	function test_creating_controller_when_no_file_exists() {
		c = controller(name = "Admin", params = {controller = "Admin", action = "test"});
		assert('isObject(c)');
		name = c.$getControllerClassData().name;
		assert('name eq "Admin"');
	}

	function test_creating_controller_when_no_nested_file_exists() {
		c = controller(name = "admin.nothing.Admin", params = {controller = "admin.nothing.Admin", action = "test"});
		assert('isObject(c)');
		name = c.$getControllerClassData().name;
		assert('name eq "admin.nothing.Admin"');
	}

}
