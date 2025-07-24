component extends="wheels.tests.Test" {

	function test_update() {
		transaction action="begin" {
			author = model("Author").findOne();
			author.update(firstName = "Kermit", lastName = "Frog");
			allKermits = model("Author").findAll(where = "firstName='Kermit' AND lastName='Frog'");
			transaction action="rollback";
		}
		assert('allKermits.recordcount eq 1');
	}

	function test_dynamic_update_with_named_argument() {
		transaction action="begin" {
			author = model("author").findOne(where = "firstName='Andy'");
			profile = model("profile").findOne(where = "bio LIKE 'ColdFusion Developer'");
			author.setProfile(profile = profile);
			updatedProfile = model("profile").findByKey(profile.id);
			transaction action="rollback";
		}
		assert("updatedProfile.authorId IS author.id");
	}

	function test_dynamic_update_with_unnamed_argument() {
		transaction action="begin" {
			author = model("author").findOne(where = "firstName='Andy'");
			profile = model("profile").findOne(where = "bio LIKE 'ColdFusion Developer'");
			author.setProfile(profile);
			updatedProfile = model("profile").findByKey(profile.id);
			transaction action="rollback";
		}
		assert("updatedProfile.authorId IS author.id");
	}

	function test_update_one() {
		transaction action="begin" {
			model("Author").updateOne(where = "firstName='Andy'", firstName = "Kermit", lastName = "Frog");
			allKermits = model("Author").findAll(where = "firstName='Kermit' AND lastName='Frog'");
			transaction action="rollback";
		}
		assert('allKermits.recordcount eq 1');
	}

	function test_update_one_for_soft_deleted_records() {
		transaction action="begin" {
			post = model("Post").deleteOne(where = "views=0");
			model("Post").updateOne(where = "views=0", title = "This is a new title", includeSoftDeletes = true);
			changedPosts = model("Post").findAll(where = "title='This is a new title'", includeSoftDeletes = true);
			transaction action="rollback";
		}
		assert('changedPosts.recordcount eq 1');
	}

	function test_update_by_key() {
		transaction action="begin" {
			author = model("Author").findOne();
			model("Author").updateByKey(key = author.id, firstName = "Kermit", lastName = "Frog");
			allKermits = model("Author").findAll(where = "firstName='Kermit' AND lastName='Frog'");
			transaction action="rollback";
		}
		assert('allKermits.recordcount eq 1');
	}

	function test_update_by_key_for_soft_deleted_records() {
		transaction action="begin" {
			post = model("Post").findOne(where = "views=0");
			model("Post").updateByKey(key = post.id, title = "This is a new title", includeSoftDeletes = true);
			changedPosts = model("Post").findAll(where = "title='This is a new title'", includeSoftDeletes = true);
			transaction action="rollback";
		}
		assert('changedPosts.recordcount eq 1');
	}

	function test_update_all() {
		transaction action="begin" {
			model("Author").updateAll(firstName = "Kermit", lastName = "Frog");
			allKermits = model("Author").findAll(where = "firstName='Kermit' AND lastName='Frog'");
			transaction action="rollback";
		}
		assert('allKermits.recordcount eq 10');
	}

	function test_update_all_for_soft_deleted_records() {
		transaction action="begin" {
			model("Post").updateAll(title = "This is a new title", includeSoftDeletes = true);
			changedPosts = model("Post").findAll(where = "title='This is a new title'", includeSoftDeletes = true);
			transaction action="rollback";
		}
		assert('changedPosts.recordcount eq 5');
	}

	function test_columns_that_are_not_null_should_allow_for_blank_string_during_update() {
		info = $dbinfo(datasource = application.wheels.dataSourceName, type = "version");
		db = LCase(
			Replace(
				info.database_productname,
				" ",
				"",
				"all"
			)
		);
		transaction action="begin" {
			author = model("author").findOne(where = "firstName='Tony'");
			author.lastName = "";
			author.save();
			author = model("author").findOne(where = "firstName='Tony'");
			transaction action="rollback";
		}
		assert("IsObject(author) AND !len(author.lastName)");
	}

	// Issue#1273: Added this test for includes in the updateAll function
	function test_update_all_with_include() {
		transaction action="begin"	{
			loc.query0 = model("Post").findAll(where="averagerating = '5.0'");
			assert("loc.query0.recordcount eq 0");
			loc.query1 = model("Post").updateAll(averagerating = "5.0", where = "c_o_r_e_comments.postid = '1'", include = "c_o_r_e_Comments");
			loc.query2 = model("Post").findAll(where="averagerating = '5.0'");
			transaction action="rollback";
		}
		assert("loc.query2.recordcount eq 1");
	}
}
