component extends="wheels.tests.Test" {

	function test_new_model_with_property_defaults() {
		author = model("Author").new();
		assert('StructKeyExists(author, "firstName") and author.firstName eq "Dave"');
	}

	function test_new_model_with_property_defaults_set_to_blank() {
		author = model("Author").new();
		assert('StructKeyExists(author, "lastName") and author.lastName eq ""');
	}

	function test_database_defaults_load_after_create() {
		transaction action="begin" {
			user = model("UserBlank").create(
				username = "The Dude",
				password = "doodle",
				firstName = "The",
				lastName = "Dude",
				reload = true
			);
			transaction action="rollback";
		}
		assert('StructKeyExists(user, "birthTime") and TimeFormat(user.birthTime, "HH:mm:ss") eq "18:26:08"');
	}

	function test_database_defaults_load_after_save() {
		transaction action="begin" {
			user = model("UserBlank").new(
				username = "The Dude",
				password = "doodle",
				firstName = "The",
				lastName = "Dude"
			);
			user.save(reload = true);
			transaction action="rollback";
		}
		assert('StructKeyExists(user, "birthTime") and TimeFormat(user.birthTime, "HH:mm:ss") eq "18:26:08"');
	}

}
