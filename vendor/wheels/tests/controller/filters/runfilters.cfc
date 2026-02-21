component extends="wheels.tests.Test" {

	function setup() {
		params = {controller = "filtering", action = "index"};
		_controller = controller("filtering", params);
		request.filterTests = StructNew();
	}

	function test_should_run_public() {
		_controller.$runFilters(type = "before", action = "index");
		assert("StructKeyExists(request.filterTests, 'pubTest')");
	}

	function test_should_run_private() {
		_controller.$runFilters(type = "before", action = "index");
		assert("StructKeyExists(request.filterTests, 'privTest')");
	}

	function test_should_run_in_order() {
		_controller.$runFilters(type = "before", action = "index");
		assert("request.filterTests.test IS 'bothpubpriv'");
	}

	function test_should_not_run_excluded() {
		_controller.$runFilters(type = "before", action = "doNotRun");
		assert("NOT StructKeyExists(request.filterTests, 'dirTest')");
	}

	function test_should_run_included_only() {
		_controller.$runFilters(type = "before", action = "doesNotExist");
		assert("NOT StructKeyExists(request.filterTests, 'pubTest')");
	}

	function test_should_pass_direct_arguments() {
		_controller.$runFilters(type = "before", action = "index");
		assert("request.filterTests.dirTest IS 1");
	}

	function test_should_pass_struct_arguments() {
		_controller.$runFilters(type = "before", action = "index");
		assert("request.filterTests.strTest IS 21");
	}

	function test_should_pass_both_direct_and_struct_arguments() {
		_controller.$runFilters(type = "before", action = "index");
		assert("request.filterTests.bothTest IS 31");
	}

}
