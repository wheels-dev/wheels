/**
 * Regression for issue ##2773 — "First 15 Minutes tutorial fails. The key
 * [WO] does not exist."
 *
 * When the Wheels Injector fails to load during onApplicationStart (e.g. a
 * stale ##wheels mapping under Lucee 7), application.wo is never assigned.
 * onError then fires for the original Injector failure, swallows a second
 * failure inside its try/catch, and unconditionally calls
 * application.wo.$getRequestTimeout() — which throws "The key [WO] does not
 * exist." and replaces the real diagnostic with a cryptic cascade.
 *
 * The defensive fix is in each Application.cfc whose onError uses the
 * try/catch + DI-init pattern: after the catch, guard application.wo with
 * StructKeyExists(application, "wo") and short-circuit to a minimal error
 * response if the global never came up. Without the guard, init failure
 * cascades and hides the actual root cause from the user.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Application.cfc onError fallback hardening (issue ##2773)", () => {

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
					it("guards application.wo before dereferencing it in onError() in " & relPath, () => {
						var absolute = repoRoot & "/" & relPath;
						expect(fileExists(absolute)).toBeTrue("Missing file: " & absolute);

						var raw = fileRead(absolute);
						var content = $stripCfmlComments(raw);

						// Extract the onError function body so we don't pick up
						// guards from other handlers (e.g. onAbort) that already
						// check application.wo.
						var onErrorMatch = reFindNoCase(
							"(?s)public\s+void\s+function\s+onError\s*\([^\)]*\)\s*\{",
							content,
							1,
							true
						);
						expect(onErrorMatch.len[1] > 0).toBeTrue(
							relPath & " should declare a public void onError() function."
						);

						var bodyStart = onErrorMatch.pos[1] + onErrorMatch.len[1];
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
						var onErrorBody = mid(content, bodyStart, bodyEnd - bodyStart + 1);

						// 1. The cascade-guard must exist.
						expect(
							reFindNoCase(
								"StructKeyExists\s*\(\s*application\s*,\s*[""']wo[""']\s*\)",
								onErrorBody
							) > 0
						).toBeTrue(
							relPath & " onError() must guard application.wo with "
							& "StructKeyExists(application, ""wo"") before dereferencing "
							& "it — without the guard a failed Injector init cascades "
							& "into ""The key [WO] does not exist."" (issue ##2773)."
						);

						// 2. The guard must short-circuit before the first
						//    application.wo.* dereference. Find the position of
						//    the first such call after the catch block closes,
						//    and assert the guard appears before it.
						var catchClosePattern = "catch\s*\(\s*any\s+\w+\s*\)\s*\{[^\}]*\}";
						var catchMatch = reFindNoCase(catchClosePattern, onErrorBody, 1, true);

						// If the body has a try/catch at the top of onError, the
						// guard must land between the close of that catch and
						// the first application.wo.* reference. If it doesn't
						// (simpler form), the guard still needs to come before
						// the first application.wo.* reference.
						var scanFrom = (catchMatch.pos[1] > 0)
							? (catchMatch.pos[1] + catchMatch.len[1])
							: 1;
						var tail = mid(onErrorBody, scanFrom, len(onErrorBody) - scanFrom + 1);

						var derefPos = reFindNoCase("application\.wo\.", tail);
						var guardPos = reFindNoCase(
							"StructKeyExists\s*\(\s*application\s*,\s*[""']wo[""']\s*\)",
							tail
						);

						if (derefPos > 0) {
							expect(guardPos > 0 && guardPos < derefPos).toBeTrue(
								relPath & " onError() dereferences application.wo "
								& "after the recovery try/catch without first "
								& "guarding it. The guard must appear before any "
								& "application.wo.* call so a failed Injector "
								& "init can short-circuit cleanly (issue ##2773)."
							);
						}
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
