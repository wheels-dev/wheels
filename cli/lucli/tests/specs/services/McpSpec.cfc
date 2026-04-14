component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.tempRoot = getTempDirectory() & "wheels-mcp-test-" & createUUID();
		directoryCreate(variables.tempRoot, true);
		variables.mcp = new cli.lucli.services.MCP(projectRoot = variables.tempRoot);
	}

	function afterAll() {
		if (len(variables.tempRoot) > 10 && directoryExists(variables.tempRoot)) {
			directoryDelete(variables.tempRoot, true);
		}
	}

	function run() {

		describe("MCP Service", () => {

			describe("getToolSchemas()", () => {

				it("returns an array", () => {
					var schemas = mcp.getToolSchemas();
					expect(isArray(schemas)).toBeTrue();
				});

				it("returns at least 10 tool schemas", () => {
					var schemas = mcp.getToolSchemas();
					expect(arrayLen(schemas)).toBeGTE(10);
				});

				it("each schema has name, description, and inputSchema", () => {
					var schemas = mcp.getToolSchemas();
					for (var schema in schemas) {
						expect(structKeyExists(schema, "name")).toBeTrue("Schema missing name: #serializeJSON(schema)#");
						expect(structKeyExists(schema, "description")).toBeTrue("Schema missing description for: #schema.name#");
						expect(structKeyExists(schema, "inputSchema")).toBeTrue("Schema missing inputSchema for: #schema.name#");
					}
				});

				it("tool names are prefixed with wheels_", () => {
					var schemas = mcp.getToolSchemas();
					for (var schema in schemas) {
						expect(left(schema.name, 7)).toBe("wheels_", "Tool name not prefixed: #schema.name#");
					}
				});

				it("includes wheels_generate tool", () => {
					var schemas = mcp.getToolSchemas();
					var names = [];
					for (var s in schemas) arrayAppend(names, s.name);
					expect(arrayFindNoCase(names, "wheels_generate")).toBeGT(0);
				});

				it("includes wheels_migrate tool", () => {
					var schemas = mcp.getToolSchemas();
					var names = [];
					for (var s in schemas) arrayAppend(names, s.name);
					expect(arrayFindNoCase(names, "wheels_migrate")).toBeGT(0);
				});

				it("includes wheels_test tool", () => {
					var schemas = mcp.getToolSchemas();
					var names = [];
					for (var s in schemas) arrayAppend(names, s.name);
					expect(arrayFindNoCase(names, "wheels_test")).toBeGT(0);
				});

				it("includes wheels_destroy tool", () => {
					var schemas = mcp.getToolSchemas();
					var names = [];
					for (var s in schemas) arrayAppend(names, s.name);
					expect(arrayFindNoCase(names, "wheels_destroy")).toBeGT(0);
				});

				it("includes wheels_doctor tool", () => {
					var schemas = mcp.getToolSchemas();
					var names = [];
					for (var s in schemas) arrayAppend(names, s.name);
					expect(arrayFindNoCase(names, "wheels_doctor")).toBeGT(0);
				});

				it("includes wheels_db tool", () => {
					var schemas = mcp.getToolSchemas();
					var names = [];
					for (var s in schemas) arrayAppend(names, s.name);
					expect(arrayFindNoCase(names, "wheels_db")).toBeGT(0);
				});

				it("inputSchema has type property", () => {
					var schemas = mcp.getToolSchemas();
					for (var schema in schemas) {
						expect(structKeyExists(schema.inputSchema, "type")).toBeTrue(
							"inputSchema missing type for: #schema.name#"
						);
					}
				});

				it("wheels_generate inputSchema requires type parameter", () => {
					var schemas = mcp.getToolSchemas();
					var generateSchema = {};
					for (var s in schemas) {
						if (s.name == "wheels_generate") { generateSchema = s; break; }
					}
					expect(structKeyExists(generateSchema, "inputSchema")).toBeTrue();
					expect(structKeyExists(generateSchema.inputSchema, "properties")).toBeTrue();
					expect(structKeyExists(generateSchema.inputSchema.properties, "type")).toBeTrue();
				});

			});

		});

	}

}
