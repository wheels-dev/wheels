component extends="wheels.tests.Test" {

	function test_getting_child() {
		author = model("author").findOne(order = "id");
		dynamicResult = author.profile();
		coreResult = model("profile").findOne(where = "authorId=#author.id#");
		assert("dynamicResult.bio IS coreResult.bio");
	}

	function test_checking_if_child_exist() {
		author = model("author").findOne(order = "id");
		dynamicResult = author.hasProfile();
		coreResult = model("profile").exists(where = "authorId=#author.id#");
		assert("dynamicResult IS coreResult");
	}

	function test_adding_child_by_setting_foreign_key() {
		author = model("author").findOne(order = "id DESC");
		profile = model("profile").findOne(order = "id");
		transaction {
			author.setProfile(profile = profile, transaction = "none");
			profile.reload();
			transaction action="rollback";
		}
		assert("author.id IS profile.authorId");
		profile.reload();
		transaction {
			author.setProfile(key = profile.id, transaction = "none");
			profile.reload();
			transaction action="rollback";
		}
		assert("author.id IS profile.authorId");
		profile.reload();
		transaction {
			model("profile").updateByKey(key = profile.id, authorId = author.id, transaction = "none");
			profile.reload();
			transaction action="rollback";
		}
		assert("author.id IS profile.authorId");
	}

	function test_removing_child_by_nullifying_foreign_key() {
		author = model("author").findOne(order = "id");
		transaction {
			author.removeProfile(transaction = "none");
			assert("model('profile').findOne().authorId IS ''");
			transaction action="rollback";
		}
		transaction {
			model("profile").updateOne(authorId = "", where = "authorId=#author.id#", transaction = "none");
			assert("model('profile').findOne().authorId IS ''");
			transaction action="rollback";
		}
	}

	function test_deleting_child() {
		author = model("author").findOne(order = "id");
		profileCount = model("profile").count();
		transaction {
			author.deleteProfile(transaction = "none");
			assert("model('profile').count() eq (profileCount - 1)");
			transaction action="rollback";
		}
		transaction {
			model("profile").deleteOne(where = "authorId=#author.id#", transaction = "none");
			assert("model('profile').count() eq (profileCount - 1)");
			transaction action="rollback";
		}
	}

	function test_creating_new_child() {
		author = model("author").findOne(order = "id");
		newProfile = author.newProfile(dateOfBirth = "17/12/1981");
		dynamicResult = newProfile.authorId;
		newProfile = model("profile").new(authorId = author.id, dateOfBirth = "17/12/1981");
		coreResult = newProfile.authorId;
		assert("dynamicResult IS coreResult");
	}

	function test_creating_new_child_and_saving_it() {
		author = model("author").findOne(order = "id");
		transaction {
			newProfile = author.createProfile(dateOfBirth = "17/12/1981", transaction = "none");
			dynamicResult = newProfile.authorId;
			transaction action="rollback";
		}
		transaction {
			newProfile = model("profile").create(authorId = author.id, dateOfBirth = "17/12/1981", transaction = "none");
			coreResult = newProfile.authorId;
			transaction action="rollback";
		}
		assert("dynamicResult IS coreResult");
	}

	function test_getting_child_with_join_key() {
		obj = model("user").findOne(order = "id", include = "author");
		assert('obj.firstName eq obj.author.firstName');
	}

}
