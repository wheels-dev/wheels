/**
 * Run browser-based E2E tests.
 *
 * Pre-flight checks that Playwright JARs are installed, then hits
 * the test runner URL scoped to browser test specs.
 *
 * Examples:
 *   wheels browser:test
 *   wheels browser:test --verbose
 *   wheels browser:test --format=json
 */
component aliases="wheels browser:test, wheels browser test" extends="../base" {

	property name="browserService" inject="BrowserService@wheels-cli";

	/**
	 * @format    Output format: text or json
	 * @verbose   Show full spec names
	 * @directory Test directory (dot-notation, relative to vendor/wheels/)
	 */
	function run(
		string format = "text",
		boolean verbose = false,
		string directory = "wheels.tests.specs.wheelstest"
	) {
		error("DEPRECATED: CommandBox `wheels browser:test` is frozen and does not fail-closed. Use the LuCLI `wheels` binary (`wheels browser test`). Removal scheduled for Wheels 5.0. See cli/src/README.md.");
		return;
	}

}
