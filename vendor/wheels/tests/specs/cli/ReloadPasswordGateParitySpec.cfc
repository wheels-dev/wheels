/**
 * Regression for issue ##3062 — "Reload-password contract drift: empty password
 * leaves ?reload=true open to anonymous restarts, warm-app wrong-password
 * attempts are never logged or rate-limited, and the boot warning misstates
 * behavior".
 *
 * The reload gate in onRequestStart() used to fire whenever the configured
 * reloadPassword was EMPTY or missing (`!Len(application.wheels.reloadPassword)`
 * sat on the allow side of the disjunction), so any anonymous client could
 * `?reload=true` a warm app into a full applicationStop() restart loop
 * (restart-DoS). Meanwhile the framework's own boot warning
 * (vendor/wheels/events/onapplicationstart.cfc) claimed the opposite: that an
 * empty password disables URL-based reload. And a wrong-password attempt
 * against a warm app fell through to normal serving with no wheels_security
 * log entry and no rate-limit count — all of the ##2082 hardening (non-empty
 * password requirement, rejected/accepted logging, 5-failures-in-5-minutes
 * per-IP lockout) lived only in the cold-start path.
 *
 * The fixed contract, which ALL FOUR same-lineage copies of
 * public/Application.cfc must carry (same lineage as
 * ReloadEnvironmentSwitchParitySpec.cfc):
 *
 *   1. FAIL CLOSED: the gate fires only when application.wheels exists, a
 *      NON-EMPTY reloadPassword is configured, a password parameter was
 *      supplied, AND it matches. An empty/missing reloadPassword disables
 *      ?reload= entirely — matching the environment-switch leg and making the
 *      boot warning true. No `||` leg may reopen the gate for a missing
 *      application.wheels struct or an empty password.
 *   2. CONSTANT-TIME, CASE-SENSITIVE COMPARE: $secureCompare(), never CFML
 *      `==` (case-insensitive, early-exit — leaks timing and accepts
 *      wrong-case passwords). The two examples/ copies used `==` until ##3062.
 *   3. WARM-PATH OBSERVABILITY: wrong-password attempts log to
 *      wheels_security.log with the trusted client IP and increment the SAME
 *      per-IP application.$reloadRateLimit store the cold-start path uses
 *      (5 failed attempts within 5 minutes locks the IP, parity with
 *      vendor/wheels/events/onapplicationstart.cfc). Accepted reloads log too.
 *
 * Structural spec (no runtime): the gate lives in the app template's
 * onRequestStart() dispatch path, so exercising it at runtime would
 * applicationStop() the suite mid-run. Reads each copy and asserts the
 * contract is wired. Modeled on ReloadEnvironmentSwitchParitySpec.cfc.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("reload-password gate parity (issue ##3062)", () => {

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

					it("fails closed when reloadPassword is empty or missing in " & relPath, () => {
						var absolute = repoRoot & "/" & relPath;
						expect(fileExists(absolute)).toBeTrue("Missing file: " & absolute);
						var content = fileRead(absolute);

						// The pre-##3062 open gate: `|| !Len(application.wheels.reloadPassword)`
						// fired the restart whenever the password was EMPTY. It must be gone.
						expect(
							reFind("\|\|\s*!Len\(application\.wheels\.reloadPassword\)", content) == 0
						).toBeTrue(
							relPath & " still allows ?reload=true when reloadPassword is empty "
							& "(`|| !Len(application.wheels.reloadPassword)` on the allow side of "
							& "the gate) — anonymous restart-DoS, issue ##3062."
						);

						// So must the missing-struct escape hatches: a request must never be
						// able to restart the app just because application.wheels (or the
						// reloadPassword key) does not exist. The exact disjunction below
						// only ever existed inside the reload gate — the issue-359 boot
						// check pairs the same first operand with "eventPath" instead and
						// stays legal.
						expect(
							reFind("!StructKeyExists\(application,\s*""wheels""\)\s*\|\|\s*!StructKeyExists\(application\.wheels,\s*""reloadPassword""\)", content) == 0
						).toBeTrue(
							relPath & " still opens the reload gate when application.wheels "
							& "or its reloadPassword key is missing — the gate must fail "
							& "closed (issue ##3062)."
						);
						expect(
							reFind("\|\|\s*!StructKeyExists\(application\.wheels,\s*""reloadPassword""\)", content) == 0
							&& reFind("!StructKeyExists\(application\.wheels,\s*""reloadPassword""\)\s*\|\|", content) == 0
						).toBeTrue(
							relPath & " still opens the reload gate when reloadPassword is "
							& "unset — the gate must fail closed (issue ##3062)."
						);

						// And the positive requirement: a NON-EMPTY configured password is a
						// conjunctive precondition, mirroring the environment-switch leg in
						// vendor/wheels/events/onapplicationstart.cfc.
						expect(
							reFind("&&\s*Len\(application\.wheels\.reloadPassword\)", content) > 0
						).toBeTrue(
							relPath & " must require a non-empty reloadPassword (`&& Len(...)`) "
							& "before any URL-based reload can fire (issue ##3062)."
						);
					});

					it("compares the reload password in constant time in " & relPath, () => {
						var absolute = repoRoot & "/" & relPath;
						expect(fileExists(absolute)).toBeTrue("Missing file: " & absolute);
						var content = fileRead(absolute);

						expect(
							content contains "application.wo.$secureCompare(url.password, application.wheels.reloadPassword)"
						).toBeTrue(
							relPath & " must verify the reload password with "
							& "application.wo.$secureCompare() — same gate as the environment "
							& "switch in wheels/events/onapplicationstart.cfc (issue ##3062)."
						);
						expect(
							reFind("url\.password\s*==\s*application\.wheels\.reloadPassword", content) == 0
						).toBeTrue(
							relPath & " still compares the reload password with CFML `==`, which "
							& "is case-insensitive and exits early (timing leak + wrong-case "
							& "passwords accepted) — issue ##3062."
						);
					});

					it("logs and rate-limits warm-path reload attempts per IP in " & relPath, () => {
						var absolute = repoRoot & "/" & relPath;
						expect(fileExists(absolute)).toBeTrue("Missing file: " & absolute);
						var content = fileRead(absolute);

						// Keyed on the trusted client IP, same resolver as the cold-start path.
						expect(
							content contains "application.wo.$trustedClientIp()"
						).toBeTrue(
							relPath & " must key warm-path reload attempts on "
							& "application.wo.$trustedClientIp(), parity with the cold-start "
							& "path (issue ##3062)."
						);

						// Shares the cold-start store and window: 5 failures in 5 minutes.
						expect(
							content contains "application.$reloadRateLimit"
						).toBeTrue(
							relPath & " must feed warm-path failures into the same "
							& "application.$reloadRateLimit store the cold-start path uses "
							& "(issue ##3062)."
						);
						expect(
							reFind("count\s*>=\s*5\s*&&\s*DateDiff\(""n"",.+,\s*Now\(\)\)\s*<\s*5", content) > 0
						).toBeTrue(
							relPath & " must enforce the 5-failed-attempts-in-5-minutes per-IP "
							& "window on the warm path, parity with "
							& "vendor/wheels/events/onapplicationstart.cfc (issue ##3062)."
						);

						// Both outcomes are visible in wheels_security.log.
						expect(
							content contains """wheels_security"""
							&& content contains "Reload password rejected from"
						).toBeTrue(
							relPath & " must log warm-path wrong-password reload attempts to "
							& "wheels_security.log with the source IP (issue ##3062)."
						);
						expect(
							content contains "Reload accepted from"
						).toBeTrue(
							relPath & " must log accepted warm-path reloads to "
							& "wheels_security.log with the source IP (issue ##3062)."
						);
					});

				})(rel);
			}

		});

	}

}
