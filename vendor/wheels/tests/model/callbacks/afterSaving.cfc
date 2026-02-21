component extends="wheels.tests.Test" {

	function setup() {
		model("tag").$registerCallback(type = "afterValidation", methods = "callbackThatIncreasesVariable");
		model("tag").$registerCallback(type = "afterValidationOnCreate", methods = "callbackThatIncreasesVariable");
		model("tag").$registerCallback(type = "afterValidationOnUpdate", methods = "callbackThatIncreasesVariable");
		model("tag").$registerCallback(type = "afterSave", methods = "callbackThatIncreasesVariable");
		model("tag").$registerCallback(type = "afterCreate", methods = "callbackThatIncreasesVariable");
		model("tag").$registerCallback(type = "afterUpdate", methods = "callbackThatIncreasesVariable");
		obj = model("tag").findOne();
		obj.name = "somethingElse";
	}

	function teardown() {
		model("tag").$clearCallbacks(
			type = "afterValidation,afterValidationOnCreate,afterValidationOnUpdate,afterSave,afterCreate,afterUpdate"
		);
	}

	function test_chain_when_saving_existing_object() {
		transaction {
			obj.save(transaction = "none");
			transaction action="rollback";
		}
		assert("obj.callbackCount IS 4");
	}

	function test_chain_when_saving_existing_object_with_all_callbacks_skipped() {
		transaction {
			obj.save(transaction = "none", callbacks = false);
			transaction action="rollback";
		}
		assert("NOT StructKeyExists(obj, 'callbackCount')");
	}

}
