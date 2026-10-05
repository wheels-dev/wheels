/**
 * Docblocks sit directly above the function they describe.
 *
 * When a function was inserted under another function's docblock, the
 * displaced docblock stopped describing anything. For `setup()` that lost its
 * `hint:`, which is what `wheels <command> --help` prints, so
 * `wheels setup --help` showed the general command list instead.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.mod = new cli.lucli.Module(cwd = getTempDirectory());
	}

	function run() {

		describe("wheels setup --help", () => {

			it("prints the setup command's own help", () => {
				var help = mod.showHelp("setup");
				expect(help).toInclude("wheels setup");
				expect(help).toInclude("write .mcp.json and .opencode.json for AI assistants");
				expect(help).notToInclude("wheels <command> [options]");
			});

		});

		describe("docblock placement in the CLI and framework sources", () => {

			it("has no docblock directly followed by another docblock", () => {
				var offenders = [];
				for (var tree in ["cli/lucli", "vendor/wheels"]) {
					var root = expandPath("/" & tree);
					for (var path in directoryList(root, true, "path", "*.cfc|*.cfm")) {
						var source = fileRead(path);
						var at = reFind("\*/[ \t]*\r?\n[ \t]*/\*\*", source);
						while (at > 0) {
							var lineNumber = listLen(left(source, at), chr(10), true);
							arrayAppend(offenders, replace(path, root, tree) & ":" & lineNumber);
							at = reFind("\*/[ \t]*\r?\n[ \t]*/\*\*", source, at + 2);
						}
					}
				}
				expect(arrayToList(offenders, ", ")).toBe(
					"",
					"a docblock is followed directly by another docblock, so it no longer sits above its function"
				);
			});

		});

	}

}
