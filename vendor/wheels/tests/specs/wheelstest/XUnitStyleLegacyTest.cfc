component extends="wheels.WheelsTest" {

    /**
     * xUnit-style legacy bundle: deliberately has NO run() method, so TestBox
     * executes it through the UnitRunner path (the same path the legacy
     * wheels.Test / RocketUnit base used). Covers runTestMethod(), setup()/
     * teardown() invocation, and the expectedException() contract.
     *
     * Method discovery: isValidTestMethod() accepts methods that start or
     * end with "test".
     */

    variables.xunitSetupCount = 0;
    variables.xunitTeardownCount = 0;

    function setup(currentMethod = "") {
        variables.xunitSetupCount++;
    }

    function teardown(currentMethod = "") {
        variables.xunitTeardownCount++;
    }

    function test_setup_increments_per_spec() {
        assert(variables.xunitSetupCount > 0, "setup() should have run for this spec");
    }

    function test_passes_when_assertions_hold() {
        assert(2 + 2 == 4);
        assert(isBoolean(true));
    }

    function additionTest() {
        assert(1 + 1 == 2);
    }

    function test_expectedException_catches_typed_throw() {
        expectedException(type = "Wheels.LegacyExpected");
        throw(type = "Wheels.LegacyExpected", message = "expected boom");
    }

    function test_expectedException_with_regex_matches_the_message() {
        expectedException(type = "Wheels.LegacyExpectedRegex", regex = "must say .*");
        throw(type = "Wheels.LegacyExpectedRegex", message = "must say hello");
    }

}
