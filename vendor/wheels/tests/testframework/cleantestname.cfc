component extends="wheels.tests.Test" {

	function setup() {
		expected = "Actual equals expected";
	}

	// not testing case sensitivity

	function test_$cleantestname_with_underscores_returns_expected_value() {
		actual = $cleanTestName("test_actual_equals_expected");
		assert("actual eq expected");
	}

	function test_$cleantestname_with_hyphens_returns_expected_value() {
		actual = $cleanTestName("test_actual-equals-expected");
		assert("actual eq expected");
	}

	function test_$cleantestname_with_camelcase_returns_expected_value() {
		actual = $cleanTestName("test_actualEqualsExpected");
		assert("actual eq expected");
	}

}
