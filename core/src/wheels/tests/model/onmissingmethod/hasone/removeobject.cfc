component extends="wheels.tests.Test" {

	function setup() {
		authorModel = model("author");
	}

	function test_removeObject_valid() {
		author = authorModel.findOne(where = "firstName = 'Per'");
		profile = author.profile();
		transaction action="begin" {
			updated = author.removeProfile();
			profile.reload();
			assert('updated eq true');
			assert('profile.authorid eq ""');
			transaction action="rollback";
		}
	}

}
