/**
 * The AGENTS.md that `wheels new` ships (#3971) must not make the MCP advice
 * depend on a .mcp.json the generator never writes, and must say how to enable
 * MCP: `wheels setup agents`, or the config by hand.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {
		describe("shipped AGENTS.md MCP advice", () => {
			it("tells the reader how to enable MCP in a new app", () => {
				var text = fileRead(expandPath("/cli/lucli/templates/app/AGENTS.md"));
				expect(text).toInclude("wheels setup agents");
				expect(text).toInclude('"command":"wheels","args":["mcp","wheels"]');
			});

			it("does not condition the advice on an existing .mcp.json", () => {
				var text = fileRead(expandPath("/cli/lucli/templates/app/AGENTS.md"));
				expect(text).notToInclude("when `.mcp.json` is configured");
			});
		});
	}

}
