component extends="wheels.tests.Test" {

	function test_delete_by_key() {
		transaction action="begin" {
			local.author = model("author").findOne();
			model("author").deleteByKey(local.author.id);
			allAuthors = model("author").findAll();
			transaction action="rollback";
		}
		assert("allAuthors.recordcount eq 9");
	}

	function test_soft_delete_by_key() {
		transaction action="begin" {
			local.post = model("post").findOne();
			model("post").deleteByKey(local.post.id);
			postsWithoutSoftDeletes = model("post").findAll(includeSoftDeletes = false);
			postsWithSoftDeletes = model("post").findAll(includeSoftDeletes = true);
			transaction action="rollback";
		}
		assert("postsWithoutSoftDeletes.recordcount eq 4 AND postsWithSoftDeletes.recordcount eq 5");
	}

	function test_permanent_delete_by_key() {
		transaction action="begin" {
			local.post = model("post").findOne();
			model("post").deleteByKey(key = local.post.id, softDelete = false);
			postsWithoutSoftDeletes = model("post").findAll();
			postsWithSoftDeletes = model("post").findAll(includeSoftDeletes = true);
			transaction action="rollback";
		}
		assert("postsWithoutSoftDeletes.recordcount eq 4 AND postsWithSoftDeletes.recordcount eq 4");
	}

}
