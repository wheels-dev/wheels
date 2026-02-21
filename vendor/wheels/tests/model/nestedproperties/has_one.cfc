component extends = "wheels.tests.Test"{
	function setup() {
		author = model("author");
		profile = model("profile");
		$setTestObjects();
		testParamsStruct = $setTestParamsStruct();
	}

	/**
	 * Simulates adding an `author` and its child `profile` through a single
	 * structure passed into `author.create()`, much like what's normally done
	 * with the `params` struct.
	 */
	function test_add_entire_data_set_via_create_and_struct() {
		transaction {
			/* Should return `true` on successful create */
			author = author.create(testParamsStruct.author);
			assert('IsObject(author)');
			transaction action="rollback";
		}
		/* Test whether profile was transformed into an object */
		assert("IsObject(author.profile)");
		/* Test generated primary keys */
		assert("IsNumeric(author.id) and IsNumeric(author.profile.id)");
	}

	/**
	 * Simulates adding an `author` and its child `profile` through a single
	 * structure passed into `author.new()` and saved with `author.save()`, much
	 * like what's normally done with the `params` struct.
	 */
	function test_add_entire_data_set_via_new_and_struct() {
		author = author.new(testParamsStruct.author);
		transaction {
			/* Should return `true` on successful create */
			assert("author.save()");
			transaction action="rollback";
		}
		/* Test whether profile was transformed into an object */
		assert("IsObject(author.profile)");
		/* Test generated primary keys */
		assert("IsNumeric(author.id) and IsNumeric(author.profile.id)");
	}

	/**
	 * Loads an existing `author` and sets its child `profile` as an object before saving.
	 */
	function test_add_child_via_object() {
		transaction {
			assert("testAuthor.save()");
			p = profile.findByKey(testAuthor.profile.id);
			transaction action="rollback";
		}
		assert("IsObject(p)");
	}

	/*
	 * Loads an existing `author` and sets its child `profile` as a struct before saving.
	 */
	function test_add_child_via_struct() {
		transaction {
			assert("testAuthor.save()");
			testAuthor.profile = {dateOfBirth = "10/02/1980 18:00:00", bio = bioText};
			assert("testAuthor.save()");
			assert("IsObject(testAuthor.profile)");
			p = profile.findByKey(testAuthor.profile.id);
			transaction action="rollback";
		}
		assert("IsObject(p)");
	}

	/**
	 * Loads an existing `author` and deletes its child `profile` by setting the `_delete` property to `true`.
	 */
	function test_delete_child_through_object_property() {
		transaction {
			testAuthor.save();
			/* Delete profile through nested property */
			testAuthor.profile._delete = true;
			profileID = testAuthor.profile.id;
			assert("testAuthor.save()");
			/* Should return `false` because the record is now deleted */
			missingProfile = profile.findByKey(key = profileId, reload = true);
			transaction action="rollback";
		}
		assert("IsBoolean(missingProfile) and not missingProfile");
	}

	/**
	 * Loads an existing `author` and deletes its child `property` by passing in a struct through `update()`.
	 */
	function test_delete_child_through_struct() {
		transaction {
			/* Save test author with child profile and grab new profile's ID */
			testAuthor.save();
			profileID = testAuthor.profile.id;
			/* Delete profile through nested property */
			updateStruct.profile._delete = true;
			assert("testAuthor.update(properties=updateStruct)");
			/* Should return `false` because the record is now deleted */
			missingProfile = profile.findByKey(key = profileId, reload = true);
			transaction action="rollback";
		}
		assert("IsBoolean(missingProfile) and not missingProfile");
	}

	function test_valid_beforeValidation_callback_on_child() {
		assert("testAuthor.valid()");
		assert("testAuthor.profile.beforeValidationCallbackRegistered");
		assert("testAuthor.profile.beforeValidationCallbackCount eq 1");
	}

	function test_valid_beforeValidation_callback_on_child_with_validation_error_on_parent() {
		testAuthor.firstName = "";
		assert("not testAuthor.valid()");
		assert("testAuthor.profile.beforeValidationCallbackRegistered");
		assert("testAuthor.profile.beforeValidationCallbackCount eq 1");
	}

	function test_save_beforeValidation_callback_on_child() {
		transaction {
			assert("testAuthor.save()");
			assert("testAuthor.profile.beforeValidationCallbackRegistered");
			assert("testAuthor.profile.beforeValidationCallbackCount eq 1");
			transaction action="rollback";
		}
	}

	function test_save_beforeValidation_callback_on_child_with_validation_error_on_parent() {
		testAuthor.firstName = "";
		transaction {
			assert("not testAuthor.save()");
			assert("testAuthor.profile.beforeValidationCallbackRegistered");
			assert("testAuthor.profile.beforeValidationCallbackCount eq 1");
			transaction action="rollback";
		}
	}

	function test_beforeCreate_callback_on_child() {
		transaction {
			testAuthor.save();
			assert("testAuthor.profile.beforeCreateCallbackCount eq 1");
			transaction action="rollback";
		}
	}

	function test_beforeSave_callback_on_child() {
		transaction {
			testAuthor.save();
			assert("testAuthor.profile.beforeSaveCallbackCount eq 1");
			transaction action="rollback";
		}
	}

	function test_afterCreate_callback_on_child() {
		transaction {
			testAuthor.save();
			assert("testAuthor.profile.afterCreateCallbackCount eq 1");
			transaction action="rollback";
		}
	}

	function test_afterSave_callback_on_child() {
		transaction {
			testAuthor.save();
			assert("testAuthor.profile.afterSaveCallbackCount eq 1");
			transaction action="rollback";
		}
	}

	function test_parent_primary_key_rolled_back_on_parent_validation_error() {
		testAuthor = author.new(testParams.author);
		testAuthor.firstName = "";
		transaction {
			testAuthor.save();
			transaction action="rollback";
		}
		assert("not Len(testAuthor.key())");
	}

	function test_child_primary_key_rolled_back_on_parent_validation_error() {
		testAuthor = author.new(testParams.author);
		testAuthor.firstName = "";
		transaction {
			testAuthor.save();
			transaction action="rollback";
		}
		assert("not Len(testAuthor.profile.key())");
	}

	function test_parent_primary_key_rolled_back_on_child_validation_error() {
		testAuthor = author.new(testParams.author);
		testAuthor.profile.dateOfBirth = "";
		transaction {
			testAuthor.save();
			transaction action="rollback";
		}
		assert("not Len(testAuthor.key())");
	}

	function test_child_primary_key_rolled_back_on_child_validation_error() {
		testAuthor = author.new(testParams.author);
		testAuthor.profile.dateOfBirth = "";
		transaction {
			testAuthor.save();
			transaction action="rollback";
		}
		assert("not Len(testAuthor.profile.key())");
	}

	/**
	 * HELPERS
	 */

	private void function $setTestObjects() {
		testAuthor = author.findOneByLastName(value = "Peters", include = "profile");
		bioText = "Loves learning how to write tests.";
		testAuthor.profile = model("profile").new(dateOfBirth = "10/02/1980 18:00:00", bio = bioText);
	}

	/**
	 * Sets up test `author` struct reminiscent of what would be passed through a
	 * form. The `author` represented here also includes a nested child `profile` struct.
	 */
	private struct function $setTestParamsStruct() {
		testParams = {
			author = {
				firstName = "Brian",
				lastName = "Meloche",
				profile = {
					dateOfBirth = "10/02/1970 18:01:00",
					bio = "Host of CFConversations, the best ColdFusion podcast out there."
				}
			}
		};
		return testParams;
	}
}
