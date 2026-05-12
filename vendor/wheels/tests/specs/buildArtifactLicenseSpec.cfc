component extends="wheels.WheelsTest" {

	// Apache 2.0 §4(a) requires every distributed artifact to ship a copy of
	// LICENSE, and §4(d) requires NOTICE to propagate to derivatives. PR ##2593
	// added that bundling to tools/build/scripts/prepare-base.sh but missed
	// the three sibling prepare scripts (core, cli, starter-app). This spec
	// pins all four scripts to the same contract so they cannot drift back.
	//
	// Structural assertion against the script source — invoking the shell
	// scripts from inside a test would require a writable build context,
	// release inputs, and platform-specific tooling. Reading the source and
	// asserting the canonical `cp LICENSE` / `cp NOTICE` lines mirrors the
	// regression-guard pattern used by buildInfoSpec.cfc and
	// routesViewBrowserFixturesSpec.cfc.

	function run() {

		describe("Release-artifact prepare scripts bundle LICENSE and NOTICE", () => {

			// expandPath("/wheels") resolves to vendor/wheels via the
			// configured Lucee mapping; the repo root is two levels above.
			var repoRoot = expandPath("/wheels/../..");
			var scripts = [
				"tools/build/scripts/prepare-base.sh",
				"tools/build/scripts/prepare-core.sh",
				"tools/build/scripts/prepare-cli.sh",
				"tools/build/scripts/prepare-starterApp.sh"
			];

			for (var rel in scripts) {
				// Capture the loop variable so the closure body binds the
				// current value, not the final iteration's value.
				(function(relPath) {
					describe(relPath, () => {

						it("copies LICENSE into its BUILD_DIR", () => {
							var src = fileRead(repoRoot & "/" & relPath);
							var hasLicense = reFindNoCase(
								"cp[[:space:]]+LICENSE[[:space:]]+""\$\{BUILD_DIR\}",
								src
							) > 0;
							expect(hasLicense).toBeTrue(
								relPath & " must bundle LICENSE into its build artifact for Apache 2.0 §4(a) compliance. Mirror the `cp LICENSE ""${BUILD_DIR}/""` line from prepare-base.sh."
							);
						});

						it("copies NOTICE into its BUILD_DIR", () => {
							var src = fileRead(repoRoot & "/" & relPath);
							var hasNotice = reFindNoCase(
								"cp[[:space:]]+NOTICE[[:space:]]+""\$\{BUILD_DIR\}",
								src
							) > 0;
							expect(hasNotice).toBeTrue(
								relPath & " must bundle NOTICE into its build artifact for Apache 2.0 §4(d) propagation. Mirror the `cp NOTICE ""${BUILD_DIR}/""` line from prepare-base.sh."
							);
						});

					});
				})(rel);
			}

		});

	}

}
