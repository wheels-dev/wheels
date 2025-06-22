component extends="wheels.tests.Test" {

	function setup() {
		model("tag").$registerCallback(type = "beforeDelete", methods = "callbackThatSetsProperty,callbackThatReturnsFalse");
		obj = model("tag").findOne();
	}

	function teardown() {
		model("tag").$clearCallbacks(type = "beforeDelete");
	}

	function test_existing_object() {
		obj.delete();
		assert("StructKeyExists(obj, 'setByCallback')");
	}

	function test_existing_object_with_skipped_callback() {
		obj.delete(callbacks = false, transaction = "rollback");
		assert("NOT StructKeyExists(obj, 'setByCallback')");
	}

}
