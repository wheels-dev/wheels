component extends="wheels.WheelsTest" {

	function run() {
		describe("BrowserTest artifact directory creation", () => {

			// Regression for #2614 — Adobe CF rejects directoryCreate(path, true);
			// $ensureArtifactDir routes through java.io.File.mkdirs() instead.
			it("creates deeply nested artifact directories whose parents do not yet exist (regression ##2614)", () => {
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
