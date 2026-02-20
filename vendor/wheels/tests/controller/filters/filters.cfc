component extends="wheels.tests.Test" {

	function test_adding_filter() {
		local.controller = controller(name = "dummy");
		local.controller.setFilterChain([]);
		local.args = {};
		local.args.through = "restrictAccess";
		local.controller.filters(argumentcollection = local.args);
		result = ArrayLen(local.controller.filterChain());
		expected = 1;
		assert("result eq expected");
		local.controller.setFilterChain([]);
	}

}
