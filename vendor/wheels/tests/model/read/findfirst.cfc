component extends="wheels.tests.Test" {

	function test_find_first() {
		result = model("user").findFirst();
		assert('result.id IS 1');
		result = model("user").findFirst(property = "firstName");
		assert("result.firstName IS 'Chris'");
		result = model("user").findFirst(properties = "firstName");
		assert("result.firstName IS 'Chris'");
		result = model("user").findFirst(property = "firstName", where = "id != 2");
		assert("result.firstName IS 'Joe'");
	}

}
