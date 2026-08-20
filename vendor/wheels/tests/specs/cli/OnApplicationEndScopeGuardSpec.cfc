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
 * runner. So we assert the source shape across every shipped Application.cfc
 * that declares onApplicationEnd — the CLI template (`wheels new`), the repo
 * demo app, and the bundled example apps. A discovery check walks those
 * trees so a newly added copy cannot slip the list. Mirrors
 * OnErrorFallbackGuardSpec (issue ##2773).
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Application.cfc onApplicationEnd scope hardening (issue ##3379)", () => {

			// expandPath("/wheels") resolves to vendor/wheels via the configured
			// Lucee mapping; the repo root is two levels above.
			var repoRoot = expandPath("/wheels/../..");
			var targets = [
				"cli/lucli/templates/app/public/Application.cfc",
				"public/Application.cfc",
				"examples/starter-app/public/Application.cfc",
				"examples/tweet/public/Application.cfc"
			];

			it("scans every shipped Application.cfc that declares onApplicationEnd", () => {
				var discovered = $discoverShippedOnApplicationEndHandlers(repoRoot);
				expect(ArrayLen(discovered) > 0).toBeTrue(
					"Expected to discover at least one shipped Application.cfc "
					& "that declares onApplicationEnd under cli/lucli/templates, "
					& "public/, or examples/."
				);
				for (var relPath in targets) {
					expect(ArrayFindNoCase(discovered, relPath) > 0).toBeTrue(
						"Required shipped handler " & relPath
						& " was not discovered. Found: " & ArrayToList(discovered)
					);
				}
				for (var foundPath in discovered) {
					expect(ArrayFindNoCase(targets, foundPath) > 0).toBeTrue(
						"Shipped Application.cfc " & foundPath
						& " declares onApplicationEnd but is not in the guard's "
						& "targets list. Add it so a future revert cannot go "
						& "uncaught (issue ##3379)."
					);
				}
			});

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
	 * Walk the trees that ship an Application.cfc to users (CLI `wheels new`
	 * template, repo demo app, bundled examples) and return repo-relative
	 * paths of every file that still declares onApplicationEnd after comment
	 * stripping. Test-only Application.cfc copies under vendor/wheels/tests,
	 * rocketunit_tests, and cli/lucli/tests are out of scope — they are not
	 * shipped to apps.
	 */
	private array function $discoverShippedOnApplicationEndHandlers(required string repoRoot) {
		var shippedRoots = ["cli/lucli/templates", "public", "examples"];
		var found = [];
		var rootNormalized = Replace(arguments.repoRoot, "\", "/", "all");
		if (Right(rootNormalized, 1) == "/" && Len(rootNormalized) > 1) {
			rootNormalized = Left(rootNormalized, Len(rootNormalized) - 1);
		}

		for (var relRoot in shippedRoots) {
			var absoluteRoot = rootNormalized & "/" & relRoot;
			if (!DirectoryExists(absoluteRoot)) {
				continue;
			}
			var files = DirectoryList(absoluteRoot, true, "path", "*.cfc");
			for (var filePath in files) {
				if (ListLast(filePath, "/\") != "Application.cfc") {
					continue;
				}
				var content = $stripCfmlComments(FileRead(filePath));
				if (reFindNoCase("function\s+onApplicationEnd\s*\(", content) == 0) {
					continue;
				}
				var normalized = Replace(filePath, "\", "/", "all");
				var rel = Mid(normalized, Len(rootNormalized) + 2, Len(normalized));
				ArrayAppend(found, rel);
			}
		}

		ArraySort(found, "textnocase");
		return found;
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
