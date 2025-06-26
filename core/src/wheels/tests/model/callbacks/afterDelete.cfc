component extends="wheels.tests.Test" {

	function setup() {
		model("tag").$registerCallback(type = "afterDelete", methods = "callbackThatSetsProperty");
		obj = model("tag").findOne();
	}

	function teardown() {
		model("tag").$clearCallbacks(type = "afterDelete");
	}

	function test_existing_object() {
		transaction {
			obj.delete(transaction = "none");
			transaction action="rollback";
		}
		assert("StructKeyExists(obj, 'setByCallback')");
	}

	function test_existing_object_with_skipped_callback() {
		transaction {
			obj.delete(transaction = "none", callbacks = "false");
			transaction action="rollback";
		}
		assert("NOT StructKeyExists(obj, 'setByCallback')");
	}

}
