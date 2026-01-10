component extends="wheels.tests.Test" {

	function setup() {
		dispatch = CreateObject("component", "wheels.Dispatch");
		SavedRoutes = Duplicate(application.wheels.routes);
		application.wheels.routes = [];
	}

	function teardown() {
		application.wheels.routes = SavedRoutes;
	}

	function test_empty_route() {
		mapper().root(to = "pages##index").end();
		r = dispatch.$findMatchingRoute(path = "", format = "");
		assert('r.controller eq "pages"');
		assert('r.action eq "index"');
	}

	function test_controller_only() {
		mapper().$match(pattern = "pages", to = "pages##index").end();
		r = dispatch.$findMatchingRoute(path = "pages", format = "");
		assert('r.controller eq "pages"');
		assert('r.action eq "index"');
	}

	function test_controller_and_action_required() {
		mapper().$match(pattern = "pages/blah", to = "pages##index").end();
		r = raised('dispatch.$findMatchingRoute(path="/pages", format="")');
		assert('r eq "Wheels.RouteNotFound"');
		r = dispatch.$findMatchingRoute(path = "pages/blah", format = "");
		assert('r.controller eq "pages"');
		assert('r.action eq "index"');
	}

	function test_extra_variables_passed() {
		mapper().$match(pattern = "pages/blah/[firstname]/[lastname]", to = "pages##index").end();
		r = dispatch.$findMatchingRoute(path = "pages/blah/tony/petruzzi", format = "");
		assert('r.controller eq "pages"');
		assert('r.action eq "index"');
		assert('r.foundvariables eq "firstname,lastname"');
	}

	function test_wildcard_route() {
		mapper().$match(pattern = "*", to = "pages##index").end();
		r = dispatch.$findMatchingRoute(path = "thisismyroute/therearemanylikeit/butthisoneismine", format = "");
		assert('r.controller eq "pages"');
		assert('r.action eq "index"');
	}

}
