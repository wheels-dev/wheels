component extends="wheels.tests.Test" {

	function setup() {
		StructDelete(request, "filterTestTypes");
	}

	function test_process_request() {
		local.params = {action = "show", controller = "csrfProtectedExcept"};
		result = processRequest(local.params);
		expected = "Show ran";
		assert("Find(expected, result)");
	}

	// this is not so easy to test...
	/**
	function test_process_request_using_route() {
		local.params = {route = "wheelsInfo"};
		actual = processRequest(params = local.params, returnAs = "struct");
		assert("actual.controller eq 'wheels'");
		assert("actual.action eq 'wheels'");
	}
	*/

	function test_process_request_return_as_struct() {
		local.params = {action = "show", controller = "csrfProtectedExcept"};
		result = processRequest(params = local.params, returnAs = "struct").status;
		expected = 200;
		assert("Compare(expected, result) eq 0");
	}

	function test_process_request_as_get() {
		local.params = {action = "actionGet", controller = "verifies"};
		result = processRequest(method = "get", params = local.params);
		expected = "actionGet";
		assert("Find(expected, result)");
	}

	function test_process_request_as_post() {
		local.params = {action = "actionPost", controller = "verifies"};
		result = processRequest(method = "post", params = local.params);
		expected = "actionPost";
		assert("Find(expected, result)");
	}

	function test_processRequest_executes_filters() {
		local.params = {controller = "Filtering", action = "noView"};
		response = processRequest(params = local.params);
		actual = ArrayLen(request.filterTestTypes);
		expected = 2;
		assert("actual IS expected");
	}

	function test_processRequest_skips_all_filters() {
		local.params = {controller = "Filtering", action = "noView"};
		response = processRequest(params = local.params, includeFilters = false);
		actual = StructKeyExists(request, "filterTestTypes");
		expected = false;
		assert("actual IS expected", "request.filterTestTypes");
	}

	function test_processRequest_only_runs_before_filters() {
		local.params = {controller = "Filtering", action = "noView"};
		response = processRequest(params = local.params, includeFilters = "before");
		actual = request.filterTestTypes;
		expected = "before";
		assert("ArrayLen(actual) IS 1");
		assert("actual[1] IS expected", "request.filterTestTypes");
	}

	function test_processRequest_only_runs_after_filters() {
		local.params = {controller = "Filtering", action = "noView"};
		response = processRequest(params = local.params, includeFilters = "after");
		actual = request.filterTestTypes;
		expected = "after";
		assert("ArrayLen(actual) IS 1");
		assert("actual[1] IS expected", "request.filterTestTypes");
	}

}
