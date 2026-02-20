component extends="wheels.tests.Test" {

	/* integers */

	function test_average_with_integer() {
		result = model("post").average(property = "views");
		assert("result IS 3");
	}

	function test_average_with_integer_with_non_matching_where() {
		result = model("post").average(property = "views", where = "id=0");
		assert("result IS ''");
	}

	function test_average_with_integer_with_distinct() {
		result = model("post").average(property = "views", distinct = "true");
		assert("DecimalFormat(result) IS DecimalFormat(2.50)");
	}

	function test_average_with_integer_with_ifNull() {
		result = model("post").average(property = "views", where = "id=0", ifNull = 0);
		assert("result IS 0");
	}

	/* floats */

	function test_average_with_group() {
		if (ListFindNoCase("MySQL,SQLServer", get("adaptername"))) {
			result = model("post").average(property = "averageRating", group = "authorId");
			assert("DecimalFormat(result['averageRatingAverage'][1]) IS DecimalFormat(3.40)");
		} else {
			assert(true);
		}
	}

	function test_average_with_float() {
		result = model("post").average(property = "averageRating");
		assert("DecimalFormat(result) IS DecimalFormat(3.50)");
	}

	function test_average_with_float_with_non_matching_where() {
		result = model("post").average(property = "averageRating", where = "id=0");
		assert("result IS ''");
	}

	function test_average_with_float_with_distinct() {
		result = model("post").average(property = "averageRating", distinct = "true");
		assert("DecimalFormat(result) IS DecimalFormat(3.4)");
	}

	function test_average_with_float_with_ifNull() {
		result = model("post").average(property = "averageRating", where = "id=0", ifNull = 0);
		assert("result IS 0");
	}

	/* include deleted records */

	function test_average_with_include_soft_deletes() {
		transaction action="begin" {
			post = model("Post").findOne(where = "views=0");
			post.delete(transaction = "none");
			average = model("Post").average(property = "views", includeSoftDeletes = true);
			transaction action="rollback";
		}
		assert('average eq 3');
	}

}
