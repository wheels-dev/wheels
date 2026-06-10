/**
 * Regression for issue #2959 — dev-UI delivery refactor (wave 2 review
 * remediation, P2 Medium).
 *
 * `vendor/wheels/public/views/cli.cfm` ships a 1,000+ line `<cfswitch>`
 * over 44 commands plus an in-page UDF for test-data generation. Two
 * structural defects need addressing without expanding the wave-2
 * `cli.cfm` hardening PR:
 *
 *   1. The `dbSetup` case re-enters the dispatcher via a recursive
 *      `<cfinclude>` of `cli.cfm` itself (mutating `request.wheels.params`
 *      mid-flight to fake a `dbSeed` call). The recursive include rebuilds
 *      `data` from scratch, discarding the "Migrations completed." string
 *      so the final JSON envelope reports the seed message only — the
 *      migration outcome is lost.
 *
 *   2. The error envelope is inconsistent: per-command catches set
 *      `data.message` (singular) while the outer catch sets
 *      `data.messages` (plural). A CLI client that reads either name in
 *      isolation will miss half the failure modes.
 *
 * Cross-framework research (Rails, Laravel, Django, Phoenix, Spring,
 * Symfony) converged on: sub-action chaining happens through direct
 * method calls (`$this->call(...)` / `call_command(...)` /
 * `Rake::Task[...].invoke`) — never by re-entering the dispatcher view.
 * The Wheels equivalent for the minimum-viable refactor is to extract
 * the seed orchestration into a helper that `dbSetup` calls directly,
 * preserving the migration message in the response envelope.
 *
 * This spec source-scans `cli.cfm` (mirroring the existing cli/* spec
 * style — `OnErrorFallbackGuardSpec.cfc`, `PackagesCommandHelpSpec.cfc`)
 * because cli.cfm runs under a full HTTP request context that the spec
 * runner does not synthesize.
 */
component extends="wheels.WheelsTest" {

	function run() {

		// expandPath("/wheels") resolves to vendor/wheels via the configured
		// Lucee mapping; the repo root is two levels above.
		var ctx = {repoRoot: expandPath("/wheels/../..")};
		ctx.cliViewPath = ctx.repoRoot & "/vendor/wheels/public/views/cli.cfm";

		describe("cli.cfm dispatcher decomposition (issue ##2959)", () => {

			it("cli.cfm source file is reachable", () => {
				expect(fileExists(ctx.cliViewPath)).toBeTrue("Missing file: " & ctx.cliViewPath);
			});

			it("does not recursively include cli.cfm from within itself for dbSetup → dbSeed chaining", () => {
				var raw = fileRead(ctx.cliViewPath);
				var content = $stripCfmlComments(raw);

				// A `<cfinclude>` or scripted `include` of `cli.cfm` from
				// inside `cli.cfm` is the recursive-dispatch anti-pattern.
				// The fix replaces it with a direct call to the extracted
				// seed-orchestration helper, so no remaining include of
				// `cli.cfm` should survive in the source.
				var recursiveCfinclude = reFindNoCase(
					"<cfinclude[^>]+template\s*=\s*[""'][^""']*cli\.cfm[""']",
					content
				);
				expect(recursiveCfinclude == 0).toBeTrue(
					"cli.cfm still contains a `<cfinclude>` of cli.cfm itself — that's the "
					& "recursive-dispatch anti-pattern (issue ##2959): the second include "
					& "rebuilds `data` from scratch and discards the `Migrations completed.` "
					& "string the outer dbSetup run set. Replace with a direct call to the "
					& "extracted seed-orchestration helper."
				);

				var scriptedInclude = reFindNoCase(
					"\binclude\s+[""'][^""']*cli\.cfm[""']",
					content
				);
				expect(scriptedInclude == 0).toBeTrue(
					"cli.cfm still contains a scripted `include` of cli.cfm itself. Replace "
					& "the recursive dispatch with a direct helper call (issue ##2959)."
				);
			});

			it("dbSetup does not mutate request.wheels.params.command mid-flight", () => {
				var raw = fileRead(ctx.cliViewPath);
				var content = $stripCfmlComments(raw);

				// The legacy recursive-include path forged a `dbSeed` call
				// by overwriting `request.wheels.params.command`. After the
				// refactor, dbSetup composes through a direct helper call
				// and must not touch the dispatcher's own input.
				var paramsCommandWrite = reFindNoCase(
					"request\.wheels\.params\.command\s*=",
					content
				);
				expect(paramsCommandWrite == 0).toBeTrue(
					"cli.cfm writes to `request.wheels.params.command` — the legacy "
					& "side-effect used to coerce a recursive `dbSeed` call. The refactored "
					& "dbSetup must compose sub-actions through a direct helper call instead "
					& "(issue ##2959)."
				);
			});

			it("outer catch populates both data.message and data.messages for envelope consistency", () => {
				var raw = fileRead(ctx.cliViewPath);
				var content = $stripCfmlComments(raw);

				// Locate the OUTER `} catch (any e) { ... }` — distinguished
				// from per-command inner catches by being unindented (column 0)
				// at the start of a line, immediately following the dispatch
				// try's close brace. Inner catches sit deep inside switch
				// cases and are leading-indented.
				var outerCatchPattern = "(?m)^\}\s*catch\s*\(\s*any\s+\w+\s*\)\s*\{";
				var catchMatch = reFindNoCase(outerCatchPattern, content, 1, true);
				expect(catchMatch.len[1] > 0).toBeTrue(
					"cli.cfm should declare an outer (unindented) `} catch (any e) {` "
					& "block guarding the dispatch try."
				);

				var bodyStart = catchMatch.pos[1] + catchMatch.len[1];
				var depth = 1;
				var bodyEnd = bodyStart;
				var iEnd = len(content);
				for (var i = bodyStart; i <= iEnd; i++) {
					var ch = mid(content, i, 1);
					if (ch == "{") {
						depth++;
					} else if (ch == "}") {
						depth--;
						if (depth == 0) {
							bodyEnd = i - 1;
							break;
						}
					}
				}
				var catchBody = mid(content, bodyStart, bodyEnd - bodyStart + 1);

				// `data\.message\s*=` matches `data.message =` but NOT
				// `data.messages = ...` — the `s` after `message` breaks the
				// match before `\s*=` can succeed.
				expect(reFindNoCase("data\.message\s*=", catchBody) > 0).toBeTrue(
					"Outer catch must assign `data.message` (singular) for envelope "
					& "consistency — per-command catches already use the singular form, "
					& "so the outer envelope must too (issue ##2959)."
				);
				expect(reFindNoCase("data\.messages\s*=", catchBody) > 0).toBeTrue(
					"Outer catch must continue to assign `data.messages` (plural) so "
					& "existing CLI clients reading the plural key keep working "
					& "(issue ##2959)."
				);
			});

		});

	}

	/**
	 * Strip CFML tag, block, and line comments before scanning. Mirrors
	 * the helpers under cli/lucli/services (Analysis.cfc, Doctor.cfc) so a
	 * commented-out access pattern doesn't pollute the structural check
	 * (CLAUDE.md anti-pattern ##14).
	 */
	private string function $stripCfmlComments(required string source) {
		var stripped = arguments.source;
		stripped = reReplace(stripped, "<!---[\s\S]*?--->", "", "all");
		stripped = reReplace(stripped, "/\*[\s\S]*?\*/", "", "all");
		stripped = reReplace(stripped, "(?m)//[^\n]*", "", "all");
		return stripped;
	}

}
