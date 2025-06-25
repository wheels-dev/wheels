component extends="wheels.tests.Test" {

	function setup() {
		request.wheels["myhandle"] = {test = "true"};
		params = {controller = "dummy", action = "dummy"};
		_controller = controller("dummy", params);
	}

	function teardown() {
		StructDelete(request.wheels, "myhandle", false);
	}

	function test_pagination_handle_exists() {
		actual = _controller.pagination('myhandle');
		assert('isstruct(actual)');
		assert('structkeyexists(actual, "test")');
		assert('actual.test eq true');
	}

	function test_pagination_handle_does_not_exists() {
		expected = "Wheels.QueryHandleNotFound";
		actual = raised('_controller.pagination("someotherhandle")');
		assert('expected eq actual');
	}

}
