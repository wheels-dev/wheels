component extends="wheels.WheelsTest" {

	function run() {
		describe("ManifestCache directory creation", () => {

			// Regression for #2567: the original $ensureDir used
			// DirectoryCreate(path, true). The createPath flag is a
			// Lucee-only extension — Adobe CF rejects the second
			// argument with "The function takes 1 parameter", which
			// crashed the Tools → Packages page on every fresh ACF
			// install. The fix routes through java.io.File.mkdirs(),
			// which is engine-agnostic. This test exercises the
			// multi-level parent case the BIF createPath flag was
			// meant to cover.
			it("creates deeply nested cache directories whose parents do not yet exist", () => {
				var nestedRoot = GetTempDirectory() & "wheels-cache-2567-" & CreateUUID() & "/level-a/level-b/level-c/";
				try {
					var cache = new wheels.services.packages.ManifestCache(root = nestedRoot);
					cache.writeIndex(["wheels-sentry"]);
					expect(DirectoryExists(nestedRoot)).toBeTrue("expected $ensureDir to create the nested cache root");
					expect(cache.hasFreshIndex()).toBeTrue("expected the index file to land under the freshly created nested root");
					expect(cache.readIndex()).toBe(["wheels-sentry"]);
				} finally {
					// Walk up to the unique parent we control, so we
					// remove only this test's tree.
					var unique = ListFirst(Replace(nestedRoot, GetTempDirectory(), ""), "/");
					var sweep = GetTempDirectory() & unique;
					if (DirectoryExists(sweep)) {
						DirectoryDelete(sweep, true);
					}
				}
			});

			it("creates the manifests subdirectory when only the root exists", () => {
				var root = GetTempDirectory() & "wheels-cache-2567-" & CreateUUID() & "/";
				try {
					var cache = new wheels.services.packages.ManifestCache(root = root);
					cache.writeManifest("wheels-sentry", {name: "wheels-sentry", versions: [{version: "1.0.0"}]});
					expect(DirectoryExists(root & "manifests")).toBeTrue("expected the manifests/ subdirectory to be created");
					expect(cache.hasFreshManifest("wheels-sentry")).toBeTrue();
				} finally {
					if (DirectoryExists(root)) {
						DirectoryDelete(root, true);
					}
				}
			});
		});
	}
}
