component extends="wheels.tests.Test" {

	function test_normal_variable() {
		result = humanize("wheelsIsAFramework");
		assert("NOT Compare(result, 'Wheels Is A Framework')");
	}

	function test_unchanged() {
		result = humanize("Website (SP Referral)");
		assert("NOT Compare(result, 'Website (SP Referral)')");
		result = humanize("Moto-Type");
		assert("NOT Compare(result, 'Moto-Type')");
		result = humanize("All AIMS users");
		assert("NOT Compare(result, 'All AIMS users')");
		result = humanize("FTRI staff");
		assert("NOT Compare(result, 'FTRI staff')");
	}

	function test_variable_starting_with_uppercase() {
		result = humanize("WheelsIsAFramework");
		assert("NOT Compare(result, 'Wheels Is A Framework')");
	}

	function test_abbreviation() {
		result = humanize("CFML");
		assert("NOT Compare(result, 'CFML')");
	}

	function test_abbreviation_as_exception() {
		result = humanize(text = "ACfmlFramework", except = "CFML");
		assert("NOT Compare(result, 'A CFML Framework')");
	}

	function test_exception_within_string() {
		result = humanize(text = "ACfmlFramecfmlwork", except = "CFML");
		assert("NOT Compare(result, 'A CFML Framecfmlwork')");
	}

	function test_abbreviation_without_exception_cannot_be_done() {
		result = humanize("wheelsIsACFMLFramework");
		assert("NOT Compare(result, 'Wheels Is ACFML Framework')");
	}

	function test_issue_663() {
		result = humanize("Some Input");
		assert("NOT Compare(result, 'Some Input')");
	}

}
