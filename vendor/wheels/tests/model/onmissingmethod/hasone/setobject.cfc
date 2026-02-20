component extends="wheels.tests.Test" {

	function setup() {
		authorModel = model("author");
	}

	function test_setObject_valid() {
		author = authorModel.findOne(where = "firstName = 'James'");
		profile = model("profile").findOne();
		transaction action="begin" {
			updated = author.setProfile(profile);
			assert('updated eq true');
			assert('profile.authorid eq author.id');
			transaction action="rollback";
		}
	}

}
