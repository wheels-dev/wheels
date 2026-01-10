component extends="wheels.tests.Test" {

	function setup() {
		user = model("user");
		shop = model("shop");
		isACF2016 = application.wheels.serverName == "Adobe Coldfusion" && application.wheels.serverVersionMajor == 2016;
		isACF2018 = application.wheels.serverName == "Adobe Coldfusion" && application.wheels.serverVersionMajor == 2018;
		isACF2021 = application.wheels.serverName == "Adobe Coldfusion" && application.wheels.serverVersionMajor == 2021;
		isACF2023 = application.wheels.serverName == "Adobe Coldfusion" && application.wheels.serverVersionMajor == 2023;
	}

	function test_select_distinct_addresses() {
		q = user.findAll(select = "address", distinct = "true", order = "address");
		assert('q.recordcount eq 4');
		e = "123 Petruzzi St.|456 Peters Dr.|789 Djurner Ave.|987 Riera Blvd.";
		r = ValueList(q.address, "|");
		assert('e eq r');
	}

	function test_select_users_groupby_address() {
		q = user.findAll(select = "address", group = "address", order = "address", result = "result");
		assert('q.recordcount eq 4');
		e = "123 Petruzzi St.|456 Peters Dr.|789 Djurner Ave.|987 Riera Blvd.";
		r = ValueList(q.address, "|");
		assert('e eq r');
	}

	function test_findByKey() {
		e = user.findOne(where = "lastname = 'Petruzzi'");
		q = user.findByKey(e.id);
		assert('q.id eq e.id');
	}

	function test_findByKey_returns_object_when_key_has_leading_space() {
		e = shop.findByKey(" shop6");
		assert('isobject(e)');
	}

	function test_findByKey_returns_false_when_record_not_found() {
		q = user.findByKey(999999999);
		assert('q eq false');
	}

	function test_findByKey_returns_false_when_passed_blank_string() {
		q = user.findByKey("");
		assert('q eq false');
	}

	function test_findByKey_returns_empty_query_when_record_not_found_with_return_as_equal_query() {
		q = user.findByKey(key = 999999999, returnAs = "query");
		assert('q.RecordCount eq false');
	}

	function test_findOne() {
		e = user.findOne(where = "lastname = 'Petruzzi'");
		assert('isobject(e)');
	}

	function test_findOne_returns_false_when_record_not_found() {
		e = user.findOne(where = "lastname = 'somenamenotfound'");
		assert('e eq false');
	}

	function test_findOne_returns_empty_query_when_record_not_found_with_return_as_equal_query() {
		e = user.findOne(where = "lastname = 'somenamenotfound'", returnAs = "query");
		assert('e.RecordCount eq false');
	}

	function test_findOne_returns_false_when_record_not_found_with_inner_join_include() {
		e = user.findOne(where = "lastname= = 'somenamenotfound'", include = "galleries");
		assert('e eq false');
	}

	function test_findOne_returns_false_when_record_not_found_with_outer_join_include() {
		e = user.findOne(where = "lastname= = 'somenamenotfound'", include = "outerjoinphotogalleries");
		assert('e eq false');
	}

	function test_findAll() {
		q = user.findAll();
		assert('q.recordcount eq 5');
		q = user.findAll(where = "lastname = 'Petruzzi' OR lastname = 'Peters'", order = "lastname");
		assert('q.recordcount eq 2');
		assert('valuelist(q.lastname) eq "peters,Petruzzi"');
	}

	function test_findAllByXXX() {
		q = user.findAllByZipcode(value = "22222", order = "id");
		assert('q.recordcount eq 2');
		q = user.findAllByZipcode(value = "11111", order = "id");
		assert('q.recordcount eq 1');
		q = user.findAllByZipcode(zipCode = "11111");
		assert('q.recordcount eq 1');
		q = user.findAllByZipcode("11111");
		assert('q.recordcount eq 1');
		q = user.findAllByZipcodeAndBirthDayMonth(values = "22222,11");
		assert('q.recordcount eq 1');
		q = user.findAllByZipcodeAndBirthDayMonth(zipCode = "22222", birthDayMonth = "11");
		assert('q.recordcount eq 1');
	}

	function test_findByKey_norecords_returns_correct_type() {
		q = user.findByKey("0");
		debug('q', false);
		assert('isboolean(q) and q eq false');

		q = user.findByKey(key = "0", returnas = "query");
		debug('q', false);
		assert('isquery(q) and q.recordcount eq 0');

		q = user.findByKey(key = "0", returnas = "object");
		debug('q', false);
		assert('isboolean(q) and q eq false');

		/* read when we have implemented the code to throw an error when an incorrect returnAs value is passed in
		q = raised('user.findByKey(key="0", returnas="objects")');
		r = "Wheels.IncorrectArgumentValue";
		debug('q', false);
		assert('q eq r'); */
	}

	function test_findOne_norecords_returns_correct_type() {
		q = user.findOne(where = "id = 0");
		debug('q', false);
		assert('isboolean(q) and q eq false');

		q = user.findOne(where = "id = 0", returnas = "query");
		debug('q', false);
		assert('isquery(q) and q.recordcount eq 0');

		q = user.findOne(where = "id = 0", returnas = "object");
		debug('q', false);
		assert('isboolean(q) and q eq false');

		/* read when we have implemented the code to throw an error when an incorrect returnAs value is passed in
		q = raised('user.findOne(where="id = 0", returnas="objects")');
		r = "Wheels.IncorrectArgumentValue";
		debug('q', false);
		assert('q eq r'); */
	}

	function test_findAll_returnAs_query_noRecords_returns_correct_type() {
		q = user.findAll(where = "id = 0", returnas = "query");
		debug('q', false);
		assert('isquery(q) and q.recordcount eq 0');
	}

	function test_findAll_returnAs_structs_noRecords_returns_correct_type() {
		q = user.findAll(where = "id = 0", returnAs = "structs");
		debug('q', false);
		assert('isarray(q) and arrayisempty(q)');
	}

	function test_findAll_returnAs_objects_noRecords_returns_correct_type() {
		q = user.findAll(where = "id = 0", returnas = "objects");
		debug('q', false);
		assert('isarray(q) and arrayisempty(q)');
	}

	function test_findAll_returnAs_invalid_throws_error() {
		q = raised('user.findAll(where="id = 1", returnas="notvalid")');
		r = "Wheels.IncorrectArgumentValue";
		debug('q', false);
		assert('q eq r');
	}

	function test_findAll_supports_inbuilt_returnType() {
		// returnType wasn't supported until ACF2021
		if (isACF2016 || isACF2018 || isACF2021 || isACF2023) {
			return;
		}
		actual = user.findAll(returnType = "struct", keyColumn = "id");

		assert('IsStruct(actual)');
		assert("IsStruct(actual['1'])");
	}

	function test_findAll_inbuilt_returnType_takes_precedence_over_returnAs() {
		if (isACF2016 || isACF2018 || isACF2021 || isACF2023) {
			return;
		}
		actual = user.findAll(returnType = "array", returnAs = "query");
		assert('IsArray(actual)');
	}

	function test_exists_by_key_valid() {
		e = user.findOne(where = "lastname = 'Petruzzi'");
		r = user.exists(e.id);
		assert('r eq true');
	}

	function test_exists_by_key_invalid() {
		r = user.exists(0);
		assert('r eq false');
	}

	function test_exists_by_where_one_record_valid() {
		r = user.exists(where = "lastname = 'Petruzzi'");
		assert('r eq true');
	}

	function test_exists_by_where_one_record_invalid() {
		r = user.exists(where = "lastname = 'someoneelse'");
		assert('r eq false');
	}

	function test_exists_by_where_two_records_valid() {
		r = user.exists(where = "zipcode = '22222'");
		assert('r eq true');
	}

	function test_exists_any_record() {
		r = user.exists();
		assert('r eq true');
	}

	function test_exists_no_records() {
		transaction action="begin" {
			user.deleteAll();
			r = user.exists();
			transaction action="rollback";
		}
		assert('r eq false');
	}

	function test_allow_negative_values_in_where_clause() {
		r = user.exists(where = "id = -1");
		assert('r eq false');
	}

	function test_findByKey_with_include_soft_deletes() {
		transaction action="begin" {
			post1 = model("Post").findOne();
			post1.delete(transaction = "none");
			post2 = model("Post").findByKey(key = post1.id, includeSoftDeletes = true);
			transaction action="rollback";
		}
		assert('IsObject(post2) is true');
	}

	function test_findOne_with_include_soft_deletes() {
		transaction action="begin" {
			post1 = model("Post").findOne();
			post1.delete(transaction = "none");
			post2 = model("Post").findOne(where = "id=#post1.id#", includeSoftDeletes = true);
			transaction action="rollback";
		}
		assert('IsObject(post2) is true');
	}

	function test_findAll_with_include_soft_deletes() {
		transaction action="begin" {
			model("Post").deleteAll();
			allPosts = model("Post").findAll(includeSoftDeletes = true);
			transaction action="rollback";
		}
		assert('allPosts.recordcount eq 5');
	}

	function test_findOne_returns_empty_array_for_included_model_when_none_exist() {
		e = model("author").findOne(where = "lastname = 'Bellenie'", include = "posts");
		assert('IsArray(e.posts) && ArrayIsEmpty(e.posts)');
	}

	function test_findAll_with_softdeleted_associated_rows() {
		transaction action="begin" {
			model("Post").deleteAll();
			posts = model("Author").findByKey(key = 1, include = "Posts", returnAs = "query");
			transaction action="rollback";
		}
		assert('posts.recordcount eq 1');
	}

}
