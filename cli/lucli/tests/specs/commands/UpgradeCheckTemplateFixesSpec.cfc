/**
 * `wheels upgrade check` names each framework fix that lives in the app-owned
 * public/Application.cfc and that the app's copy lacks. The template itself
 * passes every one; a copy with one fix's code removed is flagged for that
 * fix only; a check runs only when the target release has the fix.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.template = fileRead(expandPath("/cli/lucli/templates/app/public/Application.cfc"));
	}

	private void function seed(string version = "4.1.2") {
		directoryCreate(variables.tempRoot & "/vendor/wheels", true, true);
		fileWrite(variables.tempRoot & "/vendor/wheels/wheels.json", '{"name":"wheels","version":"' & arguments.version & '"}');
	}

	private void function app(required string content) {
		directoryCreate(variables.tempRoot & "/public", true, true);
		fileWrite(variables.tempRoot & "/public/Application.cfc", arguments.content);
	}

	private struct function runCheck(string to = "4.2.0") {
		var mod = new cli.lucli.tests._fixtures.commands.ModuleOutputCapture(cwd = variables.tempRoot);
		try {
			mod.upgrade(argumentCollection = {"arg1": "check", "to": arguments.to, "format": "json"});
		} catch (Wheels.UpgradeCheckFailed e) {
		}
		var printed = trim(mod.capturedOutput());
		return deserializeJSON(mid(printed, find("{", printed), len(printed)));
	}

	/** Descriptions of every reported finding about public/Application.cfc fixes. */
	private array function flagged(required struct report, required string bucket) {
		var hits = [];
		for (var entry in arguments.report[arguments.bucket]) {
			if (findNoCase("public/Application.cfc", entry.description) && !findNoCase("template drift", entry.description)) {
				arrayAppend(hits, entry.description);
			}
		}
		return hits;
	}

	function run() {

		describe("wheels upgrade check, public/Application.cfc fixes", () => {

			beforeEach(() => {
				variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
				seed();
			});

			afterEach(() => {
				testHelper.cleanupTempProject(variables.tempRoot);
			});

			it("passes the current template", () => {
				app(variables.template);
				var report = runCheck();
				expect(flagged(report, "breaking")).toBeEmpty();
				expect(flagged(report, "advisories")).toBeEmpty();
			});

			it("is an error when onApplicationEnd doesn't go through arguments.applicationScope", () => {
				app(replace(variables.template, "applicationScope.wo.$include", "application.wo.$include", "all"));
				var report = runCheck();
				expect(arrayToList(flagged(report, "breaking"), "|")).toInclude("onApplicationEnd()");
				expect(arrayLen(flagged(report, "advisories"))).toBe(0);
			});

			it("names the file it checked in the finding", () => {
				app(replace(variables.template, "resources/java", "resources/jar", "all"));
				var entry = {};
				for (var a in runCheck().advisories) {
					if (findNoCase("jBCrypt", a.description)) entry = a;
				}
				expect(structIsEmpty(entry)).toBeFalse();
				expect(entry.matches).toBe(["public/Application.cfc (no occurrences found)"]);
			});

			it("is an error when onSessionEnd doesn't go through arguments.applicationScope", () => {
				app(replace(variables.template, "applicationScope.wo.$simpleLock", "application.wo.$simpleLock", "all"));
				expect(arrayToList(flagged(runCheck(), "breaking"), "|")).toInclude("onSessionEnd()");
			});

			it("doesn't flag the teardown routing when onApplicationEnd isn't declared", () => {
				// No function and no routing code: nothing to fix.
				var noEnd = replace(variables.template, "function onApplicationEnd(", "function notAnAppEndHandler(", "all");
				app(replace(noEnd, "applicationScope.wo.$include", "application.wo.$include", "all"));
				expect(arrayToList(flagged(runCheck(), "breaking"), "|")).notToInclude("onApplicationEnd()");
			});

			it("doesn't flag the teardown routing when onSessionEnd isn't declared", () => {
				var noEnd = replace(variables.template, "function onSessionEnd(", "function notASessionEndHandler(", "all");
				app(replace(noEnd, "applicationScope.wo.$simpleLock", "application.wo.$simpleLock", "all"));
				expect(arrayToList(flagged(runCheck(), "breaking"), "|")).notToInclude("onSessionEnd()");
			});

			it("is advisory when onError doesn't tell a running-app error from a startup failure", () => {
				app(replace(variables.template, "startupPhase", "startupStage", "all"));
				var report = runCheck();
				expect(arrayToList(flagged(report, "advisories"), "|")).toInclude("running-app error");
				expect(flagged(report, "breaking")).toBeEmpty();
			});

			it("is advisory without the jBCrypt load path", () => {
				app(replace(variables.template, "resources/java", "resources/jar", "all"));
				expect(arrayToList(flagged(runCheck(), "advisories"), "|")).toInclude("jBCrypt");
			});

			it("only checks fixes the target release has", () => {
				app(replace(variables.template, "startupPhase", "startupStage", "all"));
				seed("4.0.6");
				var report = runCheck("4.1.0");
				expect(arrayToList(flagged(report, "advisories"), "|")).notToInclude("running-app error");
			});

			it("passes when the app has no public/Application.cfc", () => {
				if (fileExists(variables.tempRoot & "/public/Application.cfc")) {
					fileDelete(variables.tempRoot & "/public/Application.cfc");
				}
				var report = runCheck();
				expect(flagged(report, "breaking")).toBeEmpty();
			});
		});
	}
}
