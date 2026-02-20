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

	function test_generates_url_pattern_without_name() {
		$mapper()
			.$draw()
			.package("public")
			.root(to = "pages##home")
			.end()
			.end();

		assert("application.wheels.routes[1].pattern is '/.[format]'");
		assert("application.wheels.routes[2].pattern is '/'");
	}

	function test_scopes_controller_to_subfolder() {
		$mapper()
			.$draw()
			.package("public")
			.root(to = "pages##home")
			.end()
			.end();

		assert("application.wheels.routes[1].controller is 'public.pages'");
		assert("application.wheels.routes[2].controller is 'public.pages'");
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
