/**
 * `wheels setup agents` — writes the AI-client configs.
 *
 * The target is `agents`, NOT `mcp`: LuCLI intercepts the literal token `mcp`
 * in ANY argument position, so `wheels setup mcp` never reaches Module.cfc.
 * Verified live: it prints "mcp: missing module name" (and so does
 * `wheels info mcp` — the interception is positional, not argv[1]-only).
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

		describe("setup agents — writing the AI-client configs", () => {

			it("creates .mcp.json with the documented wheels server", () => {
				probe.$setupMcpProbe([]);
				var path = variables.root & "/.mcp.json";
				expect(fileExists(path)).toBeTrue();
				var cfg = deserializeJSON(fileRead(path));
				expect(cfg.mcpServers.wheels.command).toBe("wheels");
				expect(cfg.mcpServers.wheels.args[1]).toBe("mcp");
				expect(cfg.mcpServers.wheels.args[2]).toBe("wheels");
			});

			it("creates .opencode.json in OpenCode's own shape", () => {
				// Different client, different schema: an `mcp` key (not
				// `mcpServers`), `type: "local"`, and command+args as ONE array.
				// The wrapper's `wheels mcp` help has always promised both files.
				var path = variables.root & "/.opencode.json";
				expect(fileExists(path)).toBeTrue();
				var cfg = deserializeJSON(fileRead(path));
				expect(cfg["$schema"]).toBe("https://opencode.ai/config.json");
				expect(cfg.mcp.wheels.type).toBe("local");
				expect(cfg.mcp.wheels.enabled).toBeTrue();
				expect(arrayLen(cfg.mcp.wheels.command)).toBe(3);
				expect(cfg.mcp.wheels.command[1]).toBe("wheels");
				expect(cfg.mcp.wheels.command[2]).toBe("mcp");
				expect(cfg.mcp.wheels.command[3]).toBe("wheels");
			});

			it("is idempotent — a second run leaves the same content", () => {
				var path = variables.root & "/.mcp.json";
				var first = fileRead(path);
				probe.$setupMcpProbe([]);
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
				probe.$setupMcpProbe([]);
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
				probe.$setupMcpProbe([]);
				expect(deserializeJSON(fileRead(path)).mcpServers.wheels.command).toBe("wheels");
			});

			it("leaves a hand-added key on the wheels entry alone", () => {
				// Only the fields setup owns are compared, so an `environment`
				// block (or any other client-specific key) must not make setup
				// consider the entry wrong and rewrite the file every run.
				var path = variables.root & "/.opencode.json";
				var cfg = deserializeJSON(fileRead(path));
				cfg.mcp.wheels.environment = {FOO: "bar"};
				fileWrite(path, serializeJSON(cfg));
				var before = fileRead(path);
				probe.$setupMcpProbe([]);
				expect(compare(fileRead(path), before)).toBe(0);
			});

			it("validates every file before writing any — no half-applied setup", () => {
				var mcpPath = variables.root & "/.mcp.json";
				var ocPath = variables.root & "/.opencode.json";
				fileWrite(mcpPath, serializeJSON({mcpServers: {old: {command: "x", args: []}}}));
				fileWrite(ocPath, '{ "mcp": { broken');
				var before = fileRead(mcpPath);
				expect(() => {
					probe.$setupMcpProbe([]);
				}).toThrow(type = "Wheels.McpSetup.InvalidJson");
				// .mcp.json was valid and would have been rewritten first if the
				// files were processed one at a time.
				expect(fileRead(mcpPath)).toBe(before);
			});

			it("refuses to clobber malformed JSON, and raises", () => {
				var path = variables.root & "/.mcp.json";
				var broken = '{ "mcpServers": { broken';
				// Clear the other file so this exercises .mcp.json, not whichever
				// file happens to be validated first.
				if (fileExists(variables.root & "/.opencode.json")) {
					fileWrite(variables.root & "/.opencode.json", '{}');
				}
				fileWrite(path, broken);
				expect(() => {
					probe.$setupMcpProbe([]);
				}).toThrow(type = "Wheels.McpSetup.InvalidJson");
				// The half-written file must survive untouched — rewriting it would
				// discard whatever the user was editing and hide the syntax error.
				expect(fileRead(path)).toBe(broken);
			});

			it("refuses when the JSON is valid but not an object", () => {
				var path = variables.root & "/.mcp.json";
				fileWrite(path, '["not","an","object"]');
				expect(() => {
					probe.$setupMcpProbe([]);
				}).toThrow(type = "Wheels.McpSetup.InvalidShape");
			});

			it("writes nothing outside a Wheels project", () => {
				var bare = expandPath("/tmp") & "/wheelsMapBare" & randRange(100000, 999999);
				directoryCreate(bare, true);
				try {
					probe.$setProjectRoot(bare);
					probe.$setupMcpProbe([]);
					expect(fileExists(bare & "/.mcp.json")).toBeFalse();
				} finally {
					probe.$setProjectRoot(variables.root);
					directoryDelete(bare, true);
				}
			});

		});

	}

}
