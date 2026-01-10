component extends="wheels.tests.Test" {

	function teardown() {
		model("tag").$clearCallbacks(type = "beforeCreate,beforeUpdate");
	}

	function test_existing_object() {
		model("tag").$registerCallback(type = "beforeCreate", methods = "callbackThatSetsProperty");
		model("tag").$registerCallback(type = "beforeUpdate", methods = "callbackThatReturnsFalse");
		obj = model("tag").findOne();
		obj.name = "somethingElse";
		obj.save();
		assert("NOT StructKeyExists(obj, 'setByCallback')");
	}

	function test_new_object() {
		model("tag").$registerCallback(type = "beforeUpdate", methods = "callbackThatSetsProperty");
		model("tag").$registerCallback(type = "beforeCreate", methods = "callbackThatReturnsFalse");
		obj = model("tag").create();
		assert("NOT StructKeyExists(obj, 'setByCallback')");
	}

}
