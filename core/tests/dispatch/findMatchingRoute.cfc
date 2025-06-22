component extends="wheels.tests.Test" {

	public void function packageSetup() {
		_originalRoutes = Duplicate(application.wheels.routes);
		$clearRoutes();


		mapper()
			.namespace("admin")
			.resources("users")
			.root(to = "dashboard##index")
			.end()
			.resources("users")
			.resource("profile")
			.root(to = "dashboard##index")
			.end();

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

	function test_find_get_collection_route_that_exists() {
		request.cgi["request_method"] = "GET";
		route = d.$findMatchingRoute(path = "users");
		assert('route.name eq "users" and route.methods eq "GET"');
	}

	function test_find_get_collection_route_that_exists_with_format() {
		request.cgi["request_method"] = "GET";
		route = d.$findMatchingRoute(path = "users.csv");
		assert('route.name eq "users" and route.methods eq "GET"');
	}

	function test_find_post_collection_route_that_exists() {
		request.cgi["request_method"] = "POST";
		route = d.$findMatchingRoute(path = "users");
		assert('route.name eq "users" and route.methods eq "POST"');
	}

	function test_find_post_collection_route_that_exists_with_format() {
		request.cgi["request_method"] = "POST";
		route = d.$findMatchingRoute(path = "users.json");
		assert('route.name eq "users" and route.methods eq "POST"');
	}

	function test_find_get_member_new_route_that_exists() {
		request.cgi["request_method"] = "GET";
		route = d.$findMatchingRoute(path = "users/new");
		assert('route.name eq "newUser" and route.methods eq "GET"');
	}

	function test_find_get_member_new_route_that_exists_with_format() {
		request.cgi["request_method"] = "GET";
		route = d.$findMatchingRoute(path = "users/new.json");
		assert('route.name eq "newUser" and route.methods eq "GET"');
	}

	function test_find_get_member_edit_route_that_exists() {
		request.cgi["request_method"] = "GET";
		route = d.$findMatchingRoute(path = "users/1/edit");
		assert('route.name eq "editUser" and route.methods eq "GET"');
	}

	function test_find_get_member_edit_route_that_exists_with_format() {
		request.cgi["request_method"] = "GET";
		route = d.$findMatchingRoute(path = "users/1/edit.json");
		assert('route.name eq "editUser" and route.methods eq "GET"');
	}

	function test_find_get_member_route_that_exists() {
		request.cgi["request_method"] = "GET";
		route = d.$findMatchingRoute(path = "users/1");
		assert('route.name eq "user" and route.methods eq "GET"');
	}

	function test_find_get_member_route_that_exists_with_format() {
		request.cgi["request_method"] = "GET";
		route = d.$findMatchingRoute(path = "users/1.json");
		assert('route.name eq "user" and route.methods eq "GET"');
	}

	function test_find_put_member_route_that_exists() {
		request.cgi["request_method"] = "POST";
		form._method = "PUT";
		route = d.$findMatchingRoute(path = "users/1");
		assert('route.name eq "user" and route.methods eq "PUT"');
	}

	function test_find_put_member_route_that_exists_with_format() {
		request.cgi["request_method"] = "POST";
		form._method = "PUT";
		route = d.$findMatchingRoute(path = "users/1.json");
		assert('route.name eq "user" and route.methods eq "PUT"');
	}

	function test_find_delete_member_route_that_exists() {
		request.cgi["request_method"] = "POST";
		form._method = "delete";
		route = d.$findMatchingRoute(path = "users/1.json");
		assert('route.name eq "user" and route.methods eq "delete"');
	}

	function test_find_delete_member_route_that_exists_with_format() {
		request.cgi["request_method"] = "POST";
		form._method = "delete";
		route = d.$findMatchingRoute(path = "users/1");
		assert('route.name eq "user" and route.methods eq "delete"');
	}

	// nested route tests

	function test_find_nested_get_collection_route_that_exists() {
		request.cgi["request_method"] = "GET";
		route = d.$findMatchingRoute(path = "admin/users");
		assert('route.name eq "adminUsers" and route.methods eq "GET"');
	}

	function test_find_nested_get_collection_route_that_exists_with_format() {
		request.cgi["request_method"] = "GET";
		route = d.$findMatchingRoute(path = "admin/users.csv");
		assert('route.name eq "adminUsers" and route.methods eq "GET"');
	}

	function test_find_nested_post_collection_route_that_exists() {
		request.cgi["request_method"] = "POST";
		route = d.$findMatchingRoute(path = "admin/users");
		assert('route.name eq "adminUsers" and route.methods eq "POST"');
	}

	function test_find_nested_post_collection_route_that_exists_with_format() {
		request.cgi["request_method"] = "POST";
		route = d.$findMatchingRoute(path = "admin/users.json");
		assert('route.name eq "adminUsers" and route.methods eq "POST"');
	}

	function test_find_nested_get_member_new_route_that_exists() {
		request.cgi["request_method"] = "GET";
		route = d.$findMatchingRoute(path = "admin/users/new");
		assert('route.name eq "newAdminUser" and route.methods eq "GET"');
	}

	function test_find_nested_get_member_new_route_that_exists_with_format() {
		request.cgi["request_method"] = "GET";
		route = d.$findMatchingRoute(path = "admin/users/new.json");
		assert('route.name eq "newAdminUser" and route.methods eq "GET"');
	}

	function test_find_nested_get_member_edit_route_that_exists() {
		request.cgi["request_method"] = "GET";
		route = d.$findMatchingRoute(path = "admin/users/1/edit");
		assert('route.name eq "editAdminUser" and route.methods eq "GET"');
	}

	function test_find_nested_get_member_edit_route_that_exists_with_format() {
		request.cgi["request_method"] = "GET";
		route = d.$findMatchingRoute(path = "admin/users/1/edit.json");
		assert('route.name eq "editAdminUser" and route.methods eq "GET"');
	}

	function test_find_nested_get_member_route_that_exists() {
		request.cgi["request_method"] = "GET";
		route = d.$findMatchingRoute(path = "admin/users/1");
		assert('route.name eq "adminUser" and route.methods eq "GET"');
	}

	function test_find_nested_get_member_route_that_exists_with_format() {
		request.cgi["request_method"] = "GET";
		route = d.$findMatchingRoute(path = "admin/users/1.json");
		assert('route.name eq "adminUser" and route.methods eq "GET"');
	}

	function test_find_nested_put_member_route_that_exists() {
		request.cgi["request_method"] = "POST";
		form._method = "PUT";
		route = d.$findMatchingRoute(path = "admin/users/1");
		assert('route.name eq "adminUser" and route.methods eq "PUT"');
	}

	function test_find_nested_put_member_route_that_exists_with_format() {
		request.cgi["request_method"] = "POST";
		form._method = "PUT";
		route = d.$findMatchingRoute(path = "admin/users/1.json");
		assert('route.name eq "adminUser" and route.methods eq "PUT"');
	}

	function test_find_nested_delete_member_route_that_exists() {
		request.cgi["request_method"] = "POST";
		form._method = "delete";
		route = d.$findMatchingRoute(path = "admin/users/1.json");
		assert('route.name eq "adminUser" and route.methods eq "delete"');
	}

	function test_find_nested_delete_member_route_that_exists_with_format() {
		request.cgi["request_method"] = "POST";
		form._method = "delete";
		route = d.$findMatchingRoute(path = "admin/users/1");
		assert('route.name eq "adminUser" and route.methods eq "delete"');
	}

	function test_head_request_aliases_get() {
		request.cgi["request_method"] = "HEAD";
		route = d.$findMatchingRoute(path = "users");
		assert('route.name eq "Users" and route.methods eq "GET"');
	}

}
