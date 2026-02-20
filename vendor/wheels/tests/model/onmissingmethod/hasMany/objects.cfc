component extends="wheels.tests.Test" {

	function setup() {
		authorModel = model("author");
		userModel = model("user");
	}

	function test_objects_returns_query() {
		author = authorModel.findOne(where = "firstName = 'Per'");
		posts = author.posts();
		assert('IsQuery(posts) eq true');
		assert('posts.Recordcount');
	}

	function test_objects_valid_with_combi_key() {
		user = userModel.findByKey(key = 1);
		combiKeys = user.combiKeys();
		assert('IsQuery(combiKeys) eq true');
		assert('combiKeys.Recordcount');
	}

	function test_objects_returns_empty_query() {
		author = authorModel.findOne(where = "firstName = 'James'");
		posts = author.posts();
		assert('IsQuery(posts) eq true');
		assert('not posts.Recordcount');
	}

	function test_pagination_with_blank_where() {
		author = authorModel.findOne(where = "firstName = 'Per'");
		posts = author.posts(where = "", page = 1, perPage = 2);
		assert('posts.Recordcount IS 2');
	}

}
