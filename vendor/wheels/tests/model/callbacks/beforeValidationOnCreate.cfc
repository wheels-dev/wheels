component extends="wheels.tests.Test" {

	function setup() {
		model("tag").$registerCallback(
			type = "beforeValidationOnCreate",
			methods = "callbackThatSetsProperty,callbackThatReturnsFalse"
		);
	}

	function teardown() {
		model("tag").$clearCallbacks(type = "beforeValidationOnCreate");
	}

	function test_new_object() {
		obj = model("tag").create();
		assert("StructKeyExists(obj, 'setByCallback')");
	}

	function test_new_object_with_skipped_callback() {
		obj = model("tag").create(
			name = "mustSetAtLeastOnePropertyOrCreateFails",
			transaction = "rollback",
			callbacks = false
		);
		assert("NOT StructKeyExists(obj, 'setByCallback')");
	}

}
