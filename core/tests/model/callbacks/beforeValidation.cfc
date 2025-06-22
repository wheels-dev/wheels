component extends="wheels.tests.Test" {

	function setup() {
		model("tag").$registerCallback(
			type = "beforeValidation",
			methods = "callbackThatSetsProperty,callbackThatReturnsFalse"
		);
		obj = model("tag").findOne();
		obj.name = "somethingElse";
	}

	function teardown() {
		model("tag").$clearCallbacks(type = "beforeValidation");
	}

	function test_saving_object() {
		obj.save();
		assert("StructKeyExists(obj, 'setByCallback')");
	}

	function test_saving_object_without_callbacks() {
		obj.save(callbacks = false, transaction = "rollback");
		assert("NOT StructKeyExists(obj, 'setByCallback')");
	}

	function test_validating_nested_property_object_should_register_callback() {
		obj = $setGalleryNestedProperties();
		obj.gallery.valid();
		assert("StructKeyExists(obj.gallery.photos[1].properties(), 'beforeValidationCallbackRegistered')");
	}

	function test_saving_nested_property_object_should_register_callback_only_once() {
		transaction {
			obj = $setGalleryNestedProperties();
			obj.gallery.save();
			assert("obj.gallery.photos[1].beforeValidationCallbackCount IS 1");
			transaction action="rollback";
		}
	}

	function $setGalleryNestedProperties() {
		var rv = {};
		rv.user = model("user").findOneByLastName("Petruzzi");
		rv.gallery = model("gallery").new(
			userId = rv.user.id,
			title = "Nested Properties Gallery",
			description = "A gallery testing nested properties."
		);
		rv.gallery.photos = [
			model("photo").new(
				userId = rv.user.id,
				filename = "Nested Properties Photo Test 1",
				DESCRIPTION1 = "test photo 1 for nested properties gallery"
			)
		];
		return rv;
	}

}
