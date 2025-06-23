component extends="wheels.tests.Test" {

	function test_table_name_with_star_translates_to_all_fields() {
		postModel = model("post");
		r = postModel.$createSQLFieldList(clause = "select", list = "_c_o_r_e_posts.*", include = "", returnAs = "query");
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
			'columnList eq "_c_o_r_e_authors.firstname,_c_o_r_e_authors.id,_c_o_r_e_authors.id AS authorid,_c_o_r_e_authors.lastname,_c_o_r_e_posts.averagerating AS postaveragerating,_c_o_r_e_posts.body AS postbody,_c_o_r_e_posts.createdat AS postcreatedat,_c_o_r_e_posts.deletedat AS postdeletedat,_c_o_r_e_posts.id AS postid,_c_o_r_e_posts.title AS posttitle,_c_o_r_e_posts.updatedat AS postupdatedat,_c_o_r_e_posts.views AS postviews"'
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
			'columnList eq "_c_o_r_e_authors.firstname,_c_o_r_e_authors.id,_c_o_r_e_authors.id AS authorid,_c_o_r_e_authors.lastname,_c_o_r_e_posts.averagerating,_c_o_r_e_posts.body,_c_o_r_e_posts.createdat,_c_o_r_e_posts.deletedat,_c_o_r_e_posts.id AS postid,_c_o_r_e_posts.title,_c_o_r_e_posts.updatedat,_c_o_r_e_posts.views"'
		);
	}

	function test_select_argument_on_calculated_property() {
		columnList = ListSort(model("AuthorSelectArgument").findAll(returnAs = "query").columnList, "text");
		assert('columnList eq "firstname,id,lastname,selectargdefault,selectargtrue"');
	}

}