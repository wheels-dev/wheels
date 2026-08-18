/**
 * Regression for issue ##3379 — "Element wo is undefined in a Java object of
 * type class [Ljava.lang.String;".
 *
 * On Adobe ColdFusion 2023 the framework's onApplicationEnd() handler fires
 * synchronously during applicationStop() teardown (e.g. a ?reload restart or
 * an idle-timeout reclaim). Inside that teardown the LIVE `application` scope
 * is no longer reliable — bare `application.wo` can resolve against a
 * stale/torn-down scope and land on a Java String[] instead of the Wheels
 * global, throwing "Element wo is undefined in a Java object of type class
 * [Ljava.lang.String;". The whole site then errors until the CF service is
 * restarted.
 *
 * The only dependable reference during shutdown is the passed-in
 * arguments.applicationScope (already used for the $wheelsBrowserLauncher
 * cleanup in the same handler). The fix routes the onapplicationend.cfm
 * include through arguments.applicationScope.wo and guards it with
 * StructKeyExists(arguments.applicationScope, "wo") so a partially reclaimed
 * scope degrades to a no-op instead of a hard error.
 *
 * This is a structural guard: the failure only manifests on Adobe CF during
 * real teardown, which cannot be reproduced inside a spec without killing the
 * runner. So we assert the source shape across every Application.cfc that
 * ships the handler — the CLI template (what `wheels new` scaffolds) and the
 * repo's own demo app. Mirrors OnErrorFallbackGuardSpec (issue ##2773).
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Application.cfc onApplicationEnd scope hardening (issue ##3379)", () => {

			// expandPath("/wheels") resolves to vendor/wheels via the configured
			// Lucee mapping; the repo root is two levels above.
			var repoRoot = expandPath("/wheels/../..");
			var targets = [
				"cli/lucli/templates/app/public/Application.cfc",
				"public/Application.cfc"
			];

			for (var rel in targets) {
				// Capture the loop variable so the closure body binds the
				// current value, not the final iteration's value.
				(function(relPath) {
					it("routes onApplicationEnd through arguments.applicationScope.wo in " & relPath, () => {
						var absolute = repoRoot & "/" & relPath;
						expect(fileExists(absolute)).toBeTrue("Missing file: " & absolute);

						var raw = fileRead(absolute);
						var content = $stripCfmlComments(raw);

						// Extract the onApplicationEnd function body so we don't
						// pick up references from other handlers.
						var fnMatch = reFindNoCase(
							"(?s)public\s+void\s+function\s+onApplicationEnd\s*\([^\)]*\)\s*\{",
							content,
							1,
							true
						);
						expect(fnMatch.len[1] > 0).toBeTrue(
							relPath & " should declare a public void onApplicationEnd() function."
						);

						var bodyStart = fnMatch.pos[1] + fnMatch.len[1];
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
						var fnBody = mid(content, bodyStart, bodyEnd - bodyStart + 1);

						// 1. The handler must NOT dereference the live application
						//    scope — bare `application.wo` is exactly what breaks on
						//    Adobe CF during teardown.
						expect(
							reFindNoCase("application\.wo\.", fnBody) == 0
						).toBeTrue(
							relPath & " onApplicationEnd() must not dereference the live "
							& "application scope (application.wo.*). During Adobe CF 2023 "
							& "teardown that resolves to a stale Java String[] and throws "
							& "'Element wo is undefined...' (issue ##3379). Route the call "
							& "through arguments.applicationScope.wo instead."
						);

						// 2. The include must be routed through the passed-in
						//    application scope, the only reliable reference at
						//    shutdown.
						expect(
							reFindNoCase("arguments\.applicationScope\.wo\.", fnBody) > 0
						).toBeTrue(
							relPath & " onApplicationEnd() must invoke the Wheels global via "
							& "arguments.applicationScope.wo (mirroring the $wheelsBrowserLauncher "
							& "cleanup) so it survives teardown on Adobe CF (issue ##3379)."
						);

						// 3. The dereference must be guarded so a partially reclaimed
						//    scope degrades to a no-op instead of a hard error.
						var guardPos = reFindNoCase(
							"StructKeyExists\s*\(\s*arguments\.applicationScope\s*,\s*[""']wo[""']\s*\)",
							fnBody
						);
						var derefPos = reFindNoCase("arguments\.applicationScope\.wo\.", fnBody);
						expect(guardPos > 0 && guardPos < derefPos).toBeTrue(
							relPath & " onApplicationEnd() must guard "
							& "arguments.applicationScope.wo with "
							& "StructKeyExists(arguments.applicationScope, ""wo"") before "
							& "dereferencing it, so a torn-down scope short-circuits cleanly "
							& "(issue ##3379)."
						);
					});
				})(rel);
			}

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
