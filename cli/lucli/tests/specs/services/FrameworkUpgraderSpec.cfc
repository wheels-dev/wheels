/**
 * Specs for FrameworkUpgrader — the in-place vendor/wheels/ swap that
 * powers `wheels upgrade apply`. Exercises file-level behavior in
 * isolation so the Module-level spec doesn't need to fake out CLI-bundle
 * paths.
 *
 * Covers issue #3035 (PR1 of the apply-mode plan): the previous
 * `wheels upgrade check` suggested `brew upgrade wheels`, which only
 * touches the CLI binary and never the app's vendor/wheels/ copy.
 *
 * Fixture lifecycle: every temp directory is registered in
 * variables.tempPaths (via newTempDir()/buildFixture()) and removed by the
 * afterEach hook in each describe, so a failing expectation can't leak
 * fixtures into the OS temp dir.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.upgrader = new cli.lucli.services.FrameworkUpgrader();
		variables.tempPaths = [];
	}

	/**
	 * Create (and register for afterEach cleanup) a unique temp directory.
	 */
	private string function newTempDir(required string prefix) {
		var dir = getTempDirectory() & arguments.prefix & "-#createUUID()#";
		directoryCreate(dir, true, true);
		arrayAppend(variables.tempPaths, dir);
		return dir;
	}

	private struct function buildFixture(
		string sourceManifest = '{"name":"wheels","version":"4.0.1"}',
		string targetManifest = '{"name":"wheels","version":"4.0.0-SNAPSHOT+1687"}',
		boolean writeTargetManifest = true,
		string sourceMarker = "new-framework",
		string targetMarker = "old-framework"
	) {
		var f = {};
		f.root = newTempDir("wheels-upgrader-fixture");
		f.sourceDir = f.root & "/bundled/vendor/wheels";
		f.vendorParent = f.root & "/app/vendor";
		f.vendorDir = f.vendorParent & "/wheels";
		f.backupsDir = f.root & "/app/.wheels/backups";
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

	private void function $cleanupTempDirs() {
		for (var p in variables.tempPaths) {
			if (directoryExists(p)) {
				directoryDelete(p, true);
			}
		}
		variables.tempPaths = [];
	}

	/**
	 * Drop read permission on a file so directoryCopy fails partway —
	 * the hermetic mid-swap failure the CopyFailed contract is for.
	 * Returns false when the platform can't revoke read access (Windows),
	 * in which case the caller skips: the contract is covered on POSIX.
	 */
	private boolean function $makeUnreadable(required string path) {
		var File = createObject("java", "java.io.File");
		var handle = File.init(arguments.path);
		return handle.setReadable(false, false) && !handle.canRead();
	}

	private void function $makeReadable(required string path) {
		createObject("java", "java.io.File").init(arguments.path).setReadable(true, false);
	}

	function run() {

		describe("FrameworkUpgrader.looksLikeWheelsFramework", () => {

			afterEach(() => $cleanupTempDirs());

			// #3039 review hardening: a bare manifest file is not evidence —
			// any CFML project has a box.json. Require version (and, for
			// box.json, a wheels-ish name/slug when one is present).

			it("returns true for wheels.json with a non-empty version", () => {
				var dir = newTempDir("lwf");
				fileWrite(dir & "/wheels.json", '{"version":"4.0.1"}');
				expect(upgrader.looksLikeWheelsFramework(dir)).toBeTrue();
			});

			it("returns false for wheels.json without a version", () => {
				var dir = newTempDir("lwf");
				fileWrite(dir & "/wheels.json", "{}");
				expect(upgrader.looksLikeWheelsFramework(dir)).toBeFalse();
			});

			it("returns false for malformed wheels.json", () => {
				var dir = newTempDir("lwf");
				fileWrite(dir & "/wheels.json", "{not json");
				expect(upgrader.looksLikeWheelsFramework(dir)).toBeFalse();
			});

			it("returns true for legacy box.json with a version and a wheels name", () => {
				var dir = newTempDir("lwf");
				fileWrite(dir & "/box.json", '{"name":"cfwheels","version":"3.9.0"}');
				expect(upgrader.looksLikeWheelsFramework(dir)).toBeTrue();
			});

			it("returns true for legacy box.json with a version and a wheels slug", () => {
				var dir = newTempDir("lwf");
				fileWrite(dir & "/box.json", '{"slug":"wheels-be","version":"4.1.0-SNAPSHOT"}');
				expect(upgrader.looksLikeWheelsFramework(dir)).toBeTrue();
			});

			it("returns true for a version-only box.json (no name/slug — old framework drops)", () => {
				var dir = newTempDir("lwf");
				fileWrite(dir & "/box.json", '{"version":"3.9.0"}');
				expect(upgrader.looksLikeWheelsFramework(dir)).toBeTrue();
			});

			it("returns false for a generic app box.json (name myapp)", () => {
				var dir = newTempDir("lwf");
				fileWrite(dir & "/box.json", '{"name":"myapp","version":"1.0.0"}');
				expect(upgrader.looksLikeWheelsFramework(dir)).toBeFalse();
			});

			it("returns false for box.json with an empty version", () => {
				var dir = newTempDir("lwf");
				fileWrite(dir & "/box.json", '{"name":"wheels","version":""}');
				expect(upgrader.looksLikeWheelsFramework(dir)).toBeFalse();
			});

			it("falls back to a qualifying box.json when wheels.json lacks a version", () => {
				var dir = newTempDir("lwf");
				fileWrite(dir & "/wheels.json", "{}");
				fileWrite(dir & "/box.json", '{"name":"wheels","version":"3.9.0"}');
				expect(upgrader.looksLikeWheelsFramework(dir)).toBeTrue();
			});

			it("returns false for a directory with neither manifest", () => {
				var dir = newTempDir("lwf");
				fileWrite(dir & "/README.md", "");
				expect(upgrader.looksLikeWheelsFramework(dir)).toBeFalse();
			});

			it("returns false for a non-existent directory", () => {
				expect(upgrader.looksLikeWheelsFramework(getTempDirectory() & "does-not-exist-#createUUID()#")).toBeFalse();
			});
		});

		describe("FrameworkUpgrader.readFrameworkVersion", () => {

			afterEach(() => $cleanupTempDirs());

			it("reads version from wheels.json when present", () => {
				var dir = newTempDir("rfv");
				fileWrite(dir & "/wheels.json", '{"version":"4.0.1"}');
				expect(upgrader.readFrameworkVersion(dir)).toBe("4.0.1");
			});

			it("falls back to box.json when wheels.json is absent", () => {
				var dir = newTempDir("rfv");
				fileWrite(dir & "/box.json", '{"version":"3.9.0"}');
				expect(upgrader.readFrameworkVersion(dir)).toBe("3.9.0");
			});

			it("prefers wheels.json over box.json when both exist", () => {
				var dir = newTempDir("rfv");
				fileWrite(dir & "/wheels.json", '{"version":"4.0.1"}');
				fileWrite(dir & "/box.json", '{"version":"3.9.0"}');
				expect(upgrader.readFrameworkVersion(dir)).toBe("4.0.1");
			});

			it("returns empty string when no manifest is present", () => {
				var dir = newTempDir("rfv");
				expect(upgrader.readFrameworkVersion(dir)).toBe("");
			});

			it("returns empty string for malformed manifest JSON", () => {
				var dir = newTempDir("rfv");
				fileWrite(dir & "/wheels.json", "{not json");
				expect(upgrader.readFrameworkVersion(dir)).toBe("");
			});
		});

		describe("FrameworkUpgrader.reserveBackupPath", () => {

			afterEach(() => $cleanupTempDirs());

			it("returns <project>/.wheels/backups/wheels.bak-<timestamp>, outside vendor/, never an existing path", () => {
				var dir = newTempDir("rbp");
				var vendorDir = dir & "/vendor/wheels";
				directoryCreate(vendorDir, true, true);
				var first = upgrader.reserveBackupPath(vendorDir);
				expect(first).toBe(dir & "/.wheels/backups/" & listLast(first, "/"));
				expect(reFindNoCase("^wheels\.bak-\d{8}-\d{6}$", listLast(first, "/"))).toBeGT(0);
				expect(first).notToInclude("/vendor/");
				// Occupy the first reservation — the next one must dodge it.
				directoryCreate(first, true, true);
				var second = upgrader.reserveBackupPath(vendorDir);
				expect(second).notToBe(first);
				expect(directoryExists(second)).toBeFalse();
			});
		});

		describe("FrameworkUpgrader box.json wheels-core pin", () => {

			afterEach(() => $cleanupTempDirs());

			it("reads the pin from dependencies or devDependencies", () => {
				var dir = newTempDir("pin");
				expect(upgrader.readBoxJsonCorePin(dir & "/box.json").declared).toBeFalse();
				fileWrite(dir & "/box.json", '{"dependencies":{"wheels-core":"^3.0.1"}}');
				var pin = upgrader.readBoxJsonCorePin(dir & "/box.json");
				expect(pin.declared).toBeTrue();
				expect(pin.value).toBe("^3.0.1");
				fileWrite(dir & "/box.json", '{"devDependencies":{"wheels-core":"4.1.2"}}');
				expect(upgrader.readBoxJsonCorePin(dir & "/box.json").value).toBe("4.1.2");
				fileWrite(dir & "/box.json", '{"installPaths":{"wheels-core":"vendor/wheels/"}}');
				expect(upgrader.readBoxJsonCorePin(dir & "/box.json").declared).toBeFalse();
			});

			it("reports a box.json that isn't a JSON object", () => {
				var dir = newTempDir("pin");
				fileWrite(dir & "/box.json", '{"dependencies":');
				expect(upgrader.readBoxJsonCorePin(dir & "/box.json").error).toInclude("not valid JSON");
				fileWrite(dir & "/box.json", '[1,2]');
				expect(upgrader.readBoxJsonCorePin(dir & "/box.json").error).toInclude("not valid JSON");
			});

			it("lists each section's pin with its own value", () => {
				var dir = newTempDir("pin");
				fileWrite(dir & "/box.json", '{"dependencies":{"wheels-core":"^3.0.1"},"devDependencies":{"wheels-core":"~3.0.0"}}');
				var pins = upgrader.readBoxJsonCorePin(dir & "/box.json").pins;
				expect(arrayLen(pins)).toBe(2);
				expect(pins[1].section).toBe("dependencies");
				expect(pins[1].value).toBe("^3.0.1");
				expect(pins[2].section).toBe("devDependencies");
				expect(pins[2].value).toBe("~3.0.0");
			});

			it("doesn't rewrite a range, channel or forgebox spec", () => {
				for (var spec in ["4.x", ">=4.0.0", "be", "stable", "forgebox:wheels-core@3.0.1", "*", ""]) {
					expect(upgrader.boxJsonCorePinFor(spec, "4.2.0")).toBe("", "spec: " & spec);
				}
			});

			it("rewrites only the named section", () => {
				var dir = newTempDir("pin");
				var before = '{"dependencies":{"wheels-core":"^3.0.1"},"devDependencies":{"wheels-core":"~3.0.0"}}';
				fileWrite(dir & "/box.json", before);
				expect(upgrader.writeBoxJsonCorePin(dir & "/box.json", "~4.2.0", "devDependencies")).toBe(1);
				expect(fileRead(dir & "/box.json")).toBe(replace(before, '"~3.0.0"', '"~4.2.0"'));
			});

			it("keeps a ^ or ~ range for a release and pins a prerelease exactly", () => {
				expect(upgrader.boxJsonCorePinFor("^3.0.1", "4.2.0")).toBe("^4.2.0");
				expect(upgrader.boxJsonCorePinFor("~3.0.1", "4.2.0")).toBe("~4.2.0");
				expect(upgrader.boxJsonCorePinFor("3.0.1", "4.2.0")).toBe("4.2.0");
				expect(upgrader.boxJsonCorePinFor("^3.0.1", "4.2.0-snapshot.2867")).toBe("4.2.0-snapshot.2867");
			});

			it("rewrites only the dependency values and leaves the rest of the file as it was", () => {
				var dir = newTempDir("pin");
				var before = '{' & chr(10)
					& '  "name": "app",' & chr(10)
					& '  "dependencies": { "wheels-core": "^3.0.1", "other": "1.0.0" },' & chr(10)
					& '  "devDependencies": {"wheels-core" :"3.0.1"},' & chr(10)
					& '  "installPaths": { "wheels-core": "vendor/wheels/" }' & chr(10)
					& '}' & chr(10);
				fileWrite(dir & "/box.json", before);
				// A version starting with a digit right after the kept prefix
				// must not be read as a regex group reference.
				var count = upgrader.writeBoxJsonCorePin(dir & "/box.json", "14.2.0");
				expect(count).toBe(2);
				var expected = replace(replace(before, '"wheels-core": "^3.0.1"', '"wheels-core": "14.2.0"'), '"wheels-core" :"3.0.1"', '"wheels-core" :"14.2.0"');
				expect(fileRead(dir & "/box.json")).toBe(expected);
			});
		});

		describe("FrameworkUpgrader.validateSwap", () => {

			afterEach(() => $cleanupTempDirs());

			// #3039 review (blocking): the pre-mutation refusal checks must be
			// callable on their own, BEFORE the caller prints the pre-swap plan
			// (backup destination + `rm -rf … && mv …` restore one-liner) —
			// otherwise every refusal path hands the user a restore command
			// for a backup that was never made. validateSwap() is that same
			// check block, extracted; applyUpgrade() still runs it first, so
			// the checks are idempotent reads with no drift risk.

			it("returns an empty string for a valid source/target pair", () => {
				var f = buildFixture();
				expect(upgrader.validateSwap(f.sourceDir, f.vendorDir)).toBe("");
			});

			it("returns an empty string for a fresh install (target absent, parent present)", () => {
				var f = buildFixture();
				directoryDelete(f.vendorDir, true);
				expect(upgrader.validateSwap(f.sourceDir, f.vendorDir)).toBe("");
			});

			it("returns the sniff refusal for a non-framework source", () => {
				var f = buildFixture();
				fileDelete(f.sourceDir & "/wheels.json");
				expect(upgrader.validateSwap(f.sourceDir, f.vendorDir)).toInclude("does not look like a Wheels framework");
			});

			it("returns the identity refusal when source and target are the same directory", () => {
				var f = buildFixture();
				expect(upgrader.validateSwap(f.vendorDir, f.vendorDir)).toInclude("same directory");
			});

			it("returns the target-sniff refusal when the target exists but is not a framework", () => {
				var f = buildFixture(writeTargetManifest = false);
				expect(upgrader.validateSwap(f.sourceDir, f.vendorDir)).toInclude("does not look like a Wheels framework");
			});

			it("returns the missing-parent refusal without creating anything", () => {
				var f = buildFixture();
				var orphanTarget = f.root & "/no-such-parent/wheels";
				expect(upgrader.validateSwap(f.sourceDir, orphanTarget)).toInclude("Parent of target directory does not exist");
				expect(directoryExists(f.root & "/no-such-parent")).toBeFalse();
			});
		});

		describe("FrameworkUpgrader.applyUpgrade", () => {

			afterEach(() => $cleanupTempDirs());

			it("replaces vendor/wheels/ contents with the source contents", () => {
				var f = buildFixture();
				var result = upgrader.applyUpgrade(f.sourceDir, f.vendorDir, false);
				expect(result.success).toBeTrue();
				expect(fileRead(f.vendorDir & "/marker.txt")).toBe("new-framework");
				expect(fileExists(f.vendorDir & "/model/Base.cfc")).toBeTrue();
			});

			it("records the old and new framework versions on success", () => {
				var f = buildFixture();
				var result = upgrader.applyUpgrade(f.sourceDir, f.vendorDir, false);
				expect(result.oldVersion).toBe("4.0.0-SNAPSHOT+1687");
				expect(result.newVersion).toBe("4.0.1");
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
			});

			it("parks the backup at .wheels/backups/wheels.bak-<timestamp>, leaving only wheels/ in vendor/", () => {
				var f = buildFixture();
				var result = upgrader.applyUpgrade(f.sourceDir, f.vendorDir, true);
				expect(result.backupDir).toBe(f.backupsDir & "/" & listLast(result.backupDir, "/"));
				expect(reFindNoCase("^wheels\.bak-\d{8}-\d{6}$", listLast(result.backupDir, "/"))).toBeGT(0);
				expect(fileRead(result.backupDir & "/marker.txt")).toBe("old-framework");
				// The framework loads every vendor/ folder as a package, so the
				// backup must not sit beside vendor/wheels/.
				expect(directoryList(f.vendorParent, false, "name")).toBe(["wheels"]);
				// And it ignores itself in git, whatever the app's .gitignore says.
				expect(fileRead(f.backupsDir & "/.gitignore")).toInclude("*");
			});

			it("honors a caller-reserved backupPath so pre-swap announcements match reality", () => {
				// runUpgradeApply announces the backup destination BEFORE the
				// swap (#3039 review) — the reserved path it prints must be the
				// path the backup actually lands on.
				var f = buildFixture();
				var reserved = upgrader.reserveBackupPath(f.vendorDir);
				var result = upgrader.applyUpgrade(f.sourceDir, f.vendorDir, true, reserved);
				expect(result.success).toBeTrue();
				expect(result.backupDir).toBe(reserved);
				expect(directoryExists(reserved)).toBeTrue();
				expect(fileRead(reserved & "/marker.txt")).toBe("old-framework");
			});

			it("does NOT create a backup when doBackup is false", () => {
				var f = buildFixture();
				var result = upgrader.applyUpgrade(f.sourceDir, f.vendorDir, false);
				expect(result.success).toBeTrue();
				expect(result.backupDir).toBe("");
				expect(directoryExists(f.backupsDir)).toBeFalse();
				// No sibling .bak-* directory should exist.
				var sibs = directoryList(f.vendorParent, false, "name");
				for (var name in sibs) {
					expect(reFindNoCase("^wheels\.bak-", name)).toBe(0);
				}
			});

			it("returns an error when the source directory does not exist", () => {
				var f = buildFixture();
				var bogusSource = f.root & "/does-not-exist";
				var result = upgrader.applyUpgrade(bogusSource, f.vendorDir, false);
				expect(result.success).toBeFalse();
				expect(result.error).toInclude("Source");
				// And vendor/wheels/ is untouched.
				expect(fileRead(f.vendorDir & "/marker.txt")).toBe("old-framework");
			});

			it("returns an error when the source directory lacks a wheels.json/box.json marker", () => {
				var f = buildFixture();
				fileDelete(f.sourceDir & "/wheels.json");
				var result = upgrader.applyUpgrade(f.sourceDir, f.vendorDir, false);
				expect(result.success).toBeFalse();
				expect(result.error).toInclude("does not look like a Wheels framework");
				expect(fileRead(f.vendorDir & "/marker.txt")).toBe("old-framework");
			});

			it("refuses a source directory whose box.json belongs to a generic app", () => {
				// #3039 review: any CFML project has a box.json — pointing
				// WHEELS_FRAMEWORK_PATH (or a mangled install tree) at a
				// random app must not vendor that app into the target.
				var f = buildFixture();
				fileDelete(f.sourceDir & "/wheels.json");
				fileWrite(f.sourceDir & "/box.json", '{"name":"myapp","version":"1.0.0"}');
				var result = upgrader.applyUpgrade(f.sourceDir, f.vendorDir, false);
				expect(result.success).toBeFalse();
				expect(result.error).toInclude("does not look like a Wheels framework");
				expect(fileRead(f.vendorDir & "/marker.txt")).toBe("old-framework");
			});

			it("refuses to swap when target dir exists but does not look like a Wheels framework", () => {
				var f = buildFixture(writeTargetManifest = false);
				// buildFixture skipped writing wheels.json — the target dir is
				// now just a directory with marker.txt, so the sniff must fail.
				var result = upgrader.applyUpgrade(f.sourceDir, f.vendorDir, false);
				expect(result.success).toBeFalse();
				expect(result.error).toInclude("does not look like a Wheels framework");
				expect(fileRead(f.vendorDir & "/marker.txt")).toBe("old-framework");
			});

			it("refuses when source and target resolve to the same directory", () => {
				// Running the apply inside the wheels repo checkout itself
				// resolves the bundled source to the very directory being
				// replaced — the rename/delete would destroy the source
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
			});

			it("refuses when the target lives inside the source directory", () => {
				var f = buildFixture();
				// Make vendor/ itself sniff as a framework dir and use it as
				// the source — the target vendor/wheels/ sits inside it.
				fileWrite(f.vendorParent & "/wheels.json", '{"version":"9.9.9"}');
				var result = upgrader.applyUpgrade(f.vendorParent, f.vendorDir, false);
				expect(result.success).toBeFalse();
				expect(fileRead(f.vendorDir & "/marker.txt")).toBe("old-framework");
			});

			it("refuses when the source lives inside the target directory", () => {
				var f = buildFixture();
				var nested = f.vendorDir & "/sub";
				directoryCreate(nested, true, true);
				fileWrite(nested & "/wheels.json", '{"version":"9.9.9"}');
				var result = upgrader.applyUpgrade(nested, f.vendorDir, false);
				expect(result.success).toBeFalse();
				expect(fileRead(f.vendorDir & "/marker.txt")).toBe("old-framework");
			});

			it("creates vendor/wheels/ from scratch when it does not already exist", () => {
				var f = buildFixture();
				directoryDelete(f.vendorDir, true);
				var result = upgrader.applyUpgrade(f.sourceDir, f.vendorDir, true);
				expect(result.success).toBeTrue();
				expect(result.oldVersion).toBe("");
				expect(result.backupDir).toBe("");
				expect(fileRead(f.vendorDir & "/marker.txt")).toBe("new-framework");
			});

			it("returns an error when the parent of vendorDir does not exist", () => {
				var f = buildFixture();
				var bogusVendor = f.root & "/no-parent-here/wheels";
				var result = upgrader.applyUpgrade(f.sourceDir, bogusVendor, false);
				expect(result.success).toBeFalse();
				expect(result.error).toInclude("Parent");
			});

			it("throws RenameFailed naming the --nobackup workaround when the rename is refused", () => {
				// An unwritable backups directory stands in for a separately
				// mounted vendor/. POSIX-only, like the CopyFailed spec below.
				var f = buildFixture();
				directoryCreate(f.backupsDir, true, true);
				fileWrite(f.backupsDir & "/.gitignore", "*");
				var handle = createObject("java", "java.io.File").init(f.backupsDir);
				if (!handle.setWritable(false, false) || handle.canWrite()) {
					handle.setWritable(true, false);
					return;
				}
				var state = {type = "", message = ""};
				try {
					upgrader.applyUpgrade(f.sourceDir, f.vendorDir, true);
				} catch (any e) {
					state.type = e.type;
					state.message = e.message;
				}
				handle.setWritable(true, false);

				expect(state.type).toBe("Wheels.FrameworkUpgrader.RenameFailed");
				expect(state.message).toInclude("nothing was changed");
				expect(state.message).toInclude("wheels upgrade apply --nobackup");
				expect(fileRead(f.vendorDir & "/marker.txt")).toBe("old-framework");
			});

			it("throws RenameFailed, not a raw error, when the backup directory can't be prepared", () => {
				// An unwritable backups directory stands in for a separately
				// mounted vendor/. POSIX-only, like the CopyFailed spec below.
				var f = buildFixture();
				directoryCreate(f.backupsDir, true, true);
				var handle = createObject("java", "java.io.File").init(f.backupsDir);
				if (!handle.setWritable(false, false) || handle.canWrite()) {
					handle.setWritable(true, false);
					return;
				}
				var state = {type = "", message = ""};
				try {
					upgrader.applyUpgrade(f.sourceDir, f.vendorDir, true);
				} catch (any e) {
					state.type = e.type;
					state.message = e.message;
				}
				handle.setWritable(true, false);

				expect(state.type).toBe("Wheels.FrameworkUpgrader.RenameFailed");
				expect(state.message).toInclude("nothing was changed");
				expect(state.message).toInclude("wheels upgrade apply --nobackup");
				expect(fileRead(f.vendorDir & "/marker.txt")).toBe("old-framework");
			});

			it("throws CopyFailed naming the backup to restore when the copy fails after the rename", () => {
				// An unreadable file inside the source makes directoryCopy
				// blow up AFTER the backup rename already ran — the exact
				// mid-swap failure the error contract exists for (#3039
				// review). POSIX-only simulation: Windows can't revoke read
				// permission via File.setReadable, so skip there (the
				// contract is exercised on every POSIX run).
				var f = buildFixture();
				var blocker = f.sourceDir & "/unreadable.txt";
				fileWrite(blocker, "secret");
				if (!$makeUnreadable(blocker)) {
					return;
				}
				var state = {caught = false, type = "", message = ""};
				try {
					upgrader.applyUpgrade(f.sourceDir, f.vendorDir, true);
				} catch (any e) {
					state.caught = true;
					state.type = e.type;
					state.message = e.message;
				}
				$makeReadable(blocker);

				expect(state.caught).toBeTrue();
				expect(state.type).toBe("Wheels.FrameworkUpgrader.CopyFailed");
				// The rename ran before the copy, so the backup exists on
				// disk and the message must name it (quoted) for the restore.
				var backups = directoryList(f.backupsDir, false, "name", "wheels.bak-*");
				expect(arrayLen(backups)).toBe(1);
				expect(state.message).toInclude(backups[1]);
				expect(state.message).toInclude('"' & f.vendorDir & '"');
				expect(state.message).toInclude("partial state");
			});

			it("CopyFailed with --nobackup says the old tree is gone and how to re-vendor", () => {
				var f = buildFixture();
				var blocker = f.sourceDir & "/unreadable.txt";
				fileWrite(blocker, "secret");
				if (!$makeUnreadable(blocker)) {
					return;
				}
				var state = {caught = false, type = "", message = ""};
				try {
					upgrader.applyUpgrade(f.sourceDir, f.vendorDir, false);
				} catch (any e) {
					state.caught = true;
					state.type = e.type;
					state.message = e.message;
				}
				$makeReadable(blocker);

				expect(state.caught).toBeTrue();
				expect(state.type).toBe("Wheels.FrameworkUpgrader.CopyFailed");
				expect(state.message).toInclude("no backup exists");
				expect(state.message).toInclude("gone");
				expect(state.message).toInclude("wheels upgrade apply");
			});
		});
	}
}
