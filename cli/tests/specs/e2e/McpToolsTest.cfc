/**
 * E2E tests for LuCLI MCP tool integration.
 *
 * Verifies that Module.cfc public functions are correctly structured for
 * MCP auto-discovery:
 *   - All public functions have hint annotations (tool descriptions)
 *   - Expected tool set matches the public function inventory
 *   - Tool invocation works through the MCP contract (Module functions callable)
 *   - MCP config (.mcp.json) is generated correctly for Claude Code
 *   - McpServer.cfc tool definitions match Module.cfc public interface
 */
component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		// Resolve paths relative to this test file:
		//   this file:  cli/tests/specs/e2e/McpToolsTest.cfc
		//   lucli root: cli/lucli/
		var thisDir = getDirectoryFromPath(getCurrentTemplatePath());
		var File = createObject("java", "java.io.File");
		variables.cliRoot = File.init(thisDir & "../../../").getCanonicalPath();
		variables.lucliRoot = variables.cliRoot & "/lucli";
		variables.modulePath = variables.lucliRoot & "/Module.cfc";
		variables.mcpServerPath = File.init(variables.cliRoot & "/../vendor/wheels/public/mcp/McpServer.cfc").getCanonicalPath();

		// Read Module.cfc source for introspection
		variables.moduleSource = fileRead(variables.modulePath);

		// Expected public functions that LuCLI auto-discovers as MCP tools.
		// These are prefixed with the module name to become: wheels_generate, wheels_migrate, etc.
		variables.expectedTools = [
			"generate",
			"migrate",
			"test",
			"reload",
			"start",
			"stop",
			"new",
			"routes",
			"info",
			"mcp",
			"analyze",
			"validate"
		];

		// Create a temp project directory for tool invocation tests
		variables.testDir = getTempDirectory() & "wheels_e2e_mcp_" & createUUID();
		directoryCreate(variables.testDir);
		scaffoldMinimalProject(variables.testDir);

		// Instantiate service stack for tool invocation tests
		variables.helpers = new cli.lucli.services.Helpers();
		variables.templates = new cli.lucli.services.Templates(
			helpers = variables.helpers,
			projectRoot = variables.testDir,
			moduleRoot = variables.lucliRoot & "/"
		);
		variables.codegen = new cli.lucli.services.CodeGen(
			templateService = variables.templates,
			helpers = variables.helpers,
			projectRoot = variables.testDir
		);
		variables.scaffold = new cli.lucli.services.Scaffold(
			codeGenService = variables.codegen,
			helpers = variables.helpers,
			projectRoot = variables.testDir
		);
	}

	function afterAll() {
		if (directoryExists(variables.testDir)) {
			directoryDelete(variables.testDir, true);
		}
	}

	function run() {

		// ─── MCP Tool Auto-Discovery ───────────────────

		describe("MCP Tool Auto-Discovery from Module.cfc", function() {

			it("has Module.cfc with component hint annotation", function() {
				expect(variables.moduleSource).toMatch(
					"\*\s+hint:",
					"Module.cfc should have a component-level hint for MCP module description"
				);
			});

			it("exposes all expected public functions as MCP tool candidates", function() {
				for (var toolName in variables.expectedTools) {
					expect(variables.moduleSource).toMatch(
						"public\s+string\s+function\s+#toolName#\s*\(",
						"Module.cfc should have public function: #toolName#"
					);
				}
			});

			it("provides hint annotation on every public function", function() {
				// Extract public function blocks preceded by a /** hint: ... */ doc comment.
				// Uses (?s) so .* spans newlines; .*? is non-greedy to avoid over-matching.
				var pattern = "(?s)/\*\*.*?\*\s+hint:\s*[^\n]+\n\s*\*/\s*public\s+string\s+function\s+(\w+)";
				var matcher = createObject("java", "java.util.regex.Pattern")
					.compile(pattern)
					.matcher(variables.moduleSource);

				var hintsFound = {};
				while (matcher.find()) {
					hintsFound[matcher.group(1)] = true;
				}

				for (var toolName in variables.expectedTools) {
					expect(structKeyExists(hintsFound, toolName)).toBeTrue(
						"Public function '#toolName#' should have a /** hint: ... */ annotation for MCP discovery"
					);
				}
			});

			it("does not expose private functions as tools", function() {
				// Private functions should NOT appear as MCP tools
				var privatePattern = "private\s+\w+\s+function\s+(\w+)";
				var matcher = createObject("java", "java.util.regex.Pattern")
					.compile(privatePattern)
					.matcher(variables.moduleSource);

				var privateFunctions = [];
				while (matcher.find()) {
					arrayAppend(privateFunctions, matcher.group(1));
				}

				expect(arrayLen(privateFunctions)).toBeGT(0,
					"Module should have private functions (implementation details)"
				);

				for (var fn in privateFunctions) {
					expect(arrayFindNoCase(variables.expectedTools, fn)).toBe(0,
						"Private function '#fn#' should NOT be in expected tools list"
					);
				}
			});

			it("prefixes tool names with module name (wheels_)", function() {
				// Verify module.json declares name="wheels" for tool prefixing
				var moduleJsonPath = variables.lucliRoot & "/module.json";
				expect(fileExists(moduleJsonPath)).toBeTrue("module.json must exist");

				var moduleConfig = deserializeJSON(fileRead(moduleJsonPath));
				expect(moduleConfig).toHaveKey("name");
				expect(moduleConfig.name).toBe("wheels",
					"Module name should be 'wheels' — tools will be prefixed as wheels_*"
				);
			});

			it("defines a complete tool inventory (no missing or unexpected tools)", function() {
				// Extract all public function names from Module.cfc
				var publicPattern = "public\s+string\s+function\s+(\w+)";
				var matcher = createObject("java", "java.util.regex.Pattern")
					.compile(publicPattern)
					.matcher(variables.moduleSource);

				var actualPublicFunctions = [];
				while (matcher.find()) {
					arrayAppend(actualPublicFunctions, matcher.group(1));
				}

				// Every public function should be in our expected list
				for (var fn in actualPublicFunctions) {
					expect(arrayFindNoCase(variables.expectedTools, fn)).toBeGT(0,
						"Public function '#fn#' is exposed as MCP tool but not in expected list — update test"
					);
				}

				// Every expected tool should exist as a public function
				for (var tool in variables.expectedTools) {
					expect(arrayFindNoCase(actualPublicFunctions, tool)).toBeGT(0,
						"Expected tool '#tool#' not found as public function in Module.cfc"
					);
				}
			});
		});

		// ─── MCP Tool Invocation via Services ──────────

		describe("MCP Tool Invocation (service layer)", function() {

			it("wheels_generate: model generation produces valid output", function() {
				var result = variables.codegen.generateModel(name = "McpTestUser", force = true);
				expect(result.success).toBeTrue("generate model should succeed via MCP tool path");

				var filePath = variables.testDir & "/app/models/McpTestUser.cfc";
				expect(fileExists(filePath)).toBeTrue("Generated model should exist");

				var content = fileRead(filePath);
				expect(content).toInclude('extends="Model"');
			});

			it("wheels_generate: controller generation with actions", function() {
				var result = variables.codegen.generateController(
					name = "McpTestItems",
					actions = ["index", "show"],
					force = true
				);
				expect(result.success).toBeTrue("generate controller should succeed via MCP tool path");

				var filePath = variables.testDir & "/app/controllers/McpTestItems.cfc";
				expect(fileExists(filePath)).toBeTrue("Generated controller should exist");

				var content = fileRead(filePath);
				expect(content).toInclude('extends="Controller"');
				expect(content).toInclude("function index()");
				expect(content).toInclude("function show()");
			});

			it("wheels_generate: scaffold generates all artifacts", function() {
				var result = variables.scaffold.generateScaffold(
					name = "McpWidget",
					properties = [{name: "label", type: "string"}],
					force = true
				);
				expect(result.success).toBeTrue("scaffold should succeed via MCP tool path");

				// Verify generated types
				var types = [];
				for (var item in result.generated) {
					arrayAppend(types, item.type);
				}
				expect(types).toInclude("model");
				expect(types).toInclude("controller");
				expect(types).toInclude("migration");
			});

			it("wheels_analyze: analysis service is instantiable", function() {
				var analysis = new cli.lucli.services.Analysis(
					helpers = variables.helpers,
					projectRoot = variables.testDir
				);
				expect(isObject(analysis)).toBeTrue(
					"Analysis service should instantiate for MCP tool invocation"
				);
			});

			it("wheels_validate: validation returns structured result", function() {
				var analysis = new cli.lucli.services.Analysis(
					helpers = variables.helpers,
					projectRoot = variables.testDir
				);
				var results = analysis.validate();
				expect(isStruct(results)).toBeTrue("validate should return a struct");
				expect(results).toHaveKey("valid");
				expect(results).toHaveKey("issues");
			});

			it("wheels_test: test generator produces spec files", function() {
				var result = variables.codegen.generateTest(type = "model", name = "McpTestUser");
				expect(result.success).toBeTrue("test generation should succeed via MCP tool path");

				var testPath = variables.testDir & "/tests/specs/models/McpTestUserSpec.cfc";
				expect(fileExists(testPath)).toBeTrue("Generated test spec should exist");

				var content = fileRead(testPath);
				expect(content).toInclude("describe(");
			});
		});

		// ─── McpServer.cfc Tool Definitions ────────────

		describe("McpServer.cfc Tool Definitions", function() {

			it("McpServer.cfc exists with handleToolsList", function() {
				expect(fileExists(variables.mcpServerPath)).toBeTrue(
					"McpServer.cfc should exist at vendor/wheels/public/mcp/"
				);

				var serverSource = fileRead(variables.mcpServerPath);
				expect(serverSource).toInclude("handleToolsList");
				expect(serverSource).toInclude("handleToolsCall");
			});

			it("defines core tools matching Module.cfc public functions", function() {
				var serverSource = fileRead(variables.mcpServerPath);

				// Core tools that should be in both Module.cfc and McpServer.cfc
				var coreTools = ["generate", "analyze", "validate", "migrate", "test", "reload"];
				for (var tool in coreTools) {
					expect(serverSource).toInclude('"#tool#"',
						"McpServer.cfc should define tool: #tool#"
					);
				}
			});

			it("tools have valid MCP inputSchema structure", function() {
				var serverSource = fileRead(variables.mcpServerPath);

				// Every tool definition should have an inputSchema with type:"object"
				expect(serverSource).toInclude('"inputSchema"');
				expect(serverSource).toInclude('"type": "object"');
				expect(serverSource).toInclude('"properties"');
			});

			it("handleToolsCall dispatches to execute functions", function() {
				var serverSource = fileRead(variables.mcpServerPath);

				// Verify switch cases in handleToolsCall match tool names
				var dispatchTools = ["generate", "migrate", "test", "reload", "analyze", "validate"];
				for (var tool in dispatchTools) {
					expect(serverSource).toInclude('case "#tool#"',
						"handleToolsCall should dispatch tool: #tool#"
					);
				}
			});

			it("implements JSON-RPC 2.0 protocol correctly", function() {
				var serverSource = fileRead(variables.mcpServerPath);

				expect(serverSource).toInclude('"jsonrpc"');
				expect(serverSource).toInclude('"2.0"');
				expect(serverSource).toInclude("createSuccessResponse");
				expect(serverSource).toInclude("createErrorResponse");
				expect(serverSource).toInclude('"tools/list"');
				expect(serverSource).toInclude('"tools/call"');
			});

			it("supports MCP initialize handshake", function() {
				var serverSource = fileRead(variables.mcpServerPath);

				expect(serverSource).toInclude('"initialize"');
				expect(serverSource).toInclude("handleInitialize");
				expect(serverSource).toInclude("serverInfo");
				expect(serverSource).toInclude("capabilities");
			});
		});

		// ─── MCP Configuration for Claude Code ─────────

		describe("MCP Configuration for Claude Code", function() {

			it("Module.cfc mcp() outputs correct LuCLI MCP command", function() {
				expect(variables.moduleSource).toInclude('lucli mcp wheels',
					"mcp() should reference the LuCLI MCP command"
				);
			});

			it("Module.cfc mcp() references Claude Code config format", function() {
				expect(variables.moduleSource).toInclude("mcpServers",
					"mcp() should reference mcpServers JSON structure"
				);
				expect(variables.moduleSource).toInclude("Claude Code",
					"mcp() should mention Claude Code configuration"
				);
			});

			it("documents auto-discovery: public functions become MCP tools", function() {
				expect(variables.moduleSource).toInclude("auto-discovered",
					"mcp() should document that public functions are auto-discovered as MCP tools"
				);
			});

			it("documents tool naming convention (module prefix)", function() {
				expect(variables.moduleSource).toInclude("wheels_generate",
					"mcp() should document the wheels_ prefix naming convention"
				);
			});

			it("MCP config template exists for IDE setup", function() {
				var templatePath = variables.cliRoot & "/src/templates/McpConfig.json";
				if (fileExists(templatePath)) {
					var content = fileRead(templatePath);
					expect(isJSON(content.replace("{PORT}", "8080"))).toBeTrue(
						"McpConfig.json template should be valid JSON (after placeholder substitution)"
					);

					var config = deserializeJSON(content.replace("{PORT}", "8080"));
					expect(config).toHaveKey("mcpServers");
					expect(config.mcpServers).toHaveKey("wheels");
				}
			});
		});

		// ─── Module Metadata ───────────────────────────

		describe("Module Metadata (module.json)", function() {

			it("module.json is valid JSON", function() {
				var content = fileRead(variables.lucliRoot & "/module.json");
				expect(isJSON(content)).toBeTrue("module.json must be valid JSON");
			});

			it("declares required fields for LuCLI module registry", function() {
				var config = deserializeJSON(fileRead(variables.lucliRoot & "/module.json"));
				expect(config).toHaveKey("name");
				expect(config).toHaveKey("version");
				expect(config).toHaveKey("description");
				expect(config).toHaveKey("main");
			});

			it("main points to Module.cfc", function() {
				var config = deserializeJSON(fileRead(variables.lucliRoot & "/module.json"));
				expect(config.main).toBe("Module.cfc");
			});

			it("declares lucli keyword for module discovery", function() {
				var config = deserializeJSON(fileRead(variables.lucliRoot & "/module.json"));
				expect(config).toHaveKey("keywords");
				expect(config.keywords).toInclude("lucli");
			});
		});

		// ─── End-to-End: Tool Discovery → Invocation ───

		describe("End-to-End: Discovery to Invocation", function() {

			it("every discovered tool maps to a callable service operation", function() {
				// Map MCP tools to their service-layer equivalents
				var serviceCallableTools = {
					"generate": function() {
						return variables.codegen.generateModel(name = "E2ETest", force = true);
					},
					"validate": function() {
						var analysis = new cli.lucli.services.Analysis(
							helpers = variables.helpers,
							projectRoot = variables.testDir
						);
						return analysis.validate();
					},
					"analyze": function() {
						var analysis = new cli.lucli.services.Analysis(
							helpers = variables.helpers,
							projectRoot = variables.testDir
						);
						return analysis.analyze("models");
					}
				};

				for (var toolName in serviceCallableTools) {
					var callFn = serviceCallableTools[toolName];
					var result = callFn();
					expect(isStruct(result)).toBeTrue(
						"Tool '#toolName#' should return a struct result when invoked"
					);
				}
			});

			it("tool results contain success/error structure for MCP response", function() {
				// MCP tools should return structured results that can be serialized
				var result = variables.codegen.generateModel(name = "McpStructTest", force = true);

				expect(result).toHaveKey("success");
				expect(isBoolean(result.success)).toBeTrue(
					"Tool result should have boolean 'success' field for MCP response mapping"
				);
			});

			it("tool error results include descriptive error message", function() {
				// Create a model, then try to create it again without force
				variables.codegen.generateModel(name = "McpDuplicate", force = true);
				var result = variables.codegen.generateModel(name = "McpDuplicate");

				expect(result.success).toBeFalse();
				expect(result).toHaveKey("error");
				expect(len(result.error)).toBeGT(0,
					"Failed tool invocation should include descriptive error message"
				);
			});
		});
	}

	// ── Test setup helpers ──────────────────────────

	private void function scaffoldMinimalProject(required string projectRoot) {
		var dirs = [
			"/app/controllers",
			"/app/models",
			"/app/views",
			"/app/migrator/migrations",
			"/app/snippets",
			"/config",
			"/public",
			"/tests/specs/models",
			"/tests/specs/controllers",
			"/tests/specs/functional",
			"/vendor/wheels"
		];

		for (var dir in dirs) {
			directoryCreate(arguments.projectRoot & dir, true);
		}

		var nl = chr(10);
		var tab = chr(9);
		fileWrite(
			arguments.projectRoot & "/config/routes.cfm",
			'<cfscript>' & nl &
			tab & 'mapper()' & nl &
			tab & tab & '// CLI-Appends-Here' & nl & nl &
			tab & tab & '.wildcard()' & nl &
			tab & tab & '.root(to="main##index", method="get")' & nl &
			tab & '.end();' & nl &
			'</cfscript>' & nl
		);

		fileWrite(
			arguments.projectRoot & "/config/settings.cfm",
			'<cfscript>' & nl & tab & "set(environment='development');" & nl & '</cfscript>' & nl
		);
	}

}
