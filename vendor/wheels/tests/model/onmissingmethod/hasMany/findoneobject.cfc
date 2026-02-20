component extends="wheels.tests.Test" {

	function setup() {
		authorModel = model("author");
	}

	function test_findOneObject_valid() {
		author = authorModel.findOne(where = "firstName = 'Per'");
		post = author.findOnePost(order = "id");
		assert('IsObject(post) eq true');
	}

}
