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
 * Mirrors UpgradeApplyCommandSpec: a fresh scaffolded temp project per spec and
 * an output-capturing Module driven through the structured callerArgs path.
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
				// share a fixture. scaffoldTempProject leaves no vendor/wheels/.
				variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
				variables.mod = new cli.lucli.tests._fixtures.commands.ModuleOutputCapture(cwd = variables.tempRoot);
			});

			afterEach(() => {
				testHelper.cleanupTempProject(variables.tempRoot);
			});

			describe("help", () => {

				it("returns usage for --help", () => {
					var result = mod.framework(help = true);
					expect(result).toInclude("wheels framework install");
					expect(result).toInclude("--to=");
					expect(result).toInclude("upgrade apply");
				});

				it("returns usage for the bare command", () => {
					var result = mod.framework(arg1 = "");
					expect(result).toInclude("wheels framework install");
				});

				it("returns usage for the help subcommand", () => {
					expect(mod.framework(arg1 = "help")).toInclude("wheels framework install");
				});

				it("the bare command does not create vendor/wheels/", () => {
					mod.framework(arg1 = "");
					expect(vendorWheelsExists()).toBeFalse();
				});

			});

			describe("install into an app with no vendor/wheels/", () => {

				it("installs the bundled framework", () => {
					expect(vendorWheelsExists()).toBeFalse("precondition: no vendor/wheels/");
					mod.framework(arg1 = "install");
					expect(vendorWheelsExists()).toBeTrue("install created vendor/wheels/");
					expect(installedVersion()).toBe(variables.bundledVersion);
				});

				it("accepts --to when it matches the bundled version", () => {
					mod.framework(arg1 = "install", to = variables.bundledVersion);
					expect(installedVersion()).toBe(variables.bundledVersion);
				});

			});

			describe("refusals (no mutation)", () => {

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
					// untouched
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
