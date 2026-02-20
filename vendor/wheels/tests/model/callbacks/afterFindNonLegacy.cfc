component extends="wheels.tests.Test" {

	function setup() {
		model("post").$registerCallback(type = "afterFind", methods = "afterFindCallback");
	}

	function teardown() {
		model("post").$clearCallbacks(type = "afterFind");
	}

	function test_setting_property_on_one_object() {
		post = model("post").findOne();
		assert("post.title IS 'setTitle'");
	}

	function test_setting_properties_on_multiple_objects() {
		postsOrg = model("post").findAll(returnAs = "objects", callbacks = "false", orderby = "views DESC");
		views1 = postsOrg[1].views + 100;
		views2 = postsOrg[2].views + 100;
		posts = model("post").findAll(returnAs = "objects", orderby = "views DESC");
		assert("posts[1].title IS 'setTitle'");
		assert("posts[2].title IS 'setTitle'");
		assert("posts[1].views EQ views1");
		assert("posts[2].views EQ views2");
	}

	function test_creation_of_new_column_and_property() {
		posts = model("post").findAll(order = "id DESC");
		assert("posts.something[1] eq 'hello world'");
		posts = model("post").findAll(returnAs = "objects");
		assert("posts[1].something eq 'hello world'");
	}

}
