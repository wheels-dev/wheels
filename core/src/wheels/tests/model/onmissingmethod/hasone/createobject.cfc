component extends="wheels.tests.Test" {

	function setup() {
		authorModel = model("author");
	}

	function test_createObject_valid() {
		author = authorModel.findOne(where = "firstName = 'James'");
		transaction action="begin" {
			profile = author.createProfile(dateOfBirth = "1/1/1970", bio = "Some profile.");
			assert('IsObject(profile) eq true');
			assert('profile.authorid eq author.id');
			transaction action="rollback";
		}
	}

}
