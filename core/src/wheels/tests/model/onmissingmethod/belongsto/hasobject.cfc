component extends="wheels.tests.Test" {

	function setup() {
		profileModel = model("profile");
		combiKeyModel = model("combiKey");
	}

	function test_hasObject_valid() {
		profile = profileModel.findByKey(key = 1);
		hasAuthor = profile.hasAuthor();
		assert('hasAuthor eq true');
	}

	function test_hasObject_valid_with_combi_key() {
		combikey = combiKeyModel.findByKey(key = "1,1");
		hasUser = combikey.hasUser();
		assert('hasUser eq true');
	}

	function test_hasObject_returns_false() {
		profile = profileModel.findByKey(key = 2);
		hasAuthor = profile.hasAuthor();
		assert('hasAuthor eq false');
	}

}
