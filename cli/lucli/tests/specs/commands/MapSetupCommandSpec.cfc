/**
 * `wheels map setup` — writes .mcp.json for AI assistants.
 *
 * Named `map`, not `mcp setup`: LuCLI owns the `mcp` verb at the runtime level
 * (`wheels mcp <name>` = "run module <name>"), so nothing under `mcp` ever
 * reaches Module.cfc. Verified live: `wheels mcp setup` printed
 * "mcp: module not found: 'setup'".
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.probe = new cli.lucli.tests._fixtures.commands.ModuleArgvProbe(cwd = expandPath("/"));
		variables.root = expandPath("/tmp") & "/wheelsMapSetupSpec" & randRange(100000, 999999);
		directoryCreate(variables.root, true);
		// $isWheelsProjectDir() requires config/settings.cfm
		directoryCreate(variables.root & "/config", true);
		fileWrite(variables.root & "/config/settings.cfm", "// spec fixture");
		probe.$setProjectRoot(variables.root);
	}

	function afterAll() {
		if (directoryExists(variables.root)) directoryDelete(variables.root, true);
	}

	function run() {

		describe("map setup — writing .mcp.json", () => {

			it("creates .mcp.json with the documented wheels server", () => {
				probe.$mcpSetupProbe([]);
				var path = variables.root & "/.mcp.json";
				expect(fileExists(path)).toBeTrue();
				var cfg = deserializeJSON(fileRead(path));
				expect(cfg.mcpServers.wheels.command).toBe("wheels");
				expect(cfg.mcpServers.wheels.args[1]).toBe("mcp");
				expect(cfg.mcpServers.wheels.args[2]).toBe("wheels");
			});

			it("is idempotent — a second run leaves the same content", () => {
				var path = variables.root & "/.mcp.json";
				var first = fileRead(path);
				probe.$mcpSetupProbe([]);
				expect(compare(fileRead(path), first)).toBe(0);
			});

			it("preserves other servers the user already listed", () => {
				var path = variables.root & "/.mcp.json";
				fileWrite(path, serializeJSON({
					mcpServers: {
						browsermcp: {command: "npx", args: ["@browsermcp/mcp@latest"]},
						postgres: {command: "npx", args: ["-y", "server-postgres"]}
					}
				}));
				probe.$mcpSetupProbe([]);
				var cfg = deserializeJSON(fileRead(path));
				expect(structKeyExists(cfg.mcpServers, "browsermcp")).toBeTrue();
				expect(cfg.mcpServers.browsermcp.args[1]).toBe("@browsermcp/mcp@latest");
				expect(structKeyExists(cfg.mcpServers, "postgres")).toBeTrue();
				expect(cfg.mcpServers.wheels.command).toBe("wheels");
			});

			it("corrects a wrong wheels entry instead of leaving it", () => {
				var path = variables.root & "/.mcp.json";
				var cfg = deserializeJSON(fileRead(path));
				cfg.mcpServers.wheels = {command: "npx", args: ["wrong"]};
				fileWrite(path, serializeJSON(cfg));
				probe.$mcpSetupProbe([]);
				expect(deserializeJSON(fileRead(path)).mcpServers.wheels.command).toBe("wheels");
			});

			it("refuses to clobber malformed JSON, and raises", () => {
				var path = variables.root & "/.mcp.json";
				var broken = '{ "mcpServers": { broken';
				fileWrite(path, broken);
				expect(() => {
					probe.$mcpSetupProbe([]);
				}).toThrow(type = "Wheels.McpSetup.InvalidJson");
				// The half-written file must survive untouched — rewriting it would
				// discard whatever the user was editing and hide the syntax error.
				expect(fileRead(path)).toBe(broken);
			});

			it("refuses when the JSON is valid but not an object", () => {
				var path = variables.root & "/.mcp.json";
				fileWrite(path, '["not","an","object"]');
				expect(() => {
					probe.$mcpSetupProbe([]);
				}).toThrow(type = "Wheels.McpSetup.InvalidShape");
			});

			it("writes nothing outside a Wheels project", () => {
				var bare = expandPath("/tmp") & "/wheelsMapBare" & randRange(100000, 999999);
				directoryCreate(bare, true);
				try {
					probe.$setProjectRoot(bare);
					probe.$mcpSetupProbe([]);
					expect(fileExists(bare & "/.mcp.json")).toBeFalse();
				} finally {
					probe.$setProjectRoot(variables.root);
					directoryDelete(bare, true);
				}
			});

		});

	}

}
