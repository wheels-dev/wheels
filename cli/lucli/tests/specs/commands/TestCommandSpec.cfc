/**
 * Tests the test command via Module.cfc.
 * Verifies argument parsing for filter, reporter, db, verbose, ci, core flags.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));

		// Create vendor/wheels/tests stub so auto-detect finds core tests
		directoryCreate(tempRoot & "/vendor/wheels/tests", true, true);

		variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		// SKIPPED pending the command-by-command CLI test audit: `wheels test`
		// shells out to a *running* Wheels server (detected via lucee.json/.env
		// ports), which the stateless TestBox harness doesn't provide — every
		// case errors with "No running Wheels server detected". (Passed against a
		// local dev server but fails in CI.) The $normalizeTestFilter and
		// $resolveAppTestDataSource describes below are pure unit tests and keep
		// running. See #2829 / PR #2831.
		xdescribe("wheels test", () => {

			it("runs without error with no args", () => {
				mod.__arguments = [];
				// Will attempt to run tests and fail gracefully (no server)
				mod.test();
				expect(true).toBeTrue();
			});

			it("accepts positional filter argument", () => {
				mod.__arguments = ["model"];
				mod.test();
				expect(true).toBeTrue();
			});

			it("accepts --filter flag", () => {
				mod.__arguments = ["--filter=controller"];
				mod.test();
				expect(true).toBeTrue();
			});

			it("accepts --filter with space syntax", () => {
				mod.__arguments = ["--filter", "model"];
				mod.test();
				expect(true).toBeTrue();
			});

			it("accepts --reporter flag", () => {
				mod.__arguments = ["--reporter=simple"];
				mod.test();
				expect(true).toBeTrue();
			});

			it("accepts --db flag", () => {
				mod.__arguments = ["--db=sqlite"];
				mod.test();
				expect(true).toBeTrue();
			});

			it("accepts --verbose flag", () => {
				mod.__arguments = ["--verbose"];
				mod.test();
				expect(true).toBeTrue();
			});

			it("accepts -v shorthand", () => {
				mod.__arguments = ["-v"];
				mod.test();
				expect(true).toBeTrue();
			});

			it("accepts --ci flag", () => {
				mod.__arguments = ["--ci"];
				mod.test();
				expect(true).toBeTrue();
			});

			it("accepts --core flag", () => {
				mod.__arguments = ["--core"];
				mod.test();
				expect(true).toBeTrue();
			});

			it("accepts combined flags", () => {
				mod.__arguments = ["--filter=model", "--db=sqlite", "--verbose", "--ci"];
				mod.test();
				expect(true).toBeTrue();
			});

			it("accepts --directory flag as filter alias", () => {
				mod.__arguments = ["--directory=tests.specs.models"];
				mod.test();
				expect(true).toBeTrue();
			});

			it("accepts --directory with space syntax", () => {
				mod.__arguments = ["--directory", "tests.specs.browser"];
				mod.test();
				expect(true).toBeTrue();
			});

		});

		describe("$normalizeTestFilter (app mode)", () => {

			it("returns empty string for empty input", () => {
				expect(mod.$normalizeTestFilter("")).toBe("");
			});

			it("returns empty for whitespace-only input", () => {
				expect(mod.$normalizeTestFilter("   ")).toBe("");
			});

			it("prefixes a bare directory name with tests.specs.", () => {
				expect(mod.$normalizeTestFilter("browser")).toBe("tests.specs.browser");
				expect(mod.$normalizeTestFilter("models")).toBe("tests.specs.models");
				expect(mod.$normalizeTestFilter("controllers")).toBe("tests.specs.controllers");
			});

			it("passes through fully-qualified app paths unchanged", () => {
				expect(mod.$normalizeTestFilter("tests.specs")).toBe("tests.specs");
				expect(mod.$normalizeTestFilter("tests.specs.browser")).toBe("tests.specs.browser");
				expect(mod.$normalizeTestFilter("tests.specs.models.UserSpec")).toBe("tests.specs.models.UserSpec");
			});

			it("trims surrounding whitespace before normalizing", () => {
				expect(mod.$normalizeTestFilter("  browser  ")).toBe("tests.specs.browser");
			});

		});

		describe("$normalizeTestFilter (core mode)", () => {

			it("prefixes bare names with wheels.tests.specs.", () => {
				expect(mod.$normalizeTestFilter("model", true)).toBe("wheels.tests.specs.model");
				expect(mod.$normalizeTestFilter("security", true)).toBe("wheels.tests.specs.security");
			});

			it("passes through fully-qualified core paths unchanged", () => {
				expect(mod.$normalizeTestFilter("wheels.tests.specs", true)).toBe("wheels.tests.specs");
				expect(mod.$normalizeTestFilter("wheels.tests.specs.model", true)).toBe("wheels.tests.specs.model");
			});

			it("passes through vendor package paths unchanged", () => {
				expect(mod.$normalizeTestFilter("vendor.wheels-sentry.tests", true)).toBe("vendor.wheels-sentry.tests");
				expect(mod.$normalizeTestFilter("vendor.wheels-basecoat.tests.specs", true)).toBe("vendor.wheels-basecoat.tests.specs");
			});

			it("does not prefix app-style paths in core mode", () => {
				// Bare `tests.specs.foo` is an app-style path; core mode
				// rejects it as bare and prefixes — runner.cfm regex won't
				// accept it either way, so prefixing is at least consistent.
				expect(mod.$normalizeTestFilter("tests.specs.foo", true)).toBe("wheels.tests.specs.tests.specs.foo");
			});

		});

		describe("$resolveAppTestDataSource (issue 2489)", () => {

			it("returns (unknown) when neither .env nor settings.cfm define a datasource", () => {
				var sandbox = $scaffold(settingsBody = "");
				var localMod = new cli.lucli.Module(cwd = sandbox);
				expect(localMod.$resolveAppTestDataSource(true)).toBe("(unknown)");
				$tearDown(sandbox);
			});

			it("appends _test to dataSourceName from config/settings.cfm when useTestDB is true", () => {
				var sandbox = $scaffold(settingsBody = 'set(dataSourceName="myapp");');
				var localMod = new cli.lucli.Module(cwd = sandbox);
				expect(localMod.$resolveAppTestDataSource(true)).toBe("myapp_test");
				$tearDown(sandbox);
			});

			it("returns base unchanged when useTestDB is false", () => {
				var sandbox = $scaffold(settingsBody = 'set(dataSourceName="myapp");');
				var localMod = new cli.lucli.Module(cwd = sandbox);
				expect(localMod.$resolveAppTestDataSource(false)).toBe("myapp");
				$tearDown(sandbox);
			});

			it("does NOT pick up coreTestDataSourceName as if it were dataSourceName", () => {
				// Reporter's exact configuration: only coreTestDataSourceName is
				// set. The previous regex matched the trailing dataSourceName
				// substring and produced `testappdb_test_test`. After the fix
				// we should fall through to (unknown) because no real
				// `dataSourceName` is configured.
				var sandbox = $scaffold(settingsBody = 'set(coreTestDataSourceName="testappdb_test");');
				var localMod = new cli.lucli.Module(cwd = sandbox);
				expect(localMod.$resolveAppTestDataSource(true)).toBe("(unknown)");
				$tearDown(sandbox);
			});

			it("ignores commented-out dataSourceName lines", () => {
				var body =
					"// set(dataSourceName=" & chr(34) & "commented_out" & chr(34) & ");" & chr(10) &
					"set(dataSourceName=" & chr(34) & "actualapp" & chr(34) & ");";
				var sandbox = $scaffold(settingsBody = body);
				var localMod = new cli.lucli.Module(cwd = sandbox);
				expect(localMod.$resolveAppTestDataSource(true)).toBe("actualapp_test");
				$tearDown(sandbox);
			});

			it("ignores dataSourceName inside CFML block comments", () => {
				var body =
					"/* set(dataSourceName=" & chr(34) & "blocked" & chr(34) & "); */" & chr(10) &
					"set(dataSourceName=" & chr(34) & "active" & chr(34) & ");";
				var sandbox = $scaffold(settingsBody = body);
				var localMod = new cli.lucli.Module(cwd = sandbox);
				expect(localMod.$resolveAppTestDataSource(true)).toBe("active_test");
				$tearDown(sandbox);
			});

			it("ignores dataSourceName inside tag-style CFML comments", () => {
				var body =
					"<!--- set(dataSourceName=" & chr(34) & "blocked" & chr(34) & "); --->" & chr(10) &
					"set(dataSourceName=" & chr(34) & "tagactive" & chr(34) & ");";
				var sandbox = $scaffold(settingsBody = body);
				var localMod = new cli.lucli.Module(cwd = sandbox);
				expect(localMod.$resolveAppTestDataSource(true)).toBe("tagactive_test");
				$tearDown(sandbox);
			});

			it("does not double-append _test when dataSourceName already ends with _test", () => {
				// Defensive guard: even if the user's app datasource happens to
				// be named `myapp_test`, surfacing `myapp_test_test` in the
				// preamble is more confusing than helpful.
				var sandbox = $scaffold(settingsBody = 'set(dataSourceName="myapp_test");');
				var localMod = new cli.lucli.Module(cwd = sandbox);
				expect(localMod.$resolveAppTestDataSource(true)).toBe("myapp_test");
				$tearDown(sandbox);
			});

			it("prefers .env DATASOURCE_NAME over config/settings.cfm", () => {
				var sandbox = $scaffold(
					settingsBody = 'set(dataSourceName="from_settings");',
					envBody      = "DATASOURCE_NAME=from_env"
				);
				var localMod = new cli.lucli.Module(cwd = sandbox);
				expect(localMod.$resolveAppTestDataSource(true)).toBe("from_env_test");
				$tearDown(sandbox);
			});

			it("does NOT match a .env key whose name ends in DATASOURCE_NAME", () => {
				// Pre-fix, the .env matcher had no start-of-line anchor, so
				// `MY_DATASOURCE_NAME=wrongkey` false-matched on its trailing
				// DATASOURCE_NAME substring. With (?:^|\n) anchoring it doesn't.
				var sandbox = $scaffold(envBody = "MY_DATASOURCE_NAME=wrongkey");
				var localMod = new cli.lucli.Module(cwd = sandbox);
				expect(localMod.$resolveAppTestDataSource(true)).toBe("(unknown)");
				$tearDown(sandbox);
			});

		});

		describe("$normalizeBasePath (issue 3026)", () => {

			it("returns empty string for empty or whitespace input", () => {
				expect(mod.$normalizeBasePath("")).toBe("");
				expect(mod.$normalizeBasePath("   ")).toBe("");
			});

			it("adds a leading slash when missing", () => {
				expect(mod.$normalizeBasePath("myapp")).toBe("/myapp");
			});

			it("leaves an already-leading-slash value intact", () => {
				expect(mod.$normalizeBasePath("/myapp")).toBe("/myapp");
			});

			it("strips a single trailing slash", () => {
				expect(mod.$normalizeBasePath("/myapp/")).toBe("/myapp");
				expect(mod.$normalizeBasePath("myapp/")).toBe("/myapp");
			});

			it("strips multiple trailing slashes", () => {
				expect(mod.$normalizeBasePath("/myapp///")).toBe("/myapp");
			});

			it("treats a bare root slash as no prefix", () => {
				expect(mod.$normalizeBasePath("/")).toBe("");
			});

		});

		describe("$buildTestRunnerPath (issue 3026)", () => {

			it("returns the root-mounted app path when no base path is given", () => {
				expect(mod.$buildTestRunnerPath(false, "")).toBe("/wheels/app/tests");
			});

			it("returns the root-mounted core path when coreTests is true", () => {
				expect(mod.$buildTestRunnerPath(true, "")).toBe("/wheels/core/tests");
			});

			it("prefixes the base path onto the app runner path", () => {
				expect(mod.$buildTestRunnerPath(false, "/myapp")).toBe("/myapp/wheels/app/tests");
			});

			it("prefixes the base path onto the core runner path", () => {
				expect(mod.$buildTestRunnerPath(true, "/myapp")).toBe("/myapp/wheels/core/tests");
			});

			it("normalizes an un-normalized base path before prefixing", () => {
				expect(mod.$buildTestRunnerPath(false, "myapp/")).toBe("/myapp/wheels/app/tests");
			});

		});

		describe("$resolveTestBasePath (issue 3026)", () => {

			it("returns empty when no flag, env, or subpath setting is present", () => {
				var sandbox = $scaffold(settingsBody = "");
				var localMod = new cli.lucli.Module(cwd = sandbox);
				expect(localMod.$resolveTestBasePath("")).toBe("");
				$tearDown(sandbox);
			});

			it("normalizes and returns an explicit flag value", () => {
				var sandbox = $scaffold(settingsBody = "");
				var localMod = new cli.lucli.Module(cwd = sandbox);
				expect(localMod.$resolveTestBasePath("wheelsproject1/")).toBe("/wheelsproject1");
				$tearDown(sandbox);
			});

			it("derives the base path from set(subpath=...) in config/settings.cfm", () => {
				var sandbox = $scaffold(settingsBody = 'set(subpath="/myapp");');
				var localMod = new cli.lucli.Module(cwd = sandbox);
				expect(localMod.$resolveTestBasePath("")).toBe("/myapp");
				$tearDown(sandbox);
			});

			it("normalizes a derived subpath lacking a leading slash", () => {
				var sandbox = $scaffold(settingsBody = 'set(subpath="myapp");');
				var localMod = new cli.lucli.Module(cwd = sandbox);
				expect(localMod.$resolveTestBasePath("")).toBe("/myapp");
				$tearDown(sandbox);
			});

			it("lets an explicit flag win over a settings-derived subpath", () => {
				var sandbox = $scaffold(settingsBody = 'set(subpath="/fromsettings");');
				var localMod = new cli.lucli.Module(cwd = sandbox);
				expect(localMod.$resolveTestBasePath("/fromflag")).toBe("/fromflag");
				$tearDown(sandbox);
			});

			it("ignores a commented-out subpath setting", () => {
				var body =
					"// set(subpath=" & chr(34) & "/commented" & chr(34) & ");" & chr(10) &
					"set(subpath=" & chr(34) & "/active" & chr(34) & ");";
				var sandbox = $scaffold(settingsBody = body);
				var localMod = new cli.lucli.Module(cwd = sandbox);
				expect(localMod.$resolveTestBasePath("")).toBe("/active");
				$tearDown(sandbox);
			});

		});

		describe("test command base-path wiring (issue 3026)", () => {

			it("exposes --base-path on the test ArgSpec and MCP tool schema", () => {
				var schema = mod.mcpToolSpecs()["test"];
				expect(schema.properties).toHaveKey("base-path");
			});

		});

		describe("--ci annotation builder ($buildCiAnnotations, issue 3113)", () => {

			it("returns an empty array when nothing failed", () => {
				var anns = mod.$buildCiAnnotations($passingResult());
				expect(anns).toBeArray();
				expect(arrayLen(anns)).toBe(0);
			});

			it("emits one ::error annotation per failed and errored spec", () => {
				var anns = mod.$buildCiAnnotations($mixedResult());
				expect(arrayLen(anns)).toBe(2);
				var joined = arrayToList(anns, chr(10));
				expect(joined).toInclude("::error ");
				expect(joined).toInclude("fails a thing");
				expect(joined).toInclude("expected true to be false");
				expect(joined).toInclude("errors a thing");
				expect(joined).toInclude("boom NPE");
			});

			it("encodes newlines and percent signs in the annotation message", () => {
				var result = $failingResult("line1" & chr(10) & "50% off");
				var anns = mod.$buildCiAnnotations(result);
				expect(anns[1]).toInclude("line1%0A");
				expect(anns[1]).toInclude("50%25 off");
				// The raw newline must not survive — annotations are single-line.
				expect(anns[1]).notToInclude(chr(10));
			});

		});

		describe("--ci / --verbose observable output (issue 3113)", () => {

			it("a plain run prints neither a per-spec tree nor CI annotations", () => {
				var cap = new cli.lucli.tests._fixtures.commands.ModuleOutputCapture(cwd = variables.tempRoot);
				var printed = cap.renderResults($passingResult(), false, false);
				expect(printed).notToInclude("[PASS]");
				expect(printed).notToInclude("::error");
			});

			it("--verbose prints per-spec PASS lines", () => {
				var cap = new cli.lucli.tests._fixtures.commands.ModuleOutputCapture(cwd = variables.tempRoot);
				var printed = cap.renderResults($passingResult(), true, false);
				expect(printed).toInclude("[PASS]");
				expect(printed).toInclude("passes a thing");
			});

			it("--ci prints GitHub Actions error annotations for failures", () => {
				var cap = new cli.lucli.tests._fixtures.commands.ModuleOutputCapture(cwd = variables.tempRoot);
				var printed = cap.renderResults($mixedResult(), false, true);
				expect(printed).toInclude("::error");
				expect(printed).toInclude("fails a thing");
			});

		});

	}

	/**
	 * A TestBox result memento where every spec passed. Shaped like the
	 * JSONReporter getMemento() the CLI deserializes from /wheels/*/tests.
	 */
	private struct function $passingResult() {
		return {
			totalPass: 1, totalFail: 0, totalError: 0, totalDuration: 12,
			bundleStats: [{
				name: "tests.specs.FooSpec",
				suiteStats: [{
					name: "Foo feature",
					status: "Passed",
					specStats: [{ name: "passes a thing", status: "Passed" }],
					suiteStats: []
				}]
			}]
		};
	}

	/**
	 * A result with one pass, one failure, and one error spec.
	 */
	private struct function $mixedResult() {
		return {
			totalPass: 1, totalFail: 1, totalError: 1, totalDuration: 34,
			bundleStats: [{
				name: "tests.specs.FooSpec",
				suiteStats: [{
					name: "Foo feature",
					status: "Failed",
					specStats: [
						{ name: "passes a thing", status: "Passed" },
						{ name: "fails a thing", status: "Failed", failMessage: "expected true to be false" },
						{ name: "errors a thing", status: "Error", error: { message: "boom NPE" } }
					],
					suiteStats: []
				}]
			}]
		};
	}

	/**
	 * A result with a single failure carrying the given fail message — used
	 * to exercise annotation message encoding.
	 */
	private struct function $failingResult(required string failMessage) {
		return {
			totalPass: 0, totalFail: 1, totalError: 0, totalDuration: 5,
			bundleStats: [{
				name: "tests.specs.FooSpec",
				suiteStats: [{
					name: "Foo feature",
					status: "Failed",
					specStats: [{ name: "fails a thing", status: "Failed", failMessage: arguments.failMessage }],
					suiteStats: []
				}]
			}]
		};
	}

	/**
	 * Build an isolated temp project rooted under /tmp so each spec can
	 * lay down its own config/settings.cfm and .env without polluting the
	 * suite-level fixture. Returns the temp root path.
	 */
	private string function $scaffold(
		string settingsBody = "",
		string envBody = ""
	) {
		var tempBase = getTempDirectory() & "wheels-cli-resolver-" & createUUID();
		directoryCreate(tempBase & "/config", true, true);
		directoryCreate(tempBase & "/vendor/wheels", true, true);

		var nl = chr(10);
		var settingsContent = "<cfscript>" & nl & arguments.settingsBody & nl & "</cfscript>" & nl;
		fileWrite(tempBase & "/config/settings.cfm", settingsContent);

		if (Len(arguments.envBody)) {
			fileWrite(tempBase & "/.env", arguments.envBody & nl);
		}

		return tempBase;
	}

	private void function $tearDown(required string tempRoot) {
		if (Len(arguments.tempRoot) > 10 && directoryExists(arguments.tempRoot)) {
			directoryDelete(arguments.tempRoot, true);
		}
	}

}
