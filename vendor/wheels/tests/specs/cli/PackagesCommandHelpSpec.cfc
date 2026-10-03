/**
 * The `packages` help leads with the canonical verb, `add`.
 *
 * Issue #2706: `wheels --help` summarised `packages` as "Install, update,
 * search Wheels packages", so users typed `wheels packages install <name>`.
 * On the CLIs of the time LuCLI's built-in extension installer took that
 * verb before Module.cfc, and nothing installed. Since #4206 `install` is
 * an alias of `add` in Wheels 4.2; `add` stays the documented verb because
 * it works on every 4.x CLI.
 */
component extends="wheels.WheelsTest" {

	function run() {

		// Shared struct so nested `it()` closures can reach `modulePath` —
		// CFML closures can't reliably access outer `var` slots, only struct
		// references (see CLAUDE.md Testing Quick Reference, "Closure gotcha").
		var ctx = {repoRoot: expandPath("/wheels/../..")};
		ctx.modulePath = ctx.repoRoot & "/cli/lucli/Module.cfc";

		describe("wheels packages — top-level help summary alignment", () => {

			it("Module.cfc source file is reachable", () => {
				expect(fileExists(ctx.modulePath)).toBeTrue("Missing file: " & ctx.modulePath);
			});

			it("showHelp() summary line leads with `Add`, not `Install`", () => {
				var source = fileRead(ctx.modulePath);

				// The legacy phrasing led with "Install", the verb older CLIs
				// did not deliver to the module (#2706).
				expect(source contains "packages            Install, update, search Wheels packages").toBeFalse(
					"showHelp() still summarises `wheels packages` with `Install, update, search ...`. "
					& "Lead with `Add`, the canonical verb, which works on every 4.x CLI."
				);
			});

			it("showHelp() summary line for `packages` points at the canonical `add` verb", () => {
				var source = fileRead(ctx.modulePath);

				// Find the line that starts the `packages` summary entry in
				// the showHelp() block and confirm it names `add` (or `Add`)
				// somewhere in the description.
				var marker = "  packages            ";
				var markerPos = find(marker, source);
				expect(markerPos > 0).toBeTrue(
					"Could not locate the `packages` summary line in Module.cfc showHelp()."
				);

				if (markerPos > 0) {
					var lineEnd = find(chr(10), source, markerPos);
					var lineLen = (lineEnd > markerPos) ? (lineEnd - markerPos) : (len(source) - markerPos + 1);
					var summaryLine = mid(source, markerPos, lineLen);

					expect(reFindNoCase("\badd\b", summaryLine) > 0).toBeTrue(
						"The `packages` summary line in showHelp() should mention `add` — the "
						& "canonical install verb. Current line: " & summaryLine
					);
				}
			});

			it("packages() hint metadata leads with `Add`, not `Install`", () => {
				var source = fileRead(ctx.modulePath);

				// `wheels packages --help` prints the packages() `hint:` line.
				// It leads with `Add`, the documented verb, to match showHelp().
				expect(source contains "hint: Install, update, and list Wheels packages").toBeFalse(
					"packages() hint still leads with `Install`. Lead with `Add` "
					& "(the canonical verb) so auto-introspected help matches showHelp()."
				);
				expect(source contains "hint: Add, update, and list Wheels packages").toBeTrue(
					"packages() hint should lead with `Add, update, and list ...`."
				);
			});

			it("unknown-subcommand error points users at `wheels packages add`", () => {
				var source = fileRead(ctx.modulePath);

				expect(source contains "Unknown packages subcommand").toBeTrue(
					"Expected the packages() default branch to throw an unknown-subcommand error."
				);
				expect(source contains "To install a package: wheels packages add <name>").toBeTrue(
					"The unknown-subcommand error should point users at `wheels packages add`."
				);
			});

		});

	}

}
