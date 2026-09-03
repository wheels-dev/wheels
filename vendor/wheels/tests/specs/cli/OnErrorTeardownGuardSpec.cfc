/**
 * Regression for issue #3379 — Adobe CF tears down the application scope
 * during applicationStop(), and onError's post-guard dereferences of
 * application.wo then throw "Element wo is undefined in a Java object of type
 * class [Ljava.lang.String" — cascading over the original error.
 *
 * The StructKeyExists(application, "wo") guard (issue #2773) short-circuits
 * the cold-start case, but Adobe can still reclaim the scope AFTER the guard
 * passes and BEFORE the dereferences run. The main onError handling must
 * therefore be wrapped in its own try/catch that degrades to the same shared
 * minimal fallback ($renderMinimalError) instead of cascading.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Application.cfc onError teardown hardening (issue ##3379)", () => {

			// expandPath("/wheels") resolves to vendor/wheels via the configured
			// Lucee mapping; the repo root is two levels above.
			var repoRoot = expandPath("/wheels/../..");
			var targets = [
				"cli/lucli/templates/app/public/Application.cfc",
				"public/Application.cfc",
				"examples/starter-app/public/Application.cfc",
				"examples/tweet/public/Application.cfc"
			];

			for (var rel in targets) {
				// Capture the loop variable so the closure body binds the
				// current value, not the final iteration's value.
				(function(relPath) {
					it("onError wraps the post-guard handling in try/catch with a shared fallback", () => {
						var absolute = repoRoot & "/" & relPath;
						expect(fileExists(absolute)).toBeTrue("Missing file: " & absolute);

						var content = $stripCfmlComments(fileRead(absolute));
						var onErrorBody = $extractOnErrorBody(content, relPath);

						// The shared fallback must be reachable from both the
						// cold-start guard and the torn-down-scope catch.
						expect(findNoCase("$renderMinimalError", onErrorBody) > 0).toBeTrue(
							relPath & " onError() must call $renderMinimalError for the "
							& "cold-start and torn-down-scope paths (issue ##3379)."
						);

						// After the wo guard, the main handling must sit inside a
						// try block that precedes the first application.wo
						// dereference, so a mid-onError teardown is caught rather
						// than cascading "Element wo is undefined".
						var guardPos = reFindNoCase(
							"StructKeyExists\s*\(\s*application\s*,\s*[""']wo[""']\s*\)",
							onErrorBody
						);
						expect(guardPos > 0).toBeTrue(
							relPath & " onError() must keep the StructKeyExists(application, 'wo') guard."
						);

						var tail = mid(onErrorBody, guardPos, len(onErrorBody) - guardPos + 1);
						var tryPos = reFindNoCase("try\s*\{", tail);
						var derefPos = reFindNoCase("application\.wo\.\$getRequestTimeout", tail);
						expect(tryPos > 0 && derefPos > 0 && tryPos < derefPos).toBeTrue(
							relPath & " onError() must wrap the post-guard application.wo "
							& "dereference in a try block so a torn-down scope degrades "
							& "to $renderMinimalError (issue ##3379)."
						);
					});
				})(rel);
			}

		});

	}

	/**
	 * Extract the body of the onError() function via brace counting so guards
	 * in other handlers (e.g. onAbort, onApplicationStart) don't satisfy the
	 * assertions. Mirrors OnErrorFallbackGuardSpec.
	 */
	private string function $extractOnErrorBody(required string content, required string relPath) {
		var onErrorMatch = reFindNoCase(
			"(?s)public\s+void\s+function\s+onError\s*\([^\)]*\)\s*\{",
			arguments.content,
			1,
			true
		);
		expect(onErrorMatch.len[1] > 0).toBeTrue(
			arguments.relPath & " should declare a public void onError() function."
		);

		var bodyStart = onErrorMatch.pos[1] + onErrorMatch.len[1];
		var depth = 1;
		var bodyEnd = bodyStart;
		var iEnd = len(arguments.content);
		for (var i = bodyStart; i <= iEnd; i++) {
			var ch = mid(arguments.content, i, 1);
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
		return mid(arguments.content, bodyStart, bodyEnd - bodyStart + 1);
	}

	/**
	 * Strip CFML tag, block, and line comments before scanning so a
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
