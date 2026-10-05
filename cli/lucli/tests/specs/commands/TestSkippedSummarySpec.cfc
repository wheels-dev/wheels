/**
 * `wheels test` never reports skipped specs as passed: the summary counts them, a
 * run with skips is not green, and each distinct skip reason is listed (e.g. a
 * browser that could not run).
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.root = getTempDirectory() & "wheels-cli-skipped-" & createUUID();
		directoryCreate(variables.root & "/tests/specs", true, true);
		variables.mod = new cli.lucli.Module(cwd = variables.root);
	}

	function afterAll() {
		if (Len(variables.root) > 10 && directoryExists(variables.root)) {
			directoryDelete(variables.root, true);
		}
	}

	private struct function resultWith(required numeric pass, required numeric skipped, array suites = []) {
		return {
			totalPass = arguments.pass,
			totalFail = 0,
			totalError = 0,
			totalSkipped = arguments.skipped,
			bundlesDiscovered = 1,
			bundleStats = [{name = "tests.specs.SomeSpec", suiteStats = arguments.suites}]
		};
	}

	function run() {

		describe("$testSummaryLine with skipped specs", () => {

			it("counts skipped specs and is not green", () => {
				var line = variables.mod.$testSummaryLine(
					result = resultWith(pass = 3, skipped = 2), totalPass = 3, totalFail = 0, totalError = 0,
					duration = "", specsFailedToLoad = 0
				);
				expect(line.text).toBe("3 passed, 2 skipped");
				expect(line.color).toBe("yellow");
			});

			it("keeps the skipped count on a failing run", () => {
				var line = variables.mod.$testSummaryLine(
					result = resultWith(pass = 3, skipped = 1), totalPass = 3, totalFail = 1, totalError = 0,
					duration = "", specsFailedToLoad = 0
				);
				expect(line.text).toInclude("1 skipped");
				expect(line.color).toBe("red");
			});

			it("stays green with nothing skipped", () => {
				var line = variables.mod.$testSummaryLine(
					result = resultWith(pass = 3, skipped = 0), totalPass = 3, totalFail = 0, totalError = 0,
					duration = "", specsFailedToLoad = 0
				);
				expect(line.text).toBe("3 passed");
				expect(line.color).toBe("green");
			});

		});

		describe("$collectSkipReasons", () => {

			it("lists each distinct skip reason with the number of specs it covers", () => {
				var reasons = variables.mod.$collectSkipReasons(resultWith(pass = 1, skipped = 3, suites = [
					{
						name = "outer",
						specStats = [
							{name = "a", status = "Skipped", failMessage = "Playwright is not installed."},
							{name = "b", status = "Passed"}
						],
						suiteStats = [
							{
								name = "inner",
								specStats = [
									{name = "c", status = "Skipped", failMessage = "Playwright is not installed."},
									{name = "d", status = "Skipped", failMessage = ""}
								],
								suiteStats = []
							}
						]
					}
				]));
				expect(ArrayLen(reasons)).toBe(2);
				expect(reasons[1].message).toBe("Playwright is not installed.");
				expect(reasons[1].count).toBe(2);
				expect(reasons[2].message).toBe("(no reason given)");
				expect(reasons[2].count).toBe(1);
			});

			it("is empty when nothing was skipped", () => {
				expect(ArrayLen(variables.mod.$collectSkipReasons(resultWith(pass = 1, skipped = 0)))).toBe(0);
			});

		});

	}

}
