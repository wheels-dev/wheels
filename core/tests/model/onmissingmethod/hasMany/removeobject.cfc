component extends="wheels.tests.Test" {

	function setup() {
		authorModel = model("author");
	}

	function test_removeObject_valid() {
		author = authorModel.findOne(where = "firstName = 'Per'");
		post = author.findOnePost(order = "id");
		transaction action="begin" {
			updated = author.removePost(post);
			post.reload();
			assert('updated eq true');
			assert('post.authorid eq ""');
			transaction action="rollback";
		}
	}

}
