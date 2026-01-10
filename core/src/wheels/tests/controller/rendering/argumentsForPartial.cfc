component extends="wheels.tests.Test" {

	function setup() {
		include "setup.cfm";
		params = {controller = "dummy", action = "dummy"};
		_controller = controller("dummy", params);
	}

	function teardown() {
		include "teardown.cfm";
	}

	function test_name_is_not_a_function() {
		query = QueryNew("a,b,c,e");
		_controller.$injectIntoVariablesScope = this.$injectIntoVariablesScope;
		_controller.$injectIntoVariablesScope(name = "query", data = query);
		actual = _controller.$argumentsForPartial($name = "query", $dataFunction = true);
		assert('IsStruct(actual) and StructIsEmpty(actual)');
	}

	/**
	 * HELPERS
	 */

	function $injectIntoVariablesScope(required string name, required any data) {
		variables[arguments.name] = arguments.data;
	}

}
