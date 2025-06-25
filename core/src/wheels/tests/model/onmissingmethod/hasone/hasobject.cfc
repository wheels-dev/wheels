component extends="wheels.tests.Test" {

	function setup() {
		authorModel = model("author");
		userModel = model("user");
	}

	function test_hasObject_valid() {
		author = authorModel.findOne(where = "firstName = 'Per'");
		hasProfile = author.hasProfile();
		assert('hasProfile eq true');
	}

	function test_hasObject_valid_with_combi_key() {
		user = userModel.findByKey(key = 1);
		hasCombiKey = user.hasCombiKey();
		assert('hasCombiKey eq true');
	}

	function test_hasObject_returns_false() {
		author = authorModel.findOne(where = "firstName = 'James'");
		hasProfile = author.hasProfile();
		assert('hasProfile eq false');
	}

}
