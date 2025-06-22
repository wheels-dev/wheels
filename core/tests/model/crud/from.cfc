component extends="wheels.tests.Test" {

	function test_from_clause() {
		result = model("author").$fromClause(include = "");
		assert("result IS 'FROM authors'");
	}

	function test_from_clause_with_mapped_table() {
		model("author").table("tbl_authors");
		result = model("author").$fromClause(include = "");
		model("author").table("authors");
		assert("result IS 'FROM tbl_authors'");
	}

	function test_from_clause_with_include() {
		result = model("author").$fromClause(include = "posts");
		assert("result IS 'FROM authors LEFT OUTER JOIN posts ON authors.id = posts.authorid AND posts.deletedat IS NULL'");
	}

	function test_$indexHint() {
		actual = model("author").$indexHint(
			useIndex = {author = "idx_authors_123"},
			modelName = "author",
			adapterName = "MySQL"
		);
		expected = "USE INDEX(idx_authors_123)";
		assert("actual EQ expected");
	}

	function test_mysql_from_clause_with_index_hint() {
		actual = model("author").$fromClause(include = "", useIndex = {author = "idx_authors_123"}, adapterName = "MySQL");
		expected = "FROM authors USE INDEX(idx_authors_123)";
		assert("actual EQ expected");
	}

	function test_sqlserver_from_clause_with_index_hint() {
		actual = model("author").$fromClause(
			include = "",
			useIndex = {author = "idx_authors_123"},
			adapterName = "SQLServer"
		);
		expected = "FROM authors WITH (INDEX(idx_authors_123))";
		assert("actual EQ expected");
	}

	function test_from_clause_with_index_hint_on_unsupportive_db() {
		actual = model("author").$fromClause(
			include = "",
			useIndex = {author = "idx_authors_123"},
			adapterName = "PostgreSQL"
		);
		expected = "FROM authors";
		assert("actual EQ expected");
	}

	function test_from_clause_with_include_and_index_hints() {
		actual = model("author").$fromClause(
			include = "posts",
			useIndex = {author = "idx_authors_123", post = "idx_posts_123"},
			adapterName = "MySQL"
		);

		expected = "FROM authors USE INDEX(idx_authors_123) LEFT OUTER JOIN posts USE INDEX(idx_posts_123) ON authors.id = posts.authorid AND posts.deletedat IS NULL";
		assert("actual EQ expected");
	}

	// TODO: test_from_clause_with_include_and_index_hints_and_table_aliases

	/*
	test:
	inner/outer join
	composite keys joining
	mapped pkeys
	*/

}
