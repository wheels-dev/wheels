component extends="wheels.tests.Test" {

	function test_delete_all() {
		transaction action="begin" {
			model("author").deleteAll();
			allAuthors = model("author").findAll();
			transaction action="rollback";
		}
		assert("allAuthors.recordcount eq 0");
	}

	function test_soft_delete_all() {
		transaction action="begin" {
			model("post").deleteAll();
			postsWithoutSoftDeletes = model("Post").findAll();
			postsWithSoftDeletes = model("Post").findAll(includeSoftDeletes = true);
			transaction action="rollback";
		}
		assert("postsWithoutSoftDeletes.recordcount eq 0 AND postsWithSoftDeletes.recordcount eq 5");
	}

	function test_permanent_delete_all() {
		transaction action="begin" {
			model("post").deleteAll(softDelete = false);
			postsWithoutSoftDeletes = model("post").findAll();
			postsWithSoftDeletes = model("post").findAll(includeSoftDeletes = true);
			transaction action="rollback";
		}
		assert("postsWithoutSoftDeletes.recordcount eq 0 AND postsWithSoftDeletes.recordcount eq 0");
	}

	function test_permanent_delete_all_of_soft_deleted_records() {
		transaction action="begin" {
			model("post").deleteAll();
			model("post").deleteAll(includeSoftDeletes = true, softDelete = false);
			postsWithoutSoftDeletes = model("post").findAll();
			postsWithSoftDeletes = model("post").findAll(includeSoftDeletes = true);
			transaction action="rollback";
		}
		assert("postsWithoutSoftDeletes.recordcount eq 0 AND postsWithSoftDeletes.recordcount eq 0");
	}

}
