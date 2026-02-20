component extends="wheels.tests.Test" {

	function setup() {
		model("post").$registerCallback(type = "afterFind", methods = "afterFindCallback");
	}

	function teardown() {
		model("post").$clearCallbacks(type = "afterFind");
	}

	function test_property_named_method_should_not_clash_with_cfinvoke() {
		results = model("collisionTest").findAll(returnAs = "objects");
		assert("results[1].method IS 'done'");
	}

	function test_setting_one_query_record() {
		posts = model("post").findAll(maxRows = 1, order = "id DESC");
		assert("posts.views[1] IS 102 AND posts['title'][1] IS 'setTitle'");
	}

	function test_setting_one_query_record_with_skipped_callback() {
		posts = model("post").findAll(maxRows = 1, order = "id DESC");
		assert("posts.views[1] IS 102 AND posts['title'][1] IS 'setTitle'");
	}

	function test_setting_multiple_query_records() {
		posts = model("post").findAll(order = "id DESC");
		assert("posts.views[1] IS 102 AND posts.views[2] IS 103 AND posts['title'][1] IS 'setTitle'");
	}

	function test_setting_multiple_query_records_with_skipped_callback() {
		posts = model("post").findAll(order = "id DESC", callbacks = false);
		assert("posts.views[1] IS '2' AND posts.views[2] IS '3' AND posts.title[1] IS 'Title for fifth test post'");
	}

	function test_setting_property_on_one_object() {
		post = model("post").findOne();
		assert("post.title IS 'setTitle'");
	}

	function test_setting_property_on_one_object_with_skipped_callback() {
		post = model("post").findOne(callbacks = false, order = "id");
		assert("post.title IS 'Title for first test post'");
	}

	function test_setting_properties_on_multiple_objects() {
		posts = model("post").findAll(returnAs = "objects");
		assert("posts[1].title IS 'setTitle' AND posts[2].title IS 'setTitle'");
	}

	function test_setting_properties_on_multiple_objects_with_skipped_callback() {
		posts = model("post").findAll(returnAs = "objects", callbacks = false, order = "id");
		assert("posts[1].title IS 'Title for first test post' AND posts[2].title IS 'Title for second test post'");
	}

	function test_creation_of_new_column_and_property() {
		posts = model("post").findAll(order = "id DESC");
		assert("posts.something[1] eq 'hello world'");
		posts = model("post").findAll(returnAs = "objects");
		assert("posts[1].something eq 'hello world'");
	}

	/* issue 329
	function test_creation_of_new_column_and_property_on_included_model() {
		posts = model("author").findAll(include="posts");
		assert("posts.something[1] eq 'hello world'");
		posts = model("author").findAll(include="posts", returnAs="objects");
		assert("posts[1].something eq 'hello world'");
	} */

	function test_getting_columns_added_when_returnAs_is_struct() {
		posts = model("post").findAll(returnAs = "struct");
		assert("posts[1].something eq 'hello world'");
	}

}
