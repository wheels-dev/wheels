component extends="wheels.WheelsTest" {

	// Regression: the published wheels-base-template 4.0.3 zip omitted the
	// conventional db/ directory, so SQLite/H2 file paths under db/ failed
	// without a manual `mkdir`. prepare-base.sh:34 copies db/ into the build
	// dir, but tools/build/base/.gitignore (shipped as the package .gitignore)
	// contained `/db/**`, and CommandBox `package publish` honors .gitignore
	// patterns — so db/.keep was silently stripped from the artifact.
	//
	// The fix keeps `/db/**` ignored for end users (their SQLite db files stay
	// out of git) but whitelists `!/db/.keep` so the directory itself ships.
	//
	// A paired presence assertion in the release.yml "Validate Package
	// Structure" step is deferred to a human follow-up — the wheels-bot
	// GitHub App token cannot push changes to `.github/workflows/**` without
	// the `workflows` permission, so the workflow hardening is tracked
	// separately from this code fix.
	//
	// Structural assertion against the source files — actually running
	// `package publish` from inside a test would require a writable build
	// context and CommandBox tooling. Reading the source mirrors the
	// regression-guard pattern in buildArtifactLicenseSpec.cfc and
	// LinuxPackageStagingSpec.cfc. Issue #3174.

	function run() {

		describe("wheels-base-template ships the conventional db/ directory", () => {

			// expandPath("/wheels") resolves to vendor/wheels via the
			// configured Lucee mapping; the repo root is two levels above.
			var repoRoot = expandPath("/wheels/../..");
			var gitignore = repoRoot & "/tools/build/base/.gitignore";

			it("seeds db/.keep so prepare-base.sh has a directory marker to copy", () => {
				expect(fileExists(repoRoot & "/db/.keep")).toBeTrue(
					"db/.keep must exist — prepare-base.sh:34 copies db/ into the build artifact and the keep file is what makes the otherwise-empty directory survive."
				);
			});

			it("does not let the template .gitignore strip db/.keep at publish time", () => {
				expect(fileExists(gitignore)).toBeTrue("Missing file: " & gitignore);
				var src = fileRead(gitignore);

				// If a /db/ ignore pattern is present, a re-include for the
				// keep file MUST follow so CommandBox's gitignore-honoring
				// publish keeps the directory.
				var ignoresDb = reFindNoCase("(?m)^[[:space:]]*/db/\*\*[[:space:]]*$", src) > 0;
				var reIncludesKeep = reFindNoCase("(?m)^[[:space:]]*!/db/\.keep[[:space:]]*$", src) > 0;

				expect(!ignoresDb || reIncludesKeep).toBeTrue(
					"tools/build/base/.gitignore ignores /db/** but does not whitelist !/db/.keep — CommandBox `package publish` honors .gitignore and strips the db/ directory from the published template (issue ##3174). Add `!/db/.keep` so the directory ships while end-user db files stay ignored."
				);
			});

		});

	}

}
