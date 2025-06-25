component extends = "wheels.tests.Test"{
	function setup() {
		gallery = model("gallery");
		photo = model("photo");
		user = model("user");
		testGallery = $setTestObjects();
		idx = {}; // CF10 has issues with just using for(i in foo)
	}

	function test_add_children_via_object_array() {
		transaction {
			assert("testGallery.save()");
			testGallery = gallery.findOneByTitle(value = "Nested Properties Gallery", include = "photos");
			assert("IsArray(testGallery.photos)");
			assert("ArrayLen(testGallery.photos) eq 3");
			transaction action="rollback";
		}
	}

	function test_delete_children_via_object_array() {
		transaction {
			assert("testGallery.save()");
			testGallery = gallery.findOneByTitle(value = "Nested Properties Gallery", include = "photos");
			for (idx.i in testGallery.photos) {
				idx.i._delete = true;
			};
			testGallery.save();
			assert("IsArray(testGallery.photos)");
			assert("ArrayLen(testGallery.photos) eq 0");
			transaction action="rollback";
		}
	}

	function test_valid_beforeValidation_callbacks_on_children() {
		assert("testGallery.valid()");
		for (idx.i in testGallery.photos) {
			assert("idx.i.beforeValidationCallbackRegistered");
			assert("idx.i.beforeValidationCallbackCount eq 1");
		};
	}

	function test_valid_beforeValidation_callbacks_on_children_with_validation_error_on_parent() {
		testGallery.title = "";
		assert("not testGallery.valid()");
		for (idx.i in testGallery.photos) {
			assert("idx.i.beforeValidationCallbackRegistered");
			assert("idx.i.beforeValidationCallbackCount eq 1");
		};
	}

	function test_save_beforeValidation_callbacks_on_children() {
		transaction {
			assert("testGallery.save()");
			for (idx.i in testGallery.photos) {
				assert("idx.i.beforeValidationCallbackRegistered");
				assert("idx.i.beforeValidationCallbackCount eq 1");
			};
			transaction action="rollback";
		}
	}

	function test_save_beforeValidation_callbacks_on_children_with_validation_error_on_parent() {
		testGallery.title = "";
		transaction {
			assert("not testGallery.save()");
			for (idx.i in testGallery.photos) {
				assert("idx.i.beforeValidationCallbackRegistered");
				assert("idx.i.beforeValidationCallbackCount eq 1");
			};
			transaction action="rollback";
		}
	}

	function test_beforeCreate_callback_on_children() {
		transaction {
			testGallery.save();
			for (idx.i in testGallery.photos) {
				assert("idx.i.beforeCreateCallbackCount eq 1");
			};
			transaction action="rollback";
		}
	}

	function test_beforeSave_callback_on_children() {
		transaction {
			testGallery.save();
			for (idx.i in testGallery.photos) {
				assert("idx.i.beforeSaveCallbackCount eq 1");
			};
			transaction action="rollback";
		}
	}

	function test_afterCreate_callback_on_children() {
		transaction {
			testGallery.save();
			for (idx.i in testGallery.photos) {
				assert("idx.i.afterCreateCallbackCount eq 1");
			};
			transaction action="rollback";
		}
	}

	function test_afterSave_callback_on_children() {
		transaction {
			testGallery.save();
			for (idx.i in testGallery.photos) {
				assert("idx.i.afterSaveCallbackCount eq 1");
			};
			transaction action="rollback";
		}
	}

	function test_parent_primary_key_rolled_back_on_parent_validation_error() {
		testGallery.title = "";
		transaction {
			assert("not testGallery.save()");
			transaction action="rollback";
		}
		assert("not Len(testGallery.key())");
	}

	function test_children_primary_keys_rolled_back_on_parent_validation_error() {
		testGallery.title = "";
		transaction {
			assert("not testGallery.save()");
			transaction action="rollback";
		}
		for (idx.i in testGallery.photos) {
			assert("not Len(idx.i.key())");
		};
	}

	function test_parent_primary_key_rolled_back_on_child_validation_error() {
		testGallery.photos[2].filename = "";
		transaction {
			assert("not testGallery.save()");
			transaction action="rollback";
		}
		assert("not Len(testGallery.key())");
	}

	function test_children_primary_keys_rolled_back_on_child_validation_error() {
		testGallery.photos[2].filename = "";
		transaction {
			assert("not testGallery.save()");
			transaction action="rollback";
		}
		for (idx.i in testGallery.photos) {
			assert("not Len(idx.i.key())");
		};
	}

	/**
	 * HELPERS
	 */

	private any function $setTestObjects() {
		/* User */
		var u = user.findOneByLastName("Petruzzi");
		/* Gallery */
		var _params = {
			userId = u.id,
			title = "Nested Properties Gallery",
			description = "A gallery testing nested properties."
		};
		var g = gallery.new(_params);
		g.photos = [
			photo.new(
				userId = u.id,
				filename = "Nested Properties Photo Test 1",
				DESCRIPTION1 = "test photo 1 for nested properties gallery"
			),
			photo.new(
				userId = u.id,
				filename = "Nested Properties Photo Test 2",
				DESCRIPTION1 = "test photo 2 for nested properties gallery"
			),
			photo.new(
				userId = u.id,
				filename = "Nested Properties Photo Test 3",
				DESCRIPTION1 = "test photo 3 for nested properties gallery"
			)
		];
		return g;
	}
}
