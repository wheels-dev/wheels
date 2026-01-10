component extends="wheels.tests.Test" {

	public void function packageSetup() {
		_originalRoutes = Duplicate(application.wheels.routes);
		nounPlurals = [
			"people",
			"dogs",
			"cats",
			"pigs",
			"admins",
			"pages",
			"elements",
			"charts",
			"tabs",
			"categories",
			"cows",
			"services",
			"products",
			"pictures",
			"images",
			"routes",
			"cars",
			"vehicles",
			"bikes",
			"buses",
			"cups",
			"words",
			"cells",
			"phones",
			"speakers",
			"sneakers",
			"lions",
			"tigers",
			"elephants",
			"deers",
			"pandas",
			"places",
			"things",
			"mugs",
			"plants",
			"stars",
			"cards",
			"credits",
			"coins",
			"monitors",
			"books",
			"coats",
			"shirts",
			"jackets",
			"pants",
			"miners",
			"hangers",
			"plates",
			"spoons",
			"forks",
			"knives",
			"users"
		];

		$clearRoutes();


		dr = mapper().root(to = "dashboard##index").namespace("admin");
		for (local.item in nounPlurals) {
			dr.resources(name = local.item, nested = true)
				.resources(name = "comments", shallow = true)
				.resources(name = "likes", shallow = true)
				.end();
		}
		dr.root(to = "dashboard##index").end();
		for (local.item in nounPlurals) {
			dr.resources(name = local.item, nested = true)
				.resources(name = "comments", shallow = true)
				.resources(name = "likes", shallow = true)
				.end();
		}
		dr.resource("profile").end();

		d = $createObjectFromRoot(path = "wheels", fileName = "Dispatch", method = "$init");
	}

	public void function packageTeardown() {
		application.wheels.routes = _originalRoutes;
	}

	public void function $clearRoutes() {
		application.wheels.routes = [];
	}

	function setup() {
		_originalForm = Duplicate(form);
		_originalUrl = Duplicate(url);
		StructClear(form);
		StructClear(url);
		_originalCgiMethod = request.cgi.request_method;
	}

	function teardown() {
		StructClear(form);
		StructClear(url);
		StructAppend(form, _originalForm, false);
		StructAppend(url, _originalUrl, false);
		request.cgi["request_method"] = _originalCgiMethod;
	}

	function test_error_raised_when_route_not_found() {
		e = raised('d.$findMatchingRoute(path="scouts")');
		assert('e eq "Wheels.RouteNotFound"');
	}

	function test_find_nested_get_collection_route_that_exists() {
		request.cgi["request_method"] = "GET";
		route = d.$findMatchingRoute(path = "admin/users");
		assert('route.name eq "adminUsers" and route.methods eq "GET"');
	}

}
