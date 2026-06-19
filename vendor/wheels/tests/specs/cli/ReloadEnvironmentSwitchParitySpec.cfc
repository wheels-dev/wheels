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
 * The fix has four cooperating parts, and ALL FOUR same-lineage copies of
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
 *   4. Both the preserve (1) and the handoff (3) honor
 *      allowEnvironmentSwitchViaUrl: when switching is explicitly disallowed —
 *      set(allowEnvironmentSwitchViaUrl=false) or the framework's
 *      production/testing/maintenance auto-disable — the request degrades to
 *      the strip-everything plain restart. This gate MUST live pre-restart in
 *      the template: after applicationStop() the framework cannot enforce the
 *      flag itself (the revert in wheels/events/onapplicationstart.cfc needs
 *      carryover state the restart destroys, and the cold-start default is
 *      allow). A missing flag counts as allowed, matching the framework's
 *      carryover default.
 *
 * Structural spec (no runtime): reads each copy and asserts the four parts
 * are wired. Modeled on ApplicationCfcInjectorAssignmentSpec.cfc.
 *
 * Issue ##3053 addendum: the ##3030 fix read the URL scope unscoped
 * (StructKeyExists(url, "reload"), url.reload, ...) inside $buildRedirectUrl,
 * which had ALWAYS declared a string local named url. On Adobe CF unscoped
 * name resolution finds the local before the URL scope, so every password
 * reload and environment switch dereferenced a string and returned HTTP 500
 * (CLAUDE.md anti-pattern ##11 — reserved scope names). The local is renamed
 * to redirectPath; the fifth it-block below pins the rename and fails if any
 * local/var declaration named url reappears anywhere in these files.
 *
 * Second ##3053 addendum (the ##3051 Adobe smoke legs caught it): the reload
 * gate and the shared-application-name branch invoke their handlers through
 * $simpleLock with componentReference = "application" — a component PATH that
 * Global.cfc's $invoke hands to cfinvoke. On case-sensitive filesystems Adobe
 * CF resolves CFC names by exact case then all-lowercase, so the lowercase
 * literal never matches Application.cfc and every authorized reload dies with
 * HTTP 500 "Could not find the ColdFusion component or interface application".
 * It passed every pre-merge check because macOS bind mounts (and Lucee's
 * resolver) are case-insensitive — the environment was a red herring; the
 * filesystem was the variable. The sixth it-block pins the case-exact literal.
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

					it("honors allowEnvironmentSwitchViaUrl on the preserve and handoff paths in " & relPath, () => {
						var absolute = repoRoot & "/" & relPath;
						expect(fileExists(absolute)).toBeTrue("Missing file: " & absolute);
						var content = fileRead(absolute);

						// Both the redirect-preserve condition ($buildRedirectUrl) and the
						// password-handoff condition ($handleRestartAppRequest) must consult
						// the flag. After applicationStop() the framework cannot enforce it
						// (the revert in wheels/events/onapplicationstart.cfc needs carryover
						// state the restart destroys, and the cold-start default is allow),
						// so this pre-restart gate is the only place the configured
						// off-switch — including the production/testing/maintenance
						// auto-disable — can hold. A disallowed switch must degrade to the
						// strip-all plain restart, never preserve the parameters.
						var flagGuard = '!StructKeyExists\(application\.wheels,\s*"allowEnvironmentSwitchViaUrl"\)\s*\|\|\s*application\.wheels\.allowEnvironmentSwitchViaUrl';
						expect(
							ArrayLen(reMatch(flagGuard, content)) >= 2
						).toBeTrue(
							relPath & " must gate BOTH the reload+password preserve "
							& "($buildRedirectUrl) and the reloadPassword handoff "
							& "($handleRestartAppRequest) on allowEnvironmentSwitchViaUrl so "
							& "set(allowEnvironmentSwitchViaUrl=false) and the production "
							& "auto-disable degrade an environment switch to the strip-all "
							& "plain restart (issues ##3030/##3031)."
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

					it("never shadows the url scope with a local named url in " & relPath, () => {
						var absolute = repoRoot & "/" & relPath;
						expect(fileExists(absolute)).toBeTrue("Missing file: " & absolute);
						var content = fileRead(absolute);

						// Pin the renamed, non-reserved local that carries the redirect
						// target through $buildRedirectUrl (issue ##3053).
						expect(
							reFind("local\.redirectPath\s*=\s*cgi\.path_info", content) > 0
						).toBeTrue(
							relPath & " must carry the redirect target in local.redirectPath "
							& "(issue ##3053)."
						);
						expect(
							content contains "return local.redirectPath;"
						).toBeTrue(
							relPath & " must return local.redirectPath from $buildRedirectUrl "
							& "(issue ##3053)."
						);

						// No local/var declaration (or any other use) named url may exist
						// anywhere in the file: this lineage reads the URL scope unscoped in
						// onRequestStart, $handleRestartAppRequest AND $buildRedirectUrl, and
						// on Adobe CF a local named url shadows the URL scope, turning every
						// password reload into an HTTP 500 (issue ##3053, CLAUDE.md
						// anti-pattern ##11 — reserved scope names). Line-anchored scan that
						// skips comment lines (CLAUDE.md anti-pattern ##14).
						var offenders = [];
						var sourceLines = ListToArray(content, Chr(10), true);
						var lineCount = ArrayLen(sourceLines);
						for (var lineNo = 1; lineNo <= lineCount; lineNo++) {
							var line = Trim(sourceLines[lineNo]);
							if (!Len(line)) {
								continue;
							}
							// Skip line comments and block-comment lines (open/continuation).
							if (Left(line, 2) == "//" || Left(line, 2) == "/*" || Left(line, 1) == "*") {
								continue;
							}
							if (
								reFindNoCase("local\.url[^a-z0-9_]", line & " ") > 0
								|| reFindNoCase("var[ #Chr(9)#]+url[ #Chr(9)#=;]", line & " ") > 0
							) {
								ArrayAppend(offenders, "line " & lineNo & ": " & line);
							}
						}
						expect(ArrayLen(offenders) == 0).toBeTrue(
							relPath & " declares or uses a local named url, which shadows the "
							& "URL scope on Adobe CF and breaks every password reload "
							& "(issue ##3053, CLAUDE.md anti-pattern ##11). Offending "
							& ArrayToList(offenders, " | ")
						);
					});

					it("references the Application component case-exactly in " & relPath, () => {
						var absolute = repoRoot & "/" & relPath;
						expect(fileExists(absolute)).toBeTrue("Missing file: " & absolute);
						var content = fileRead(absolute);

						// Both $simpleLock dispatch sites (the shared-application-name
						// branch in onSessionStart and the reload gate in onRequestStart)
						// must reference the component as "Application" -- matching
						// Application.cfc exactly. Adobe CF resolves CFC names on
						// case-sensitive filesystems by exact case then all-lowercase,
						// so the lowercase literal never matches and every authorized
						// reload returns HTTP 500 "Could not find the ColdFusion
						// component or interface application" (issue ##3053 follow-up;
						// caught by the ##3051 Adobe smoke legs). reMatch is
						// case-sensitive, which is exactly what this pin needs.
						expect(
							ArrayLen(reMatch('"componentReference"\s*=\s*"Application"', content)) >= 2
						).toBeTrue(
							relPath & " must dispatch BOTH the onSessionStart "
							& "shared-application-name branch and the onRequestStart reload "
							& "gate with componentReference set to the case-exact "
							& """Application"" literal so Adobe CF can resolve "
							& "Application.cfc on case-sensitive filesystems "
							& "(issue ##3053 follow-up)."
						);

						// And no dispatch site may carry a differently-cased literal.
						// Line-anchored scan that skips comment lines (CLAUDE.md
						// anti-pattern ##14) so prose mentioning the lowercase form
						// stays legal.
						var caseOffenders = [];
						var specLines = ListToArray(content, Chr(10), true);
						var specLineCount = ArrayLen(specLines);
						for (var specLineNo = 1; specLineNo <= specLineCount; specLineNo++) {
							var specLine = Trim(specLines[specLineNo]);
							if (!Len(specLine)) {
								continue;
							}
							if (Left(specLine, 2) == "//" || Left(specLine, 2) == "/*" || Left(specLine, 1) == "*") {
								continue;
							}
							var literalMatches = reMatchNoCase('"componentReference"\s*=\s*"application"', specLine);
							for (var literalMatch in literalMatches) {
								if (Find('"Application"', literalMatch) == 0) {
									ArrayAppend(caseOffenders, "line " & specLineNo & ": " & specLine);
								}
							}
						}
						expect(ArrayLen(caseOffenders) == 0).toBeTrue(
							relPath & " dispatches with a miscased Application component "
							& "reference, which Adobe CF cannot resolve on case-sensitive "
							& "filesystems -- every authorized reload becomes an HTTP 500 "
							& "(issue ##3053 follow-up). Offending "
							& ArrayToList(caseOffenders, " | ")
						);
					});

				})(rel);
			}

		});

	}

}
