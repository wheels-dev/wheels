/**
 * `wheels test` / `wheels browser test` must fail-closed (issue #3083).
 *
 * tools/test-local.sh and tools/ci/run-tests.sh already treat
 * directoryRejected and bundlesDiscovered=0 as exit 1. The CLI's
 * runTests() historically only OR'd totalFail + totalError, so a
 * rejected scope, a vacuous 0-bundle run, or unloadable *Spec.cfc
 * files (displayTestResults warns but does not fail) exited 0.
 * browserTest() printed Fail/Error then always returned "" (LuCLI
 * success).
 *
 * These specs lock the Module helpers that own the exit decision.
 * No live server — MigrationExitCodeSpec / TestCommandSpec pattern.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		directoryCreate(tempRoot & "/vendor/wheels", true, true);
		fileWrite(tempRoot & "/lucee.json", "{}");
		variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		describe("$cliTestResultFailed — wheels test fail-closed (##3083)", () => {

			it("flags directoryRejected: true even when totalFail/Error are 0", () => {
				expect(
					mod.$cliTestResultFailed({
						directoryRejected: true,
						totalFail: 0,
						totalError: 0,
						bundlesDiscovered: 314
					})
				).toBeTrue();
			});

			it("flags bundlesDiscovered: 0 even when totalFail/Error are 0", () => {
				expect(
					mod.$cliTestResultFailed({
						directoryRejected: false,
						totalFail: 0,
						totalError: 0,
						bundlesDiscovered: 0
					})
				).toBeTrue();
			});

			it("flags unloadable specs (specsFailedToLoad > 0) even when totalFail/Error are 0", () => {
				expect(
					mod.$cliTestResultFailed(
						result = {
							directoryRejected: false,
							totalFail: 0,
							totalError: 0,
							bundlesDiscovered: 1
						},
						specsFailedToLoad = 2
					)
				).toBeTrue();
			});

			it("flags totalFail > 0 (regression lock on the existing Fail path)", () => {
				expect(
					mod.$cliTestResultFailed({
						totalFail: 1,
						totalError: 0,
						bundlesDiscovered: 1
					})
				).toBeTrue();
			});

			it("flags totalError > 0 (regression lock on the existing Error path)", () => {
				expect(
					mod.$cliTestResultFailed({
						totalFail: 0,
						totalError: 3,
						bundlesDiscovered: 1
					})
				).toBeTrue();
			});

			it("does not flag a clean pass (no reject, bundles present, nothing unloadable, no Fail/Error)", () => {
				expect(
					mod.$cliTestResultFailed(
						result = {
							directoryRejected: false,
							totalFail: 0,
							totalError: 0,
							bundlesDiscovered: 4
						},
						specsFailedToLoad = 0
					)
				).toBeFalse();
			});

		});

		describe("$browserTestResultFailed — wheels browser test fail-closed", () => {

			it("flags totalFail > 0", () => {
				expect(
					mod.$browserTestResultFailed({
						totalPass: 0,
						totalFail: 1,
						totalError: 0
					})
				).toBeTrue();
			});

			it("flags totalError > 0", () => {
				expect(
					mod.$browserTestResultFailed({
						totalPass: 2,
						totalFail: 0,
						totalError: 1
					})
				).toBeTrue();
			});

			it("does not flag a clean pass", () => {
				expect(
					mod.$browserTestResultFailed({
						totalPass: 3,
						totalFail: 0,
						totalError: 0
					})
				).toBeFalse();
			});

		});

		describe("$throwIfCliTestsFailed — wheels test process-exit seam (##3083)", () => {

			it("throws Wheels.TestsFailed when directoryRejected: true and totalFail/Error are 0", () => {
				expect(() =>
					mod.$throwIfCliTestsFailed({
						directoryRejected: true,
						totalFail: 0,
						totalError: 0,
						bundlesDiscovered: 314
					})
				).toThrow(type = "Wheels.TestsFailed");
			});

			it("throws Wheels.TestsFailed when bundlesDiscovered: 0 and totalFail/Error are 0", () => {
				expect(() =>
					mod.$throwIfCliTestsFailed({
						directoryRejected: false,
						totalFail: 0,
						totalError: 0,
						bundlesDiscovered: 0
					})
				).toThrow(type = "Wheels.TestsFailed");
			});

			it("throws Wheels.TestsFailed when specsFailedToLoad > 0 and totalFail/Error are 0", () => {
				expect(() =>
					mod.$throwIfCliTestsFailed(
						result = {
							directoryRejected: false,
							totalFail: 0,
							totalError: 0,
							bundlesDiscovered: 1
						},
						specsFailedToLoad = 2
					)
				).toThrow(type = "Wheels.TestsFailed");
			});

			it("throws Wheels.TestsFailed when totalFail > 0", () => {
				expect(() =>
					mod.$throwIfCliTestsFailed({
						totalFail: 1,
						totalError: 0,
						bundlesDiscovered: 1
					})
				).toThrow(type = "Wheels.TestsFailed");
			});

			it("throws Wheels.TestsFailed when totalError > 0", () => {
				expect(() =>
					mod.$throwIfCliTestsFailed({
						totalFail: 0,
						totalError: 3,
						bundlesDiscovered: 1
					})
				).toThrow(type = "Wheels.TestsFailed");
			});

			it("does not throw on a clean pass", () => {
				expect(() =>
					mod.$throwIfCliTestsFailed(
						result = {
							directoryRejected: false,
							totalFail: 0,
							totalError: 0,
							bundlesDiscovered: 4
						},
						specsFailedToLoad = 0
					)
				).notToThrow();
			});

		});

		describe("$throwIfBrowserTestsFailed — wheels browser test process-exit seam", () => {

			it("throws Wheels.TestsFailed when totalFail > 0", () => {
				expect(() =>
					mod.$throwIfBrowserTestsFailed({
						totalPass: 0,
						totalFail: 1,
						totalError: 0
					})
				).toThrow(type = "Wheels.TestsFailed");
			});

			it("throws Wheels.TestsFailed when totalError > 0", () => {
				expect(() =>
					mod.$throwIfBrowserTestsFailed({
						totalPass: 2,
						totalFail: 0,
						totalError: 1
					})
				).toThrow(type = "Wheels.TestsFailed");
			});

			it("does not throw on a clean pass", () => {
				expect(() =>
					mod.$throwIfBrowserTestsFailed({
						totalPass: 3,
						totalFail: 0,
						totalError: 0
					})
				).notToThrow();
			});

		});

		describe("$testResultDiagnosticLines — runner JSON that is not a TestBox pass", () => {

			it("is empty for a clean TestBox pass (no populate/0-bundle noise)", () => {
				expect(
					arrayLen(
						mod.$testResultDiagnosticLines({
							totalPass: 12,
							totalFail: 0,
							totalError: 0,
							bundlesDiscovered: 6,
							directoryRejected: false,
							warnings: []
						})
					)
				).toBe(0);
			});

			it("surfaces populate/constructor errors that the compile-skip WARN used to hide", () => {
				var lines = mod.$testResultDiagnosticLines({
					success: false,
					error: "tests/populate.cfm failed",
					message: "Test-db migration did not complete cleanly",
					detail: "Error migrating 003",
					bundlesDiscovered: 0
				});
				var joined = arrayToList(lines, chr(10));
				expect(joined).toInclude("tests/populate.cfm failed");
				expect(joined).toInclude("Test-db migration did not complete cleanly");
				expect(joined).toInclude("Error migrating 003");
				expect(joined).toInclude("bundlesDiscovered: 0");
			});

			it("surfaces a missing test-directory mapping", () => {
				var lines = mod.$testResultDiagnosticLines({
					testDirectoryExists: false,
					testDirectoryPath: "/tmp/app/public/tests/specs",
					directoryResolved: "tests.specs",
					warnings: ["Test directory mapping 'tests.specs' expanded to '/tmp/app/public/tests/specs' which does not exist."]
				});
				var joined = arrayToList(lines, chr(10));
				expect(joined).toInclude("testDirectoryExists: false");
				expect(joined).toInclude("/tmp/app/public/tests/specs");
				expect(joined).toInclude("does not exist");
			});

		});

	}

}
