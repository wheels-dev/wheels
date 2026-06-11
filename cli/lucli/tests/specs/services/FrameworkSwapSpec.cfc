/**
 * Coverage for GH #3035 — `wheels upgrade` apply mode.
 *
 * `FrameworkSwap` is the pure planner + executor behind the new bare
 * `wheels upgrade`: it swaps an app's vendored `vendor/wheels/` for the
 * framework bundled inside the installed CLI, parking the old copy in a
 * timestamped `vendor/wheels.bak-*` backup first.
 *
 * `plan()` is side-effect-free — it resolves source/target, sniffs both as
 * Wheels framework dirs, enforces the safety rails (outside-app, same-dir,
 * `--to` version match), and reports old -> new. `apply()` performs the
 * atomic backup rename + copy. We exercise both against temp-dir fixtures so
 * the destructive path is verified without touching a real install.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.swap = new cli.lucli.services.FrameworkSwap();
	}

	/**
	 * Stand up a fake app layout in a temp dir:
	 *   <root>/app/vendor/wheels        (target — the app being upgraded)
	 *   <root>/cli/vendor/wheels        (source — the CLI's bundled framework)
	 * Each gets a wheels.json carrying the requested version plus a marker file
	 * so a swap is observable. Pass blank version to omit the manifest entirely
	 * (simulates a non-framework directory).
	 */
	private struct function buildFixture(string targetVersion = "4.0.0", string sourceVersion = "4.1.0") {
		var f = {};
		f.root = getTempDirectory() & "wheels-swap-#createUUID()#";
		f.target = f.root & "/app/vendor/wheels";
		f.source = f.root & "/cli/vendor/wheels";
		directoryCreate(f.target, true, true);
		directoryCreate(f.source, true, true);
		if (len(arguments.targetVersion)) {
			fileWrite(f.target & "/wheels.json", '{"name":"Wheels.fw","version":"#arguments.targetVersion#"}');
			fileWrite(f.target & "/MARKER.txt", "OLD");
		}
		if (len(arguments.sourceVersion)) {
			fileWrite(f.source & "/wheels.json", '{"name":"Wheels.fw","version":"#arguments.sourceVersion#"}');
			fileWrite(f.source & "/MARKER.txt", "NEW");
		}
		return f;
	}

	function run() {

		describe("FrameworkSwap.plan() — safety rails (GH ##3035)", () => {

			it("refuses when run outside a Wheels app (no target vendor/wheels)", () => {
				var f = buildFixture();
				var p = swap.plan(target = f.root & "/nope/vendor/wheels", source = f.source);
				expect(p.ok).toBeFalse();
				expect(p.reason).toInclude("Wheels app");
				directoryDelete(f.root, true);
			});

			it("refuses when the bundled source cannot be located", () => {
				var f = buildFixture();
				var p = swap.plan(target = f.target, source = f.root & "/missing/vendor/wheels");
				expect(p.ok).toBeFalse();
				expect(p.reason).toInclude("bundled");
				directoryDelete(f.root, true);
			});

			it("refuses when the target is not a Wheels framework dir (no manifest)", () => {
				var f = buildFixture(targetVersion = "");
				var p = swap.plan(target = f.target, source = f.source);
				expect(p.ok).toBeFalse();
				expect(p.reason).toInclude("framework");
				directoryDelete(f.root, true);
			});

			it("refuses when source and target resolve to the same directory", () => {
				var f = buildFixture();
				var p = swap.plan(target = f.target, source = f.target);
				expect(p.ok).toBeFalse();
				expect(p.sameDir).toBeTrue();
				expect(p.reason).toInclude("same directory");
				directoryDelete(f.root, true);
			});

			it("refuses when --to does not match the bundled framework version", () => {
				var f = buildFixture(sourceVersion = "4.1.0");
				var p = swap.plan(target = f.target, source = f.source, requestedTo = "9.9.9");
				expect(p.ok).toBeFalse();
				expect(p.reason).toInclude("9.9.9");
				expect(p.reason).toInclude("4.1.0");
				directoryDelete(f.root, true);
			});

			it("accepts when --to matches the bundled framework version exactly", () => {
				var f = buildFixture(sourceVersion = "4.1.0");
				var p = swap.plan(target = f.target, source = f.source, requestedTo = "4.1.0");
				expect(p.ok).toBeTrue();
				directoryDelete(f.root, true);
			});

		});

		describe("FrameworkSwap.plan() — happy path", () => {

			it("reports old -> new versions and a timestamped backup path", () => {
				var f = buildFixture(targetVersion = "4.0.0", sourceVersion = "4.1.0");
				var p = swap.plan(target = f.target, source = f.source, timestamp = "20260611-193000");
				expect(p.ok).toBeTrue();
				expect(p.fromVersion).toBe("4.0.0");
				expect(p.toVersion).toBe("4.1.0");
				expect(p.backupPath).toInclude(".bak-20260611-193000");
				expect(p.backupPath).toInclude("wheels");
				directoryDelete(f.root, true);
			});

		});

		describe("FrameworkSwap.apply() — the swap", () => {

			it("backs up the old framework and installs the bundled one", () => {
				var f = buildFixture(targetVersion = "4.0.0", sourceVersion = "4.1.0");
				var p = swap.plan(target = f.target, source = f.source, timestamp = "20260611-193000");
				var r = swap.apply(plan = p);

				expect(r.fromVersion).toBe("4.0.0");
				expect(r.toVersion).toBe("4.1.0");
				expect(r.backedUp).toBeTrue();
				// The new framework now sits at vendor/wheels.
				expect(fileRead(f.target & "/MARKER.txt")).toBe("NEW");
				// The old framework was preserved in the backup dir.
				expect(directoryExists(r.backupPath)).toBeTrue();
				expect(fileRead(r.backupPath & "/MARKER.txt")).toBe("OLD");
				directoryDelete(f.root, true);
			});

			it("swaps without a backup dir when backup=false", () => {
				var f = buildFixture(targetVersion = "4.0.0", sourceVersion = "4.1.0");
				var p = swap.plan(target = f.target, source = f.source, timestamp = "20260611-193000");
				var r = swap.apply(plan = p, backup = false);

				expect(r.backedUp).toBeFalse();
				expect(fileRead(f.target & "/MARKER.txt")).toBe("NEW");
				expect(directoryExists(p.backupPath)).toBeFalse();
				directoryDelete(f.root, true);
			});

			it("throws Wheels.UpgradeApplyRefused when handed a non-ok plan", () => {
				var f = buildFixture();
				var p = swap.plan(target = f.target, source = f.target); // same-dir => not ok
				expect(() => swap.apply(plan = p)).toThrow("Wheels.UpgradeApplyRefused");
				directoryDelete(f.root, true);
			});

		});

	}

}
