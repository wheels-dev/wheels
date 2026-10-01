/**
 * out() passes LuCLI a colour only on an interactive terminal. Under the stdio
 * MCP server the output is captured into the tool result, where ANSI escapes
 * are noise to the client. The test BaseModule records what reaches LuCLI's
 * out(); the escapes themselves are LuCLI's (checked live against the pinned
 * LuCLI for the PR).
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	private struct function lastOut(required any m) {
		var log = arguments.m.$outLog ?: [];
		return arrayLen(log) ? log[arrayLen(log)] : {};
	}

	function run() {

		describe("out() and ANSI colour", () => {

			it("passes no colour or style when output is not a terminal", () => {
				var m = new cli.lucli.Module(cwd = expandPath("/"));
				prepareMock(m);
				m.$("$useColour", false);
				makePublic(m, "out");
				m.out("Validating...", "cyan", "bold");
				var sent = lastOut(m);
				expect(sent.message).toBe("Validating...");
				expect(sent.colour).toBe("");
				expect(sent.style).toBe("");
			});

			it("passes the colour through on a terminal", () => {
				var m = new cli.lucli.Module(cwd = expandPath("/"));
				prepareMock(m);
				m.$("$useColour", true);
				makePublic(m, "out");
				m.out("Validating...", "cyan");
				expect(lastOut(m).colour).toBe("cyan");
			});

			it("decides from the console and NO_COLOR, never throwing", () => {
				var m = new cli.lucli.Module(cwd = expandPath("/"));
				makePublic(m, "$useColour");
				expect(IsBoolean(m.$useColour())).toBeTrue();
				var src = fileRead(expandPath("/cli/lucli/Module.cfc"));
				expect(src).toInclude('env.get("NO_COLOR")');
				expect(src).toInclude("console.isTerminal()");
			});

			it("never colours inside the stdio MCP server process", () => {
				var m = new cli.lucli.Module(cwd = expandPath("/"));
				prepareMock(m);
				m.$("$isMcpServerProcess", true);
				makePublic(m, "$useColour");
				expect(m.$useColour()).toBeFalse();
				// This test server was not started with `mcp`.
				var plain = new cli.lucli.Module(cwd = expandPath("/"));
				makePublic(plain, "$isMcpServerProcess");
				expect(plain.$isMcpServerProcess()).toBeFalse();
			});

		});

	}

}
