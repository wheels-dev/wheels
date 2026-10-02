/**
 * #3910: `new` was hidden from the stdio MCP server, but an MCP client could
 * still scaffold a whole application into the server's working directory
 * through the `create` tool or `generate` with type=app. `create` is now hidden
 * too (LuCLI refuses a call to an unlisted tool), so it has no MCP schema; its
 * advertised type+name schema never matched the new() options it forwards.
 * `app` is no longer an advertised choice for generate's type, but a client
 * that ignores the schema can still send it: server-side refusal is #3980.
 * CLI usage is unchanged.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		directoryCreate(tempRoot & "/vendor/wheels", true, true);
		variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {
		describe("create is hidden from MCP and generate no longer advertises app", () => {

			it("hides create alongside new", () => {
				var hidden = mod.mcpHiddenTools();
				expect(arrayFindNoCase(hidden, "new")).toBeGT(0);
				expect(arrayFindNoCase(hidden, "create")).toBeGT(0, "create scaffolds an application, like new");
			});

			it("advertises no MCP schema for the hidden create tool", () => {
				expect(mod.mcpToolSpecs()).notToHaveKey("create");
			});

			it("drops app from generate's advertised type enum and keeps every real generator", () => {
				var choices = mod.mcpToolSpecs().generate.properties.type.enum;
				expect(arrayFindNoCase(choices, "app")).toBe(0);
				for (var t in ["model", "controller", "view", "scaffold", "migration", "api-resource", "route", "test", "property", "helper", "policy", "snippets", "admin", "auth"]) {
					expect(arrayFindNoCase(choices, t)).toBeGT(0, "generate should still advertise #t#");
				}
				expect(mod.mcpToolSpecs().generate.properties.type.description).notToInclude("app");
			});
		});
	}

}
