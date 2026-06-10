/**
 * Coverage for `mcpToolSpecs()` — the per-tool MCP inputSchema registry
 * (issue #2963, the headline item left after PR #2967 shipped the
 * `ArgSpec.toInputSchema()` foundation).
 *
 * Module.cfc command functions declare no formal parameters (they consume
 * LuCLI's structured argCollection), so the runtime's signature-derived
 * inputSchema is `{properties: {}, additionalProperties: false}` — MCP
 * clients can neither discover nor pass parameters. `mcpToolSpecs()` returns
 * a struct of populated schemas keyed by tool name, each built from the SAME
 * ArgSpec the command's parse helper uses, so the CLI parse surface and the
 * MCP advertisement cannot drift. LuCLI reads it per the same optional-
 * convention mechanism as `mcpHiddenTools()`.
 *
 * Behavioral specs run through ModuleArgvProbe (no server, no side effects);
 * structure facts that can't be exercised without the LuCLI runtime are
 * pinned source-level, like UpgradeCommandSpec / McpHiddenToolsSpec.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.probe = new cli.lucli.tests._fixtures.commands.ModuleArgvProbe(
			cwd = expandPath("/")
		);
		variables.moduleSource = fileRead(expandPath("/cli/lucli/Module.cfc"));
	}

	function run() {

		describe("mcpToolSpecs() — MCP inputSchema registry (##2963)", () => {

			it("returns a populated object schema for every ArgSpec-backed tool", () => {
				var specs = probe.mcpToolSpecs();
				expect(specs).toBeStruct();
				for (var toolName in ["test", "seed", "analyze", "destroy", "notes", "upgrade", "doctor", "stats"]) {
					expect(specs).toHaveKey(toolName, "Expected an inputSchema entry for the `#toolName#` tool.");
					expect(specs[toolName].type).toBe("object");
					expect(structCount(specs[toolName].properties)).toBeGT(
						0,
						"The `#toolName#` schema must advertise at least one property — an empty schema is exactly the gap ##2963 tracks."
					);
					expect(specs[toolName].additionalProperties).toBeFalse();
				}
			});

			it("derives the test tool schema from the same ArgSpec parseTestArgs uses", () => {
				var schema = probe.mcpToolSpecs().test;
				expect(schema.properties).toHaveKey("filter");
				expect(schema.properties).toHaveKey("reporter");
				expect(schema.properties).toHaveKey("db");
				expect(schema.properties).toHaveKey("verbose");
				expect(schema.properties.verbose.type).toBe("boolean");
				expect(schema.properties.reporter["default"]).toBe("simple");
			});

			it("includes upgrade's subcommand positional and strict flag", () => {
				var schema = probe.mcpToolSpecs().upgrade;
				expect(schema.properties).toHaveKey("subcommand");
				expect(schema.properties).toHaveKey("strict");
				expect(schema.properties.strict.type).toBe("boolean");
			});

			it("describes every property so MCP clients see usable parameter docs", () => {
				var specs = probe.mcpToolSpecs();
				for (var toolName in specs) {
					for (var propName in specs[toolName].properties) {
						expect(specs[toolName].properties[propName]).toHaveKey(
							"description",
							"Property `#propName#` of tool `#toolName#` is missing a description."
						);
					}
				}
			});

			it("hides mcpToolSpecs itself from the MCP tool surface", () => {
				// mcpToolSpecs() is a public module function, so auto-discovery
				// would otherwise advertise the registry itself as a callable
				// tool on runtimes that predate the convention.
				expect(arrayContainsNoCase(probe.mcpHiddenTools(), "mcpToolSpecs")).toBeTrue();
			});

			it("parse helpers share the registry's builders (no-drift check)", () => {
				// The parse path and the schema path must construct the SAME
				// ArgSpec. Source-level: parseTestArgs/parseSeedArgs call their
				// builder instead of chaining an inline `new services.ArgSpec()`.
				expect(variables.moduleSource).toInclude("testArgSpec().parse(");
				expect(variables.moduleSource).toInclude("seedArgSpec().parse(");
				expect(variables.moduleSource).toInclude("upgradeArgSpec().parse(");
			});

		});

		describe("wheels test — crashed runs exit non-zero (##2963)", () => {

			it("throws Wheels.TestRunFailed when the run crashes before producing results", () => {
				// A crash during the HTTP/parse phase printed red and exited 0:
				// the post-catch Wheels.TestsFailed throw handles FAILING tests,
				// not CRASHED runs. Source-level (the path needs a live server
				// to exercise): the catch path must mark the run crashed and a
				// post-catch gate must throw a typed error, mirroring the
				// Wheels.TestsFailed pattern at the same altitude.
				expect(variables.moduleSource).toInclude("Wheels.TestRunFailed");
			});

			it("marks the non-JSON (HTML error page) response path as crashed too", () => {
				// `runState.crashed` must be set on BOTH silent paths: the
				// catch block and the server-returned-HTML branch. The struct
				// form (not a bare local) is required — local writes inside
				// catch don't persist on BoxLang (CLAUDE.md invariant 11).
				expect(variables.moduleSource).toInclude("runState.crashed");
			});

		});

	}

}
