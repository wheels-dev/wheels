component extends="wheels.tests.Test" {

	function test_delete() {
		transaction action="begin" {
			local.author = model("author").findOne();
			local.author.delete();
			allAuthors = model("author").findAll();
			transaction action="rollback";
		}
		assert("allAuthors.recordcount eq 9");
	}

	function test_soft_delete() {
		transaction action="begin" {
			local.post = model("post").findOne();
			local.post.delete();
			postsWithoutSoftDeletes = model("post").findAll();
			postsWithSoftDeletes = model("post").findAll(includeSoftDeletes = true);
			transaction action="rollback";
		}
		assert("postsWithoutSoftDeletes.recordcount eq 4 AND postsWithSoftDeletes.recordcount eq 5");
	}

	function test_permanent_delete() {
		transaction action="begin" {
			local.post = model("post").findOne();
			local.post.delete(softDelete = false);
			postsWithoutSoftDeletes = model("post").findAll();
			postsWithSoftDeletes = model("post").findAll(includeSoftDeletes = true);
			transaction action="rollback";
		}
		assert("postsWithoutSoftDeletes.recordcount eq 4 AND postsWithSoftDeletes.recordcount eq 4");
	}

	function test_permanent_delete_of_soft_deleted_records() {
		transaction action="begin" {
			local.post = model("post").findOne();
			local.post.delete();
			local.softDeletedPost = model("post").findByKey(key = local.post.id, includeSoftDeletes = true);
			local.softDeletedPost.delete(includeSoftDeletes = true, softDelete = false);
			postsWithoutSoftDeletes = model("post").findAll();
			postsWithSoftDeletes = model("post").findAll(includeSoftDeletes = true);
			transaction action="rollback";
		}
		assert("postsWithoutSoftDeletes.recordcount eq 4 AND postsWithSoftDeletes.recordcount eq 4");
	}

}
