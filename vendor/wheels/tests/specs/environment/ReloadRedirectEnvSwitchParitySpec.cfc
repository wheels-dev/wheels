/**
 * Regression for issue #3030 — "app template: reload redirect strips the
 * environment-switch params, making ?reload=<env> a silent no-op".
 *
 * The only path that restarts a stock app is the reload gate in
 * public/Application.cfc's onRequestStart(): it calls applicationStop() then
 * redirects via $buildRedirectUrl(), which historically stripped `reload`,
 * `password`, and `lock` from the query string (the anti-loop default for
 * `?reload=true`). But the framework's environment switch in
 * wheels/events/onapplicationstart.cfc only fires when a NON-boolean
 * `URL.reload` is present on the request that starts the NEW application —
 * which is exactly that post-strip redirect. Stripping the params made the
 * switch unreachable in the stock flow, so `?reload=testing&password=X` was a
 * silent no-op.
 *
 * Fix (loop-safe), applied identically to all four lineage copies of
 * Application.cfc:
 *   1. $buildRedirectUrl() preserves `reload`+`password` when the reload value
 *      is an environment switch (`!IsBoolean(url.reload)`), via a dynamic
 *      `local.stripKeys` list ("lock" for a switch, "reload,password,lock" for
 *      a boolean reload). The unconditional ListFindNoCase("reload,password,lock", …)
 *      is gone.
 *   2. The onRequestStart() reload gate gains a loop-break: when
 *      `!IsBoolean(url.reload)` AND `application.wheels.environment` already
 *      equals `url.reload`, the switch has already been applied by the restart
 *      this redirect came from, so it skips applicationStop() and serves the
 *      request normally — otherwise the now-preserved params would loop forever.
 *
 * This is a structural parity spec (no runtime): it reads the four
 * Application.cfc copies and asserts the gate/redirect wiring is present and
 * consistent across all of them. Modeled on the structural specs in
 * vendor/wheels/tests/specs/cli/Bot*ShaThreadingSpec.cfc.
 *
 * The four copies share one lineage and must not drift:
 *   - public/Application.cfc                              (repo demo app — what the docker harness exercises)
 *   - cli/lucli/templates/app/public/Application.cfc      (what `wheels new` ships)
 *   - examples/starter-app/public/Application.cfc
 *   - examples/tweet/public/Application.cfc
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("reload redirect environment-switch parity (issue ##3030)", () => {

			// expandPath("/wheels") resolves to vendor/wheels via the configured
			// Lucee mapping; the repo root is two levels above.
			var repoRoot = expandPath("/wheels/../..");

			var copies = [
				repoRoot & "/public/Application.cfc",
				repoRoot & "/cli/lucli/templates/app/public/Application.cfc",
				repoRoot & "/examples/starter-app/public/Application.cfc",
				repoRoot & "/examples/tweet/public/Application.cfc"
			];

			for (var path in copies) {
				// Closure capture: bind the path per iteration so each `it`
				// reads its own file (CFML loop var would otherwise alias).
				(function(file) {

					describe(Replace(file, repoRoot & "/", ""), () => {

						it("preserves reload+password on an environment switch via a dynamic strip list", () => {
							expect(fileExists(file)).toBeTrue("Missing file: " & file);
							var content = fileRead(file);

							// $buildRedirectUrl() must strip a DYNAMIC key list so an
							// environment switch keeps reload+password through the redirect.
							expect(
								reFindNoCase("ListFindNoCase\s*\(\s*local\.stripKeys", content) > 0
							).toBeTrue(
								file & ": $buildRedirectUrl() must strip via a dynamic "
								& "`local.stripKeys` list so an environment switch (?reload=<env>) "
								& "keeps reload+password through the post-applicationStop() redirect "
								& "(issue ##3030)."
							);

							// The stripKeys list must be the documented conditional:
							// "lock" for a switch, "reload,password,lock" for a boolean reload.
							expect(
								reFindNoCase(
									"local\.stripKeys\s*=\s*local\.isEnvironmentSwitch\s*\?\s*""lock""\s*:\s*""reload,password,lock""",
									content
								) > 0
							).toBeTrue(
								file & ": local.stripKeys must resolve to ""lock"" for an "
								& "environment switch and ""reload,password,lock"" for a boolean "
								& "reload (issue ##3030)."
							);

							// The old unconditional strip must be gone — its presence means
							// the env-switch params are still being discarded.
							expect(
								reFindNoCase("ListFindNoCase\s*\(\s*""reload,password,lock""", content) > 0
							).toBeFalse(
								file & ": the unconditional "
								& "ListFindNoCase(""reload,password,lock"", …) strip must be replaced "
								& "by the dynamic stripKeys list — otherwise ?reload=<env> stays a "
								& "silent no-op (issue ##3030)."
							);
						});

						it("detects an environment switch with !IsBoolean(url.reload)", () => {
							expect(fileExists(file)).toBeTrue("Missing file: " & file);
							var content = fileRead(file);
							expect(
								reFindNoCase("!\s*IsBoolean\s*\(\s*url\.reload\s*\)", content) > 0
							).toBeTrue(
								file & ": an environment switch must be detected via "
								& "!IsBoolean(url.reload) — a non-boolean reload value names the "
								& "target environment (issue ##3030)."
							);
						});

						it("loop-breaks the gate when the switch has already been applied", () => {
							expect(fileExists(file)).toBeTrue("Missing file: " & file);
							var content = fileRead(file);
							// Once the restart that produced this redirect has switched the
							// environment, application.wheels.environment already equals
							// url.reload; restarting again would loop forever now that the
							// params survive the redirect, so the gate must skip applicationStop().
							expect(
								reFindNoCase(
									"application\.wheels\.environment\s*==\s*url\.reload",
									content
								) > 0
							).toBeTrue(
								file & ": the onRequestStart() reload gate must loop-break when "
								& "application.wheels.environment already equals url.reload, so a "
								& "preserved ?reload=<env> redirect does not restart forever "
								& "(issue ##3030)."
							);
						});

					});

				})(path);
			}

		});

	}

}
