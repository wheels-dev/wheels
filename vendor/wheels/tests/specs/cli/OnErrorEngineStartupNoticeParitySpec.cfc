/**
 * Every copy of public/Application.cfc passes over the Adobe ColdFusion 2025
 * graphqlclient startup notice at the very top of onError() (#3726), before
 * anything touches the application scope: the notice arrives before the
 * application starts, and anything that could throw or render there would
 * turn a working first request into an HTTP 500.
 *
 * Structural spec (no runtime), like OnErrorFallbackGuardSpec: the guard lives
 * in each app's onError(), which the suite cannot drive without tearing down
 * the application. The matcher itself is covered by EngineStartupNoticeSpec.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("onError passes over the engine startup notice first (##3726)", () => {

			var repoRoot = expandPath("/wheels/../..");
			var targets = [
				"cli/lucli/templates/app/public/Application.cfc",
				"public/Application.cfc",
				"examples/starter-app/public/Application.cfc",
				"examples/tweet/public/Application.cfc"
			];

			for (var rel in targets) {
				(function(relPath) {
					it("guards the notice before any application scope use in " & relPath, () => {
						$requireRepoPath("cli/lucli/templates/app/public/Application.cfc");
						var absolute = repoRoot & "/" & relPath;
						expect(fileExists(absolute)).toBeTrue("Missing file: " & absolute);
						var content = fileRead(absolute);
						var start = reFindNoCase("public\s+void\s+function\s+onError\s*\([^\)]*\)\s*\{", content, 1, true);
						expect(start.len[1] > 0).toBeTrue(relPath & " should declare a public void onError() function.");
						var body = mid(content, start.pos[1] + start.len[1], len(content));

						var noticePos = reFindNoCase("new\s+wheels\.events\.EngineStartupNotice\s*\(", body);
						var benignPos = reFindNoCase("\.isBenign\s*\(\s*arguments\.Exception\s*,", body);
						var recordPos = reFindNoCase("\.record\s*\(\s*\)", body);
						var appPos = reFindNoCase("application\s*[\.,\)]", body);
						expect(noticePos > 0 && benignPos > noticePos).toBeTrue(
							relPath & " onError() must call wheels.events.EngineStartupNotice.isBenign(arguments.Exception, ...)."
						);
						expect(appPos == 0 || benignPos < appPos).toBeTrue(
							relPath & " onError() must check the startup notice before it touches the application scope."
						);
						// It returns only after logging, so the notice is recorded, not silently dropped.
						var returnPos = reFindNoCase("\breturn\s*;", body);
						expect(recordPos > benignPos && returnPos > recordPos).toBeTrue(
							relPath & " onError() must record the notice and then return."
						);
					});
				})(rel);
			}

		});

	}

}
