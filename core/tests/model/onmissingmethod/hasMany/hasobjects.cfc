component extends="wheels.tests.Test" {

	function setup() {
		authorModel = model("author");
		userModel = model("user");
	}

	function test_hasObjects_valid() {
		author = authorModel.findOne(where = "firstName = 'Per'");
		hasPosts = author.hasPosts();
		assert('hasPosts eq true');
	}

	function test_hasObjects_valid_with_combi_key() {
		user = userModel.findByKey(key = 1);
		hasCombiKeys = user.hasCombiKeys();
		assert('hasCombiKeys eq true');
	}

	function test_hasObjects_returns_false() {
		author = authorModel.findOne(where = "firstName = 'James'");
		hasPosts = author.hasPosts();
		assert('hasPosts eq false');
	}

}
