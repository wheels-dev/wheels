/**
 * Behavioral specs for `wheels framework install` dispatch (F20): installing the
 * CLI's bundled framework into an app that has no vendor/wheels/, and the
 * refusals that fire before any mutation.
 *
 * `framework install` is the fresh-install entry point; replacing an EXISTING
 * framework stays `wheels upgrade apply`'s job, so this command refuses when
 * vendor/wheels/ is already present. The actual copy is the shared
 * FrameworkUpgrader.applyUpgrade path (covered in depth by FrameworkUpgraderSpec);
 * this spec covers the thin dispatch layer in Module.cfc.
 *
 * Uses the output-capturing Module so help/refusal specs can assert what was
 * PRINTED (the command returns "" to avoid the double-print — U4/#4265).
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		// The command resolves its source by walking up from cli/lucli/, which in
		// this checkout lands on the repo's own vendor/wheels/. Read the version it
		// actually bundles so assertions don't pin a release number.
		variables.bundledVersion = new cli.lucli.services.FrameworkUpgrader()
			.readFrameworkVersion(expandPath("/vendor/wheels"));
	}

	private void function seedVendorWheels(string version = "0.0.1-spec-fixture") {
		var vendorDir = variables.tempRoot & "/vendor/wheels";
		directoryCreate(vendorDir, true, true);
		fileWrite(vendorDir & "/wheels.json", '{"name":"wheels","version":"' & arguments.version & '"}');
		fileWrite(vendorDir & "/marker.txt", "old-framework");
	}

	private boolean function vendorWheelsExists() {
		return directoryExists(variables.tempRoot & "/vendor/wheels");
	}

	private string function installedVersion() {
		return deserializeJSON(fileRead(variables.tempRoot & "/vendor/wheels/wheels.json")).version;
	}

	function run() {

		describe("wheels framework install dispatch", () => {

			beforeEach(() => {
				// Fresh project per spec: install mutates vendor/, so specs can't
				// share a fixture. scaffoldTempProject writes config/settings.cfm
				// (so the app-root guard passes) and leaves no vendor/ directory.
				variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
				variables.mod = new cli.lucli.tests._fixtures.commands.ModuleOutputCapture(cwd = variables.tempRoot);
			});

			afterEach(() => {
				testHelper.cleanupTempProject(variables.tempRoot);
			});

			describe("help", () => {

				it("prints usage ONCE for --help and installs nothing", () => {
					mod.framework(help = true);
					var printed = mod.capturedOutput();
					expect(printed).toInclude("wheels framework install");
					expect(printed).toInclude("--to=");
					expect(printed).toInclude("upgrade apply");
					// Printed via out() only — returning the text too would double it.
					expect(arrayLen(reMatchNoCase("Usage:", printed))).toBe(1, "help must print once, not twice");
					expect(vendorWheelsExists()).toBeFalse();
				});

				it("prints usage for the bare command and the help subcommand", () => {
					mod.framework(arg1 = "");
					expect(mod.capturedOutput()).toInclude("wheels framework install");
				});

				it("prints usage for the help subcommand", () => {
					mod.framework(arg1 = "help");
					expect(mod.capturedOutput()).toInclude("wheels framework install");
				});

			});

			describe("install into an app with no vendor/ at all", () => {

				it("installs the bundled framework (creating vendor/)", () => {
					expect(directoryExists(variables.tempRoot & "/vendor")).toBeFalse("precondition: no vendor/ dir");
					mod.framework(arg1 = "install");
					expect(vendorWheelsExists()).toBeTrue("install created vendor/wheels/");
					expect(installedVersion()).toBe(variables.bundledVersion);
				});

				it("accepts --to when it matches the bundled version", () => {
					mod.framework(arg1 = "install", to = variables.bundledVersion);
					expect(installedVersion()).toBe(variables.bundledVersion);
				});

				it("runs the box.json wheels-core pin step", () => {
					fileWrite(
						variables.tempRoot & "/box.json",
						'{"name":"myapp","dependencies":{"wheels-core":"1.0.0-OLD-PIN"},"installPaths":{"wheels-core":"vendor/wheels/"}}'
					);
					mod.framework(arg1 = "install");
					expect(vendorWheelsExists()).toBeTrue();
					// For a release build the pin is rewritten to the installed version;
					// for a snapshot/placeholder build it is left with a note. Either way
					// the pin step runs and names wheels-core in its output.
					expect(mod.capturedOutput()).toInclude("wheels-core");
				});

			});

			describe("refusals (no mutation)", () => {

				it("refuses when the directory is not a Wheels app root", () => {
					var bareDir = getTempDirectory() & "/f20-notapp-" & createUUID();
					directoryCreate(bareDir, true, true);
					var bareMod = new cli.lucli.tests._fixtures.commands.ModuleOutputCapture(cwd = bareDir);
					var state = {threw = false, message = ""};
					try {
						bareMod.framework(arg1 = "install");
					} catch (any e) {
						state.threw = true;
						state.message = e.message;
					}
					expect(state.threw).toBeTrue();
					expect(state.message).toInclude("app root");
					expect(directoryExists(bareDir & "/vendor/wheels")).toBeFalse("nothing was installed");
					directoryDelete(bareDir, true);
				});

				it("refuses when vendor/wheels/ is already a framework and points to upgrade apply", () => {
					seedVendorWheels(version = "0.0.1-spec-fixture");
					var state = {threw = false, message = ""};
					try {
						mod.framework(arg1 = "install");
					} catch (any e) {
						state.threw = true;
						state.message = e.message;
					}
					expect(state.threw).toBeTrue();
					expect(state.message).toInclude("upgrade apply");
					expect(installedVersion()).toBe("0.0.1-spec-fixture");
					expect(fileExists(variables.tempRoot & "/vendor/wheels/marker.txt")).toBeTrue();
				});

				it("refuses when vendor/wheels/ exists but is not a framework", () => {
					var vendorDir = variables.tempRoot & "/vendor/wheels";
					directoryCreate(vendorDir, true, true);
					fileWrite(vendorDir & "/notframework.txt", "junk");
					var state = {threw = false};
					try {
						mod.framework(arg1 = "install");
					} catch (any e) {
						state.threw = true;
					}
					expect(state.threw).toBeTrue();
					expect(fileExists(vendorDir & "/notframework.txt")).toBeTrue("the dir was left untouched");
				});

				it("refuses --to that does not match the bundled version, and installs nothing", () => {
					var state = {threw = false, message = ""};
					try {
						mod.framework(arg1 = "install", to = "9.9.9");
					} catch (any e) {
						state.threw = true;
						state.message = e.message;
					}
					expect(state.threw).toBeTrue();
					expect(state.message).toInclude("9.9.9");
					expect(vendorWheelsExists()).toBeFalse("nothing was installed");
				});

				it("throws on an unknown subcommand and installs nothing", () => {
					var state = {threw = false};
					try {
						mod.framework(arg1 = "bogus");
					} catch (any e) {
						state.threw = true;
					}
					expect(state.threw).toBeTrue();
					expect(vendorWheelsExists()).toBeFalse();
				});

			});

		});

	}

}
