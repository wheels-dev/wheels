component extends="wheels.tests.Test" {

	function setup() {
		config = {path = "wheels", fileName = "Mapper", method = "$init"};

		_params = {controller = "test", action = "index"};
		_originalRoutes = Duplicate(application.wheels.routes);

		$clearRoutes();
	}

	function teardown() {
		application.wheels.routes = _originalRoutes;
	}

	function test_redirect_argument_is_passed_through() {
		$mapper()
			.$draw()
			.get(name = "testredirect1", redirect = "https://www.google.com")
			.post(name = "testredirect2", redirect = "https://www.google.com")
			.put(name = "testredirect3", redirect = "https://www.google.com")
			.patch(name = "testredirect4", redirect = "https://www.google.com")
			.delete(name = "testredirect5", redirect = "https://www.google.com")
			.end();
		assert("structKeyExists(application.wheels.routes[1], 'redirect')");
		assert("structKeyExists(application.wheels.routes[2], 'redirect')");
		assert("structKeyExists(application.wheels.routes[3], 'redirect')");
		assert("structKeyExists(application.wheels.routes[4], 'redirect')");
		assert("structKeyExists(application.wheels.routes[5], 'redirect')");
	}


	private function $clearRoutes() {
		application.wheels.routes = [];
	}

	private struct function $mapper() {
		local.args = Duplicate(config);
		StructAppend(local.args, arguments, true);
		return $createObjectFromRoot(argumentCollection = local.args);
	}

}
