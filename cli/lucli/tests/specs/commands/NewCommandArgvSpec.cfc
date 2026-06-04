/**
 * Covers Module.cfc::argsFromCollection() — the helper that rebuilds an
 * argv array from LuCLI's argCollection struct.
 *
 * Issue #2855: LuCLI converts `--no-sqlite` on the command line into
 * `sqlite=false` in the argCollection it passes to module subcommands.
 * The previous argsFromCollection silently dropped any `false` entry,
 * so `wheels new myapp --no-sqlite` (and every other `--no-*` flag the
 * CLI honors, e.g. `--no-open-browser`, `--no-routes`, `--no-test-db`)
 * never reached the command-level parser and the user's negation was
 * lost. The reporter confirmed `--nosqlite` (no hyphen) was unaffected
 * because LuCLI does not strip a leading `no` that lacks the hyphen.
 *
 * The fix re-emits `--no-<key>` for `false` values so the user's
 * negation token reaches the command's literal-token matcher.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));

		// Module init walks up looking for vendor/wheels — give it a stub so
		// resolveProjectRoot() lands on our temp directory deterministically.
		directoryCreate(variables.tempRoot & "/vendor/wheels", true, true);

		variables.probe = new cli.lucli.tests._fixtures.commands.ModuleArgvProbe(
			cwd = variables.tempRoot
		);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		describe("argsFromCollection", () => {

			describe("LuCLI-converted negated flags (--no-X -> X=false)", () => {

				it("re-emits --no-sqlite when LuCLI passes sqlite=false (issue ##2855)", () => {
					var rebuilt = probe.$argsFromCollection({
						"arg1": "myapp",
						"sqlite": "false"
					});
					expect(rebuilt).toInclude("--no-sqlite");
				});

				it("re-emits --no-open-browser when LuCLI passes open-browser=false", () => {
					var rebuilt = probe.$argsFromCollection({
						"arg1": "myapp",
						"open-browser": "false"
					});
					expect(rebuilt).toInclude("--no-open-browser");
				});

				it("re-emits --no-routes when LuCLI passes routes=false (wheels g admin)", () => {
					var rebuilt = probe.$argsFromCollection({
						"arg1": "User",
						"routes": "false"
					});
					expect(rebuilt).toInclude("--no-routes");
				});

				it("re-emits --no-test-db when LuCLI passes test-db=false (wheels test)", () => {
					var rebuilt = probe.$argsFromCollection({
						"test-db": "false"
					});
					expect(rebuilt).toInclude("--no-test-db");
				});

			});

			describe("non-negated flags continue to round-trip", () => {

				it("preserves boolean-true flags as bare --key", () => {
					var rebuilt = probe.$argsFromCollection({
						"arg1": "myapp",
						"setup-h2": "true"
					});
					expect(rebuilt).toInclude("--setup-h2");
				});

				it("preserves value flags as --key=value", () => {
					var rebuilt = probe.$argsFromCollection({
						"arg1": "myapp",
						"port": "3000"
					});
					expect(rebuilt).toInclude("--port=3000");
				});

				it("preserves positional args in arg1..argN order", () => {
					var rebuilt = probe.$argsFromCollection({
						"arg1": "first",
						"arg2": "second",
						"arg3": "third"
					});
					expect(rebuilt[1]).toBe("first");
					expect(rebuilt[2]).toBe("second");
					expect(rebuilt[3]).toBe("third");
				});

			});

		});

	}

}
