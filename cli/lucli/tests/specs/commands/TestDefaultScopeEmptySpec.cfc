/**
 * `wheels test` on an app with no specs yet (issue 3921).
 *
 * A fresh `wheels new` app ships tests/specs with only .gitkeep files, so the
 * default run discovers no bundles. For the DEFAULT scope that is a notice and
 * exit 0; for a scope the user asked for (--filter, --directory, a path) it
 * stays a failure, and so does anything else that went wrong.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.mod = new cli.lucli.Module(cwd = getTempDirectory());
	}

	private struct function emptyRun() {
		return {totalPass = 0, totalFail = 0, totalError = 0, bundlesDiscovered = 0, bundleStats = []};
	}

	function run() {

		describe("$cliTestResultFailed and the default scope", () => {

			it("fails a scope the user asked for that discovered no bundles", () => {
				expect(mod.$cliTestResultFailed(result = emptyRun())).toBeTrue();
				expect(mod.$cliTestResultFailed(result = emptyRun(), defaultScope = false)).toBeTrue();
			});

			it("passes the default scope when it discovered no bundles and nothing went wrong", () => {
				expect(mod.$cliTestResultFailed(result = emptyRun(), defaultScope = true)).toBeFalse();
			});

			it("still fails the default scope when something else went wrong", () => {
				var rejected = emptyRun();
				rejected.directoryRejected = true;
				expect(mod.$cliTestResultFailed(result = rejected, defaultScope = true)).toBeTrue();

				var errored = emptyRun();
				errored.totalError = 1;
				expect(mod.$cliTestResultFailed(result = errored, defaultScope = true)).toBeTrue();

				expect(mod.$cliTestResultFailed(result = emptyRun(), specsFailedToLoad = 1, defaultScope = true)).toBeTrue();
				expect(mod.$cliTestResultFailed(result = {success = false, error = "populate failed"}, defaultScope = true)).toBeTrue();
				expect(mod.$cliTestResultFailed(result = {message = "no counts"}, defaultScope = true)).toBeTrue();
			});

		});

		describe("$isEmptyDefaultRun", () => {

			it("is true only for a clean, empty run of the default scope", () => {
				expect(mod.$isEmptyDefaultRun(emptyRun(), true)).toBeTrue();
				expect(mod.$isEmptyDefaultRun(emptyRun(), false)).toBeFalse();
				var ran = emptyRun();
				ran.bundlesDiscovered = 3;
				ran.totalPass = 7;
				expect(mod.$isEmptyDefaultRun(ran, true)).toBeFalse();
				var rejected = emptyRun();
				rejected.directoryRejected = true;
				expect(mod.$isEmptyDefaultRun(rejected, true)).toBeFalse();
				expect(mod.$isEmptyDefaultRun({totalPass = 0}, true)).toBeFalse();
				expect(mod.$isEmptyDefaultRun("not a result", true)).toBeFalse();
			});

		});

		describe("$testSummaryLine for an app with no specs yet", () => {

			it("prints a yellow notice for the default scope", () => {
				var line = mod.$testSummaryLine(
					result = emptyRun(), totalPass = 0, totalFail = 0, totalError = 0,
					duration = "", specsFailedToLoad = 0, defaultScope = true
				);
				expect(line.color).toBe("yellow");
				expect(line.text).toInclude("No specs yet");
				expect(line.text).toInclude("wheels generate test");
			});

			it("keeps the red no-bundles summary for a scope the user asked for", () => {
				var line = mod.$testSummaryLine(
					result = emptyRun(), totalPass = 0, totalFail = 0, totalError = 0,
					duration = "", specsFailedToLoad = 0
				);
				expect(line.color).toBe("red");
				expect(line.text).toInclude("no test bundles ran");
			});

		});

		describe("$throwIfCliTestsFailed exit code", () => {

			it("does not throw for an empty default run", () => {
				var state = {type = ""};
				try {
					mod.$throwIfCliTestsFailed(result = emptyRun(), defaultScope = true);
				} catch (any e) {
					state.type = e.type;
				}
				expect(state.type).toBe("");
			});

			it("throws Wheels.TestsFailed for an empty run of a scope the user asked for", () => {
				var state = {type = ""};
				try {
					mod.$throwIfCliTestsFailed(result = emptyRun());
				} catch (any e) {
					state.type = e.type;
				}
				expect(state.type).toBe("Wheels.TestsFailed");
			});

		});

	}

}
