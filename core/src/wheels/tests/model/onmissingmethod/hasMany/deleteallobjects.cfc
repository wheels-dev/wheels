component extends="wheels.tests.Test" {

	function setup() {
		authorModel = model("author");
	}

	function test_deleteAllObjects_valid() {
		author = authorModel.findOne(where = "firstName = 'Per'");
		transaction action="begin" {
			updated = author.deleteAllPosts();
			posts = author.posts();
			assert('IsNumeric(updated) and updated eq 3');
			assert('IsQuery(posts) eq true and not posts.Recordcount');
			transaction action="rollback";
		}
	}

}
