component extends="wheels.tests.Test" {

	function setup() {
		authorModel = model("author");
	}

	function test_addObject_valid() {
		author = authorModel.findOne(where = "firstName = 'James'");
		post = model("post").findOne();
		transaction action="begin" {
			updated = author.addPost(post);
			assert('updated eq true');
			assert('post.authorid eq author.id');
			transaction action="rollback";
		}
	}

}
