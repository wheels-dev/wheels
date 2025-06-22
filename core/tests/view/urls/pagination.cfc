component extends="wheels.tests.Test" {

	function setup() {
		_controller = controller(name = "dummy");
		user = model("users");
	}

	function test_x_pagination_valid() {
		e = user.findAll(
			where = "firstname = 'somemoron'",
			perpage = "2",
			page = "1",
			handle = "pagination_test_1",
			order = "id"
		);
		_controller.pagination("pagination_test_1");
	}

}
