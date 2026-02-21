component extends="wheels.tests.Test" {

	function setup() {
		authorModel = model("author");
	}

	function test_deleteObject_valid() {
		author = authorModel.findOne(where = "firstName = 'Per'");
		transaction action="begin" {
			updated = author.deleteProfile();
			profile = author.profile();
			assert('updated eq true');
			assert('profile eq false');
			transaction action="rollback";
		}
	}

}
