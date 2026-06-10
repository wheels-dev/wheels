/**
 * Covers cli.lucli.services.ArgSpec::toArgv() — the passthrough that rebuilds
 * an ordered argv array from LuCLI's structured argCollection. This logic used
 * to live in Module.cfc::argsFromCollection(); it moved to ArgSpec.toArgv when
 * the last argv round-trip call sites were migrated (#2861).
 *
 * Issue #2855: LuCLI converts `--no-sqlite` on the command line into
 * `sqlite=false` in the argCollection it passes to module subcommands. An
 * earlier argsFromCollection silently dropped any `false` entry, so
 * `wheels new myapp --no-sqlite` (and every other `--no-*` flag the CLI honors,
 * e.g. `--no-open-browser`, `--no-routes`, `--no-test-db`) never reached the
 * command-level parser and the user's negation was lost. The reporter confirmed
 * `--nosqlite` (no hyphen) was unaffected because LuCLI does not strip a leading
 * `no` that lacks the hyphen.
 *
 * toArgv re-emits `--no-<key>` for `false` values so the user's negation token
 * reaches the command's literal-token matcher.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {

		describe("ArgSpec.toArgv", () => {

			describe("LuCLI-converted negated flags (--no-X -> X=false)", () => {

				it("re-emits --no-sqlite when LuCLI passes sqlite=false (issue ##2855)", () => {
					var rebuilt = new cli.lucli.services.ArgSpec().toArgv({
						"arg1": "myapp",
						"sqlite": "false"
					});
					expect(rebuilt).toInclude("--no-sqlite");
				});

				it("re-emits --no-open-browser when LuCLI passes open-browser=false", () => {
					var rebuilt = new cli.lucli.services.ArgSpec().toArgv({
						"arg1": "myapp",
						"open-browser": "false"
					});
					expect(rebuilt).toInclude("--no-open-browser");
				});

				it("re-emits --no-routes when LuCLI passes routes=false (wheels g admin)", () => {
					var rebuilt = new cli.lucli.services.ArgSpec().toArgv({
						"arg1": "User",
						"routes": "false"
					});
					expect(rebuilt).toInclude("--no-routes");
				});

				it("re-emits --no-test-db when LuCLI passes test-db=false (wheels test)", () => {
					var rebuilt = new cli.lucli.services.ArgSpec().toArgv({
						"test-db": "false"
					});
					expect(rebuilt).toInclude("--no-test-db");
				});

			});

			describe("non-negated flags continue to round-trip", () => {

				it("preserves boolean-true flags as bare --key", () => {
					var rebuilt = new cli.lucli.services.ArgSpec().toArgv({
						"arg1": "myapp",
						"setup-h2": "true"
					});
					expect(rebuilt).toInclude("--setup-h2");
				});

				it("preserves value flags as --key=value", () => {
					var rebuilt = new cli.lucli.services.ArgSpec().toArgv({
						"arg1": "myapp",
						"port": "3000"
					});
					expect(rebuilt).toInclude("--port=3000");
				});

				it("preserves positional args in arg1..argN order", () => {
					var rebuilt = new cli.lucli.services.ArgSpec().toArgv({
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
