component extends="wheels.tests.Test" {

	function setup() {
		$savedenv = Duplicate(request.cgi);
	}

	function teardown() {
		request.cgi = $savedenv;
	}

	function test_valid() {
		request.cgi.request_method = "get";
		params = {controller = "verifies", action = "actionGet"};
		_controller = controller("verifies", params);
		_controller.processAction("actionGet", params);
		assert('_controller.response() eq "actionGet"');
	}

	function test_invalid_aborted() {
		request.cgi.request_method = "post";
		params = {controller = "verifies", action = "actionGet"};
		_controller = controller("verifies", params);
		_controller.processAction("actionGet", params);
		assert('_controller.$abortIssued() eq "true"');
		assert('_controller.$performedRenderOrRedirect() eq "false"');
	}

	function test_invalid_redirect() {
		request.cgi.request_method = "get";
		params = {controller = "verifies", action = "actionPostWithRedirect"};
		_controller = controller("verifies", params);
		_controller.processAction("actionPostWithRedirect", params);
		assert('_controller.$abortIssued() eq "false"');
		assert('_controller.$performedRenderOrRedirect() eq "true"');
		assert('_controller.getRedirect().$args.action  eq "index"');
		assert('_controller.getRedirect().$args.controller  eq "somewhere"');
		assert('_controller.getRedirect().$args.error  eq "invalid"');
	}

	function test_valid_types() {
		request.cgi.request_method = "post";
		params = {
			controller = "verifies",
			action = "actionPostWithTypesValid",
			userid = "0",
			authorid = "00000000-0000-0000-0000-000000000000"
		};
		_controller = controller("verifies", params);
		_controller.processAction("actionPostWithTypesValid", params);
		assert('_controller.response() eq "actionPostWithTypesValid"');
	}

	function test_invalid_types_guid() {
		request.cgi.request_method = "post";
		params = {
			controller = "verifies",
			action = "actionPostWithTypesInValid",
			userid = "0",
			authorid = "invalidguid"
		};
		_controller = controller("verifies", params);
		_controller.processAction("actionPostWithTypesInValid", params);
		assert('_controller.$abortIssued() eq "true"');
	}

	function test_invalid_types_integer() {
		request.cgi.request_method = "post";
		params = {
			controller = "verifies",
			action = "actionPostWithTypesInValid",
			userid = "1.234",
			authorid = "00000000-0000-0000-0000-000000000000"
		};
		_controller = controller("verifies", params);
		_controller.processAction("actionPostWithTypesInValid", params);
		assert('_controller.$abortIssued() eq "true"');
	}

	function test_strings_allow_blank() {
		request.cgi.request_method = "post";
		params = {
			controller = "verifies",
			action = "actionPostWithString",
			username = "tony",
			password = ""
		};
		_controller = controller("verifies", params);
		_controller.processAction("actionPostWithString", params);
		assert('_controller.$abortIssued() eq "false"');
	}

	function test_strings_cannot_be_blank() {
		request.cgi.request_method = "post";
		params = {
			controller = "verifies",
			action = "actionPostWithString",
			username = "",
			password = ""
		};
		_controller = controller("verifies", params);
		_controller.processAction("actionPostWithString", params);
		assert('_controller.$abortIssued() eq "true"');
	}

}
