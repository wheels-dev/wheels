component extends="wheels.tests.Test" {

	function setup() {
		results = {};
	}

	function test_one_value() {
		results.user = model("user").findOneByFirstname('Per');
		assert("IsObject(results.user)");
	}

	function test_explicit_arguments() {
		results.user = model("user").findOneByZipCode(value = "22222", select = "id,lastName,zipCode", order = "id");
		assert(
			"IsObject(results.user) AND results.user.lastName IS 'Peters' AND NOT StructKeyExists(results.user, 'firstName')"
		);
	}

	function test_pass_through_order() {
		results.user = model("user").findOneByIsActive(value = "1", order = "zipCode DESC");
		assert("IsObject(results.user) AND results.user.lastName IS 'Riera'");
	}

	function test_two_values() {
		results.user = model("user").findOneByFirstNameAndLastName("Per,Djurner");
		assert("IsObject(results.user) AND results.user.lastName IS 'Djurner'");
	}

	function test_two_values_with_named_arguments() {
		results.user = model("user").findOneByFirstNameAndLastName(firstName = "Per", lastName = "Djurner");
		assert("IsObject(results.user) AND results.user.lastName IS 'Djurner'");
	}

	function test_two_values_with_space() {
		results.user = model("user").findOneByFirstNameAndLastName("Per, Djurner");
		assert("IsObject(results.user) AND results.user.lastName IS 'Djurner'");
	}

	function test_two_values_with_explicit_arguments() {
		results.user = model("user").findOneByFirstNameAndLastName(values = "Per,Djurner");
		assert("IsObject(results.user) AND results.user.lastName IS 'Djurner'");
	}

	function test_text_data_type() {
		results.profile = model("profile").findOneByBio("ColdFusion Developer");
		assert("IsObject(results.profile)");
	}

	function test_unlimited_properties_for_dynamic_finders() {
		post = model("Post").findOneByTitleAndAuthoridAndViews(values = "Title for first test post|1|5", delimiter = "|");
		assert('IsObject(post)');
	}

	function test_passing_array() {
		args = ["Title for first test post", 1, 5];
		post = model("Post").findOneByTitleAndAuthoridAndViews(values = args);
		assert('IsObject(post)');
	}

	function test_can_change_delimieter_for_dynamic_finders() {
		title = "Testing to make, to make sure, commas work";
		transaction action="begin" {
			post = model("Post").findOne(where = "id = 1");
			post.title = title;
			post.save();
			post = model("Post").findOneByTitleAndAuthorid(values = "#title#|1", delimiter = "|");
			transaction action="rollback";
		}
		assert('IsObject(post)');
	}

	function test_passing_where_clause() {
		post = model("Post").findOneByTitle(value = "Title for first test post", where = "authorid = 1 AND views = 5");
		assert('IsObject(post)');
	}

	function test_can_pass_in_commas() {
		title = "Testing to make, to make sure, commas work";
		transaction action="begin" {
			post = model("Post").findOne(where = "id = 1");
			post.title = title;
			post.save();
			post = model("Post").findOneByTitle(values = "#title#");
			transaction action="rollback";
		}
		assert('IsObject(post)');
	}

}
