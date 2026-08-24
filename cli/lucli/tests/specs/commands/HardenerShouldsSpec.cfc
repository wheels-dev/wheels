/**
 * Hardener SHOULDs 4–6 (WheelsTest review slice).
 *
 * Source-scan / existence locks — no live CommandBox, no live runTests HTTP.
 * Same altitude as MainCommandSpec / TestExitFailClosedSpec.
 *
 * SHOULD 4 — guides must teach CLI fail-closed (Wheels.TestsFailed), not
 *            "no Fail/Error means exit 0" / ignore directoryRejected.
 * SHOULD 5 — legacy CommandBox cli/src test runners must not be a weaker
 *            exit path than LuCLI `wheels test` / `wheels browser test`.
 * SHOULD 6 — vendor/wheels/controllers/Tests.cfc is unrouted and must not
 *            ship; allowlisted runners stay on Public.cfc.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.repoRoot = expandPath("/cli/../");
		variables.guidesRoot = variables.repoRoot & "web/sites/guides/src/content/docs/v4-0-0/";
	}

	function run() {

		describe("SHOULD 4 — docs teach fail-closed, not silent full-suite / vacuous exit 0", () => {

			it("testing.mdx names Wheels.TestsFailed and the ##3083 honesty signals", () => {
				var src = fileRead(guidesRoot & "command-line-tools/wheels-commands/testing.mdx");
				expect(src).toInclude("Wheels.TestsFailed");
				expect(src).toInclude("directoryRejected");
				expect(src).toInclude("bundlesDiscovered");
			});

			it("running-framework-tests.mdx says wheels test throws Wheels.TestsFailed", () => {
				var src = fileRead(guidesRoot & "contributing/running-framework-tests.mdx");
				expect(src).toInclude("Wheels.TestsFailed");
			});

			it("quick-start.mdx does not teach that a run with no Fail/Error always exits 0", () => {
				var src = fileRead(guidesRoot & "command-line-tools/quick-start.mdx");
				expect(src).notToInclude("a run with no failures exits `0`");
			});

			it("running-tests-locally.mdx names Wheels.TestsFailed for the CLI path", () => {
				var src = fileRead(guidesRoot & "testing/running-tests-locally.mdx");
				expect(src).toInclude("Wheels.TestsFailed");
			});

			it("ci-integration.mdx gates the CommandBox curl example on directoryRejected / bundlesDiscovered", () => {
				var src = fileRead(guidesRoot & "testing/ci-integration.mdx");
				expect(src).toInclude("directoryRejected");
				expect(src).toInclude("bundlesDiscovered");
				expect(src).toInclude("Wheels.TestsFailed");
			});

		});

		describe("SHOULD 5 — CommandBox cli/src test runners are not a weaker exit path", () => {

			it("test/run.cfc does not swallow TestBox failing exit codes", () => {
				var src = fileRead(expandPath("/cli/src/commands/wheels/test/run.cfc"));
				expect(findNoCase("failing exit code", src)).toBe(
					0,
					"CommandBox wheels test run must not catch-and-ignore TestBox failing exit codes."
				);
			});

			it("test/all.cfc does not swallow TestBox failing exit codes", () => {
				var src = fileRead(expandPath("/cli/src/commands/wheels/test/all.cfc"));
				expect(findNoCase("failing exit code", src)).toBe(
					0,
					"CommandBox wheels test:all must not catch-and-ignore TestBox failing exit codes."
				);
			});

			it("test/unit.cfc does not swallow TestBox failing exit codes", () => {
				var src = fileRead(expandPath("/cli/src/commands/wheels/test/unit.cfc"));
				expect(findNoCase("failing exit code", src)).toBe(
					0,
					"CommandBox wheels test:unit must not catch-and-ignore TestBox failing exit codes."
				);
			});

			it("test/integration.cfc does not swallow TestBox failing exit codes", () => {
				var src = fileRead(expandPath("/cli/src/commands/wheels/test/integration.cfc"));
				expect(findNoCase("failing exit code", src)).toBe(
					0,
					"CommandBox wheels test:integration must not catch-and-ignore TestBox failing exit codes."
				);
			});

			it("browser/test.cfc refuses with a deprecation error instead of returning after Fail/Error", () => {
				var src = fileRead(expandPath("/cli/src/commands/wheels/browser/test.cfc"));
				expect(src).toInclude("DEPRECATED");
				expect(reFindNoCase("error\s*\(", src)).toBeGT(
					0,
					"CommandBox wheels browser:test must error() so the process cannot exit 0 after Fail/Error."
				);
			});

			it("legacy CommandBox test runners point operators at LuCLI wheels test", () => {
				var files = [
					"test/run.cfc",
					"test/all.cfc",
					"test/unit.cfc",
					"test/integration.cfc",
					"test/coverage.cfc",
					"test/watch.cfc",
					"browser/test.cfc"
				];
				for (var rel in files) {
					var src = fileRead(expandPath("/cli/src/commands/wheels/" & rel));
					expect(src).toInclude(
						"DEPRECATED",
						rel & " must refuse with a deprecation instead of offering a weaker exit path."
					);
					expect(src).toInclude("LuCLI");
				}
			});

		});

		describe("SHOULD 6 — orphan vendor/wheels/controllers/Tests.cfc is gone", () => {

			it("does not ship vendor/wheels/controllers/Tests.cfc", () => {
				expect(fileExists(expandPath("/vendor/wheels/controllers/Tests.cfc"))).toBeFalse(
					"Unrouted Tests.cfc is not on the ##3083 allowlisted runners; delete it rather than leave an orphan."
				);
			});

			it("allowlisted runners route to Public.cfc, not a Tests controller", () => {
				var publicRoutes = fileRead(expandPath("/vendor/wheels/public/routes.cfm"));
				var testRoutes = fileRead(expandPath("/vendor/wheels/tests/routes.cfm"));
				expect(publicRoutes).toInclude("public####tests_testbox");
				expect(publicRoutes).toInclude("wheels####public####testbox");
				expect(reFindNoCase("to\s*=\s*""Tests####", publicRoutes)).toBe(0);
				expect(reFindNoCase("to\s*=\s*""Tests####", testRoutes)).toBe(0);
			});

		});

	}

}
