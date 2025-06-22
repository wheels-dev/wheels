component extends="wheels.tests.Test" {

	function setup() {
		results = {};
	}

	function test_save_null_strings() {
		transaction {
			results.author = model("author").create(firstName = "Null", lastName = "Null");
			assert("IsObject(results.author)");
			transaction action="rollback";
		}
	}

	function test_auto_incrementing_primary_key_should_be_set() {
		transaction {
			results.author = model("author").create(firstName = "Test", lastName = "Test");
			assert(
				"IsObject(results.author) AND StructKeyExists(results.author, results.author.primaryKey()) AND IsNumeric(results.author[results.author.primaryKey()])"
			);
			transaction action="rollback";
		}
	}

	function test_non_auto_incrementing_primary_key_should_not_be_changed() {
		transaction {
			results.shop = model("shop").create(ShopId = 99, CityCode = 99, Name = "Test");
			assert(
				"IsObject(results.shop) AND StructKeyExists(results.shop, results.shop.primaryKey()) AND results.shop[results.shop.primaryKey()] IS 99"
			);
			transaction action="rollback";
		}
	}

	function test_composite_key_values_should_be_set_when_they_both_exist() {
		transaction {
			results.city = model("city").create(citycode = 99, id = "z", name = "test");
			assert("results.city.citycode IS 99 AND results.city.id IS 'z'");
			transaction action="rollback";
		}
	}

	function test_columns_that_are_not_null_should_allow_for_blank_string_during_create() {
		info = $dbinfo(datasource = application.wheels.dataSourceName, type = "version");
		db = LCase(
			Replace(
				info.database_productname,
				" ",
				"",
				"all"
			)
		);
		author = model("author").create(firstName = "Test", lastName = "", transaction = "rollback");
		assert("IsObject(author) AND !len(author.lastName)");
	}

	function test_saving_a_new_model_without_properties_should_not_throw_errors() {
		transaction action="begin" {
			model = model("tag").new();
			str = raised('model.save(reload=true)');
			assert('str eq ""');
			transaction action="rollback";
		}
	}

}
