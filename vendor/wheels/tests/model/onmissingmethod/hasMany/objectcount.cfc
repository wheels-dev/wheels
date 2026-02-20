component extends="wheels.tests.Test" {

	function setup() {
		authorModel = model("author");
		userModel = model("user");
	}

	function test_objectCount_valid() {
		author = authorModel.findOne(where = "firstName = 'Per'");
		postCount = author.postCount();
		assert('postCount eq 3');
	}

	function test_objectCount_valid_with_combi_key() {
		user = userModel.findByKey(key = 1);
		combiKeyCount = user.combiKeyCount();
		assert('combiKeyCount eq 5');
	}

	function test_objectCount_returns_zero() {
		author = authorModel.findOne(where = "firstName = 'James'");
		postCount = author.postCount();
		assert('postCount eq 0');
	}

}
