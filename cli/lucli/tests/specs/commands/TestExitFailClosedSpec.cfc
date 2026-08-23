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

	}

}
