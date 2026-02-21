component extends="wheels.tests.Test" {

	function setup() {
		model("tag").$registerCallback(
			type = "beforeValidationOnUpdate",
			methods = "callbackThatSetsProperty,callbackThatReturnsFalse"
		);
		obj = model("tag").findOne();
		obj.name = "somethingElse";
	}

	function teardown() {
		model("tag").$clearCallbacks(type = "beforeValidationOnUpdate");
	}

	function test_existing_object() {
		obj.save();
		assert("StructKeyExists(obj, 'setByCallback')");
	}

	function test_existing_object_with_skipped_callback() {
		obj.save(callbacks = false, transaction = "rollback");
		assert("NOT StructKeyExists(obj, 'setByCallback')");
	}

}
