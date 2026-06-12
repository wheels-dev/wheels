component extends="wheels.WheelsTest" {

	// Regression: the published wheels-core manifest (tools/build/core/box.json)
	// shipped both `directory:"vendor/wheels"` and `packageDirectory:"vendor/wheels"`
	// with `createPackageDirectory:true`. CommandBox appends packageDirectory to
	// directory, so `box install wheels-core` in any app without a pre-seeded
	// installPaths entry — which is every `wheels new` app, since the template
	// ships no box.json — installed the framework to vendor/wheels/vendor/wheels/.
	//
	// The double-nested copy is dead weight that never loads; the existing
	// vendor/wheels stays untouched, so the user believes they upgraded while the
	// app keeps running the old framework (the #2887 scenario). The generated
	// box.json then records the wrong installPaths, perpetuating it on every
	// future install/update.
	//
	// Fix: directory:"vendor", packageDirectory:"wheels" — CommandBox then
	// resolves installPaths {"wheels-core":"vendor/wheels/"}. This spec pins the
	// manifest against the double-nesting regression. Issue ##3177.

	function run() {

		describe("wheels-core box.json manifest (tools/build/core/box.json)", () => {

			// expandPath("/wheels") resolves to vendor/wheels via the configured
			// Lucee mapping; the repo root is two levels above.
			var repoRoot = expandPath("/wheels/../..");
			var manifestPath = repoRoot & "/tools/build/core/box.json";

			it("resolves the CommandBox install path to vendor/wheels, not a double-nest", () => {
				expect(fileExists(manifestPath)).toBeTrue("Missing file: " & manifestPath);
				var manifest = deserializeJSON(fileRead(manifestPath));

				expect(manifest).toHaveKey("directory");
				expect(manifest).toHaveKey("packageDirectory");

				// CommandBox install target with createPackageDirectory=true is
				// `directory` + "/" + `packageDirectory`. Normalize slashes so the
				// assertion is independent of trailing/leading separators.
				var createsPkgDir = StructKeyExists(manifest, "createPackageDirectory") && manifest.createPackageDirectory;
				var resolved = createsPkgDir
					? manifest.directory & "/" & manifest.packageDirectory
					: manifest.directory;
				resolved = reReplace(resolved, "/+", "/", "all");
				resolved = reReplace(resolved, "/$", "", "one");

				expect(resolved).toBe(
					"vendor/wheels",
					"box install wheels-core must land the framework at vendor/wheels/. With "
					& "directory=""#manifest.directory#"" and packageDirectory=""#manifest.packageDirectory#"" "
					& "CommandBox resolves to ""#resolved#"". Set directory:""vendor"" and "
					& "packageDirectory:""wheels"" so it does not double-nest. See issue ##3177."
				);
			});

			it("does not double-nest the framework under vendor/wheels/vendor/wheels", () => {
				var manifest = deserializeJSON(fileRead(manifestPath));
				var createsPkgDir = StructKeyExists(manifest, "createPackageDirectory") && manifest.createPackageDirectory;
				var resolved = createsPkgDir
					? manifest.directory & "/" & manifest.packageDirectory
					: manifest.directory;
				resolved = reReplace(resolved, "/+", "/", "all");

				expect(resolved).notToInclude(
					"vendor/wheels/vendor/wheels",
					"The wheels-core manifest must not resolve the install path to "
					& "vendor/wheels/vendor/wheels — that leaves the running framework "
					& "un-upgraded. See issue ##3177."
				);
			});

		});

	}

}
