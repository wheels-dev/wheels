/**
 * Regression: cli/lucli/templates/app/public/Application.cfc and the three
 * derived copies (./public, examples/tweet, examples/starter-app) declared a
 * local "injector" variable in onApplicationStart() / onError() and then
 * referenced "application.wheelsdi" without ever assigning it locally. The
 * runtime only worked because Injector.init() self-registers at
 * "application.wheelsdi" — the template itself was inconsistent and read as
 * broken (issue ##2622).
 *
 * Assert each Application.cfc:
 *   - assigns "application.wheelsdi = new wheels.Injector(...)" directly
 *   - does not declare a local "injector = new wheels.Injector(...)"
 *   - does not call "injector.getInstance(\"global\")" on the orphan local
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Application.cfc injector assignment", () => {

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
					it("assigns injector to application.wheelsdi in " & relPath, () => {
						var absolute = repoRoot & "/" & relPath;
						expect(fileExists(absolute)).toBeTrue("Missing file: " & absolute);

						var content = fileRead(absolute);

						expect(content contains "application.wheelsdi = new wheels.Injector(").toBeTrue(
							relPath & " should assign the injector to application.wheelsdi directly."
						);

						expect(reFind("(^|[\s;\{\}])injector\s*=\s*new\s+wheels\.Injector", content) > 0).toBeFalse(
							relPath & " still declares a local injector variable — every reference should go through application.wheelsdi."
						);

						expect(content contains "injector.getInstance(""global"")").toBeFalse(
							relPath & " still calls injector.getInstance(""global"") on the orphan local — use application.wheelsdi.getInstance(""global"")."
						);

						expect(content contains "application.wheelsdi.getInstance(""global"")").toBeTrue(
							relPath & " should read the wheels global through application.wheelsdi."
						);
					});
				})(rel);
			}

		});

	}

}
