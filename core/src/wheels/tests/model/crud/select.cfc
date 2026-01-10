component extends="wheels.tests.Test" {

	function test_table_name_with_star_translates_to_all_fields() {
		postModel = model("post");
		r = postModel.$createSQLFieldList(clause = "select", list = "c_o_r_e_posts.*", include = "", returnAs = "query");
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
			'columnList eq "c_o_r_e_authors.firstname,c_o_r_e_authors.id,c_o_r_e_authors.id AS authorid,c_o_r_e_authors.lastname,c_o_r_e_posts.averagerating AS postaveragerating,c_o_r_e_posts.body AS postbody,c_o_r_e_posts.createdat AS postcreatedat,c_o_r_e_posts.deletedat AS postdeletedat,c_o_r_e_posts.id AS postid,c_o_r_e_posts.title AS posttitle,c_o_r_e_posts.updatedat AS postupdatedat,c_o_r_e_posts.views AS postviews"'
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
			'columnList eq "c_o_r_e_authors.firstname,c_o_r_e_authors.id,c_o_r_e_authors.id AS authorid,c_o_r_e_authors.lastname,c_o_r_e_posts.averagerating,c_o_r_e_posts.body,c_o_r_e_posts.createdat,c_o_r_e_posts.deletedat,c_o_r_e_posts.id AS postid,c_o_r_e_posts.title,c_o_r_e_posts.updatedat,c_o_r_e_posts.views"'
		);
	}

	function test_select_argument_on_calculated_property() {
		columnList = ListSort(model("AuthorSelectArgument").findAll(returnAs = "query").columnList, "text");
		assert('columnList eq "firstname,id,lastname,selectargdefault,selectargtrue"');
	}

}