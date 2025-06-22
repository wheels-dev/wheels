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

	function test_default_wildcard_produces_routes() {
		$mapper()
			.$draw()
			.wildcard()
			.end();

		routesLen = ArrayLen(application.wheels.routes);
		assert("routesLen eq 2");
	}

	function test_default_wildcard_only_allows_get_requests() {
		$mapper()
			.$draw()
			.wildcard()
			.end();

		for (loc.route in application.wheels.routes) {
			assert("loc.route.methods is 'get'");
		}
	}

	function test_default_wildcard_generates_correct_patterns() {
		$mapper()
			.$draw()
			.wildcard()
			.end();

		assert("application.wheels.routes[1].pattern is '/[controller]/[action]'");
		assert("application.wheels.routes[2].pattern is '/[controller]'");
	}

	function test_wildcard_with_methods_produces_routes() {
		$mapper()
			.$draw()
			.wildcard(methods = "get,post")
			.end();

		routesLen = ArrayLen(application.wheels.routes);
		assert("routesLen eq 4");
	}

	function test_wildcard_only_allows_specified_methods() {
		$mapper()
			.$draw()
			.wildcard()
			.end();

		for (loc.route in application.wheels.routes) {
			assert("loc.route.methods is 'get' or loc.route.methods is 'post'");
		}
	}

	function test_wildcard_with_methods_generates_correct_patterns() {
		$mapper()
			.$draw()
			.wildcard(methods = "get,post")
			.end();

		assert("application.wheels.routes[1].pattern is '/[controller]/[action]'");
		assert("application.wheels.routes[2].pattern is '/[controller]'");
		assert("application.wheels.routes[3].pattern is '/[controller]/[action]'");
		assert("application.wheels.routes[4].pattern is '/[controller]'");
	}

	function test_controller_scoped_wildcard_produces_routes() {
		$mapper()
			.$draw()
			.controller("cats")
			.wildcard()
			.end()
			.end();

		routesLen = ArrayLen(application.wheels.routes);
		assert("routesLen eq 2");
	}

	function test_controller_scoped_wildcard_only_allows_get_requests() {
		$mapper()
			.$draw()
			.controller("cats")
			.wildcard()
			.end()
			.end();

		for (loc.route in application.wheels.routes) {
			assert("loc.route.methods is 'get'");
		}
	}

	function test_controller_scoped_wildcard_generates_correct_patterns() {
		$mapper()
			.$draw()
			.controller("cats")
			.wildcard()
			.end()
			.end();

		assert("application.wheels.routes[1].pattern is '/cats/[action]'");
		assert("application.wheels.routes[2].pattern is '/cats'");
	}

	function test_wildcard_with_map_format() {
		$mapper()
			.$draw()
			.controller("cats")
			.wildcard(mapFormat = true)
			.end()
			.end();

		assert("application.wheels.routes[1].pattern is '/cats/[action].[format]'");
		assert("application.wheels.routes[2].pattern is '/cats/[action]'");
		assert("application.wheels.routes[3].pattern is '/cats.[format]'");
		assert("application.wheels.routes[4].pattern is '/cats'");
		routesLen = ArrayLen(application.wheels.routes);
		assert("routesLen eq 4");
	}

	function test_wildcard_with_map_key() {
		$mapper()
			.$draw()
			.controller("cats")
			.wildcard(mapKey = true)
			.end()
			.end();

		assert("application.wheels.routes[1].pattern is '/cats/[action]/[key]'");
		assert("application.wheels.routes[2].pattern is '/cats/[action]'");
		assert("application.wheels.routes[3].pattern is '/cats'");
		routesLen = ArrayLen(application.wheels.routes);
		assert("routesLen eq 3");
	}

}
