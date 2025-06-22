component extends="wheels.tests.Test" {

	function test_maximum() {
		result = model("post").maximum(property = "views");
		assert("result IS 5");
	}

	function test_maximum_with_group() {
		if (ListFindNoCase("MySQL,SQLServer", get("adaptername"))) {
			result = model("post").maximum(property = "views", group = "authorId");
			assert("result['viewsMaximum'][1] IS 5");
		} else {
			assert(true);
		}
	}

	function test_maximum_with_where() {
		result = model("post").maximum(property = "views", where = "title LIKE 'Title%'");
		assert("result IS 5");
	}

	function test_maximum_with_non_matching_where() {
		result = model("post").maximum(property = "views", where = "id=0");
		assert("result IS ''");
	}

	function test_maximum_with_ifNull() {
		result = model("post").maximum(property = "views", where = "id=0", ifNull = 0);
		assert("result IS 0");
	}

	function test_maximum_with_include_soft_deletes() {
		transaction action="begin" {
			post = model("Post").deleteAll(where = "views=5", transaction = "none");
			maximum = model("Post").maximum(property = "views", includeSoftDeletes = true);
			transaction action="rollback";
		}
		assert('maximum eq 5');
	}

}
