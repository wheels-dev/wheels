/**
 * `wheels generate app <name> --dry-run` (and the MCP `generate` tool with
 * type=app and dry-run=true) reports the project it would create and writes
 * nothing: no folder, no vendor/wheels copy, no .env with generated passwords.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.workDir = getTempDirectory() & "gen-app-dry-" & createUUID();
		directoryCreate(variables.workDir);
	}

	function afterAll() {
		if (directoryExists(variables.workDir)) {
			directoryDelete(variables.workDir, true);
		}
	}

	function run() {

		describe("wheels generate app --dry-run", () => {

			it("creates no project folder and lists the one it would create", () => {
				var mod = new cli.lucli.Module(cwd = variables.workDir);
				prepareMock(mod);
				mod.$("out");
				mod.__arguments = ["app", "dryapp", "--dry-run"];
				mod.generate();
				expect(directoryExists(variables.workDir & "/dryapp")).toBeFalse("generate app --dry-run created the project");
				expect(serializeJSON(mod.$callLog().out)).toInclude("dryapp");
			});

			it("clears the dry-run flag when the command ends", () => {
				// The dry-run state must not leak into the next generate call (#2963).
				var mod = new cli.lucli.Module(cwd = variables.workDir);
				prepareMock(mod);
				mod.$("out");
				mod.__arguments = ["app", "dryapp", "--dry-run"];
				mod.generate();
				expect(StructKeyExists(request, "$wheelsGenerateDryRun") && request.$wheelsGenerateDryRun).toBeFalse("the dry-run flag outlived the command");
			});

		});

	}

}
