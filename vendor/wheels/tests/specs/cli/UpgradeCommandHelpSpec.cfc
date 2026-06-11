/**
 * Regression: cli/lucli/Module.cfc's `upgrade` command surface must match
 * what the command actually does.
 *
 * History: issue #2629 fixed the original drift — the help claimed an
 * upgrader while the runtime only honoured the read-only
 * `wheels upgrade check` scanner — by rewording every public-facing
 * description down to the scanner-only reality. Issue #3035 then added
 * the framework swap (replacing the app's vendor/wheels/ with the CLI's
 * bundled framework, backup first), and the #3039 review put it behind
 * the explicit `apply` verb: bare `wheels upgrade` prints usage and never
 * mutates, `wheels upgrade apply` performs the swap, `check` keeps the
 * read-only scan. The same alignment rules apply: the showHelp() summary,
 * the docblock hint, and the usage output must all advertise BOTH verbs —
 * without resurrecting the old "this command is read-only" claims and
 * without claiming the bare verb applies anything.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("wheels upgrade — help surface alignment", () => {

			var repoRoot = expandPath("/wheels/../..");
			var modulePath = repoRoot & "/cli/lucli/Module.cfc";

			it("Module.cfc source file is reachable", () => {
				expect(fileExists(modulePath)).toBeTrue("Missing file: " & modulePath);
			});

			it("showHelp() summary line advertises the upgrade capability", () => {
				var source = fileRead(modulePath);

				// Since #3035 the command can perform the swap, so the summary
				// must say so (the #2629-era scanner-only summary is stale).
				expect(source contains "Upgrade the Wheels framework in your app").toBeTrue(
					"showHelp() should summarise `wheels upgrade` as upgrading the framework "
					& "copy inside the app (vendor/wheels/) — that's what the `apply` verb does "
					& "as of ##3035."
				);
			});

			it("usage output still advertises the read-only check subcommand", () => {
				var source = fileRead(modulePath);

				expect(source contains "wheels upgrade check").toBeTrue(
					"upgrade() should advertise the `check` subcommand in its usage output "
					& "so users can preview breaking changes before applying."
				);
			});

			it("usage output advertises the explicit apply verb", () => {
				var source = fileRead(modulePath);

				// #3039 review: the swap is behind `wheels upgrade apply` —
				// bare `wheels upgrade` prints usage and never mutates, so
				// the help must steer users at the explicit verb.
				expect(source contains "wheels upgrade apply").toBeTrue(
					"upgrade() should advertise the `apply` subcommand in its usage output — "
					& "the swap requires the explicit verb as of the ##3039 review "
					& "(bare `wheels upgrade` is a usage printout, not the apply path)."
				);
			});

			it("usage output points at the package manager for the CLI binary itself", () => {
				var source = fileRead(modulePath);

				expect(source contains "brew upgrade wheels").toBeTrue(
					"upgrade() should tell users that the CLI binary is upgraded by "
					& "`brew upgrade wheels` (or the equivalent package manager) — apply mode "
					& "only swaps the framework copy the CLI bundles."
				);
			});

			it("usage output explicitly notes that --dry-run is not supported", () => {
				var source = fileRead(modulePath);

				// Either an explicit `--dry-run is not supported` line, or
				// a `Note:` / `Unsupported flags:` block that names dry-run.
				var mentionsDryRunGap = source contains "--dry-run is not supported"
					|| source contains "--dry-run is unsupported"
					|| source contains "Unsupported flags: --dry-run"
					|| source contains "(--dry-run is not supported)"
					|| source contains "no --dry-run";

				expect(mentionsDryRunGap).toBeTrue(
					"The help surface should call out that `--dry-run` is not supported — "
					& "`wheels upgrade check` is the read-only preview."
				);
			});

			it("the apply path exists with the backup convention", () => {
				var source = fileRead(modulePath);

				expect(source contains "runUpgradeApply").toBeTrue(
					"Module.cfc should dispatch the `apply` verb to runUpgradeApply() (##3035/##3039)."
				);
				expect(source contains "wheels.bak-").toBeTrue(
					"The apply path should reference the vendor/wheels.bak-<timestamp> "
					& "backup convention so the help/recovery output stays truthful."
				);
			});

			it("upgrade() docblock hint matches the apply-first reality", () => {
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

						// Inverted from the #2629-era assertion: the hint MUST
						// now promise the upgrade (that's what `apply` does)
						// and surface both explicit verbs — check as the
						// read-only scan, apply as the swap (#3039 review).
						expect(reFindNoCase("\bupgrade\s+the\s+wheels\s+framework\b", hintLine) > 0).toBeTrue(
							"upgrade() hint should advertise the upgrade capability — "
							& "`wheels upgrade apply` performs the framework swap as of ##3035/##3039."
						);
						expect(findNoCase("check", hintLine) > 0).toBeTrue(
							"upgrade() hint should still mention the read-only `check` scan."
						);
						expect(findNoCase("apply", hintLine) > 0).toBeTrue(
							"upgrade() hint should mention the explicit `apply` verb — bare "
							& "`wheels upgrade` no longer performs the swap (##3039 review)."
						);
					}
				}
			});

		});

	}

}
