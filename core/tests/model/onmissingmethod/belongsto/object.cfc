component extends="wheels.tests.Test" {

	function setup() {
		profileModel = model("profile");
		combiKeyModel = model("combiKey");
	}

	function test_object_valid() {
		profile = profileModel.findByKey(key = 1);
		author = profile.author();
		assert("IsObject(author) eq true");
	}

	function test_object_valid_with_combi_key() {
		combikey = combiKeyModel.findByKey(key = "1,1");
		user = combikey.user();
		assert('IsObject(user) eq true');
	}

	function test_object_returns_false() {
		profile = profileModel.findByKey(key = 2);
		author = profile.author();
		assert("IsObject(author) eq false");
	}

}
