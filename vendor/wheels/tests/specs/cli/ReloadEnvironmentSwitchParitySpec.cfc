/**
 * Regression for issue ##3030 — "app template: reload redirect strips the
 * environment-switch params, making ?reload=<env> a silent no-op".
 *
 * The only path that restarts a stock app is public/Application.cfc's reload
 * gate: it calls applicationStop() and redirects via $buildRedirectUrl(),
 * which used to strip reload, password, AND lock from the query string. But
 * the framework's environment switch (wheels/events/onapplicationstart.cfc)
 * needs URL.reload + URL.password present on the request that starts the new
 * application, so the switch code was unreachable through the stock flow.
 *
 * The fix has three cooperating parts, and ALL FOUR same-lineage copies of
 * public/Application.cfc must carry them:
 *
 *   1. $buildRedirectUrl() preserves reload + password (still strips lock)
 *      when the reload value is an environment switch (non-boolean, non-empty,
 *      password supplied, non-empty reloadPassword configured). Plain
 *      ?reload=true keeps the strip-everything behavior.
 *   2. onRequestStart() breaks the restart loop: when the redirected request
 *      arrives and the requested environment is already active, the gate is
 *      skipped and the request is served normally. Trade-off:
 *      ?reload=<current-environment> is a no-op (use ?reload=true for a
 *      same-environment restart).
 *   3. The configured reloadPassword is handed across the applicationStop()
 *      boundary via a single-use, short-lived server-scope entry
 *      ($handleRestartAppRequest stores it, onApplicationStart consumes it
 *      into this.wheels.reloadPassword). Without it the switch can never
 *      apply: the framework reads the password BEFORE config/settings.cfm is
 *      loaded, via carryover from the live application scope that
 *      applicationStop() destroys — verified live on Lucee 7, where the
 *      preserved parameters alone produced an endless 302 chain with the
 *      environment stuck on development.
 *
 * Structural spec (no runtime): reads each copy and asserts the three parts
 * are wired. Modeled on ApplicationCfcInjectorAssignmentSpec.cfc.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("reload environment-switch redirect parity (issue ##3030)", () => {

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

					it("preserves reload+password on environment-switch redirects in " & relPath, () => {
						var absolute = repoRoot & "/" & relPath;
						expect(fileExists(absolute)).toBeTrue("Missing file: " & absolute);
						var content = fileRead(absolute);

						// Default strip list stays intact for boolean reloads...
						expect(
							reFind('local\.stripParams\s*=\s*"reload,password,lock";', content) > 0
						).toBeTrue(
							relPath & " must default stripParams to reload,password,lock so plain "
							& "?reload=true keeps stripping everything (issue ##3030)."
						);

						// ...and narrows to lock-only for environment switches.
						expect(
							reFind('local\.stripParams\s*=\s*"lock";', content) > 0
						).toBeTrue(
							relPath & " must narrow stripParams to just lock for environment-switch "
							& "redirects so URL.reload and URL.password reach the request that starts "
							& "the new application (issue ##3030)."
						);

						// The strip filter must consult the computed list, not a literal.
						expect(
							content contains "ListFindNoCase(local.stripParams, local.key)"
						).toBeTrue(
							relPath & " must filter the redirect query string against local.stripParams."
						);
						expect(
							content contains 'ListFindNoCase("reload,password,lock", local.key)'
						).toBeFalse(
							relPath & " still hardcodes the reload,password,lock strip list in the "
							& "query-string filter — environment-switch parameters would never survive "
							& "the redirect (issue ##3030)."
						);

						// The narrowing is gated on a switch that can actually apply:
						// non-boolean, non-empty reload value plus a supplied password
						// and a configured reloadPassword.
						expect(
							reFind("!IsBoolean\(url\.reload\)", content) > 0
						).toBeTrue(
							relPath & " must treat only non-boolean reload values as environment switches."
						);
					});

					it("breaks the restart loop once the requested environment is active in " & relPath, () => {
						var absolute = repoRoot & "/" & relPath;
						expect(fileExists(absolute)).toBeTrue("Missing file: " & absolute);
						var content = fileRead(absolute);

						expect(
							reFind('local\.environmentSwitchAlreadyApplied\s*=\s*StructKeyExists\(url,\s*"reload"\)', content) > 0
						).toBeTrue(
							relPath & " must compute environmentSwitchAlreadyApplied before the reload "
							& "gate (issue ##3030)."
						);
						expect(
							content contains "application.wheels.environment == url.reload"
						).toBeTrue(
							relPath & " must compare the active environment against url.reload so the "
							& "redirected request does not restart again (issue ##3030)."
						);
						expect(
							reFind("&&\s*!local\.environmentSwitchAlreadyApplied", content) > 0
						).toBeTrue(
							relPath & " must skip the applicationStop() gate when the requested "
							& "environment is already active — without this the preserved parameters "
							& "redirect forever because redirectAfterReload defaults to false "
							& "(issue ##3030)."
						);
					});

					it("hands the reloadPassword across the applicationStop() boundary in " & relPath, () => {
						var absolute = repoRoot & "/" & relPath;
						expect(fileExists(absolute)).toBeTrue("Missing file: " & absolute);
						var content = fileRead(absolute);

						// Store side ($handleRestartAppRequest): single-use server-scope
						// entry holding the app's own configured password.
						expect(
							reFind('server\["\$wheelsReloadPasswordHandoff_"\s*&\s*this\.name\]\s*=\s*\{', content) > 0
						).toBeTrue(
							relPath & " must stash the configured reloadPassword in a server-scope "
							& "handoff before applicationStop() — the framework's switch code runs "
							& "before config/settings.cfm is loaded and otherwise has no password to "
							& "verify against on the post-restart cold start (issue ##3030)."
						);

						// Consume side (onApplicationStart): single-use + expiry-guarded,
						// seeded into this.wheels so the framework's carryover picks it up.
						expect(
							content contains "StructDelete(server, local.handoffKey)"
						).toBeTrue(
							relPath & " must delete the handoff on first consumption (single-use)."
						);
						expect(
							content contains "DateCompare(Now(), local.handoff.expiresAt) < 0"
						).toBeTrue(
							relPath & " must honor the handoff expiry so a stale entry is never applied."
						);
						expect(
							content contains "this.wheels.reloadPassword = local.handoff.reloadPassword;"
						).toBeTrue(
							relPath & " must seed this.wheels.reloadPassword from the handoff so the "
							& "framework's reloadPassword carryover works on the cold start "
							& "(issue ##3030)."
						);
					});

				})(rel);
			}

		});

	}

}
