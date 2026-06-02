/**
 * Regression for issue #2840 — bare `wheels` invocation must not error
 * out with "Component [modules.wheels.Module] has no function with name [main]".
 *
 * LuCLI dispatches a no-args invocation to a `main()` subcommand on the
 * module. Without it, picocli's module router surfaces the missing-method
 * exception verbatim. `cli/lucli/Module.cfc` must expose a `main()` that
 * returns the help banner so the no-args path lands on something useful.
 *
 * Source-level scan (no Module instantiation): Module extends
 * `modules.BaseModule`, which only resolves at LuCLI runtime, so we read
 * Module.cfc as a string instead — same pattern as `UpgradeCommandSpec`
 * and `ReloadCommandSpec`.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.moduleSource = fileRead(expandPath("/cli/lucli/Module.cfc"));
	}

	function run() {

		describe("wheels (no args) — Module.main() exists", () => {

			it("declares a public main() function", () => {
				// Without this, LuCLI's dispatcher hits the missing-method
				// branch on bare `wheels` invocations.
				expect(variables.moduleSource).toMatch("public\s+(string|any)\s+function\s+main\s*\(");
			});

			it("delegates main() to showHelp() so the banner is printed", () => {
				// Locate the main() body and assert it returns showHelp().
				// Anchoring on "function main" through "}" with reFind keeps
				// the test resilient to whitespace/comment churn.
				var idx = reFindNoCase("function\s+main\s*\(", variables.moduleSource);
				expect(idx).toBeGT(0);
				var tail = mid(variables.moduleSource, idx, 400);
				expect(tail).toInclude("showHelp()");
			});

			it("hides main() from MCP tools/list", () => {
				// main() is a CLI-only no-args dispatch target. It would be
				// noise as an MCP tool — hide it via mcpHiddenTools(), same
				// convention as `mcp`, `start`, `stop`, etc.
				var idx = reFindNoCase("public\s+array\s+function\s+mcpHiddenTools\s*\(", variables.moduleSource);
				expect(idx).toBeGT(0);
				var body = mid(variables.moduleSource, idx, 800);
				expect(body).toInclude("""main""");
			});

		});

	}

}
