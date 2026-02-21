component extends="wheels.tests.Test" {

	function setup() {
		authorModel = model("author");
	}

	function test_newObject_valid() {
		author = authorModel.findOne(where = "firstName = 'James'");
		profile = author.newProfile();
		assert('IsObject(profile) eq true');
		assert('profile.authorid eq author.id');
	}

}
