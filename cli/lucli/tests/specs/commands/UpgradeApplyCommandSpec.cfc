/**
 * Behavioral specs for `wheels upgrade` dispatch — explicit verb
 * selection, help paths, and the refusals that fire before any file
 * mutation. Covers issue #3035 (PR1 of the apply-mode plan) plus the
 * #3039 review hardening: the swap requires the explicit `apply` verb.
 * Bare `wheels upgrade` prints concise usage steering at the two verbs
 * and exits 0 — destructive commands deserve an explicit verb, and MCP
 * clients calling wheels_upgrade with {} must never mutate.
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

	private array function listBackups() {
		var backupsDir = variables.tempRoot & "/.wheels/backups";
		if (!directoryExists(backupsDir)) {
			return [];
		}
		return directoryList(backupsDir, false, "name", "wheels.bak-*");
	}

	function run() {

		describe("wheels upgrade dispatch", () => {

			// DSL form — component-level beforeEach()/afterEach() are not
			// BDD lifecycle hooks in this harness. Fresh project per spec:
			// apply mode mutates vendor/, so specs can't share a fixture.
			beforeEach(() => {
				variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
				// Output-capturing Module (same dispatch surface) so refusal
				// specs can assert what got PRINTED, not just what was thrown:
				// the #3039 review's blocking finding was a restore one-liner
				// printed on paths where no backup was ever made.
				variables.mod = new cli.lucli.tests._fixtures.commands.ModuleOutputCapture(cwd = variables.tempRoot);
			});

			afterEach(() => {
				testHelper.cleanupTempProject(variables.tempRoot);
			});

			describe("apply is never reached for invalid input (##2963)", () => {

				// apply swaps vendor/wheels/. For a destructive verb anything
				// unrecognized must throw, never fall through to the swap.
				// Each case seeds a framework that a real apply WOULD swap (see
				// "swaps vendor/wheels/ with the bundled framework" below), then
				// asserts the call threw and the framework is untouched.
				it("throws and leaves vendor/wheels/ untouched for every invalid combination", () => {
					var cases = [
						{subcommand: "apply", strict: "bogus"},
						{subcommand: "apply", strict: "1"},
						{subcommand: "apply", nobackup: "bogus"},
						{subcommand: "apply", "dry-run": "1"},
						{subcommand: "apply", "dry-run": "bogus"},
						{subcommand: "apply", "dry-run": true},
						{subcommand: "apply", strict: true},
						{subcommand: "apply", format: "json"},
						{subcommand: "apply", format: "bogus"},
						{subcommand: "apply", to: true},
						{arg1: "", subcommand: "bogus"},
						{subcommand: "bogus"},
						{arg1: "bogus"},
						{subcommand: "true"},
						{subcommand: true}
					];
					for (var args in cases) {
						seedVendorWheels(version = "0.0.1-spec-fixture");
						fileWrite(variables.tempRoot & "/vendor/wheels/marker.txt", "old-framework");
						var state = {threw: false};
						try {
							mod.upgrade(argumentCollection = args);
						} catch (any e) {
							state.threw = true;
						}
						var label = serializeJSON(args);
						expect(state.threw).toBeTrue("expected #label# to throw");
						expect(seededVersion()).toBe("0.0.1-spec-fixture", "#label# reached the framework swap");
						expect(fileExists(variables.tempRoot & "/vendor/wheels/marker.txt")).toBeTrue("#label# replaced vendor/wheels/");
						expect(arrayLen(listBackups())).toBe(0, "#label# made a backup");
					}
				});

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

				it("documents the explicit verbs: apply swaps, check scans, bare prints usage", () => {
					var result = mod.upgrade(arg1 = "help");
					expect(result).toInclude("wheels upgrade apply");
					expect(result).toInclude("wheels upgrade check");
					expect(result).toInclude("Apply the upgrade");
					expect(result).toInclude("--to=");
					expect(result).toInclude("--nobackup");
				});
			});

			describe("wheels upgrade (bare verb) — usage steer, never the swap", () => {

				// #3039 review: the bare verb is deliberately inert. Exit 0
				// matches the pre-apply-mode behavior (no CI surprise), and
				// an MCP wheels_upgrade call with {} must never mutate.

				it("prints usage steering at check/apply without mutating vendor/wheels/", () => {
					seedVendorWheels();
					// 4.1.2: exits non-zero (MCP isError) with the usage as the message.
					expect(() => mod.upgrade()).toThrow(type = "Wheels.InvalidArguments", regex = "wheels upgrade check");
					expect(() => mod.upgrade()).toThrow(regex = "wheels upgrade apply");
					expect(seededVersion()).toBe("4.0.0-SNAPSHOT+1687");
					expect(arrayLen(listBackups())).toBe(0);
				});

				it("steers to usage even when apply flags are present without the verb", () => {
					seedVendorWheels();
					expect(() => mod.upgrade(nobackup = true)).toThrow(type = "Wheels.InvalidArguments", regex = "wheels upgrade apply");
					expect(seededVersion()).toBe("4.0.0-SNAPSHOT+1687");
					expect(arrayLen(listBackups())).toBe(0);
				});
			});

			describe("wheels upgrade argument refusals (before any mutation)", () => {

				it("rejects --dry-run on the apply verb with a pointer at `wheels upgrade check`", () => {
					seedVendorWheels();
					expect(() => mod.upgrade(argumentCollection = {"arg1": "apply", "dry-run": "true"})).toThrow(type = "Wheels.InvalidArguments");
					// vendor/wheels/ untouched.
					expect(seededVersion()).toBe("4.0.0-SNAPSHOT+1687");
				});

				it("rejects check-only flags on the apply verb (--strict)", () => {
					seedVendorWheels();
					expect(() => mod.upgrade(arg1 = "apply", strict = true)).toThrow(regex = "wheels upgrade check");
					expect(seededVersion()).toBe("4.0.0-SNAPSHOT+1687");
				});

				it("rejects check-only flags on the apply verb (--format=json)", () => {
					seedVendorWheels();
					expect(() => mod.upgrade(arg1 = "apply", format = "json")).toThrow(type = "Wheels.InvalidArguments");
					expect(seededVersion()).toBe("4.0.0-SNAPSHOT+1687");
				});

				it("rejects an unknown flag instead of silently applying", () => {
					seedVendorWheels();
					expect(() => mod.upgrade(arg1 = "apply", bogus = true)).toThrow(regex = "bogus");
					expect(seededVersion()).toBe("4.0.0-SNAPSHOT+1687");
				});

				it("rejects an unknown subcommand instead of treating it as apply", () => {
					seedVendorWheels();
					expect(() => mod.upgrade(arg1 = "chekc")).toThrow(regex = "chekc");
					expect(seededVersion()).toBe("4.0.0-SNAPSHOT+1687");
				});
			});

			describe("wheels upgrade apply refusals", () => {

				it("refuses when no vendor/wheels/ exists in the project", () => {
					// scaffoldTempProject does not create vendor/wheels/.
					expect(() => mod.upgrade(arg1 = "apply")).toThrow(type = "Wheels.UpgradeApplyFailed");
					// And nothing was created.
					expect(directoryExists(variables.tempRoot & "/vendor/wheels")).toBeFalse();
					// No backup happened, so no restore command may be offered.
					expect(mod.capturedOutput()).notToInclude("rm -rf");
				});

				it("refuses when --to= does not match the CLI's bundled framework version", () => {
					seedVendorWheels(version = "4.0.0-SNAPSHOT+1687");
					expect(() => mod.upgrade(arg1 = "apply", to = "99.99.99")).toThrow(type = "Wheels.UpgradeApplyFailed");
					// Side effect check: the seeded manifest is untouched.
					expect(seededVersion()).toBe("4.0.0-SNAPSHOT+1687");
					expect(mod.capturedOutput()).notToInclude("rm -rf");
				});

				it("refuses a vendor/wheels/ that does not sniff as a framework — without printing the restore one-liner", () => {
					// #3039 review (blocking): the service-level refusals fire
					// AFTER Module printed the pre-swap plan, so the user was
					// handed `rm -rf "<vendor/wheels>" && mv "<backup>" …` for
					// a backup that was never made — running it deletes the
					// intact vendor/wheels/. Drive a real service refusal (a
					// generic app box.json is not framework evidence) and pin
					// that the restore command never reaches the output.
					var vendorDir = variables.tempRoot & "/vendor/wheels";
					directoryCreate(vendorDir, true, true);
					fileWrite(vendorDir & "/box.json", '{"name":"myapp","version":"1.0.0"}');
					fileWrite(vendorDir & "/marker.txt", "not-a-framework");

					expect(() => mod.upgrade(arg1 = "apply")).toThrow(type = "Wheels.UpgradeApplyFailed");

					// The refusal explains itself…
					expect(mod.capturedOutput()).toInclude("does not look like a Wheels framework");
					// …but never offers a restore command for a backup that
					// does not exist.
					expect(mod.capturedOutput()).notToInclude("rm -rf");
					expect(mod.capturedOutput()).notToInclude("Backing up vendor/wheels");

					// And the target is untouched: no backup, no mutation.
					expect(arrayLen(listBackups())).toBe(0);
					expect(fileRead(vendorDir & "/marker.txt")).toBe("not-a-framework");
				});
			});

			describe("wheels upgrade apply — the swap", () => {

				it("swaps vendor/wheels/ with the bundled framework and backs the old copy up", () => {
					seedVendorWheels(version = "0.0.1-spec-fixture");
					fileWrite(variables.tempRoot & "/vendor/wheels/marker.txt", "old-framework");
					mod.upgrade(arg1 = "apply");
					var result = mod.capturedOutput();

					// Live copy now carries the bundled framework.
					expect(seededVersion()).toBe(variables.bundledVersion);
					expect(fileExists(variables.tempRoot & "/vendor/wheels/marker.txt")).toBeFalse();

					// Old copy parked under .wheels/backups/wheels.bak-<timestamp>,
					// outside vendor/: the framework loads every vendor/ folder as a
					// package, so a backup there logged an error on every boot.
					var backups = listBackups();
					expect(arrayLen(backups)).toBe(1);
					expect(reFindNoCase("^wheels\.bak-\d{8}-\d{6}", backups[1])).toBeGT(0);
					expect(fileRead(variables.tempRoot & "/.wheels/backups/" & backups[1] & "/marker.txt")).toBe("old-framework");
					expect(directoryList(variables.tempRoot & "/vendor", false, "name")).toBe(["wheels"]);
					// The backups directory ignores itself, whatever the app's .gitignore says.
					expect(fileRead(variables.tempRoot & "/.wheels/backups/.gitignore")).toInclude("*");

					// And the summary reports old -> new plus the recovery path.
					expect(result).toInclude("0.0.1-spec-fixture");
					expect(result).toInclude("Backup");
				});

				it("prints the report once and returns nothing, so the terminal doesn't show it twice", () => {
					seedVendorWheels(version = "0.0.1-spec-fixture");
					var returned = mod.upgrade(arg1 = "apply");
					expect(returned).toBe("");
					var printed = mod.capturedOutput();
					var first = find("Backing up vendor/wheels", printed);
					expect(first).toBeGT(0);
					expect(find("Backing up vendor/wheels", printed, first + 1)).toBe(0);
				});

				it("announces the exact backup destination and recovery command before the swap summary", () => {
					// #3039 review: the plan — backup destination + quoted
					// recovery one-liner — must be part of the output BEFORE
					// the swap runs, so an interrupt leaves the user holding
					// the restore command.
					seedVendorWheels(version = "0.0.1-spec-fixture");
					mod.upgrade(arg1 = "apply");
					var result = mod.capturedOutput();

					var backups = listBackups();
					expect(arrayLen(backups)).toBe(1);
					// The announced destination is the directory the backup
					// actually landed in (reserved up front, passed through).
					expect(result).toInclude("Backing up vendor/wheels -> .wheels/backups/" & backups[1] & "/ (outside vendor/, ignored by git)");
					expect(result).toInclude("If this is interrupted, restore with:");
					expect(result).toInclude('rm -rf "');
					expect(result).toInclude('/vendor/wheels" && mv "');
					// And it precedes the post-swap summary in the output.
					expect(find("Backing up vendor/wheels", result)).toBeGT(0);
					// (The summary verb depends on the version direction; this
					// checkout's bundled "@build.version@" has none, so "replaced".)
					expect(reFind("Framework (upgraded|replaced):", result)).toBeGT(find("Backing up vendor/wheels", result));
					// The restore one-liner also reached the PRINTED output
					// (the refusal specs pin its absence; this pins presence
					// on the one path where the backup really is made).
					expect(mod.capturedOutput()).toInclude('rm -rf "');
				});

				it("accepts --to= matching the bundled version and skips the backup with --nobackup", () => {
					seedVendorWheels(version = "0.0.1-spec-fixture");
					mod.upgrade(arg1 = "apply", to = variables.bundledVersion, nobackup = true);

					expect(seededVersion()).toBe(variables.bundledVersion);
					expect(arrayLen(listBackups())).toBe(0);
				});

				it("skips the backup when LuCLI normalizes --no-backup to backup=""false""", () => {
					// LuCLI converts the conventional `--no-backup` negation into
					// the named-arg shape `backup = "false"` before dispatch.
					// parseUpgradeArgs() must honour this alongside the documented
					// --nobackup spelling.
					seedVendorWheels(version = "0.0.1-spec-fixture");
					mod.upgrade(argumentCollection = {"arg1": "apply", "backup": "false"});

					expect(seededVersion()).toBe(variables.bundledVersion);
					expect(arrayLen(listBackups())).toBe(0);
				});

				it("dispatches apply when the MCP surface sends `subcommand` as a named key", () => {
					// MCP clients call wheels_upgrade with named properties
					// from the advertised inputSchema (#2963) — the explicit
					// {subcommand: "apply"} opt-in is the only MCP shape that
					// may mutate.
					seedVendorWheels(version = "0.0.1-spec-fixture");
					mod.upgrade(subcommand = "apply");
					expect(seededVersion()).toBe(variables.bundledVersion);
				});
			});

			describe("wheels upgrade apply — version direction", () => {

				// Pin the bundled version with a spec-controlled source dir so
				// the direction is known. Plain release versions only.
				beforeEach(() => {
					variables.mod = new cli.lucli.tests._fixtures.commands.ModuleBundledSource(cwd = variables.tempRoot);
					variables.bundledDir = variables.tempRoot & "/_bundled/wheels";
					directoryCreate(variables.bundledDir, true, true);
					fileWrite(variables.bundledDir & "/wheels.json", '{"name":"wheels","version":"4.1.1"}');
					fileWrite(variables.bundledDir & "/marker.txt", "bundled-framework");
					variables.mod.setBundledFrameworkSource(variables.bundledDir);
				});

				it("refuses when the bundled framework is older than vendor/wheels/ and changes nothing", () => {
					seedVendorWheels(version = "4.1.2");
					fileWrite(variables.tempRoot & "/vendor/wheels/marker.txt", "installed-framework");

					expect(() => mod.upgrade(arg1 = "apply")).toThrow(type = "Wheels.UpgradeApplyFailed", regex = "4\.1\.2.*4\.1\.1");

					expect(seededVersion()).toBe("4.1.2");
					expect(fileRead(variables.tempRoot & "/vendor/wheels/marker.txt")).toBe("installed-framework");
					expect(arrayLen(listBackups())).toBe(0);
					var printed = mod.capturedOutput();
					expect(printed).toInclude("--allow-downgrade");
					expect(printed).toInclude("brew upgrade wheels");
					expect(printed).notToInclude("rm -rf");
					expect(printed).notToInclude("Backing up vendor/wheels");
				});

				it("refuses the downgrade with --nobackup too", () => {
					seedVendorWheels(version = "4.1.2");
					expect(() => mod.upgrade(arg1 = "apply", nobackup = true)).toThrow(type = "Wheels.UpgradeApplyFailed");
					expect(seededVersion()).toBe("4.1.2");
				});

				it("downgrades with --allow-downgrade and says so", () => {
					seedVendorWheels(version = "4.1.2");
					mod.upgrade(argumentCollection = {"arg1": "apply", "allow-downgrade": true});
					var result = mod.capturedOutput();

					expect(seededVersion()).toBe("4.1.1");
					expect(arrayLen(listBackups())).toBe(1);
					expect(result).toInclude("Downgrading framework (--allow-downgrade): 4.1.2 -> 4.1.1");
					expect(result).toInclude("Framework downgraded: 4.1.2 -> 4.1.1");
					expect(result).notToInclude("upgraded");
				});

				it("upgrades when the bundled framework is newer and says upgraded", () => {
					seedVendorWheels(version = "4.1.0");
					mod.upgrade(arg1 = "apply");
					var result = mod.capturedOutput();

					expect(seededVersion()).toBe("4.1.1");
					expect(arrayLen(listBackups())).toBe(1);
					expect(result).toInclude("Upgrading framework: 4.1.0 -> 4.1.1");
					expect(result).toInclude("Framework upgraded: 4.1.0 -> 4.1.1");
				});

				it("reinstalls when vendor/wheels/ is already at the bundled version", () => {
					seedVendorWheels(version = "4.1.1");
					fileWrite(variables.tempRoot & "/vendor/wheels/marker.txt", "installed-framework");
					mod.upgrade(arg1 = "apply");
					var result = mod.capturedOutput();

					expect(fileRead(variables.tempRoot & "/vendor/wheels/marker.txt")).toBe("bundled-framework");
					expect(result).toInclude("Framework reinstalled: 4.1.1 -> 4.1.1");
					expect(result).notToInclude("upgraded");
				});

				// A CommandBox app's box.json pins wheels-core. Left at the old
				// version, a later `box install` copies that framework back
				// over the new vendor/wheels/ and leaves a mix of both.
				it("points box.json's wheels-core at the new framework and says so", () => {
					seedVendorWheels(version = "4.1.0");
					var box = '{' & chr(10)
						& '    "name":"app",' & chr(10)
						& '    "dependencies":{' & chr(10)
						& '        "wheels-core":"^3.0.1"' & chr(10)
						& '    },' & chr(10)
						& '    "installPaths":{' & chr(10)
						& '        "wheels-core":"vendor/wheels/"' & chr(10)
						& '    }' & chr(10)
						& '}' & chr(10);
					fileWrite(variables.tempRoot & "/box.json", box);

					mod.upgrade(arg1 = "apply");
					var result = mod.capturedOutput();

					expect(seededVersion()).toBe("4.1.1");
					expect(fileRead(variables.tempRoot & "/box.json")).toBe(replace(box, '"wheels-core":"^3.0.1"', '"wheels-core":"^4.1.1"'));
					expect(result).toInclude("box.json: wheels-core ^3.0.1 -> ^4.1.1 (so box install keeps this framework)");
				});

				it("keeps each section's own range when both sections pin wheels-core", () => {
					seedVendorWheels(version = "4.1.0");
					var box = '{"dependencies":{"wheels-core":"^3.0.1"},"devDependencies":{"wheels-core":"~3.0.0"}}';
					fileWrite(variables.tempRoot & "/box.json", box);

					mod.upgrade(arg1 = "apply");
					var result = mod.capturedOutput();

					expect(fileRead(variables.tempRoot & "/box.json")).toBe('{"dependencies":{"wheels-core":"^4.1.1"},"devDependencies":{"wheels-core":"~4.1.1"}}');
					expect(result).toInclude("box.json: wheels-core ^3.0.1 -> ^4.1.1");
					expect(result).toInclude("box.json (devDependencies): wheels-core ~3.0.0 -> ~4.1.1");
				});

				it("leaves a channel spec alone and names the line to change", () => {
					seedVendorWheels(version = "4.1.0");
					var box = '{"dependencies":{"wheels-core":"be"}}';
					fileWrite(variables.tempRoot & "/box.json", box);

					mod.upgrade(arg1 = "apply");
					var result = mod.capturedOutput();

					expect(fileRead(variables.tempRoot & "/box.json")).toBe(box);
					expect(result).toInclude('box.json: wheels-core is "be", which apply doesn''t rewrite');
					expect(result).toInclude('"wheels-core": "4.1.1"');
					expect(result).notToInclude("be ->");
				});

				it("doesn't report an update it couldn't write", () => {
					seedVendorWheels(version = "4.1.0");
					// Valid JSON, but a nested object keeps the in-place rewrite
					// from locating the dependencies block.
					var box = '{"dependencies":{"wheels-core":"^3.0.1","x":{"y":"1"}}}';
					fileWrite(variables.tempRoot & "/box.json", box);

					mod.upgrade(arg1 = "apply");
					var result = mod.capturedOutput();

					expect(fileRead(variables.tempRoot & "/box.json")).toBe(box);
					expect(result).toInclude("box.json: wheels-core could not be located to rewrite");
					expect(result).notToInclude("^3.0.1 -> ^4.1.1");
				});

				it("refuses before changing anything when box.json can't be read", () => {
					seedVendorWheels(version = "4.1.0");
					fileWrite(variables.tempRoot & "/box.json", '{"dependencies":{"wheels-core":"^3.0.1"');

					expect(() => mod.upgrade(arg1 = "apply")).toThrow(type = "Wheels.UpgradeApplyFailed", regex = "box\.json is not valid JSON.*Nothing was changed");

					expect(seededVersion()).toBe("4.1.0");
					expect(arrayLen(listBackups())).toBe(0);
					expect(mod.capturedOutput()).notToInclude("Backing up vendor/wheels");
				});

				it("names old framework backups still inside vendor/", () => {
					seedVendorWheels(version = "4.1.0");
					directoryCreate(variables.tempRoot & "/vendor/wheels.bak-20260101-000000", true, true);
					directoryCreate(variables.tempRoot & "/vendor/wheels-basecoat", true, true);

					mod.upgrade(arg1 = "apply");
					var result = mod.capturedOutput();

					expect(result).toInclude("Old framework backups are still inside vendor/: vendor/wheels.bak-20260101-000000/.");
					expect(result).toInclude("move them to .wheels/backups/ or delete them");
					expect(result).notToInclude("vendor/wheels-basecoat");
				});

				it("leaves a box.json without wheels-core alone", () => {
					seedVendorWheels(version = "4.1.0");
					var box = '{"name":"app","dependencies":{"other":"1.0.0"}}';
					fileWrite(variables.tempRoot & "/box.json", box);

					mod.upgrade(arg1 = "apply");
					var result = mod.capturedOutput();

					expect(fileRead(variables.tempRoot & "/box.json")).toBe(box);
					expect(result).notToInclude("box.json: wheels-core");
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
