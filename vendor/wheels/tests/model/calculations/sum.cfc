component extends="wheels.tests.Test" {

	function test_sum() {
		result = model("post").sum(property = "views");
		assert("result IS 15");
	}

	function test_sum_with_group() {
		if (ListFindNoCase("MySQL,SQLServer", get("adaptername"))) {
			result = model("post").sum(property = "views", group = "authorId");
			assert("result['viewsSum'][2] IS 5");
		} else {
			assert(true);
		}
	}

	function test_sum_with_group_on_associated_model() {
		if (ListFindNoCase("MySQL,SQLServer", get("adaptername"))) {
			result = model("post").sum(property = "views", include = "author", group = "lastName");
			assert("result['viewsSum'][2] IS 5");
		} else {
			assert(true);
		}
	}

	function test_sum_with_group_on_calculated_property() {
		if (ListFindNoCase("MySQL,SQLServer", get("adaptername"))) {
			result = model("photo").sum(property = "galleryId", group = "DESCRIPTION1");
			assert("result.recordcount IS 250");
		} else {
			assert(true);
		}
	}

	function test_sum_with_group_on_calculated_property_on_associated_model() {
		if (ListFindNoCase("MySQL,SQLServer", get("adaptername"))) {
			result = model("gallery").sum(property = "userId", include = "photos", group = "DESCRIPTION1");
			assert("result.recordcount IS 250");
		} else {
			assert(true);
		}
	}

	function test_sum_with_where() {
		author = model("author").findOne(where = "lastName='Djurner'");
		result = model("post").sum(property = "views", where = "authorid=#author.id#");
		assert("result IS 10");
	}

	function test_sum_with_non_matching_where() {
		result = model("post").sum(property = "views", where = "id=0");
		assert("result IS ''");
	}

	function test_sum_with_distinct() {
		result = model("post").sum(property = "views", distinct = true);
		assert("result IS 10");
	}

	function test_sum_with_ifNull() {
		result = model("post").sum(property = "views", where = "id=0", ifNull = 0);
		assert("result IS 0");
	}

	function test_sum_with_include_soft_deletes() {
		transaction action="begin" {
			post = model("Post").deleteAll(transaction = "none");
			sum = model("Post").sum(property = "views", includeSoftDeletes = true);
			transaction action="rollback";
		}
		assert('sum eq 15');
	}

}