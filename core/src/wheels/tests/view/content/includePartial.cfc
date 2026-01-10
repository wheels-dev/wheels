component extends="wheels.tests.Test" {

	function setup() {
		params = {controller = "test", action = "test"};
		_controller = controller("test", params);
		$$oldViewPath = application.wheels.viewPath;
		application.wheels.viewPath = "/wheels/tests/_assets/views";
	}

	function test_including_partial() {
		savecontent variable="result" {
			WriteOutput(_controller.includePartial(partial = "partialTemplate"));
		}
		assert("result Contains 'partial template content'");
	}

	function test_including_partial_loading_data() {
		savecontent variable="result" {
			WriteOutput(_controller.includePartial(partial = "partialDataImplicitPrivate"));
		}
		assert("result IS 'Apple,Banana,Kiwi'");
	}

	function test_including_partial_loading_data_allowed_from_explicit_public_method() {
		savecontent variable="result" {
			WriteOutput(
				_controller.includePartial(partial = "partialDataExplicitPublic", dataFunction = "partialDataExplicitPublic")
			);
		}
		assert("result IS 'Apple,Banana,Kiwi'");
	}

	function test_including_partial_loading_data_allowed_from_explicit_public_method_with_arg() {
		savecontent variable="result" {
			WriteOutput(
				_controller.includePartial(
					partial = "partialDataExplicitPublic",
					dataFunction = "partialDataExplicitPublic",
					passThrough = 1
				)
			);
		}
		assert("result IS 'Apple,Banana,Kiwi,passThroughWorked'");
	}

	function test_including_partial_loading_data_not_allowed_from_implicit_public_method() {
		result = "";
		try {
			savecontent variable="result" {
				WriteOutput(_controller.includePartial(partial = "partialDataImplicitPublic"));
			}
		} catch (any e) {
			result = e;
		}
		assert("!issimplevalue(result)");
		assert("result.type eq 'expression'");
	}

	function test_including_partial_with_query() {
		usersQuery = model("user").findAll(order = "firstName");
		request.partialTests.currentTotal = 0;
		request.partialTests.thirdUserName = "";
		savecontent variable="result" {
			WriteOutput(_controller.includePartial(query = usersQuery, partial = "user"));
		}
		assert("request.partialTests.currentTotal IS 15 AND request.partialTests.thirdUserName IS 'Per'");
	}

	function test_including_partial_with_special_query_argument() {
		usersQuery = model("user").findAll(order = "firstName");
		request.partialTests.currentTotal = 0;
		request.partialTests.thirdUserName = "";
		request.partialTests.noQueryArg = true;
		savecontent variable="result" {
			WriteOutput(_controller.includePartial(partial = "custom", query = usersQuery));
		}
		assert(
			"request.partialTests.noQueryArg IS true AND request.partialTests.currentTotal IS 15 AND request.partialTests.thirdUserName IS 'Per'"
		);
	}

	function test_including_partial_with_normal_query_argument() {
		usersQuery = model("user").findAll(order = "firstName");
		savecontent variable="result" {
			WriteOutput(_controller.includePartial(partial = "custom", customQuery = usersQuery));
		}
		assert("Trim(result) IS 'Per'");
	}

	function test_including_partial_with_special_objects_argument() {
		usersArray = model("user").findAll(order = "firstName", returnAs = "objects");
		request.partialTests.currentTotal = 0;
		request.partialTests.thirdUserName = "";
		request.partialTests.thirdObjectExists = false;
		request.partialTests.noObjectsArg = true;
		savecontent variable="result" {
			WriteOutput(_controller.includePartial(partial = "custom", objects = usersArray));
		}
		assert(
			"request.partialTests.thirdObjectExists IS true AND request.partialTests.noObjectsArg IS true AND request.partialTests.currentTotal IS 15 AND request.partialTests.thirdUserName IS 'Per'"
		);
	}

	function test_including_partial_with_object() {
		userObject = model("user").findOne(order = "firstName");
		request.wheelsTests.objectTestsPassed = false;
		savecontent variable="result" {
			WriteOutput(_controller.includePartial(userObject));
		}
		assert("request.wheelsTests.objectTestsPassed IS true AND Trim(result) IS 'Chris'");
	}

	function teardown() {
		application.wheels.viewPath = $$oldViewPath;
	}

}
