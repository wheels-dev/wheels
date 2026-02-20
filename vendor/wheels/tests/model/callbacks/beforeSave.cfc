component extends="wheels.tests.Test" {

	function test_proceeding_on_true_and_nothing() {
		model("tag").$registerCallback(type = "beforeSave", methods = "callbackThatReturnsTrue,callbackThatReturnsNothing");
		obj = model("tag").findOne(order = "id");
		oldName = obj.name;
		obj.name = "somethingElse";
		obj.save();
		obj.reload();
		name = obj.name;
		obj.name = oldName;
		obj.save();
		model("tag").$clearCallbacks(type = "beforeSave");
		assert("name IS NOT oldName");
	}

	function test_aborting_on_false() {
		model("tag").$registerCallback(type = "beforeSave", methods = "callbackThatReturnsFalse");
		obj = model("tag").findOne(order = "id");
		oldName = obj.name;
		obj.name = "somethingElse";
		obj.save();
		obj.reload();
		model("tag").$clearCallbacks(type = "beforeSave");
		assert("obj.name IS oldName");
	}

	function test_setting_property() {
		model("tag").$registerCallback(type = "beforeSave", methods = "callbackThatSetsProperty");
		obj = model("tag").findOne(order = "id");
		existBefore = StructKeyExists(obj, "setByCallback");
		obj.save();
		existAfter = StructKeyExists(obj, "setByCallback");
		model("tag").$clearCallbacks(type = "beforeSave");
		assert("NOT existBefore AND existAfter");
	}

	function test_setting_property_with_skipped_callback() {
		model("tag").$registerCallback(type = "beforeSave", methods = "callbackThatSetsProperty");
		obj = model("tag").findOne(order = "id");
		existBefore = StructKeyExists(obj, "setByCallback");
		obj.save(callbacks = false, transaction = "rollback");
		existAfter = StructKeyExists(obj, "setByCallback");
		model("tag").$clearCallbacks(type = "beforeSave");
		assert("NOT existBefore AND NOT existAfter");
	}

	function test_execution_order() {
		model("tag").$registerCallback(type = "beforeSave", methods = "firstCallback,secondCallback");
		obj = model("tag").findOne(order = "id");
		obj.name = "somethingElse";
		obj.save();
		model("tag").$clearCallbacks(type = "beforeSave");
		assert("obj.orderTest IS 'first,second'");
	}

	function test_aborting_chain() {
		model("tag").$registerCallback(
			type = "beforeSave",
			methods = "firstCallback,callbackThatReturnsFalse,secondCallback"
		);
		obj = model("tag").findOne(order = "id");
		obj.name = "somethingElse";
		obj.save();
		model("tag").$clearCallbacks(type = "beforeSave");
		assert("obj.orderTest IS 'first'");
	}

	function test_setting_in_config_and_clearing() {
		callbacks = model("author").$callbacks();
		assert("callbacks.beforeSave[1] IS 'callbackThatReturnsTrue'");
		model("author").$clearCallbacks(type = "beforeSave");
		assert("ArrayLen(callbacks.beforeSave) IS 0 AND callbacks.beforeDelete[1] IS 'callbackThatReturnsTrue'");
		model("author").$clearCallbacks();
		assert("ArrayLen(callbacks.beforeDelete) IS 0");
	}

}
