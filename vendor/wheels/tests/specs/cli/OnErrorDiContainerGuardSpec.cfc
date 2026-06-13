/**
 * Regression for issue ##3061 — onError() unconditionally re-created the DI
 * container, silently wiping all user service registrations after any error
 * page.
 *
 * Application.cfc::onError() began with:
 *
 *   application.wheelsdi = new wheels.Injector("wheels.Bindings");
 *
 * Injector.init() self-registers at application.wheelsdi, so this construction
 * replaced the live container on EVERY uncaught exception — including routine
 * development-mode 404 error pages (Wheels.RouteNotFound etc.) — discarding
 * every registration made in config/services.cfm plus all cached singletons.
 * From that moment inject()-declared services stopped resolving and
 * controllers crashed with "Element <SERVICE> is undefined in THIS." until the
 * next reload.
 *
 * The re-creation exists only as a fallback for "the Wheels global never came
 * up" (issue ##2773), so it must be guarded: construct a fresh Injector only
 * when application.wheelsdi is missing, and rebuild application.wo only when
 * it is missing. This spec pins that guard across all four same-lineage
 * Application.cfc copies.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Application.cfc onError DI-container guard (issue ##3061)", () => {

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
					it("guards the Injector re-creation in onError() in " & relPath, () => {
						var absolute = repoRoot & "/" & relPath;
						expect(fileExists(absolute)).toBeTrue("Missing file: " & absolute);

						var raw = fileRead(absolute);
						var content = $stripCfmlComments(raw);
						var onErrorBody = $extractOnErrorBody(content, relPath);

						// onError must keep its recovery path: the Injector
						// construction stays available for the genuine
						// "Wheels never booted" case.
						var injectorPos = reFindNoCase("new\s+wheels\.Injector\s*\(", onErrorBody);
						expect(injectorPos > 0).toBeTrue(
							relPath & " onError() should retain the fallback "
							& "Injector construction for the cold-start "
							& "recovery path (issue ##2773)."
						);

						// 1. The construction must be reachable only when the
						//    live container is missing. Injector.init()
						//    self-registers at application.wheelsdi, so an
						//    unguarded `new wheels.Injector(...)` clobbers the
						//    live container even without the assignment.
						var diGuardPos = reFindNoCase(
							"if\s*\(\s*!\s*StructKeyExists\s*\(\s*application\s*,\s*[""']wheelsdi[""']\s*\)\s*\)",
							onErrorBody
						);
						expect(diGuardPos > 0 && diGuardPos < injectorPos).toBeTrue(
							relPath & " onError() must guard the Injector "
							& "re-creation with "
							& "if (!StructKeyExists(application, ""wheelsdi"")) — "
							& "an unguarded construction replaces the live "
							& "container on every error page and wipes all "
							& "config/services.cfm registrations (issue ##3061)."
						);

						// 2. Likewise application.wo must only be rebuilt when
						//    missing, so the cached Global (and everything it
						//    carries) survives routine error pages.
						var woAssignPos = reFindNoCase(
							"application\.wo\s*=\s*application\.wheelsdi\.getInstance",
							onErrorBody
						);
						expect(woAssignPos > 0).toBeTrue(
							relPath & " onError() should retain the fallback "
							& "application.wo assignment for the cold-start "
							& "recovery path."
						);
						var woGuardPos = reFindNoCase(
							"if\s*\(\s*!\s*StructKeyExists\s*\(\s*application\s*,\s*[""']wo[""']\s*\)\s*\)",
							onErrorBody
						);
						expect(woGuardPos > 0 && woGuardPos < woAssignPos).toBeTrue(
							relPath & " onError() must guard the application.wo "
							& "rebuild with "
							& "if (!StructKeyExists(application, ""wo"")) so the "
							& "live Wheels global is not replaced on routine "
							& "error pages (issue ##3061)."
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
