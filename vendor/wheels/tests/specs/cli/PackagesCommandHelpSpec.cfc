/**
 * Regression: `wheels --help` advertises the `packages` command with the
 * summary "Install, update, search Wheels packages." Users naturally try
 * `wheels packages install <name>` next, which is intercepted by LuCLI's
 * built-in extension installer before dispatch reaches Module.cfc — they
 * see `[INFO] No git or extension dependencies to install`, exit 0, and
 * nothing actually installs. The canonical verb is `wheels packages add`.
 *
 * Issue #2706. The help summary line must stop leading with the broken
 * `Install` verb and point at `add` (the same trap that earlier renamed
 * `wheels browser install` to `wheels browser setup`).
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

			it("showHelp() summary line no longer leads with the broken `Install` verb", () => {
				var source = fileRead(ctx.modulePath);

				// The legacy phrasing leads with "Install" — the exact verb
				// users will then try to type, which LuCLI intercepts.
				expect(source contains "packages            Install, update, search Wheels packages").toBeFalse(
					"showHelp() still summarises `wheels packages` with `Install, update, search ...`. "
					& "The verb users will try (`wheels packages install`) is intercepted by LuCLI's "
					& "built-in extension installer and silently no-ops. Lead with `Add` (the canonical verb) instead."
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
						& "canonical install verb — so users don't reach for the intercepted "
						& "`install` verb. Current line: " & summaryLine
					);
				}
			});

			it("packages() hint metadata leads with `Add`, not the intercepted `Install` verb", () => {
				var source = fileRead(ctx.modulePath);

				// LuCLI surfaces the `hint:` javadoc on the packages() function
				// in auto-introspected help. Leading with "Install" nudges
				// users toward `wheels packages install`, which never reaches
				// this module.
				expect(source contains "hint: Install, update, and list Wheels packages").toBeFalse(
					"packages() hint still leads with `Install`. Lead with `Add` "
					& "(the canonical verb) so auto-introspected help matches showHelp()."
				);
				expect(source contains "hint: Add, update, and list Wheels packages").toBeTrue(
					"packages() hint should lead with `Add, update, and list ...` "
					& "and mention that the verb is `add`, not `install`."
				);
			});

			it("unknown-subcommand error points users at `wheels packages add`", () => {
				var source = fileRead(ctx.modulePath);

				expect(source contains "Unknown packages subcommand").toBeTrue(
					"Expected the packages() default branch to throw an unknown-subcommand error."
				);
				expect(source contains "The install verb is `add` (not `install`): wheels packages add <name>").toBeTrue(
					"The unknown-subcommand error should tell users the install verb is `add`."
				);
			});

		});

	}

}
