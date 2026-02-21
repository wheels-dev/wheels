component extends="wheels.tests.Test" {

	function setup() {
		authorModel = model("author");
		userModel = model("user");
	}

	function test_object_valid() {
		author = authorModel.findOne(where = "firstName = 'Per'");
		profile = author.profile();
		assert('IsObject(profile) eq true');
	}

	function test_object_valid_with_combi_key() {
		user = userModel.findByKey(key = 1);
		combiKey = user.combiKey();
		assert('IsObject(combiKey) eq true');
	}

	function test_object_returns_false() {
		author = authorModel.findOne(where = "firstName = 'James'");
		profile = author.profile();
		assert('IsObject(profile) eq false');
	}

}
