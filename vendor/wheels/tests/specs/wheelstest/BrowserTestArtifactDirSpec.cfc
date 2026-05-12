component extends="wheels.WheelsTest" {

	function run() {
		describe("BrowserTest artifact directory creation", () => {

			// Regression for #2614: $captureFailureArtifacts used to call
			// directoryCreate(path, true). On Adobe ColdFusion the second
			// argument is rejected with "Parameter validation error for the
			// DIRECTORYCREATE function. The function takes 1 parameter.",
			// which fired any time a browser spec failed under ACF and the
			// artifact directory did not yet exist. The fix routes through
			// java.io.File.mkdirs(), which recurses parents uniformly on
			// every engine — same canonical pattern as ManifestCache's
			// $ensureDir (#2567). This spec covers the multi-level parent
			// case the BIF createPath flag was meant to handle.
			it("creates deeply nested artifact directories whose parents do not yet exist", () => {
				var nestedRoot = GetTempDirectory() & "wheels-browser-2614-" & CreateUUID() & "/level-a/level-b/level-c";
				try {
					var browserTest = new wheels.wheelstest.BrowserTest();
					browserTest.$ensureArtifactDir(nestedRoot);
					expect(DirectoryExists(nestedRoot)).toBeTrue(
						"expected $ensureArtifactDir to create the nested artifact root"
					);
				} finally {
					var unique = ListFirst(Replace(nestedRoot, GetTempDirectory(), ""), "/");
					var sweep = GetTempDirectory() & unique;
					if (DirectoryExists(sweep)) {
						DirectoryDelete(sweep, true);
					}
				}
			});

			it("is a no-op when the artifact directory already exists", () => {
				var existingDir = GetTempDirectory() & "wheels-browser-2614-" & CreateUUID();
				DirectoryCreate(existingDir);
				try {
					var browserTest = new wheels.wheelstest.BrowserTest();
					browserTest.$ensureArtifactDir(existingDir);
					expect(DirectoryExists(existingDir)).toBeTrue(
						"expected the pre-existing directory to remain"
					);
				} finally {
					if (DirectoryExists(existingDir)) {
						DirectoryDelete(existingDir, true);
					}
				}
			});

		});
	}
}
