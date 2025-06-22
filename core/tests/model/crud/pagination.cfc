component extends="wheels.tests.Test" {

	function setup() {
		user = model("user");
		photo = model("photo");
		gallery = model("gallery");
	}

	function test_exist_early_if_no_records_match_where_clause() {
		e = user.findAll(
			where = "firstname = 'somemoron'",
			perpage = "2",
			page = "1",
			handle = "pagination_test_1",
			order = "id"
		);
		assert('request.wheels.pagination_test_1.CURRENTPAGE eq 1');
		assert('request.wheels.pagination_test_1.TOTALPAGES eq 0');
		assert('request.wheels.pagination_test_1.TOTALRECORDS eq 0');
		assert('request.wheels.pagination_test_1.ENDROW eq 1');
		assert("e.recordcount eq 0");
	}

	function test_5_records_2_perpage_3_pages() {
		r = user.findAll(select = "id", order = "id");

		/* 1st page */
		e = user.findAll(
			select = "id",
			perpage = "2",
			page = "1",
			handle = "pagination_test_2",
			order = "id"
		);
		assert('request.wheels.pagination_test_2.CURRENTPAGE eq 1');
		assert('request.wheels.pagination_test_2.TOTALPAGES eq 3');
		assert('request.wheels.pagination_test_2.TOTALRECORDS eq 5');
		assert('request.wheels.pagination_test_2.ENDROW eq 2');
		assert("e.recordcount eq 2");
		assert('e.id[1] eq r.id[1]');
		assert('e.id[2] eq r.id[2]');

		/* 2nd page */
		e = user.findAll(
			perpage = "2",
			page = "2",
			handle = "pagination_test_3",
			order = "id"
		);
		assert('request.wheels.pagination_test_3.CURRENTPAGE eq 2');
		assert('request.wheels.pagination_test_3.TOTALPAGES eq 3');
		assert('request.wheels.pagination_test_3.TOTALRECORDS eq 5');
		assert('request.wheels.pagination_test_3.ENDROW eq 4');
		assert("e.recordcount eq 2");
		assert('e.id[1] eq r.id[3]');
		assert('e.id[2] eq r.id[4]');

		/* 3rd page */
		e = user.findAll(
			perpage = "2",
			page = "3",
			handle = "pagination_test_4",
			order = "id"
		);
		assert('request.wheels.pagination_test_4.CURRENTPAGE eq 3');
		assert('request.wheels.pagination_test_4.TOTALPAGES eq 3');
		assert('request.wheels.pagination_test_4.TOTALRECORDS eq 5');
		assert('request.wheels.pagination_test_4.ENDROW eq 5');
		assert("e.recordcount eq 1");
		assert('e.id[1] eq r.id[5]');
	}

	function test_specify_where_on_joined_table() {
		q = gallery.findOne(include = "user", where = "users.lastname = 'Petruzzi'", orderby = "id");

		/* 10 records, 2 perpage, 5 pages */
		args = {
			perpage = "2",
			page = "1",
			handle = "pagination_test",
			order = "id",
			include = "gallery",
			where = "galleryid = #q.id#"
		};

		args2 = Duplicate(args);
		StructDelete(args2, "perpage", false);
		StructDelete(args2, "page", false);
		StructDelete(args2, "handle", false);
		r = photo.findAll(argumentCollection = args2);

		/* page 1 */
		e = photo.findAll(argumentCollection = args);
		assert('e.galleryid[1] eq r.galleryid[1]');
		assert('e.galleryid[2] eq r.galleryid[2]');

		/* page 3 */
		args.page = "3";
		e = photo.findAll(argumentCollection = args);
		assert('e.galleryid[1] eq r.galleryid[5]');
		assert('e.galleryid[2] eq r.galleryid[6]');

		/* page 5 */
		args.page = "5";
		e = photo.findAll(argumentCollection = args);
		assert('e.galleryid[1] eq r.galleryid[9]');
		assert('e.galleryid[2] eq r.galleryid[10]');
	}

	function test_make_sure_that_remapped_columns_containing_desc_and_asc_work() {
		result = model("photo").findAll(
			page = 1,
			perPage = 20,
			order = 'DESCription1 DESC',
			handle = "pagination_order_test_1"
		);
		assert('request.wheels.pagination_order_test_1.CURRENTPAGE eq 1');
		assert('request.wheels.pagination_order_test_1.TOTALPAGES eq 13');
		assert('request.wheels.pagination_order_test_1.TOTALRECORDS eq 250');
		assert('request.wheels.pagination_order_test_1.ENDROW eq 20');
	}

	function test_with_renamed_primary_key() {
		photo = model("photo2").findAll(page = 1, perpage = 3, where = "DESCRIPTION1 LIKE '%test%'");
		assert('photo.recordcount eq 3');
	}

	function test_with_parameterize_set_to_false_with_string() {
		result = model("photo").findAll(
			page = 1,
			perPage = 20,
			handle = "pagination_order_test_1",
			parameterize = "false",
			where = "description1 LIKE '%photo%'"
		);
		assert('request.wheels.pagination_order_test_1.CURRENTPAGE eq 1');
		assert('request.wheels.pagination_order_test_1.TOTALPAGES eq 13');
		assert('request.wheels.pagination_order_test_1.TOTALRECORDS eq 250');
		assert('request.wheels.pagination_order_test_1.ENDROW eq 20');
	}

	function test_with_parameterize_set_to_false_with_numeric() {
		result = model("photo").findAll(
			page = 1,
			perPage = 20,
			handle = "pagination_order_test_1",
			parameterize = "false",
			where = "id = 1"
		);
		assert('request.wheels.pagination_order_test_1.CURRENTPAGE eq 1');
		assert('request.wheels.pagination_order_test_1.TOTALPAGES eq 1');
		assert('request.wheels.pagination_order_test_1.TOTALRECORDS eq 1');
		assert('request.wheels.pagination_order_test_1.ENDROW eq 1');
	}

	function test_compound_keys() {
		result = model("combikey").findAll(page = 2, perPage = 4, order = "id2");
		assert('result.recordCount eq 4');
	}

	function test_incorrect_number_of_record_returned_when_where_clause_satisfies_records_beyond_the_first_identifier_value() {
		q = model("author").findAll(
			include = "posts",
			where = "posts.views > 2",
			page = 1,
			perpage = 5
		);
		assert('q.recordcount eq 3');
	}

}
