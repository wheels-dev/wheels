component extends="wheels.WheelsTest" {

	function run() {
		describe("the deprecated HTTP MCP surface is read-only", () => {

			// McpServer backs ONLY the deprecated /wheels/mcp HTTP endpoint (the
			// canonical MCP is the stdio server, `wheels mcp wheels`). Mutating /
			// command-executing tools must not be reachable over this surface.
			var mcp = new wheels.public.mcp.McpServer();

			it("does not advertise mutating tools in tools/list", () => {
				var response = mcp.handleRequest({jsonrpc = "2.0", id = 1, method = "tools/list", params = {}}, "test-session");
				var names = "";
				for (var tool in response.result.tools) {
					names = ListAppend(names, tool.name);
				}
				// Write / command-executing tools are gone from the HTTP surface.
				for (var mutating in ["generate", "migrate", "test", "validate", "server", "reload", "develop"]) {
					expect(ListFindNoCase(names, mutating)).toBe(0, mutating & " must not be advertised over HTTP");
				}
				// The read-only analysis tool remains.
				expect(ListFindNoCase(names, "analyze")).toBeGT(0, "analyze stays available");
			});

			it("refuses a tools/call for the generate (write) tool", () => {
				// Empty args: on the unpatched code this returns a parameter error
				// WITHOUT writing a file, so the red baseline has no side effect.
				var response = mcp.handleRequest(
					{jsonrpc = "2.0", id = 2, method = "tools/call", params = {name = "generate", arguments = {}}},
					"test-session"
				);
				expect(StructKeyExists(response, "error")).toBeTrue("generate must be refused over HTTP");
				expect(FindNoCase("stdio MCP", response.error.message) > 0 || FindNoCase("not available", response.error.message) > 0).toBeTrue(
					"the error should point to the canonical stdio MCP"
				);
			});

			it("still allows the read-only analyze tool through tools/call", () => {
				var response = mcp.handleRequest(
					{jsonrpc = "2.0", id = 3, method = "tools/call", params = {name = "analyze", arguments = {}}},
					"test-session"
				);
				// analyze may return a tool-level error for missing args, but it must
				// NOT be blocked by the HTTP read-only gate.
				var blocked = StructKeyExists(response, "error")
					&& (FindNoCase("stdio MCP", response.error.message ?: "") > 0 || FindNoCase("not available over the deprecated HTTP", response.error.message ?: "") > 0);
				expect(blocked).toBeFalse("analyze must stay callable over HTTP");
			});

			it("still answers read-only protocol meta-methods (prompts/list)", () => {
				var response = mcp.handleRequest({jsonrpc = "2.0", id = 4, method = "prompts/list", params = {}}, "test-session");
				expect(StructKeyExists(response, "result")).toBeTrue();
			});

		});
	}
}
