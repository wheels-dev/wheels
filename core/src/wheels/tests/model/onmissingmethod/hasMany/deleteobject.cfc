component extends="wheels.tests.Test" {

	function setup() {
		authorModel = model("author");
	}

	function test_deleteObject_valid() {
		author = authorModel.findOne(where = "firstName = 'Per'");
		post = author.findOnePost(order = "id");
		transaction action="begin" {
			updated = author.deletePost(post);
			post = model("post").findByKey(key = post.id);
			assert('updated eq true');
			assert('not IsObject(post) and post eq false');
			transaction action="rollback";
		}
	}

}
