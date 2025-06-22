component extends="wheels.tests.Test" {

	function setup() {
		authorModel = model("author");
	}

	function test_createObject_valid() {
		author = authorModel.findOne(where = "firstName = 'James'");
		transaction action="begin" {
			post = author.createPost(title = "Title for first test post", body = "Text for first test post", views = 0);
			assert('IsObject(post) eq true');
			assert('post.authorid eq author.id');
			transaction action="rollback";
		}
	}

}
