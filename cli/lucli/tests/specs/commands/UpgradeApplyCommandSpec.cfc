/**
 * Behavioral specs for `wheels upgrade` dispatch — apply vs check mode
 * selection, help paths, and the refusals that fire before any file
 * mutation. Covers issue #3035 (PR1 of the apply-mode plan): bare
 * `wheels upgrade` previously printed usage and pointed at
 * `brew upgrade wheels`, which upgrades the CLI binary but never the
 * app's vendored framework copy.
 *
 * The actual file swap is exercised by FrameworkUpgraderSpec — Module.cfc
 * here is the thin dispatch layer that decides which service call to make.
 * Instantiates Module.cfc against a scaffolded temp project and drives it
 * through the structured callerArgs path (`mod.upgrade(arg1 = "check")`),
 * the same shape LuCLI's own dispatch produces — the `__arguments` stash
 * is only readable for internal delegation, not from a spec (see
 * DbCommandSpec's unknown-subcommand spec for the prior art).
 *
 * The companion UpgradeCommandSpec covers the check-mode scanner structure
 * at the source level; this spec covers runtime dispatch behavior.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		// Apply mode resolves its source by walking up from cli/lucli/ —
		// in this checkout that lands on the repo's own vendor/wheels/.
		// Read whatever version this checkout actually bundles so the
		// assertions don't pin a release number.
		variables.bundledVersion = new cli.lucli.services.FrameworkUpgrader()
			.readFrameworkVersion(expandPath("/vendor/wheels"));
	}

	private void function seedVendorWheels(string version = "4.0.0-SNAPSHOT+1687") {
		var vendorDir = variables.tempRoot & "/vendor/wheels";
		directoryCreate(vendorDir, true, true);
		fileWrite(vendorDir & "/wheels.json", '{"name":"wheels","version":"' & arguments.version & '"}');
	}

	private string function seededVersion() {
		var manifest = deserializeJSON(fileRead(variables.tempRoot & "/vendor/wheels/wheels.json"));
		return manifest.version;
	}

	function run() {

		describe("wheels upgrade dispatch", () => {

			// DSL form — component-level beforeEach()/afterEach() are not
			// BDD lifecycle hooks in this harness. Fresh project per spec:
			// apply mode mutates vendor/, so specs can't share a fixture.
			beforeEach(() => {
				variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
				variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);
			});

			afterEach(() => {
				testHelper.cleanupTempProject(variables.tempRoot);
			});

			describe("wheels upgrade help", () => {

				it("returns help text when invoked with --help", () => {
					var result = mod.upgrade(help = true);
					expect(result).toInclude("wheels upgrade");
					expect(result).toInclude("--nobackup");
					expect(result).toInclude("check");
				});

				it("returns help text when invoked with -h", () => {
					var result = mod.upgrade(arg1 = "-h");
					expect(result).toInclude("wheels upgrade");
				});

				it("returns help text when invoked with bare `help`", () => {
					var result = mod.upgrade(arg1 = "help");
					expect(result).toInclude("wheels upgrade");
				});

				it("documents bare `wheels upgrade` as the apply verb and check as the scan", () => {
					var result = mod.upgrade(arg1 = "help");
					expect(result).toInclude("Apply the upgrade");
					expect(result).toInclude("check");
					expect(result).toInclude("--to=");
					expect(result).toInclude("--nobackup");
				});
			});

			describe("wheels upgrade argument refusals (before any mutation)", () => {

				it("rejects --dry-run with a pointer at `wheels upgrade check`", () => {
					seedVendorWheels();
					expect(() => mod.upgrade(argumentCollection = {"dry-run": "true"})).toThrow(type = "Wheels.InvalidArguments");
					// vendor/wheels/ untouched.
					expect(seededVersion()).toBe("4.0.0-SNAPSHOT+1687");
				});

				it("rejects check-only flags on the apply verb (--strict)", () => {
					seedVendorWheels();
					expect(() => mod.upgrade(strict = true)).toThrow(regex = "wheels upgrade check");
					expect(seededVersion()).toBe("4.0.0-SNAPSHOT+1687");
				});

				it("rejects check-only flags on the apply verb (--format=json)", () => {
					seedVendorWheels();
					expect(() => mod.upgrade(format = "json")).toThrow(type = "Wheels.InvalidArguments");
					expect(seededVersion()).toBe("4.0.0-SNAPSHOT+1687");
				});

				it("rejects an unknown flag instead of silently applying", () => {
					seedVendorWheels();
					expect(() => mod.upgrade(bogus = true)).toThrow(regex = "bogus");
					expect(seededVersion()).toBe("4.0.0-SNAPSHOT+1687");
				});

				it("rejects an unknown subcommand instead of treating it as apply", () => {
					seedVendorWheels();
					expect(() => mod.upgrade(arg1 = "chekc")).toThrow(regex = "chekc");
					expect(seededVersion()).toBe("4.0.0-SNAPSHOT+1687");
				});
			});

			describe("wheels upgrade (bare verb — apply mode) refusals", () => {

				it("refuses when no vendor/wheels/ exists in the project", () => {
					// scaffoldTempProject does not create vendor/wheels/.
					expect(() => mod.upgrade()).toThrow(type = "Wheels.UpgradeApplyFailed");
					// And nothing was created.
					expect(directoryExists(variables.tempRoot & "/vendor/wheels")).toBeFalse();
				});

				it("refuses when --to= does not match the CLI's bundled framework version", () => {
					seedVendorWheels(version = "4.0.0-SNAPSHOT+1687");
					expect(() => mod.upgrade(to = "99.99.99")).toThrow(type = "Wheels.UpgradeApplyFailed");
					// Side effect check: the seeded manifest is untouched.
					expect(seededVersion()).toBe("4.0.0-SNAPSHOT+1687");
				});
			});

			describe("wheels upgrade (bare verb — apply mode) swap", () => {

				it("swaps vendor/wheels/ with the bundled framework and backs the old copy up", () => {
					seedVendorWheels(version = "0.0.1-spec-fixture");
					fileWrite(variables.tempRoot & "/vendor/wheels/marker.txt", "old-framework");
					var result = mod.upgrade();

					// Live copy now carries the bundled framework.
					expect(seededVersion()).toBe(variables.bundledVersion);
					expect(fileExists(variables.tempRoot & "/vendor/wheels/marker.txt")).toBeFalse();

					// Old copy parked under vendor/wheels.bak-<timestamp>.
					var backups = directoryList(variables.tempRoot & "/vendor", false, "name", "wheels.bak-*");
					expect(arrayLen(backups)).toBe(1);
					expect(reFindNoCase("^wheels\.bak-\d{8}-\d{6}", backups[1])).toBeGT(0);
					expect(fileRead(variables.tempRoot & "/vendor/" & backups[1] & "/marker.txt")).toBe("old-framework");

					// And the summary reports old -> new plus the recovery path.
					expect(result).toInclude("0.0.1-spec-fixture");
					expect(result).toInclude("Backup");
				});

				it("accepts --to= matching the bundled version and skips the backup with --nobackup", () => {
					seedVendorWheels(version = "0.0.1-spec-fixture");
					mod.upgrade(to = variables.bundledVersion, nobackup = true);

					expect(seededVersion()).toBe(variables.bundledVersion);
					var backups = directoryList(variables.tempRoot & "/vendor", false, "name", "wheels.bak-*");
					expect(arrayLen(backups)).toBe(0);
				});
			});

			describe("wheels upgrade check (read-only scan)", () => {

				it("treats `check` as a read-only mode (no vendor/wheels/ mutation)", () => {
					seedVendorWheels(version = "4.0.0");
					// Add a marker file we can check is preserved after the scan.
					fileWrite(variables.tempRoot & "/vendor/wheels/marker.txt", "untouched");
					mod.upgrade(arg1 = "check", to = "4.0.1");
					expect(fileExists(variables.tempRoot & "/vendor/wheels/marker.txt")).toBeTrue();
					expect(fileRead(variables.tempRoot & "/vendor/wheels/marker.txt")).toBe("untouched");
				});

				it("dispatches check when the MCP surface sends `subcommand` as a named key", () => {
					// MCP clients call wheels_upgrade with named properties from
					// the advertised inputSchema (#2963) — {subcommand: "check"}
					// must select the scan, never fall through to apply.
					seedVendorWheels(version = "4.0.0");
					fileWrite(variables.tempRoot & "/vendor/wheels/marker.txt", "untouched");
					mod.upgrade(subcommand = "check", to = "4.0.1");
					expect(fileRead(variables.tempRoot & "/vendor/wheels/marker.txt")).toBe("untouched");
				});
			});

		});
	}
}
