/**
 * Bare `exit` and `quit` end a `wheels console` session like `/exit` (#3892).
 * They used to be evaluated as CFML, failing with "variable [EXIT] doesn't
 * exist", so a piped session that ended with `exit` exited 1.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		directoryCreate(tempRoot & "/vendor/wheels", true, true);
		createObject("java", "java.io.File").init(expandPath("/testbox/system/stubs")).mkdirs();
		variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);
		prepareMock(variables.mod);
		makePublic(variables.mod, "$consoleHandleCommand", "consoleVerdictFor");
		variables.javaSystem = createObject("java", "java.lang.System");
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	private string function verdict(required string line) {
		return variables.mod.consoleVerdictFor(arguments.line, "http://127.0.0.1:1/x", "", "1", variables.javaSystem);
	}

	function run() {
		describe("console exit words", () => {
			it("ends the session on bare exit and quit, in any case", () => {
				for (var word in ["exit", "quit", "EXIT", "Quit"]) {
					expect(verdict(word)).toBe("exit", "`#word#` should end the session");
				}
			});

			it("still ends the session on the slash forms", () => {
				for (var word in ["/exit", "/quit", "/q"]) {
					expect(verdict(word)).toBe("exit");
				}
			});

			it("still evaluates expressions that merely contain the word", () => {
				for (var expr in ["exitCode", "model(""Exit"").count()", "quitting = 1"]) {
					expect(verdict(expr)).toBe("", "`#expr#` must reach evaluation");
				}
			});
		});
	}

}
