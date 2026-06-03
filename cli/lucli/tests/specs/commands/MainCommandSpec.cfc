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
 *   1. THIS spec — a comment-aware source scan. Module extends
 *      `modules.BaseModule`, a CLI-runtime mapping that is NOT resolvable in
 *      the TestBox server context (the test Application.cfc maps
 *      `modules.wheels` but not the BaseModule parent), so we cannot
 *      instantiate Module here. Same constraint as `UpgradeCommandSpec` and
 *      `ReloadCommandSpec`, which also scan source.
 *   2. A behavioral check in `tools/test-onboarding.sh` (Phase 16) that runs
 *      the real `wheels` binary against the mounted worktree module and
 *      asserts the help banner prints with no dispatch error — the end-to-end
 *      path this source scan can only approximate.
 *
 * The scan strips CFML comments before matching so a commented-out
 * declaration can't produce a false green (CLAUDE.md anti-pattern #14 / the
 * PR #2595 lesson: substring scans over CFML source must ignore comments).
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.rawSource = fileRead(expandPath("/cli/lucli/Module.cfc"));
		variables.source = $stripComments(variables.rawSource);
	}

	function run() {

		describe("wheels (no args) — Module.main() dispatch target", () => {

			it("declares a public main() function", () => {
				// Without this, LuCLI's dispatcher hits the missing-method
				// branch on bare `wheels` invocations and throws.
				expect(reFindNoCase("public\s+(string|any)\s+function\s+main\s*\(", variables.source)).toBeGT(0);
			});

			it("delegates main() to showHelp() so the banner is printed", () => {
				// Isolate main()'s body (declaration through its first closing
				// brace) and assert it calls showHelp(). Scoping to the body —
				// rather than a fixed-width window — keeps the check honest if
				// neighbouring functions move.
				var startIdx = reFindNoCase("function\s+main\s*\(", variables.source);
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
				expect(reFindNoCase("public\s+string\s+function\s+showHelp\s*\(", variables.source)).toBeGT(0);
				expect(variables.source).toInclude("Wheels CLI ");
			});

			it("hides main() from MCP tools/list", () => {
				// main() is a CLI-only no-args dispatch target. It would be noise
				// as an MCP tool — hide it via mcpHiddenTools(), same convention
				// as `mcp`, `start`, `stop`, etc.
				var startIdx = reFindNoCase("public\s+array\s+function\s+mcpHiddenTools\s*\(", variables.source);
				expect(startIdx).toBeGT(0);
				var body = mid(variables.source, startIdx, 800);
				expect(body).toInclude("""main""");
			});

		});

	}

	/**
	 * Strip CFML comments so source scans ignore commented-out code. Module.cfc
	 * is a cfscript component, so only line comments and block comments occur —
	 * never tag-style comments. We deliberately OMIT a tag-comment rule: a
	 * literal tag-comment opener inside a CFC string can trip Lucee's
	 * pre-compile tag scanner and crash the whole bundle. Block comments span
	 * lines; the [\s\S] character class matches across newlines without the
	 * (?s) dotall flag, keeping this cross-engine safe. Line comments are
	 * stripped WHOLE-LINE only (anchored at line start): a blanket match would
	 * swallow the guides.wheels.dev URL in showHelp()'s banner, so the
	 * line-start anchor removes commented-out code while leaving mid-string
	 * URL slashes intact. (CLAUDE.md anti-pattern #14 / PR #2595.)
	 */
	private string function $stripComments(required string source) {
		var s = arguments.source;
		s = reReplace(s, "/\*[\s\S]*?\*/", "", "all");
		s = reReplace(s, "(?m)^[ \t]*//.*", "", "all");
		return s;
	}

}
