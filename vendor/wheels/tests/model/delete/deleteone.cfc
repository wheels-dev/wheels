component extends="wheels.tests.Test" {

	function test_permanent_delete_by_key_of_soft_deleted_records() {
		transaction action="begin" {
			local.post = model("post").findOne();
			model("post").deleteOne(where = "id = #local.post.id#");
			model("post").deleteOne(where = "id = #local.post.id#", includeSoftDeletes = true, softDelete = false);
			postsWithoutSoftDeletes = model("post").findAll();
			postsWithSoftDeletes = model("post").findAll(includeSoftDeletes = true);
			transaction action="rollback";
		}
		assert("postsWithoutSoftDeletes.recordcount eq 4 AND postsWithSoftDeletes.recordcount eq 4");
	}

	function test_delete_one() {
		transaction action="begin" {
			model("author").deleteOne();
			allAuthors = model("author").findAll();
			transaction action="rollback";
		}
		assert("allAuthors.recordcount eq 9");
	}

	function test_soft_delete_one() {
		transaction action="begin" {
			model("post").deleteOne();
			postsWithoutSoftDeletes = model("post").findAll();
			postsWithSoftDeletes = model("post").findAll(includeSoftDeletes = true);
			transaction action="rollback";
		}
		assert("postsWithoutSoftDeletes.recordcount eq 4 AND postsWithSoftDeletes.recordcount eq 5");
	}

	function test_permanent_delete_one() {
		transaction action="begin" {
			model("post").deleteOne(softDelete = false);
			postsWithoutSoftDeletes = model("post").findAll();
			postsWithSoftDeletes = model("post").findAll(includeSoftDeletes = true);
			transaction action="rollback";
		}
		assert("postsWithoutSoftDeletes.recordcount eq 4 AND postsWithSoftDeletes.recordcount eq 4");
	}

	function test_permanent_delete_one_of_soft_deleted_records() {
		transaction action="begin" {
			local.post = model("post").findOne();
			model("post").deleteOne(where = "id = #local.post.id#");
			model("post").deleteOne(where = "id = #local.post.id#", includeSoftDeletes = true, softDelete = false);
			postsWithoutSoftDeletes = model("post").findAll();
			postsWithSoftDeletes = model("post").findAll(includeSoftDeletes = true);
			transaction action="rollback";
		}
		assert("postsWithoutSoftDeletes.recordcount eq 4 AND postsWithSoftDeletes.recordcount eq 4");
	}

}
