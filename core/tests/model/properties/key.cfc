component extends="wheels.tests.Test" {

	function test_pk_calculated_property_selecting_pk() {
		shop = model("Shop").findOne(select = "shopid", where = "id = 'shop1'");
		actual = shop.key();
		assert("Len(actual) gt 0");
	}

	// TODO: fix this failing test. Issue #631
	function _test_pk_calculated_property_selecting_alias() {
		shop = model("Shop").findOne(select = "id", where = "id = 'shop1'");
		actual = shop.key();
		debug("shop.properties()", false);
		assert("Len(actual) gt 0", "actual");
	}

	function test_key() {
		author = model("author").findOne();
		result = author.key();
		assert("result IS author.id");
	}

	function test_key_with_new() {
		author = model("author").new(id = 1, firstName = "Per", lastName = "Djurner");
		result = author.key();
		assert("result IS 1");
	}

	function test_return_numeric_value_if_PK_is_numeric() {
		author = model("author").findByKey(1);
		authorArr = [];

		ArrayAppend(authorArr, {"id" = author.key(), "firstname" = author.firstname, "lastname" = author.lastname});

		responseJSON = SerializeJSON(authorArr);

		assert("find('""id"":1',responseJSON)");
	}

}
