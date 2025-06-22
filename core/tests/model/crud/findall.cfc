component extends="wheels.tests.Test" {

	function setup() {
		source = model("user").findAll(select = "id,lastName", maxRows = 3);
	}

	function test_paginated_finder_calls_with_no_records_include_column_names() {
		q = model("user").findAll(select = "id, firstName", where = "id = -1", page = 1, perPage = 10);
		assert("ListSort(q.columnList, 'text') eq 'FIRSTNAME,ID'");
	}

	function test_maxrows_change_should_break_cache() {
		$cacheQueries = application.wheels.cacheQueries;
		application.wheels.cacheQueries = true;
		q = model("user").findAll(maxrows = 1, cache = 10);
		assert('q.recordCount IS 1');
		q = model("user").findAll(maxrows = 2, cache = 10);
		assert('q.recordCount IS 2');
		application.wheels.cacheQueries = $cacheQueries;
	}

	function test_in_operator_with_quoted_strings() {
		values = QuotedValueList(source.lastName);
		q = model("user").findAll(where = "lastName IN (#values#)");
		assert('q.recordCount IS 3');
	}

	function test_in_operator_with_numbers() {
		values = ValueList(source.id);
		q = model("user").findAll(where = "id IN (#values#)");
		assert('q.recordCount IS 3');
	}

	function test_custom_query_and_orm_query_in_transaction() {
		transaction {
			actual = model("user").findAll(select = "id");
			expected = $query(datasource = application.wheels.dataSourceName, sql = "SELECT id FROM users");
		}
		assert("actual.recordCount eq expected.recordCount");
	}

	function test_in_operator_with_spaces() {
		authors = model("author").findAll(
			where = ArrayToList(
				["id != 0", "id IN (1, 2, 3)", "firstName IN ('Per', 'Tony')", "lastName IN ('Djurner', 'Petruzzi')"],
				" AND "
			)
		);

		assert("authors.recordCount eq 2");
	}

	function test_in_operator_with_spaces_and_equals_comma_value_combo_with_brackets() {
		authors = model("author").findAll(
			where = ArrayToList(["id IN (8)", "(lastName = 'Chapman, Duke of Surrey')"], " AND ")
		);
		assert("authors.recordCount eq 1");
	}

	function test_moving_aggregate_functions_in_where_to_having() {
		results1 = model("user").findAll(
			select = "state, salesTotal",
			group = "state",
			where = "salesTotal > 10",
			order = "salesTotal DESC"
		);
		assert("results1.RecordCount eq 2 AND results1['salesTotal'][1] eq 20");

		results2 = model("user").findAll(
			select = "state, salesTotal",
			group = "state",
			where = "username <> 'perd' AND salesTotal > 10",
			order = "salesTotal DESC"
		);
		assert("results2.RecordCount eq 2 AND results2['salesTotal'][1] eq 11");

		results3 = model("user").findAll(select = "state, salesTotal", group = "state", where = "salesTotal < 10");
		assert("results3.recordCount eq 1 AND results3['salesTotal'][1] eq 6");
	}

	function test_uppercase_table_name_containing_or_substring() {
		actual = model("category").findAll(where = "CATEGORIES.ID > 0");
		assert("actual.recordCount eq 2");
	}

	function test_convert_handle_to_allowed_variable() {
		actual = model("author").findAll(handle = "dot.notation test");
		assert("actual.recordCount eq 10");
	}

	function test_findall_returnas_sql() {
		actual = model("author").findAll(select = "id", returnAs = "sql");
		// remove line breaks
		actual = ReplaceList(actual, "#Chr(13)#,#Chr(10)#", " , ");
		// remove double spaces
		actual = ReplaceList(actual, "  ", " ", "all");
		// trim extra whitespace
		actual = Trim(actual);

		expected = "SELECT authors.id FROM authors";

		assert("actual eq expected");
	}
	function test_select_ambiguous_column_name_using_alias() {
		loc.query = model("Post").findAll(select = "createdat,commentcreatedat,commentbody", include = "Comments");
		loc.columnList = ListSort(loc.query.columnList, "text");
		assert('loc.columnList eq "commentbody,commentcreatedat,createdat"');
	}

	function test_select_calculated_property_when_implicitly_selecting_fields() {
		posts = model("Post").findAll(
			select = "posts.id,posts.title,posts.authorid,comments.id AS commentid,comments.name,titleAlias",
			include = "Comments"
		);
		assert("isDefined('posts.titleAlias')");
	}

}