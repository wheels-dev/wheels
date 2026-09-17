/**
 * Regression for issue ##3379 — "Element wo is undefined in a Java object of
 * type class [Ljava.lang.String;".
 *
 * On Adobe ColdFusion the session reaper
 * (SessionTracker.SessionCleanUpAgent) calls onSessionEnd() after the live
 * application scope can already be torn down. Bare `application.wo.$simpleLock`
 * then resolves against a stale/torn-down scope and lands on a Java String[]
 * instead of the Wheels global, throwing "Element wo is undefined in a Java
 * object of type class [Ljava.lang.String;". The whole site then errors until
 * the CF service is restarted. This is the same class of failure as
 * onApplicationEnd (issue ##3379). The onApplicationEnd paste from ##3381
 * does not cover this handler; the crash continues at
 * public/Application.cfc onSessionEnd.
 *
 * The only dependable reference during that teardown is the passed-in
 * arguments.applicationScope. The fix routes `$simpleLock` through
 * arguments.applicationScope.wo and guards it with
 * StructKeyExists(arguments.applicationScope, "wo") so a reclaimed scope
 * degrades to a no-op instead of a hard error. Unlike onApplicationEnd, this
 * path does not `$include` onapplicationend.cfm, so it does not need the
 * extra `wheels` / `eventPath` StructKeyExists checks.
 *
 * This is a structural guard: the failure only manifests on Adobe CF during
 * real session-reaper teardown, which cannot be reproduced inside a spec
 * without killing the runner. So we assert the source shape across every
 * shipped Application.cfc that declares onSessionEnd — the CLI template
 * (`wheels new`), the repo demo app, and the bundled example apps. A
 * discovery check walks those trees so a newly added copy cannot slip the
 * list. Mirrors OnApplicationEndScopeGuardSpec (issue ##3379).
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Application.cfc onSessionEnd scope hardening (issue ##3379)", () => {

			// expandPath("/wheels") resolves to vendor/wheels via the configured
			// Lucee mapping; the repo root is two levels above.
			var repoRoot = expandPath("/wheels/../..");
			var targets = [
				"cli/lucli/templates/app/public/Application.cfc",
				"public/Application.cfc",
				"examples/starter-app/public/Application.cfc",
				"examples/tweet/public/Application.cfc"
			];

			it("scans every shipped Application.cfc that declares onSessionEnd", () => {
				var discovered = $discoverShippedOnSessionEndHandlers(repoRoot);
				expect(ArrayLen(discovered) > 0).toBeTrue(
					"Expected to discover at least one shipped Application.cfc "
					& "that declares onSessionEnd under cli/lucli/templates, "
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
						& " declares onSessionEnd but is not in the guard's "
						& "targets list. Add it so a future revert cannot go "
						& "uncaught (issue ##3379)."
					);
				}
			});

			for (var rel in targets) {
				// Capture the loop variable so the closure body binds the
				// current value, not the final iteration's value.
				(function(relPath) {
					it("routes onSessionEnd through arguments.applicationScope.wo in " & relPath, () => {
						var absolute = repoRoot & "/" & relPath;
						expect(fileExists(absolute)).toBeTrue("Missing file: " & absolute);

						var raw = fileRead(absolute);
						var content = $stripCfmlComments(raw);

						// Extract the onSessionEnd function body so we don't
						// pick up references from other handlers.
						var fnMatch = reFindNoCase(
							"(?s)public\s+void\s+function\s+onSessionEnd\s*\([^\)]*\)\s*\{",
							content,
							1,
							true
						);
						expect(fnMatch.len[1] > 0).toBeTrue(
							relPath & " should declare a public void onSessionEnd() function."
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
						//    Adobe CF when SessionTracker.SessionCleanUpAgent fires
						//    after the live scope is already torn down.
						expect(
							reFindNoCase("application\.wo\.", fnBody) == 0
						).toBeTrue(
							relPath & " onSessionEnd() must not dereference the live "
							& "application scope (application.wo.*). Adobe's session "
							& "reaper can call this handler after the live scope is "
							& "reclaimed, throwing 'Element wo is undefined...' "
							& "(issue ##3379). Route the call through "
							& "arguments.applicationScope.wo instead."
						);

						// 2. `$simpleLock` must be routed through the passed-in
						//    application scope, the only reliable reference at
						//    teardown.
						expect(
							reFindNoCase("arguments\.applicationScope\.wo\.", fnBody) > 0
						).toBeTrue(
							relPath & " onSessionEnd() must invoke the Wheels global via "
							& "arguments.applicationScope.wo so it survives session-reaper "
							& "teardown on Adobe CF (issue ##3379)."
						);

						// 3. The dereference must be guarded so a reclaimed scope
						//    degrades to a no-op instead of a hard error. Only the
						//    `wo` check is required — this path uses `$simpleLock`,
						//    not `$include`, so eventPath / wheels-struct guards
						//    are out of scope.
						var guardPos = reFindNoCase(
							"StructKeyExists\s*\(\s*arguments\.applicationScope\s*,\s*[""']wo[""']\s*\)",
							fnBody
						);
						var derefPos = reFindNoCase("arguments\.applicationScope\.wo\.", fnBody);
						expect(guardPos > 0 && guardPos < derefPos).toBeTrue(
							relPath & " onSessionEnd() must guard "
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
	 * paths of every file that still declares onSessionEnd after comment
	 * stripping. Test-only Application.cfc copies under vendor/wheels/tests,
	 * rocketunit_tests, and cli/lucli/tests are out of scope — they are not
	 * shipped to apps.
	 */
	private array function $discoverShippedOnSessionEndHandlers(required string repoRoot) {
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
				if (reFindNoCase("function\s+onSessionEnd\s*\(", content) == 0) {
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
