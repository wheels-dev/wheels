component extends="wheels.tests.Test" {

	public void function setup() {
		config = {path = "wheels", fileName = "Mapper", method = "$init"};
		_params = {controller = "test", action = "index"};
		_originalRoutes = Duplicate(application.wheels.routes);
	}

	public void function teardown() {
		application.wheels.routes = _originalRoutes;
	}

	public struct function $mapper() {
		local.args = Duplicate(config);
		StructAppend(local.args, arguments, true);
		return $createObjectFromRoot(argumentCollection = local.args);
	}

	public struct function $inspect() {
		return variables;
	}

	public void function $clearRoutes() {
		application.wheels.routes = [];
	}

	// resource

	function test_resource_produces_routes() {
		$clearRoutes();
		mapper = $mapper();
		mapper
			.$draw()
			.resource(name = "pigeon")
			.end();
		routesLen = ArrayLen(application.wheels.routes);
		assert("routesLen eq 14");
	}

	function test_resource_produces_routes_with_list() {
		$clearRoutes();
		mapper = $mapper();
		mapper
			.$draw()
			.resource(name = "pigeon,pudding")
			.end();
		routesLen = ArrayLen(application.wheels.routes);
		assert("routesLen eq 28");
	}

	function test_resource_raises_error_with_list_and_nesting() {
		$clearRoutes();
		mapper = $mapper().$draw();
		e = raised('mapper.resource(name="pigeon,pudding", nested=true).end()');
		assert('e eq "Wheels.InvalidResource"');
	}

	// resources

	function test_resources_produces_routes() {
		$clearRoutes();
		mapper = $mapper();
		mapper
			.$draw()
			.resources(name = "pigeons")
			.end();
		routesLen = ArrayLen(application.wheels.routes);
		assert("routesLen eq 16");
	}

	function test_resources_produces_routes_without_format() {
		$clearRoutes();
		mapper = $mapper();
		mapper
			.$draw()
			.resources(name = "pigeons", mapFormat = false)
			.end();
		routesLen = ArrayLen(application.wheels.routes);
		assert("routesLen eq 8");
	}

	function test_resources_produces_routes_without_format_set_by_mapper() {
		$clearRoutes();
		mapper = $mapper(mapFormat = false);
		mapper
			.$draw()
			.resources(name = "pigeons")
			.end();
		routesLen = ArrayLen(application.wheels.routes);
		assert("routesLen eq 8");
	}

	function test_resources_produces_routes_without_format_set_by_mapper_override() {
		$clearRoutes();
		mapper = $mapper(mapFormat = false);
		mapper
			.$draw()
			.resources(name = "pigeons", mapFormat = true)
			.end();
		routesLen = ArrayLen(application.wheels.routes);
		assert("routesLen eq 16");
	}

	function test_resources_produces_routes_with_list() {
		$clearRoutes();
		mapper = $mapper();
		mapper
			.$draw()
			.resources(name = "pigeons,birds")
			.end();
		routesLen = ArrayLen(application.wheels.routes);
		assert("routesLen eq 32");
	}

	function test_resources_produces_routes_with_list_without_format() {
		$clearRoutes();
		mapper = $mapper();
		mapper
			.$draw()
			.resources(name = "pigeons,birds", mapFormat = false)
			.end();
		routesLen = ArrayLen(application.wheels.routes);
		assert("routesLen eq 16");
	}

	function test_resources_raises_error_with_list_and_nesting() {
		$clearRoutes();
		mapper = $mapper().$draw();
		e = raised('mapper.resources(name="pigeon,birds", nested=true).end()');
		assert('e eq "Wheels.InvalidResource"');
	}

}
