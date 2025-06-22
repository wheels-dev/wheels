component extends="wheels.tests.Test" {

	function test_table_name_with_star_translates_to_all_fields() {
		postModel = model("post");
		r = postModel.$createSQLFieldList(clause = "select", list = "posts.*", include = "", returnAs = "query");
		props = postModel.$classData().properties;
		assert('ListLen(r) eq StructCount(props)');
	}

	function test_wrong_table_alias_in_select_throws_error() {
		postModel = model("post");
		raised('postModel.$createSQLFieldList(list="comments.*", include="", returnAs="query")');
	}

	function test_association_with_expanded_aliases_enabled() {
		columnList = ListSort(
			model("Author").$createSQLFieldList(
				clause = "select",
				list = "",
				include = "Posts",
				returnAs = "query",
				useExpandedColumnAliases = true
			),
			"text"
		);
		assert(
			'columnList eq "authors.firstname,authors.id,authors.id AS authorid,authors.lastname,posts.averagerating AS postaveragerating,posts.body AS postbody,posts.createdat AS postcreatedat,posts.deletedat AS postdeletedat,posts.id AS postid,posts.title AS posttitle,posts.updatedat AS postupdatedat,posts.views AS postviews"'
		);
	}

	function test_association_with_expanded_aliases_disabled() {
		columnList = ListSort(
			model("Author").$createSQLFieldList(
				clause = "select",
				list = "",
				include = "Posts",
				returnAs = "query",
				useExpandedColumnAliases = false
			),
			"text"
		);
		assert(
			'columnList eq "authors.firstname,authors.id,authors.id AS authorid,authors.lastname,posts.averagerating,posts.body,posts.createdat,posts.deletedat,posts.id AS postid,posts.title,posts.updatedat,posts.views"'
		);
	}

	function test_select_argument_on_calculated_property() {
		columnList = ListSort(model("AuthorSelectArgument").findAll(returnAs = "query").columnList, "text");
		assert('columnList eq "firstname,id,lastname,selectargdefault,selectargtrue"');
	}

}