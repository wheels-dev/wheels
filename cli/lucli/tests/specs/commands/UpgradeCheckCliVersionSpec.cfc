/**
 * `wheels upgrade check --to=<version>` run by a CLI older than <version>
 * (#4154). The checks and the app template it compares against come from the
 * running CLI, so an older CLI can't know what the target release changed and
 * reported "All Clear" for an incomplete upgrade. It now says so before the
 * results and recommends upgrading the CLI first. A warning only: the result
 * and exit code don't change.
 *
 * $displayVersion() is stubbed to play an older or matching CLI; no network.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
	}

	private any function moduleWithCliVersion(required string version) {
		var m = new cli.lucli.tests._fixtures.commands.ModuleOutputCapture(cwd = variables.tempRoot);
		prepareMock(m);
		m.$("$displayVersion", arguments.version);
		return m;
	}

	/** Run the check, keeping the report even when breaking findings throw. */
	private struct function runCheck(required any m, struct args = {}) {
		var state = {threw = false};
		try {
			arguments.m.upgrade(argumentCollection = arguments.args);
		} catch (any e) {
			state.threw = true;
		}
		state.output = arguments.m.capturedOutput();
		return state;
	}

	private struct function lastJsonDocument(required string output) {
		var lines = listToArray(arguments.output, chr(10));
		for (var i = arrayLen(lines); i >= 1; i--) {
			if (left(trim(lines[i]), 1) == "{" && isJSON(lines[i])) {
				return deserializeJSON(lines[i]);
			}
		}
		return {};
	}

	function run() {

		describe("$upgradeCliBehindTarget (##4154)", () => {

			beforeEach(() => {
				variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
			});

			afterEach(() => {
				testHelper.cleanupTempProject(variables.tempRoot);
			});

			it("is true when the CLI is older than the target", () => {
				var m = moduleWithCliVersion("4.1.2");
				expect(m.$upgradeCliBehindTarget("4.1.2", "4.2.0")).toBeTrue();
				expect(m.$upgradeCliBehindTarget("4.1.2", "4.1.3")).toBeTrue();
			});

			it("is false when the CLI is the target or newer, whatever its suffix", () => {
				var m = moduleWithCliVersion("4.1.2");
				expect(m.$upgradeCliBehindTarget("4.2.0", "4.2.0")).toBeFalse();
				expect(m.$upgradeCliBehindTarget("4.2.0-dev", "4.2.0")).toBeFalse();
				expect(m.$upgradeCliBehindTarget("4.2.0-snapshot.2833", "4.2.0")).toBeFalse();
				expect(m.$upgradeCliBehindTarget("4.3.0", "4.2.0")).toBeFalse();
			});

			it("treats an unstamped or unreadable CLI version as unknown", () => {
				var m = moduleWithCliVersion("4.1.2");
				expect(m.$upgradeCliBehindTarget("0.0.0-dev", "4.2.0")).toBeFalse();
				expect(m.$upgradeCliBehindTarget("not-a-version", "4.2.0")).toBeFalse();
			});

		});

		describe("wheels upgrade check --to newer than the CLI (##4154)", () => {

			beforeEach(() => {
				variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
			});

			afterEach(() => {
				testHelper.cleanupTempProject(variables.tempRoot);
			});

			it("says the CLI is older and recommends upgrading it before the results", () => {
				var result = runCheck(moduleWithCliVersion("4.1.2"), {arg1 = "check", to = "4.2.0"});
				expect(result.output).toInclude("This CLI is 4.1.2");
				expect(result.output).toInclude("Upgrade the CLI first");
				expect(find("This CLI is 4.1.2", result.output)).toBeGT(find("Target version:  4.2.0", result.output));
			});

			it("reports the same in JSON", () => {
				var doc = lastJsonDocument(runCheck(moduleWithCliVersion("4.1.2"), {arg1 = "check", to = "4.2.0", format = "json"}).output);
				expect(doc.cliBehindTarget).toBeTrue();
				expect(doc.cliVersion).toBe("4.1.2");
				expect(arrayLen(doc.warnings)).toBe(1);
				expect(doc.warnings[1]).toInclude("Upgrade the CLI first");
			});

			it("says nothing when the CLI knows the target", () => {
				var result = runCheck(moduleWithCliVersion("4.2.0"), {arg1 = "check", to = "4.2.0"});
				expect(result.output).notToInclude("This CLI is");
				var doc = lastJsonDocument(runCheck(moduleWithCliVersion("4.2.0"), {arg1 = "check", to = "4.2.0", format = "json"}).output);
				expect(doc.cliBehindTarget).toBeFalse();
				expect(arrayLen(doc.warnings)).toBe(0);
			});

			it("doesn't change the result or the exit outcome", () => {
				var older = runCheck(moduleWithCliVersion("4.1.2"), {arg1 = "check", to = "4.2.0", format = "json"});
				var matching = runCheck(moduleWithCliVersion("4.2.0"), {arg1 = "check", to = "4.2.0", format = "json"});
				expect(older.threw).toBe(matching.threw);
				expect(lastJsonDocument(older.output).success).toBe(lastJsonDocument(matching.output).success);
			});

		});

	}

}
