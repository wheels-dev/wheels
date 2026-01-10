component extends="wheels.tests.Test" {

	function test_user_setting() {
		local.oldIrregulars = application.wheels.irregulars;
		local.irregulars = local.oldIrregulars;
		StructAppend(local.irregulars, {pac = "tupac"});
		application.wheels.irregulars = local.irregulars;
		result1 = pluralize("pac");
		result2 = singularize("tupac");
		application.wheels.irregulars = local.oldIrregulars;
		assert("NOT Compare(result1, 'tupac') AND NOT Compare(result2, 'pac')");
	}

	function test_singularize() {
		result = singularize("statuses");
		assert("NOT Compare(result, 'status')");
	}

	function test_singularize_starting_with_upper_case() {
		result = singularize("Instances");
		assert("NOT Compare(result, 'Instance')");
	}

	function test_singularize_two_words() {
		result = singularize("statusUpdates");
		assert("NOT Compare(result, 'statusUpdate')");
	}

	function test_singularize_multiple_words() {
		result = singularize("fancyChristmasTrees");
		assert("NOT Compare(result, 'fancyChristmasTree')");
	}

	function test_singularize_already_singularized_camel_case() {
		result = singularize("camelCasedFailure");
		assert("NOT Compare(result, 'camelCasedFailure')");
	}

	function test_pluralize() {
		result = pluralize("status");
		assert("NOT Compare(result, 'statuses')");
	}

	function test_pluralize_with_count() {
		result = pluralize("statusUpdate", 0);
		assert("NOT Compare(result, '0 statusUpdates')");
		result = pluralize("statusUpdate", 1);
		assert("NOT Compare(result, '1 statusUpdate')");
		result = pluralize("statusUpdate", 2);
		assert("NOT Compare(result, '2 statusUpdates')");
	}

	function test_pluralize_starting_with_upper_case() {
		result = pluralize("Instance");
		assert("NOT Compare(result, 'Instances')");
	}

	function test_pluralize_two_words() {
		result = pluralize("statusUpdate");
		assert("NOT Compare(result, 'statusUpdates')");
	}

	function test_pluralize_issue_450() {
		result = pluralize("statuscode");
		assert("NOT Compare(result, 'statuscodes')");
	}

	function test_pluralize_multiple_words() {
		result = pluralize("fancyChristmasTree");
		assert("NOT Compare(result, 'fancyChristmasTrees')");
	}

	function test_hyphenize_normal_variable() {
		result = hyphenize("wheelsIsAFramework");
		assert("NOT Compare(result, 'wheels-is-a-framework')");
	}

	function test_hyphenize_variable_starting_with_uppercase() {
		result = hyphenize("WheelsIsAFramework");
		debug('result', false);
		assert("NOT Compare(result, 'wheels-is-a-framework')");
	}

	function test_hyphenize_variable_with_abbreviation() {
		result = hyphenize("aURLVariable");
		debug('result', false);
		assert("NOT Compare(result, 'a-url-variable')");
	}

	function test_hyphenize_variable_with_abbreviation_starting_with_uppercase() {
		result = hyphenize("URLVariable");
		debug('result', false);
		assert("NOT Compare(result, 'url-variable')");
	}

	function test_hyphenize_should_only_insert_hyphens_in_mixed_case() {
		result = hyphenize("ERRORMESSAGE");
		assert("NOT Compare(result, 'errormessage')");
		result = hyphenize("errormessage");
		assert("NOT Compare(result, 'errormessage')");
	}

	function test_singularize_of_address() {
		result = singularize("address");
		assert("NOT Compare(result, 'address')");
	}

}
