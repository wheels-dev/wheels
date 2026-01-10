component extends="wheels.tests.Test" {

	public void function setup() {
		config = {path = "wheels", fileName = "Mapper", method = "$init"};

		_params = {controller = "test", action = "index"};
		_originalRoutes = Duplicate(application.wheels.routes);

		$clearRoutes();
	}

	public void function teardown() {
		application.wheels.routes = _originalRoutes;
	}

	public struct function $mapper() {
		local.args = Duplicate(config);
		StructAppend(local.args, arguments, true);
		return $createObjectFromRoot(argumentCollection = local.args);
	}

	public void function $clearRoutes() {
		application.wheels.routes = [];
	}

	function test_top_level_root_excludes_format_but_keeps_it_on_sub_level() {
		$mapper()
			.$draw()
			.namespace("test")
			.root(to = "test##test")
			.end()
			.root(to = "test##test")
			.end();
		assert("application.wheels.routes[1].pattern is '/test.[format]'");
		assert("application.wheels.routes[2].pattern is '/test'");
		assert("application.wheels.routes[3].pattern is '/'");
	}

	function test_overriding_default_for_map_format() {
		$mapper()
			.$draw()
			.namespace("test")
			.root(to = "test##test", mapFormat = false)
			.end()
			.root(to = "test##test", mapFormat = true)
			.end();
		assert("application.wheels.routes[1].pattern is '/test'");
		assert("application.wheels.routes[2].pattern is '/.[format]'");
		assert("application.wheels.routes[3].pattern is '/'");
	}

}
