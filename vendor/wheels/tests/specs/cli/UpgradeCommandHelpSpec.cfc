/**
 * Regression: cli/lucli/Module.cfc's `upgrade` command surface advertises an
 * upgrader that doesn't exist. The main `showHelp()` summary line claims the
 * command will "Upgrade the Wheels framework version in your project," while
 * the runtime dispatcher only honours `wheels upgrade check [--to=<version>]`
 * — a read-only scanner that points users at `brew upgrade wheels` for the
 * actual install. Users running `wheels upgrade --dry-run` or
 * `wheels upgrade --to=4.0.0` (both flags implied by the misleading summary)
 * land on a terse usage line and are left guessing.
 *
 * Issue #2629. The fix is to align every public-facing description of
 * `wheels upgrade` with the scanner-only reality: the showHelp summary, the
 * docblock hint, and the function's own usage output.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("wheels upgrade — help surface alignment", () => {

			var repoRoot = expandPath("/wheels/../..");
			var modulePath = repoRoot & "/cli/lucli/Module.cfc";

			it("Module.cfc source file is reachable", () => {
				expect(fileExists(modulePath)).toBeTrue("Missing file: " & modulePath);
			});

			it("showHelp() summary line no longer claims to perform an upgrade", () => {
				var source = fileRead(modulePath);

				// The legacy phrasing implies the command performs the
				// upgrade itself. It doesn't — it's a read-only scanner.
				expect(source contains "upgrade             Upgrade the Wheels framework version in your project").toBeFalse(
					"showHelp() still summarises `wheels upgrade` as an upgrader. "
					& "The command is read-only — describe it as scanning for breaking changes."
				);
			});

			it("showHelp() summary line describes the command as a scanner", () => {
				var source = fileRead(modulePath);

				// One of these phrasings should be present in the
				// showHelp() summary block for the `upgrade` entry.
				var summariesScanner = source contains "Scan for breaking changes before upgrading"
					|| source contains "Check for breaking changes before upgrading";

				expect(summariesScanner).toBeTrue(
					"showHelp() should describe `wheels upgrade` as scanning or checking for "
					& "breaking changes — that's what the command actually does. Add a scanner-"
					& "oriented summary line for the `upgrade` entry."
				);
			});

			it("upgrade() usage output mentions the required `check` subcommand", () => {
				var source = fileRead(modulePath);

				expect(source contains "wheels upgrade check").toBeTrue(
					"upgrade() should advertise the `check` subcommand in its usage output "
					& "so users who run `wheels upgrade --dry-run` or `wheels upgrade --to=...` "
					& "discover the right invocation."
				);
			});

			it("upgrade() usage output points users at the real upgrade path", () => {
				var source = fileRead(modulePath);

				expect(source contains "brew upgrade wheels").toBeTrue(
					"upgrade() should tell users that the actual framework upgrade is performed "
					& "by `brew upgrade wheels` (or the equivalent package manager), not by "
					& "this command."
				);
			});

			it("upgrade() usage output explicitly notes that --dry-run is not supported", () => {
				var source = fileRead(modulePath);

				// Either an explicit `--dry-run is not supported` line, or
				// a `Note:` / `Unsupported flags:` block that names dry-run.
				var mentionsDryRunGap = source contains "--dry-run is not supported"
					|| source contains "--dry-run is unsupported"
					|| source contains "Unsupported flags: --dry-run"
					|| source contains "(--dry-run is not supported)"
					|| source contains "no --dry-run";

				expect(mentionsDryRunGap).toBeTrue(
					"The usage block in upgrade() should call out that `--dry-run` is not "
					& "supported. The flag is implied by the misleading legacy summary; "
					& "naming the gap in the usage output is what keeps users unstuck."
				);
			});

			it("upgrade() docblock hint matches the scanner-only reality", () => {
				var source = fileRead(modulePath);

				// Anchor on the function declaration first, then walk
				// backward to its preceding `hint:` line. A bare
				// findNoCase("hint:", source) would grab the file's first
				// hint, not upgrade()'s; a lookahead through the closing
				// `*/` can't span the docblock body since `\s*` won't skip
				// the leading `*` on each comment line.
				var fnPos = findNoCase("public string function upgrade(", source);
				expect(fnPos > 0).toBeTrue(
					"Could not locate `public string function upgrade(` in Module.cfc."
				);

				if (fnPos > 0) {
					var hintStart = 0;
					var nextHint = findNoCase("hint:", source);
					while (nextHint > 0 && nextHint < fnPos) {
						hintStart = nextHint;
						nextHint = findNoCase("hint:", source, nextHint + 1);
					}

					expect(hintStart > 0).toBeTrue(
						"Could not locate the `hint:` docblock above `public string function upgrade()`."
					);

					if (hintStart > 0) {
						var hintEnd = find(chr(10), source, hintStart);
						var hintLen = (hintEnd > hintStart) ? (hintEnd - hintStart) : (len(source) - hintStart + 1);
						var hintLine = mid(source, hintStart, hintLen);

						expect(reFindNoCase("\bupgrade\s+the\s+wheels\s+framework\b", hintLine) > 0).toBeFalse(
							"upgrade() hint still promises to `upgrade the Wheels framework`. "
							& "It's a scanner — phrase the hint as `Scan ...` or `Check ...`."
						);
					}
				}
			});

		});

	}

}
