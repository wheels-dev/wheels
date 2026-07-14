/**
 * Issue ##3311 — dev-mode inline notice when ?reload=true is refused.
 *
 * The reload gate in the app template's onRequestStart() (fail-closed since
 * ##3062) must RECORD why a requested reload did not fire, so the framework's
 * debug bar (vendor/wheels/events/onrequestend/debug.cfm) can surface a
 * development-only notice instead of a silent no-op. Recording lives in the
 * template copies; message text and the development-environment gate live
 * framework-side so wording can improve without template drift.
 *
 * Contract, which ALL FOUR same-lineage copies of public/Application.cfc must
 * carry (same lineage as ReloadPasswordGateParitySpec.cfc):
 *
 *   1. A refused reload records request.wheels.reloadRefusedReason with one of
 *      exactly three reasons: "emptyPassword" (no non-empty reloadPassword is
 *      configured), "missingPasswordParam" (password configured but no
 *      password parameter supplied), "refused" (everything else).
 *   2. NO ORACLE: wrong-password and rate-limited refusals must collapse into
 *      the single generic "refused" reason — the copies must not record a
 *      reason string that distinguishes them.
 *
 * Structural spec (no runtime): exercising the gate at runtime would
 * applicationStop() the suite mid-run. Modeled on
 * ReloadPasswordGateParitySpec.cfc.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("reload-refused notice recording parity (issue ##3311)", () => {

			// expandPath("/wheels") resolves to vendor/wheels via the
			// configured Lucee mapping; the repo root is two levels above.
			var repoRoot = expandPath("/wheels/../..");
			var targets = [
				"cli/lucli/templates/app/public/Application.cfc",
				"public/Application.cfc",
				"examples/tweet/public/Application.cfc",
				"examples/starter-app/public/Application.cfc"
			];

			for (var rel in targets) {
				// Capture the loop variable so the closure body binds the
				// current value, not the final iteration's value.
				(function(relPath) {

					it("records all three refusal reasons in " & relPath, () => {
						var absolute = repoRoot & "/" & relPath;
						expect(fileExists(absolute)).toBeTrue("Missing file: " & absolute);
						var content = fileRead(absolute);

						expect(
							content contains 'request.wheels.reloadRefusedReason = "emptyPassword"'
						).toBeTrue(
							relPath & " must record reloadRefusedReason=emptyPassword when a "
							& "reload is requested with no non-empty reloadPassword configured "
							& "(issue ##3311)."
						);
						expect(
							content contains 'request.wheels.reloadRefusedReason = "missingPasswordParam"'
						).toBeTrue(
							relPath & " must record reloadRefusedReason=missingPasswordParam when "
							& "a password is configured but the request carried no password "
							& "parameter (issue ##3311)."
						);
						expect(
							content contains 'request.wheels.reloadRefusedReason = "refused"'
						).toBeTrue(
							relPath & " must record the generic reloadRefusedReason=refused for "
							& "wrong-password/rate-limited attempts (issue ##3311)."
						);
					});

					it("keeps wrong-password and rate-limited refusals indistinguishable in " & relPath, () => {
						var absolute = repoRoot & "/" & relPath;
						expect(fileExists(absolute)).toBeTrue("Missing file: " & absolute);
						var content = fileRead(absolute);

						// The only assignments to the flag are the three contract reasons —
						// no copy may grow a reason that leaks WHY the compare failed.
						var assignments = REMatch("request\.wheels\.reloadRefusedReason\s*=\s*""[^""]*""", content);
						expect(ArrayLen(assignments) == 3).toBeTrue(
							relPath & " must assign reloadRefusedReason exactly three times "
							& "(emptyPassword, missingPasswordParam, refused) — found "
							& ArrayLen(assignments) & " (issue ##3311)."
						);
						for (var assignment in assignments) {
							expect(
								REFindNoCase("wrong|incorrect|rate", assignment) == 0
							).toBeTrue(
								relPath & " records a refusal reason that distinguishes "
								& "wrong-password from rate-limited — the notice must stay "
								& "oracle-free (issue ##3311): " & assignment
							);
						}
					});

				})(rel);
			}

		});

	}

}
