/**
 * #3980: app creation is CLI-only. Over MCP, LuCLI (wheels-dev/LuCLI#17)
 * hands every tools/call a runtime-owned __lucliMcpCall=true argument; a
 * terminal call never has it. generate refuses type=app (and its alias a)
 * when it is present, and no command sees the marker as an argument of its
 * own (ArgSpec would reject it as unknown).
 *
 * The calls below pass the marker the way LuCLI's argCollection does: as a
 * named argument next to the client's own.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		directoryCreate(tempRoot & "/vendor/wheels", true, true);
		createObject("java", "java.io.File").init(expandPath("/testbox/system/stubs")).mkdirs();
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	private any function moduleWithStubbedNew() {
		var m = new cli.lucli.Module(cwd = variables.tempRoot);
		prepareMock(m);
		m.$(method = "new", returns = "");
		m.$("out");
		return m;
	}

	private string function thrownType(required any fn) {
		var state = {type = ""};
		try {
			arguments.fn();
		} catch (any e) {
			state.type = e.type;
		}
		return state.type;
	}

	function run() {

		describe("generate type=app over MCP", () => {

			it("refuses type=app when the call came over MCP, without scaffolding", () => {
				var m = moduleWithStubbedNew();
				expect(thrownType(() => m.generate(type = "app", name = "x", __lucliMcpCall = "true"))).toBe("Wheels.InvalidArguments");
				expect(m.$count("new")).toBe(0);
			});

			it("refuses the single-letter alias a over MCP", () => {
				var m = moduleWithStubbedNew();
				expect(thrownType(() => m.generate(type = "a", name = "x", __lucliMcpCall = "true"))).toBe("Wheels.InvalidArguments");
				expect(m.$count("new")).toBe(0);
			});

			it("still runs `wheels generate app x` from a terminal", () => {
				var m = moduleWithStubbedNew();
				m.generate(arg1 = "app", arg2 = "x");
				expect(m.$count("new")).toBe(1);
			});

			it("still runs `wheels generate --type=app x` from a terminal", () => {
				var m = moduleWithStubbedNew();
				m.generate(type = "app", arg2 = "x");
				expect(m.$count("new")).toBe(1);
			});
		});

		describe("the MCP marker never reaches a command's own arguments", () => {

			it("a strict no-argument command accepts an MCP call", () => {
				var m = new cli.lucli.Module(cwd = variables.tempRoot);
				prepareMock(m);
				m.$("out");
				expect(thrownType(() => m.info(__lucliMcpCall = "true"))).toBe("");
			});

			it("ArgSpec ignores the marker even when handed it directly", () => {
				var parsed = new cli.lucli.services.ArgSpec().option(name = "to", default = "").parse({to: "x", __lucliMcpCall: "true"});
				expect(parsed.to).toBe("x");
				expect(structKeyExists(parsed, "__lucliMcpCall")).toBeFalse();
			});
		});
	}
}
