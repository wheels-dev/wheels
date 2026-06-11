/**
 * Specs for FrameworkUpgrader — the in-place vendor/wheels/ swap that
 * powers `wheels upgrade`. Exercises file-level behavior in isolation
 * so the Module-level spec doesn't need to fake out CLI-bundle paths.
 *
 * Covers issue #3035 (PR1 of the apply-mode plan): the previous
 * `wheels upgrade check` suggested `brew upgrade wheels`, which only
 * touches the CLI binary and never the app's vendor/wheels/ copy.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.upgrader = new cli.lucli.services.FrameworkUpgrader();
	}

	private struct function buildFixture(
		string sourceManifest = '{"name":"wheels","version":"4.0.1"}',
		string targetManifest = '{"name":"wheels","version":"4.0.0-SNAPSHOT+1687"}',
		boolean writeTargetManifest = true,
		string sourceMarker = "new-framework",
		string targetMarker = "old-framework"
	) {
		var f = {};
		f.root = getTempDirectory() & "wheels-upgrader-fixture-#createUUID()#";
		f.sourceDir = f.root & "/bundled/vendor/wheels";
		f.vendorParent = f.root & "/app/vendor";
		f.vendorDir = f.vendorParent & "/wheels";
		directoryCreate(f.sourceDir, true, true);
		directoryCreate(f.vendorParent, true, true);
		directoryCreate(f.vendorDir, true, true);
		fileWrite(f.sourceDir & "/wheels.json", arguments.sourceManifest);
		fileWrite(f.sourceDir & "/marker.txt", arguments.sourceMarker);
		// Throw a nested file in so we know the recursive copy actually runs.
		directoryCreate(f.sourceDir & "/model", true, true);
		fileWrite(f.sourceDir & "/model/Base.cfc", "// new model");
		if (arguments.writeTargetManifest) {
			fileWrite(f.vendorDir & "/wheels.json", arguments.targetManifest);
		}
		fileWrite(f.vendorDir & "/marker.txt", arguments.targetMarker);
		return f;
	}

	private void function cleanup(required struct fixture) {
		if (directoryExists(arguments.fixture.root)) {
			directoryDelete(arguments.fixture.root, true);
		}
	}

	function run() {

		describe("FrameworkUpgrader.looksLikeWheelsFramework", () => {

			it("returns true for a directory with wheels.json", () => {
				var dir = getTempDirectory() & "lwf-#createUUID()#";
				directoryCreate(dir, true);
				fileWrite(dir & "/wheels.json", "{}");
				expect(upgrader.looksLikeWheelsFramework(dir)).toBeTrue();
				directoryDelete(dir, true);
			});

			it("returns true for a directory with legacy box.json (no wheels.json)", () => {
				var dir = getTempDirectory() & "lwf-#createUUID()#";
				directoryCreate(dir, true);
				fileWrite(dir & "/box.json", "{}");
				expect(upgrader.looksLikeWheelsFramework(dir)).toBeTrue();
				directoryDelete(dir, true);
			});

			it("returns false for a directory with neither manifest", () => {
				var dir = getTempDirectory() & "lwf-#createUUID()#";
				directoryCreate(dir, true);
				fileWrite(dir & "/README.md", "");
				expect(upgrader.looksLikeWheelsFramework(dir)).toBeFalse();
				directoryDelete(dir, true);
			});

			it("returns false for a non-existent directory", () => {
				expect(upgrader.looksLikeWheelsFramework(getTempDirectory() & "does-not-exist-#createUUID()#")).toBeFalse();
			});
		});

		describe("FrameworkUpgrader.readFrameworkVersion", () => {

			it("reads version from wheels.json when present", () => {
				var dir = getTempDirectory() & "rfv-#createUUID()#";
				directoryCreate(dir, true);
				fileWrite(dir & "/wheels.json", '{"version":"4.0.1"}');
				expect(upgrader.readFrameworkVersion(dir)).toBe("4.0.1");
				directoryDelete(dir, true);
			});

			it("falls back to box.json when wheels.json is absent", () => {
				var dir = getTempDirectory() & "rfv-#createUUID()#";
				directoryCreate(dir, true);
				fileWrite(dir & "/box.json", '{"version":"3.9.0"}');
				expect(upgrader.readFrameworkVersion(dir)).toBe("3.9.0");
				directoryDelete(dir, true);
			});

			it("prefers wheels.json over box.json when both exist", () => {
				var dir = getTempDirectory() & "rfv-#createUUID()#";
				directoryCreate(dir, true);
				fileWrite(dir & "/wheels.json", '{"version":"4.0.1"}');
				fileWrite(dir & "/box.json", '{"version":"3.9.0"}');
				expect(upgrader.readFrameworkVersion(dir)).toBe("4.0.1");
				directoryDelete(dir, true);
			});

			it("returns empty string when no manifest is present", () => {
				var dir = getTempDirectory() & "rfv-#createUUID()#";
				directoryCreate(dir, true);
				expect(upgrader.readFrameworkVersion(dir)).toBe("");
				directoryDelete(dir, true);
			});

			it("returns empty string for malformed manifest JSON", () => {
				var dir = getTempDirectory() & "rfv-#createUUID()#";
				directoryCreate(dir, true);
				fileWrite(dir & "/wheels.json", "{not json");
				expect(upgrader.readFrameworkVersion(dir)).toBe("");
				directoryDelete(dir, true);
			});
		});

		describe("FrameworkUpgrader.applyUpgrade", () => {

			it("replaces vendor/wheels/ contents with the source contents", () => {
				var f = buildFixture();
				var result = upgrader.applyUpgrade(f.sourceDir, f.vendorDir, false);
				expect(result.success).toBeTrue();
				expect(fileRead(f.vendorDir & "/marker.txt")).toBe("new-framework");
				expect(fileExists(f.vendorDir & "/model/Base.cfc")).toBeTrue();
				cleanup(f);
			});

			it("records the old and new framework versions on success", () => {
				var f = buildFixture();
				var result = upgrader.applyUpgrade(f.sourceDir, f.vendorDir, false);
				expect(result.oldVersion).toBe("4.0.0-SNAPSHOT+1687");
				expect(result.newVersion).toBe("4.0.1");
				cleanup(f);
			});

			it("backs up the existing vendor/wheels/ when doBackup is true", () => {
				var f = buildFixture();
				var result = upgrader.applyUpgrade(f.sourceDir, f.vendorDir, true);
				expect(result.success).toBeTrue();
				expect(len(result.backupDir)).toBeGT(0);
				expect(directoryExists(result.backupDir)).toBeTrue();
				expect(fileRead(result.backupDir & "/marker.txt")).toBe("old-framework");
				// And the live vendor/wheels/ has the new contents.
				expect(fileRead(f.vendorDir & "/marker.txt")).toBe("new-framework");
				cleanup(f);
			});

			it("uses a vendor/wheels.bak-<timestamp> naming pattern for the backup", () => {
				var f = buildFixture();
				var result = upgrader.applyUpgrade(f.sourceDir, f.vendorDir, true);
				expect(reFindNoCase("/wheels\.bak-\d{8}-\d{6}", result.backupDir)).toBeGT(0);
				cleanup(f);
			});

			it("does NOT create a backup when doBackup is false", () => {
				var f = buildFixture();
				var result = upgrader.applyUpgrade(f.sourceDir, f.vendorDir, false);
				expect(result.success).toBeTrue();
				expect(result.backupDir).toBe("");
				// No sibling .bak-* directory should exist.
				var sibs = directoryList(f.vendorParent, false, "name");
				for (var name in sibs) {
					expect(reFindNoCase("^wheels\.bak-", name)).toBe(0);
				}
				cleanup(f);
			});

			it("returns an error when the source directory does not exist", () => {
				var f = buildFixture();
				var bogusSource = f.root & "/does-not-exist";
				var result = upgrader.applyUpgrade(bogusSource, f.vendorDir, false);
				expect(result.success).toBeFalse();
				expect(result.error).toInclude("Source");
				// And vendor/wheels/ is untouched.
				expect(fileRead(f.vendorDir & "/marker.txt")).toBe("old-framework");
				cleanup(f);
			});

			it("returns an error when the source directory lacks a wheels.json/box.json marker", () => {
				var f = buildFixture();
				fileDelete(f.sourceDir & "/wheels.json");
				var result = upgrader.applyUpgrade(f.sourceDir, f.vendorDir, false);
				expect(result.success).toBeFalse();
				expect(result.error).toInclude("does not look like a Wheels framework");
				expect(fileRead(f.vendorDir & "/marker.txt")).toBe("old-framework");
				cleanup(f);
			});

			it("refuses to swap when target dir exists but does not look like a Wheels framework", () => {
				var f = buildFixture(writeTargetManifest = false);
				// buildFixture skipped writing wheels.json — the target dir is
				// now just a directory with marker.txt, so the sniff must fail.
				var result = upgrader.applyUpgrade(f.sourceDir, f.vendorDir, false);
				expect(result.success).toBeFalse();
				expect(result.error).toInclude("does not look like a Wheels framework");
				expect(fileRead(f.vendorDir & "/marker.txt")).toBe("old-framework");
				cleanup(f);
			});

			it("refuses when source and target resolve to the same directory", () => {
				// Running `wheels upgrade` inside the wheels repo checkout
				// itself resolves the bundled source to the very directory
				// being replaced — the rename/delete would destroy the source
				// mid-swap. The guard must fire before any destructive step.
				var f = buildFixture();
				var result = upgrader.applyUpgrade(f.vendorDir, f.vendorDir, true);
				expect(result.success).toBeFalse();
				expect(result.error).toInclude("same directory");
				expect(fileRead(f.vendorDir & "/marker.txt")).toBe("old-framework");
				// No backup may exist — that would mean the rename ran first.
				var sibs = directoryList(f.vendorParent, false, "name");
				for (var name in sibs) {
					expect(reFindNoCase("^wheels\.bak-", name)).toBe(0);
				}
				cleanup(f);
			});

			it("refuses when the target lives inside the source directory", () => {
				var f = buildFixture();
				// Make vendor/ itself sniff as a framework dir and use it as
				// the source — the target vendor/wheels/ sits inside it.
				fileWrite(f.vendorParent & "/wheels.json", '{"version":"9.9.9"}');
				var result = upgrader.applyUpgrade(f.vendorParent, f.vendorDir, false);
				expect(result.success).toBeFalse();
				expect(fileRead(f.vendorDir & "/marker.txt")).toBe("old-framework");
				cleanup(f);
			});

			it("refuses when the source lives inside the target directory", () => {
				var f = buildFixture();
				var nested = f.vendorDir & "/sub";
				directoryCreate(nested, true, true);
				fileWrite(nested & "/wheels.json", '{"version":"9.9.9"}');
				var result = upgrader.applyUpgrade(nested, f.vendorDir, false);
				expect(result.success).toBeFalse();
				expect(fileRead(f.vendorDir & "/marker.txt")).toBe("old-framework");
				cleanup(f);
			});

			it("creates vendor/wheels/ from scratch when it does not already exist", () => {
				var f = buildFixture();
				directoryDelete(f.vendorDir, true);
				var result = upgrader.applyUpgrade(f.sourceDir, f.vendorDir, true);
				expect(result.success).toBeTrue();
				expect(result.oldVersion).toBe("");
				expect(result.backupDir).toBe("");
				expect(fileRead(f.vendorDir & "/marker.txt")).toBe("new-framework");
				cleanup(f);
			});

			it("returns an error when the parent of vendorDir does not exist", () => {
				var f = buildFixture();
				var bogusVendor = f.root & "/no-parent-here/wheels";
				var result = upgrader.applyUpgrade(f.sourceDir, bogusVendor, false);
				expect(result.success).toBeFalse();
				expect(result.error).toInclude("Parent");
				cleanup(f);
			});
		});
	}
}
