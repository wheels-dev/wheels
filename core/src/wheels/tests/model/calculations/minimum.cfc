component extends="wheels.tests.Test" {

	function test_minimum() {
		result = model("post").minimum(property = "views");
		assert("result IS 0");
	}

	function test_minimum_with_group() {
		if (ListFindNoCase("MySQL,SQLServer", get("adaptername"))) {
			result = model("post").minimum(property = "views", group = "authorId");
			assert("result['viewsMinimum'][2] IS 2");
		} else {
			assert(true);
		}
	}

	function test_minimum_with_non_matching_where() {
		result = model("post").minimum(property = "views", where = "id=0");
		assert("result IS ''");
	}

	function test_minimum_with_ifNull() {
		result = model("post").minimum(property = "views", where = "id=0", ifNull = 0);
		assert("result IS 0");
	}

	function test_minimum_with_include_soft_deletes() {
		transaction action="begin" {
			post = model("Post").deleteAll(where = "views=0", transaction = "none");
			minimum = model("Post").minimum(property = "views", includeSoftDeletes = true);
			transaction action="rollback";
		}
		assert('minimum eq 0');
	}

}
