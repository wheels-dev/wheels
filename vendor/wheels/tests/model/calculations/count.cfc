component extends="wheels.tests.Test" {

	function test_count() {
		result = model("author").count();
		assert("result IS 10");
	}

	function test_count_with_group() {
		if (ListFindNoCase("MySQL,SQLServer", get("adaptername"))) {
			result = model("post").count(property = "views", group = "authorId");
			assert("result['count'][2] IS 2");
		} else {
			assert(true);
		}
	}

	function test_count_with_include() {
		result = model("author").count(include = "posts");
		assert("result IS 10");
	}

	function test_count_with_where() {
		result = model("author").count(where = "lastName = 'Djurner'");
		assert("result IS 1");
	}

	function test_count_with_non_matching_where() {
		result = model("author").count(where = "id=0");
		assert("result IS 0");
	}

	function test_count_with_non_matching_where_and_include() {
		result = model("author").count(where = "id = 0", include = "posts");
		assert("result IS 0");
	}

	function test_count_with_where_and_include() {
		result = model("author").count(where = "lastName = 'Djurner' OR lastName = 'Peters'", include = "posts");
		assert("result IS 2");
	}

	function test_count_with_where_on_included_association() {
		result = model("author").count(
			where = "title LIKE '%first%' OR title LIKE '%second%' OR title LIKE '%fourth%'",
			include = "posts"
		);
		assert("result IS 2");
	}

	function test_dynamic_count() {
		author = model("author").findOne(where = "lastName='Djurner'");
		result = author.postCount();
		assert("result IS 3");
	}

	function test_dynamic_count_with_where() {
		author = model("author").findOne(where = "lastName='Djurner'");
		result = author.postCount(where = "title LIKE '%first%' OR title LIKE '%second%'");
		assert("result IS 2");
	}

	function test_count_with_include_soft_deletes() {
		transaction action="begin" {
			post = model("Post").findOne(where = "views=0");
			post.delete(transaction = "none");
			count = model("Post").count(property = "views", includeSoftDeletes = true);
			transaction action="rollback";
		}
		assert('count eq 5');
	}

}
