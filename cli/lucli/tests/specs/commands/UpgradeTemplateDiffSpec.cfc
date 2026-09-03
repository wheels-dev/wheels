/**
 * Source-level coverage for the app-template drift advisory in
 * `wheels upgrade check` (##3379 follow-up). The check diffs app-owned
 * template files (public/Application.cfc, public/index.cfm) against the
 * CLI's bundled app template — the same source `wheels new` scaffolds —
 * so a patch/minor upgrade surfaces missing framework-side hardening
 * without hardcoding a per-release element probe.
 *
 * Like UpgradeCommandSpec/UpgradeAdvisorySpec, this is source-level
 * inspection: Module.cfc can't be instantiated under TestBox.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.moduleSource = fileRead(expandPath("/cli/lucli/Module.cfc"));
	}

	function run() {

		describe("wheels upgrade — app template drift advisory", () => {

			it("declares a templateDiff check type (advisory, not breaking)", () => {
				expect(variables.moduleSource).toInclude("checkType: ""templateDiff""");
				expect(variables.moduleSource).toInclude("severity: ""advisory""");
			});

			it("tracks public/Application.cfc and public/index.cfm", () => {
				expect(variables.moduleSource).toInclude("public/Application.cfc");
				expect(variables.moduleSource).toInclude("public/index.cfm");
			});

			it("resolves the reference copy from the CLI's bundled app template", () => {
				expect(variables.moduleSource).toInclude("variables.moduleRoot & ""templates/app/""");
			});

			it("executes a templateDiff branch that compares file contents", () => {
				expect(variables.moduleSource).toInclude("arguments.check.checkType == ""templateDiff""");
				expect(variables.moduleSource).toInclude("compare(fileRead(userPath), fileRead(templatePath))");
			});

			it("names the Adobe teardown hardening in the fix message", () => {
				expect(variables.moduleSource).toInclude("Adobe teardown crashes");
			});

		});

	}

}
