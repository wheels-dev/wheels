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

	// match

	function test_match_with_basic_arguments() {
		$clearRoutes();
		mapper = $mapper();
		mapper
			.$draw()
			.$match(
				name = "signIn",
				method = "get",
				controller = "sessions",
				action = "new"
			)
			.end();
		routesLen = ArrayLen(application.wheels.routes);
		assert("routesLen eq 1");
		route = application.wheels.routes[1];
		assert('route.controller eq "sessions" and route.action eq "new"');
	}

	function test_match_with_to_argument() {
		$clearRoutes();
		mapper = $mapper();
		mapper
			.$draw()
			.$match(name = "signIn", method = "get", to = "sessions##new")
			.end();
		routesLen = ArrayLen(application.wheels.routes);
		assert("routesLen eq 1");
		route = application.wheels.routes[1];
		assert('route.controller eq "sessions" and route.action eq "new"');
	}

	function test_match_without_name() {
		$clearRoutes();
		mapper = $mapper();
		mapper
			.$draw()
			.$match(pattern = "/sign-in", method = "get", to = "sessions##new")
			.end();
		routesLen = ArrayLen(application.wheels.routes);
		assert("routesLen eq 1");
		route = application.wheels.routes[1];
		nameExists = StructKeyExists(route, "name");
		assert('not nameExists and route.controller eq "sessions" and route.action eq "new"');
	}

	function test_match_raises_error_without_name_or_pattern() {
		$clearRoutes();
		mapper = $mapper().$draw();
		e = raised('mapper.$match(method="get", controller="sessions", action="new")');
		assert('e eq "Wheels.MapperArgumentMissing"');
	}

	function test_match_raises_error_with_invalid_route() {
		$clearRoutes();
		mapper = $mapper().$draw();
		e = raised('mapper.$match(pattern="[controller](/[action])(/[key])")');
		assert('e eq "Wheels.InvalidRoute"');
	}

	function test_match_with_basic_arguments_and_controller_scoped() {
		$clearRoutes();
		mapper = $mapper();
		mapper
			.$draw()
			.controller("sessions")
			.$match(name = "signIn", method = "get", action = "new")
			.end()
			.end();
		routesLen = ArrayLen(application.wheels.routes);
		assert("routesLen eq 1");
		route = application.wheels.routes[1];
		assert('route.controller eq "sessions" and route.action eq "new"');
	}

	function test_match_with_basic_arguments_and_package_scoped() {
		$clearRoutes();
		mapper = $mapper();
		mapper
			.$draw()
			.namespace("admin")
			.$match(
				name = "signIn",
				method = "get",
				action = "new",
				controller = "sessions"
			)
			.end()
			.end();
		routesLen = ArrayLen(application.wheels.routes);
		assert("routesLen eq 1");
		route = application.wheels.routes[1];
		assert('route.controller eq "admin.Sessions" and route.action eq "new"');
	}

	function test_match_with_package_scope_and_controller_scope() {
		$clearRoutes();
		mapper = $mapper();
		mapper
			.$draw()
			.namespace("admin")
			.controller("sessions")
			.$match(name = "signIn", method = "get", action = "new")
			.end()
			.end()
			.end();
		routesLen = ArrayLen(application.wheels.routes);
		assert("routesLen eq 1");
		route = application.wheels.routes[1];
		assert('route.controller eq "admin.Sessions" and route.action eq "new"');
	}

	function test_match_after_disabling_methods() {
		$clearRoutes();
		mapper = $mapper();
		mapper
			.$draw(restful = false, methods = false)
			.$match(pattern = "/sign-in", method = "get", to = "sessions##new")
			.end();
		routesLen = ArrayLen(application.wheels.routes);
		assert("routesLen eq 1");
		route = application.wheels.routes[1];
		methodExists = StructKeyExists(route, "method");
		assert('methodExists eq false and route.controller eq "sessions" and route.action eq "new"');
	}

	function test_match_with_single_optional_pattern_segment() {
		$clearRoutes();
		mapper = $mapper();
		mapper
			.$draw()
			.$match(pattern = "/sign-in(.[format])", method = "get", to = "sessions##new")
			.end();
		routesLen = ArrayLen(application.wheels.routes);
		assert("routesLen eq 2");
	}

	function test_match_with_multiple_optional_pattern_segment() {
		$clearRoutes();
		mapper = $mapper();
		mapper
			.$draw()
			.$match(pattern = "/[controller](/[action](/[key](.[format])))", action = "index", method = "get")
			.end();
		routesLen = ArrayLen(application.wheels.routes);
		assert("routesLen eq 4");
	}

	function test_match_with_globing() {
		$clearRoutes();
		mapper = $mapper();
		mapper
			.$draw()
			.$match(name = "profile", pattern = "profiles/*[userseo]/[userid]", to = "profile##show")
			.end();
		routesLen = ArrayLen(application.wheels.routes);
		assert("routesLen eq 1");
		route = application.wheels.routes[1];
		assert('REFindNoCase(route.regex, "profiles/this/is/some/seo/text/id123")');
	}

	function test_match_with_multiple_globs() {
		$clearRoutes();
		mapper = $mapper();
		mapper
			.$draw()
			.$match(name = "profile", pattern = "*[before]/foo/*[after]", to = "profile##show")
			.end();
		routesLen = ArrayLen(application.wheels.routes);
		assert("routesLen eq 1");
		route = application.wheels.routes[1];
		assert('REFindNoCase(route.regex, "this/is/before/foo/this/is/after")');
	}

}
