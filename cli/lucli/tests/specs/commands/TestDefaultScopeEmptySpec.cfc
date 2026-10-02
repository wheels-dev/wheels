/**
 * `wheels test` on an app with no specs yet (issue 3921).
 *
 * A fresh `wheels new` app ships tests/specs with only .gitkeep files, so the
 * default run discovers no bundles. For the DEFAULT scope that is a notice and
 * exit 0; for a scope the user asked for (--filter, --directory, a path) it
 * stays a failure, and so does anything else that went wrong. A default run
 * that discovers no bundles while spec files DO exist on disk (the runner
 * cannot see them, e.g. a broken mapping) also stays a failure.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		// A fresh app: tests/specs holds only .gitkeep files.
		variables.emptyRoot = getTempDirectory() & "wheels-cli-no-specs-" & createUUID();
		directoryCreate(variables.emptyRoot & "/tests/specs/models", true, true);
		fileWrite(variables.emptyRoot & "/tests/specs/models/.gitkeep", "");
		variables.mod = new cli.lucli.Module(cwd = variables.emptyRoot);

		// An app whose spec files exist on disk but that the runner did not discover.
		variables.specsRoot = getTempDirectory() & "wheels-cli-unseen-specs-" & createUUID();
		directoryCreate(variables.specsRoot & "/tests/specs/models", true, true);
		fileWrite(variables.specsRoot & "/tests/specs/models/BookSpec.cfc", "component {}" & chr(10));
		variables.unseenMod = new cli.lucli.Module(cwd = variables.specsRoot);
	}

	function afterAll() {
		for (var root in [variables.emptyRoot, variables.specsRoot]) {
			if (Len(root) > 10 && directoryExists(root)) {
				directoryDelete(root, true);
			}
		}
	}

	private struct function emptyRun() {
		return {totalPass = 0, totalFail = 0, totalError = 0, bundlesDiscovered = 0, bundleStats = []};
	}

	function run() {

		describe("a default run that discovers no bundles while spec files exist on disk", () => {

			it("is not an empty default run", () => {
				expect(unseenMod.$isEmptyDefaultRun(emptyRun(), true)).toBeFalse();
			});

			it("still fails", () => {
				expect(unseenMod.$cliTestResultFailed(result = emptyRun(), defaultScope = true)).toBeTrue();
			});

			it("keeps the red no-bundles summary", () => {
				var line = unseenMod.$testSummaryLine(
					result = emptyRun(), totalPass = 0, totalFail = 0, totalError = 0,
					duration = "", specsFailedToLoad = 0, defaultScope = true
				);
				expect(line.color).toBe("red");
				expect(line.text).toInclude("no test bundles ran");
			});

			it("throws Wheels.TestsFailed", () => {
				var state = {type = ""};
				try {
					unseenMod.$throwIfCliTestsFailed(result = emptyRun(), defaultScope = true);
				} catch (any e) {
					state.type = e.type;
				}
				expect(state.type).toBe("Wheels.TestsFailed");
			});

		});

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
