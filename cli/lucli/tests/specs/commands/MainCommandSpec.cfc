/**
 * Regression for issue #2840 — bare `wheels` invocation must not error
 * out with "Component [modules.wheels.Module] has no function with name [main]".
 *
 * LuCLI's parseArguments() defaults the subcommand to "main" whenever no
 * positional subcommand is supplied (LuceeScriptEngine.java), so a bare
 * `wheels` dispatches to a main() function on the module. Every well-formed
 * LuCLI module defines one — the built-in `lang` module and the `template`
 * that scaffolds new modules both do. The wheels module was the outlier;
 * without main() picocli's router surfaces the missing-method exception
 * verbatim. `cli/lucli/Module.cfc` must expose a main() that returns the help
 * banner so the no-args path lands on something useful.
 *
 * TWO TEST ALTITUDES cover this fix:
 *   1. THIS spec — a source scan. Module extends `modules.BaseModule`, a
 *      CLI-runtime mapping that is NOT resolvable in the TestBox server
 *      context (the test Application.cfc maps `modules.wheels` but not the
 *      BaseModule parent), so we cannot instantiate Module here. Same
 *      constraint as `UpgradeCommandSpec` and `ReloadCommandSpec`.
 *   2. A bare `wheels` invocation through the LuCLI launcher (verified by
 *      hand during the fix) prints the help banner with no dispatch error —
 *      the end-to-end path this source scan can only approximate.
 *
 * The scan is comment-aware via LINE-ANCHORING rather than comment-stripping:
 * `(?m)^[ \t]*public ... function main` only matches a declaration that
 * starts a line, so a commented-out `// public ... main()` or a ` * ...`
 * docblock line cannot satisfy it. This is the cheap, robust way to honor
 * CLAUDE.md anti-pattern #14 / the PR #2595 lesson — an earlier revision
 * stripped comments with a global `reReplace(.../[\s\S]*?...)` which hung the
 * Lucee 7 CLI suite (catastrophic backtracking over the large module source).
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.source = fileRead(expandPath("/cli/lucli/Module.cfc"));
	}

	function run() {

		describe("wheels (no args) — Module.main() dispatch target", () => {

			it("declares a public main() function", () => {
				// Line-anchored: a real declaration starts a line (after
				// indentation); a commented-out `// public ... main()` or a
				// ` * ...` docblock line does not. So this won't false-green
				// on commented-out code, without scanning the whole file.
				expect(reFindNoCase("(?m)^[ \t]*public\s+(string|any)\s+function\s+main\s*\(", variables.source)).toBeGT(0);
			});

			it("delegates main() to showHelp() so the banner is printed", () => {
				// Isolate main()'s body (declaration through its first closing
				// brace) and assert it calls showHelp().
				var startIdx = reFindNoCase("(?m)^[ \t]*public\s+(string|any)\s+function\s+main\s*\(", variables.source);
				expect(startIdx).toBeGT(0);
				var rest = mid(variables.source, startIdx, 200);
				var braceAt = find("}", rest);
				// Guard Left(str, 0) — it crashes Lucee 7 (cross-engine #8).
				var body = braceAt > 0 ? left(rest, braceAt) : rest;
				expect(body).toInclude("showHelp");
			});

			it("delegates to a showHelp() that actually emits the help banner", () => {
				// Guards against main() delegating to a stub: showHelp() must be
				// declared AND build the real banner, so the no-args path yields
				// help text rather than an empty string.
				expect(reFindNoCase("(?m)^[ \t]*public\s+string\s+function\s+showHelp\s*\(", variables.source)).toBeGT(0);
				expect(variables.source).toInclude("Wheels CLI ");
			});

			it("hides main() from MCP tools/list", () => {
				// main() is a CLI-only no-args dispatch target. It would be noise
				// as an MCP tool — hide it via mcpHiddenTools(), same convention
				// as `mcp`, `start`, `stop`, etc.
				var startIdx = reFindNoCase("(?m)^[ \t]*public\s+array\s+function\s+mcpHiddenTools\s*\(", variables.source);
				expect(startIdx).toBeGT(0);
				var body = mid(variables.source, startIdx, 800);
				expect(body).toInclude("""main""");
			});

		});

	}

}
