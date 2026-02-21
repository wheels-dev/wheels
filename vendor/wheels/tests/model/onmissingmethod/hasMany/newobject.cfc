component extends="wheels.tests.Test" {

	function setup() {
		authorModel = model("author");
	}

	function test_newObject_valid() {
		author = authorModel.findOne(where = "firstName = 'James'");
		post = author.newPost();
		assert('IsObject(post) eq true');
		assert('post.authorid eq author.id');
	}

}
