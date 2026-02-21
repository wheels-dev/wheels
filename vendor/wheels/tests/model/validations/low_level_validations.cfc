component extends="wheels.tests.Test" {

	function test_validate_and_validateOnCreate_should_be_called_when_creating() {
		user = model("user").new();
		user.valid();
		assert('StructKeyExists(user, "_validateCalled")');
		assert('user._validateCalled eq true');
		assert('StructKeyExists(user, "_validateOnCreateCalled")');
		assert('user._validateOnCreateCalled eq true');
	}

	function test_validate_and_validateOnUpdate_should_be_called_when_updating() {
		user = model("user").findOne(where = "username = 'perd'");
		user.valid();
		assert('StructKeyExists(user, "_validateCalled")');
		assert('user._validateCalled eq true');
		assert('StructKeyExists(user, "_validateOnUpdateCalled")');
		assert('user._validateOnUpdateCalled eq true');
	}

}
