/**
 * `wheels new` writes the AI-assistant configs by default: `.mcp.json` (Claude
 * Code) and `.opencode.json` (OpenCode), the same files `wheels setup agents`
 * writes, so a new app's assistant finds the Wheels MCP server without a second
 * command. `--no-agents` skips them. A failure to write them only warns: the app
 * works without them and `wheels setup agents` can add them later.
 *
 * These run the real scaffold into a temp directory. The temp project's stub
 * vendor/wheels/ is the framework source new() copies, so nothing is downloaded.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		directoryCreate(tempRoot & "/vendor/wheels", true, true);
		fileWrite(tempRoot & "/vendor/wheels/Global.cfc", "component {}");
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	private any function newModule() {
		var m = new cli.lucli.Module(cwd = variables.tempRoot);
		prepareMock(m);
		m.$("out");
		m.$("printCreated");
		m.$("$isOffline", true);
		return m;
	}

	private string function printed(required any m) {
		var said = "";
		for (var call in arguments.m.$callLog().out) {
			said &= call[1] & chr(10);
		}
		return said;
	}

	private string function appName() {
		return "agentsapp" & randRange(100000, 999999);
	}

	function run() {

		describe("wheels new writes the AI-assistant configs (agents)", () => {

			it("writes .mcp.json and .opencode.json, in the shapes setup agents writes", () => {
				var name = appName();
				var m = newModule();
				m.new(arg1 = name, "open-browser" = false);
				var mcp = DeserializeJSON(FileRead(variables.tempRoot & "/" & name & "/.mcp.json"));
				expect(mcp.mcpServers.wheels.command).toBe("wheels");
				expect(mcp.mcpServers.wheels.args).toBe(["mcp", "wheels"]);
				var opencode = DeserializeJSON(FileRead(variables.tempRoot & "/" & name & "/.opencode.json"));
				expect(opencode.mcp.wheels.type).toBe("local");
				expect(opencode.mcp.wheels.command).toBe(["wheels", "mcp", "wheels"]);
			});

			it("names the files and the opt-out in its output", () => {
				var name = appName();
				var m = newModule();
				m.new(arg1 = name, "open-browser" = false);
				var said = printed(m);
				expect(said).toInclude(".mcp.json");
				expect(said).toInclude(".opencode.json");
				expect(said).toInclude("--no-agents");
				var created = [];
				for (var call in m.$callLog().printCreated) {
					ArrayAppend(created, call[1]);
				}
				expect(created).toInclude(name & "/.mcp.json");
				expect(created).toInclude(name & "/.opencode.json");
			});

			it("writes neither with --no-agents", () => {
				var name = appName();
				var m = newModule();
				// LuCLI hands `--no-agents` over as agents=false.
				m.new(arg1 = name, agents = false, "open-browser" = false);
				expect(FileExists(variables.tempRoot & "/" & name & "/.mcp.json")).toBeFalse();
				expect(FileExists(variables.tempRoot & "/" & name & "/.opencode.json")).toBeFalse();
				expect(DirectoryExists(variables.tempRoot & "/" & name & "/app")).toBeTrue();
			});

			it("only warns when it can't write them, and still creates the app", () => {
				var name = appName();
				var m = newModule();
				m.$(method = "$writeAgentConfigs", throwException = true, throwType = "Spec.WriteFailed", throwMessage = "disk full");
				m.new(arg1 = name, "open-browser" = false);
				var said = printed(m);
				expect(said).toInclude("disk full");
				expect(said).toInclude("wheels setup agents");
				expect(said).toInclude("Application created!");
			});

			it("documents --no-agents in wheels new --help", () => {
				// No arguments prints the same text as `wheels new --help`.
				var m = newModule();
				m.new();
				expect(printed(m)).toInclude("--no-agents");
			});

		});

	}

}
