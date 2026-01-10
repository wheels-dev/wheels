component extends="wheels.tests.Test" {

	function setup() {
		user = model("user");
	}

	function test_only_totalRecords() {
		setPagination(100);
		assert_pagination(handle = "query", totalRecords = 100);
	}

	function test_all_arguments() {
		setPagination(1000, 4, 50, "pageTest");
		assert_pagination(
			handle = "pageTest",
			totalRecords = 1000,
			currentPage = 4,
			perPage = 50
		);
	}

	function test_totalRecords_less_than_zero() {
		setPagination(-5, 4, 50, "pageTest");
		assert_pagination(
			handle = "pageTest",
			totalRecords = 0,
			currentPage = 1,
			perPage = 50
		);
	}

	function test_currentPage_less_than_one() {
		setPagination(1000, -4, 50, "pageTest");
		assert_pagination(
			handle = "pageTest",
			totalRecords = 1000,
			currentPage = 1,
			perPage = 50
		);
	}

	function test_numeric_arguments_must_be_integers() {
		setPagination(1000.9998, 5.876, 50.847, "pageTest");
		assert_pagination(
			handle = "pageTest",
			totalRecords = 1000,
			currentPage = 5,
			perPage = 50
		);
	}

	function assert_pagination(required string handle) {
		args = arguments;
		assert('StructKeyExists(request.wheels, args.handle)');
		p = request.wheels[args.handle];
		StructDelete(args, "handle", false);
		for (i in args) {
			actual = p[i];
			expected = args[i];
			assert('actual eq expected');
		};
	}

}
