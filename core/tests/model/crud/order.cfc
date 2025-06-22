component extends="wheels.tests.Test" {

	function test_order_with_maxrows_and_calculated_property() {
		result = model("photo").findOne(order = "DESCRIPTION1 DESC", maxRows = 1);
		assert("result.filename IS 'Gallery 9 Photo Test 9'");
	}

	function test_order_clause_no_sort() {
		result = model("author").findOne(order = "lastName");
		assert("result.lastName IS 'Amiri'");
	}

	function test_order_clause_asc_sort() {
		result = model("author").findOne(order = "lastName ASC");
		assert("result.lastName IS 'Amiri'");
	}

	function test_order_clause_desc_sort() {
		result = model("author").findOne(order = "lastName DESC");
		assert("result.lastName IS 'Riera'");
	}

	function test_order_clause_with_include() {
		result = model("post").findAll(include = "comments", order = "createdAt DESC,id DESC,name");
		assert("result['title'][1] IS 'Title for fifth test post'");
	}

	function test_order_clause_with_include_and_identical_columns() {
		result = model("post").findAll(include = "comments", order = "createdAt,createdAt");
		assert("result['title'][1] IS 'Title for first test post'");
	}

	// this ensures no "Column 'shopid' in order clause is ambiguous" exception
	function test_order_clause_with_paginated_include_and_ambiguous_columns() {
		if (get("adaptername") != "MySQL") {
			actual = model("shop").findAll(
				select = "id, name",
				include = "trucks",
				order = "CASE WHEN registration IN ('foo') THEN 0 ELSE 1 END DESC",
				page = 1,
				perPage = 3
			);
			assert("actual.recordCount gt 0");
		} else {
			// Skipping on MySQL
			assert(true);
		}
	}

	function test_order_clause_with_paginated_include_and_identical_columns() {
		if (get("adaptername") != "MySQL") {
			result = model("post").findAll(page = 1, perPage = 3, include = "comments", order = "createdAt,createdAt");
			assert("result['title'][1] IS 'Title for first test post'");
		} else {
			// Skipping on MySQL, see issue for details:
			// https://github.com/cfwheels/cfwheels/issues/666
			assert(true);
		}
	}

	function test_order_clause_with_paginated_include_and_identical_columns_desc_sort_with_specified_table_names() {
		if (get("adaptername") != "MySQL") {
			result = model("post").findAll(
				page = 1,
				perPage = 3,
				include = "comments",
				order = "posts.createdAt DESC,posts.id DESC,comments.createdAt"
			);
			assert("result['title'][1] IS 'Title for fifth test post'");
		} else {
			// Skipping on MySQL, see issue for details:
			// https://github.com/cfwheels/cfwheels/issues/666
			assert(true);
		}
	}

}