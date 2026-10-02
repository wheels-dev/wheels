/**
 * A source checkout must not print the raw `@build.version@` token as the CLI
 * version (#3891). An unstamped module reports `<monorepo version>-dev` — the
 * same derivation FrameworkInstaller uses for the framework — read from the
 * checkout's root wheels.json, and `0.0.0-dev` (BuildInfo's sentinel) when no
 * monorepo manifest is found. A stamped release version is shown unchanged.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);
		variables.moduleDir = expandPath("/cli/lucli/");
		variables.rootVersion = deserializeJSON(fileRead(variables.moduleDir & "../../wheels.json")).version;
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {
		describe("CLI version in a source checkout", () => {

			it("an unstamped module reports the monorepo version with -dev", () => {
				expect(mod.$displayVersion("@build.version@", variables.moduleDir)).toBe(variables.rootVersion & "-dev");
			});

			it("never shows the raw build token", () => {
				expect(mod.$displayVersion("@build.version@", variables.moduleDir)).notToInclude("@build");
			});

			it("falls back to 0.0.0-dev when no monorepo manifest is found", () => {
				var lonely = getTempDirectory() & "cli-version-" & createUUID() & "/a/b/";
				directoryCreate(lonely, true, true);
				try {
					expect(mod.$displayVersion("@build.version@", lonely)).toBe("0.0.0-dev");
				} finally {
					directoryDelete(getTempDirectory() & listGetAt(replace(lonely, getTempDirectory(), ""), 1, "/"), true);
				}
			});

			it("generate auth stamps generated files with the display version, not the raw token", () => {
				var src = fileRead(variables.moduleDir & "Module.cfc");
				var at = find("scaffold.generateAuth(", src);
				expect(at).toBeGT(0);
				var call = mid(src, at, find(");", src, at) - at);
				expect(call).toInclude("cliVersion = $displayVersion()");
				expect(call).notToInclude("super.version()");
			});

			it("shows a stamped release version unchanged", () => {
				expect(mod.$displayVersion("4.1.2", variables.moduleDir)).toBe("4.1.2");
			});
		});
	}

}
