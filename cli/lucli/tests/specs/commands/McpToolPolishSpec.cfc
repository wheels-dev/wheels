/**
 * MCP tool polish (#3893, items 1-3; item 4 waits on the frozen test runner):
 * - notes: markers are words, not regex ("." matched every character);
 * - seed: the schema offers the `models` (and `count`) the server's own message
 *   asks for, and an unknown environment is refused instead of ignored;
 * - tools/list: `routes` has a description and `reload`'s is a whole sentence
 *   (LuCLI shows the first line of a function's hint).
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		directoryCreate(tempRoot & "/vendor/wheels", true, true);
		createObject("java", "java.io.File").init(expandPath("/testbox/system/stubs")).mkdirs();
		variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	private struct function $fn(required string name) {
		for (var f in getMetaData(variables.mod).functions) {
			if (f.name == arguments.name) return f;
		}
		return {};
	}

	// What LuCLI's McpCommand shows: firstLine(stripHintPrefix(hint)).
	private string function $hintFirstLine(required string name) {
		var f = $fn(arguments.name);
		var h = structKeyExists(f, "hint") ? f.hint : "";
		h = reReplaceNoCase(h, "^\s*hint\s*:\s*", "");
		return trim(listFirst(h & " ", chr(10) & chr(13)));
	}

	private string function $rawHint(required string name) {
		var f = $fn(arguments.name);
		return structKeyExists(f, "hint") ? replace(replace(f.hint, chr(10), "\n", "all"), chr(13), "\r", "all") : "(none)";
	}

	function run() {
		describe("notes markers", () => {
			it("refuses a marker that is not a word", () => {
				for (var bad in [".", "TO.DO", "a|b", "(x)"]) {
					expect(() => mod.notes(annotations = bad)).toThrow("Wheels.InvalidArguments");
					expect(() => mod.notes(custom = bad)).toThrow("Wheels.InvalidArguments");
				}
			});

			it("still accepts word markers, including hyphens and underscores", () => {
				mod.notes(annotations = "TODO,FIXME", custom = "HACK,NOTE_TO_SELF,X-REVIEW");
				expect(true).toBeTrue();
			});
		});

		describe("seed", () => {
			it("advertises models and count in its MCP schema", () => {
				var props = mod.mcpToolSpecs().seed.properties;
				expect(props).toHaveKey("models");
				expect(props).toHaveKey("count");
			});

			it("refuses an unknown environment before contacting a server", () => {
				var m = new cli.lucli.Module(cwd = variables.tempRoot);
				prepareMock(m);
				m.$(method = "$requireOwnRunningServer", returns = 8999);
				m.$(method = "makeBridgePost", returns = '{"success":true}');
				expect(() => m.seed(environment = "staging-typo")).toThrow("Wheels.InvalidArguments");
				expect(m.$count("makeBridgePost")).toBe(0);
			});

			it("passes models and count to the server", () => {
				var m = new cli.lucli.Module(cwd = variables.tempRoot);
				prepareMock(m);
				m.$(method = "$requireOwnRunningServer", returns = 8999);
				m.$(method = "makeBridgePost", returns = '{"success":true,"totalCreated":3,"totalSkipped":0}');
				m.seed(mode = "generate", models = "Post,Comment", count = 3);
				var sent = m.$callLog().makeBridgePost[1][1];
				expect(sent).toInclude("models=Post%2CComment");
				expect(sent).toInclude("count=3");
			});

			it("accepts a standard environment", () => {
				var m = new cli.lucli.Module(cwd = variables.tempRoot);
				prepareMock(m);
				m.$(method = "$requireOwnRunningServer", returns = 8999);
				m.$(method = "makeBridgePost", returns = '{"success":true,"totalCreated":0,"totalSkipped":0}');
				m.seed(environment = "testing");
				expect(m.$callLog().makeBridgePost[1][1]).toInclude("environment=testing");
			});
		});

		describe("tools/list descriptions", () => {
			it("routes has a description", () => {
				expect($hintFirstLine("routes")).toInclude("route");
			});

			it("reload's description is a whole sentence on its first line", () => {
				var first = $hintFirstLine("reload");
				expect(first).toInclude("Reload", "raw hint: " & $rawHint("reload"));
				expect(right(first, 1)).toBe(".");
				// The old first line stopped mid-sentence: "... The reload password".
				expect(reFindNoCase("password$", first)).toBe(0, "raw hint: " & $rawHint("reload"));
			});
		});
	}

}
