component extends="wheels.tests.Test" {

	function test_from_clause() {
		result = model("author").$fromClause(include = "");
		assert("result IS 'FROM _c_o_r_e_authors'");
	}

	function test_from_clause_with_mapped_table() {
		model("author").table("tbl_authors");
		result = model("author").$fromClause(include = "");
		model("author").table("_c_o_r_e_authors");
		assert("result IS 'FROM tbl_authors'");
	}

	function test_from_clause_with_include() {
		result = model("author").$fromClause(include = "posts");
		assert("result IS 'FROM _c_o_r_e_authors LEFT OUTER JOIN _c_o_r_e_posts ON _c_o_r_e_authors.id = _c_o_r_e_posts.authorid AND _c_o_r_e_posts.deletedat IS NULL'");
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
		expected = "FROM _c_o_r_e_authors USE INDEX(idx_authors_123)";
		assert("actual EQ expected");
	}

	function test_sqlserver_from_clause_with_index_hint() {
		actual = model("author").$fromClause(
			include = "",
			useIndex = {author = "idx_authors_123"},
			adapterName = "SQLServer"
		);
		expected = "FROM _c_o_r_e_authors WITH (INDEX(idx_authors_123))";
		assert("actual EQ expected");
	}

	function test_from_clause_with_index_hint_on_unsupportive_db() {
		actual = model("author").$fromClause(
			include = "",
			useIndex = {author = "idx_authors_123"},
			adapterName = "PostgreSQL"
		);
		expected = "FROM _c_o_r_e_authors";
		assert("actual EQ expected");
	}

	function test_from_clause_with_include_and_index_hints() {
		actual = model("author").$fromClause(
			include = "posts",
			useIndex = {author = "idx_authors_123", post = "idx_posts_123"},
			adapterName = "MySQL"
		);

		expected = "FROM _c_o_r_e_authors USE INDEX(idx_authors_123) LEFT OUTER JOIN _c_o_r_e_posts USE INDEX(idx_posts_123) ON _c_o_r_e_authors.id = _c_o_r_e_posts.authorid AND _c_o_r_e_posts.deletedat IS NULL";
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
