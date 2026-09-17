component extends="wheels.WheelsTest" {

	function run() {

		describe("McpServer (HTTP MCP endpoint)", () => {

			var mcp = new wheels.public.mcp.McpServer();

			it("lists tools", () => {
				var response = mcp.handleRequest({ jsonrpc = "2.0", id = 1, method = "tools/list", params = {} }, "test-session");
				expect(response.jsonrpc).toBe("2.0");
				expect(StructKeyExists(response.result, "tools")).toBeTrue();
				expect(arrayLen(response.result.tools)).toBeGT(0);
			});

			it("lists prompts", () => {
				var response = mcp.handleRequest({ jsonrpc = "2.0", id = 2, method = "prompts/list", params = {} }, "test-session");
				expect(StructKeyExists(response.result, "prompts")).toBeTrue();
			});

			it("rejects a request missing jsonrpc", () => {
				var response = mcp.handleRequest({ method = "tools/list", id = 3 }, "test-session");
				expect(response.error.code).toBe(-32600);
			});

			it("rejects an unknown method", () => {
				var response = mcp.handleRequest({ jsonrpc = "2.0", id = 4, method = "bogus/method", params = {} }, "test-session");
				expect(response.error.code).toBe(-32601);
			});

		});

	}

}
