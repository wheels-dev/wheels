component extends="wheels.tests.Test" {

	function setup() {
		params = {controller = "dummy", action = "dummy"};
		_controller = controller("dummy", params);
	}


	function test_valid() {
		// Build filter chain through array - this is what we're testing
		myFilterChain = [
			{through = "restrictAccess"},
			{through = "isLoggedIn,checkIPAddress", except = "home,login"},
			{type = "after", through = "logConversion", only = "thankYou"}
		];
		_controller.setFilterChain(myFilterChain);
		filterChainSet = _controller.filterChain();
		// Undo test
		_controller.setFilterChain(ArrayNew(1));
		// Build filter chain through "normal" filters() function
		_controller.filters(through = "restrictAccess");
		_controller.filters(through = "isLoggedIn,checkIPAddress", except = "home,login");
		_controller.filters(type = "after", through = "logConversion", only = "thankYou");
		filterChainNormal = _controller.filterChain();
		// Undo test
		_controller.setFilterChain(ArrayNew(1));
		// Compare filter chains
		assert("ArrayLen(filterChainSet) eq ArrayLen(filterChainNormal)");
		assert("filterChainSet.equals(filterChainNormal)");
	}

}
