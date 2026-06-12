component extends="wheels.WheelsTest" {

	// Issue ##3179: the published wheels-core artifact shipped internal AI
	// planning artifacts (specs, draft PR.md/ISSUE.md files, patches) into every
	// app's vendor/wheels/docs/. The cause is an unfiltered `cp -r docs/*` in
	// tools/build/scripts/prepare-core.sh that sweeps in docs/superpowers/ and
	// docs/plans/ — internal working documents, not user documentation.
	//
	// This guard pins the prepare scripts so a wholesale docs copy must exclude
	// the internal trees. It mirrors the structural-source-scan pattern of
	// buildArtifactLicenseSpec.cfc and BareCfabortGuardSpec.cfc: invoking the
	// shell scripts from inside a test would need a writable build context and
	// platform tooling, so we read the source and assert the contract instead.
	// Sibling prepare scripts (base/cli/starterApp) do not copy docs today, but
	// the guard covers them too so the exposure cannot reappear via copy-paste.

	function run() {

		describe("Release-artifact prepare scripts exclude internal docs trees (issue ##3179)", () => {

			// expandPath("/wheels") resolves to vendor/wheels via the configured
			// Lucee mapping; the repo root is two levels above.
			var repoRoot = expandPath("/wheels/../..");
			var scripts = [
				"tools/build/scripts/prepare-base.sh",
				"tools/build/scripts/prepare-core.sh",
				"tools/build/scripts/prepare-cli.sh",
				"tools/build/scripts/prepare-starterApp.sh"
			];

			// Internal-only docs trees that must never reach a published package.
			var internalTrees = ["superpowers", "plans"];

			for (var rel in scripts) {
				// Capture the loop variable so the closure body binds the current
				// value, not the final iteration's value.
				(function(relPath) {
					describe(relPath, () => {

						for (var treeName in internalTrees) {
							(function(tree) {
								it("does not ship docs/" & tree & " when it copies the docs tree", () => {
									var src = fileRead(repoRoot & "/" & relPath);

									// Only scripts that copy the whole docs tree are
									// at risk; skip the rest (they ship no docs).
									var copiesDocs = reFindNoCase(
										"cp[[:space:]]+-r[[:space:]]+docs/\*",
										src
									) > 0;
									if (!copiesDocs) {
										expect(true).toBeTrue();
										return;
									}

									// A wholesale copy must be paired with an explicit
									// removal of the internal tree from the build dir.
									var excludesTree = reFindNoCase(
										"rm[[:space:]]+-rf[^\n]*docs/" & tree,
										src
									) > 0;
									expect(excludesTree).toBeTrue(
										relPath & " copies the full docs tree but never excludes docs/" & tree
										& " — internal planning artifacts would ship into every app's vendor/wheels/docs/. "
										& "Remove it from the build dir after the copy, e.g. "
										& "`rm -rf ""${BUILD_DIR}/wheels/docs/" & tree & """`. See issue ##3179."
									);
								});
							})(treeName);
						}

					});
				})(rel);
			}

		});

	}

}
