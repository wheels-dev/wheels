/**
 * Review finding test-infra:4 — the built-in-function branch of
 * Test.cfc's $evaluateExpression called Evaluate("expression") with the
 * literal variable name, which resolved to arguments.expression and
 * returned the expression TEXT instead of its result. The legacy
 * RocketUnit debug() helper is the only consumer; assert() evaluates
 * arguments.expression directly, so assertion correctness was unaffected.
 */
component extends="wheels.WheelsTest" {

	function run() {
		describe("RocketUnit $evaluateExpression built-in function branch", () => {

			it("returns the evaluated result, not the expression text", () => {
				var rocketUnit = CreateObject("component", "wheels.Test").init();
				// "UCase('abc')" takes the built-in-function branch: one
				// dot-part, contains "(", parenthesized args without "=".
				expect(rocketUnit.$evaluateExpression("UCase('abc')")).toBe("ABC");
			});

		});
	}

}
