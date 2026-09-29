/**
 * On a platform RustCFML publishes no build for (an Intel Mac), the CLI says
 * so plainly AND exits non-zero (#3815). Printing the message and returning ""
 * would report success; the refusal is rethrown so it reaches $?.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		directoryCreate(tempRoot & "/vendor/wheels", true, true);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	private any function unsupportedModule() {
		createObject("java", "java.io.File").init(expandPath("/testbox/system/stubs")).mkdirs();
		var m = new cli.lucli.Module(cwd = variables.tempRoot);
		prepareMock(m);
		m.$(method = "$rustcfmlEngine", returns = new cli.lucli.tests.UnsupportedRustEngineStub());
		return m;
	}

	function run() {

		describe("RustCFML on an unsupported platform (##3815)", () => {

			it("wheels engines rustcfml install exits non-zero", () => {
				expect(() => unsupportedModule().engines(arg1 = "rustcfml", arg2 = "install"))
					.toThrow(type = "Wheels.RustCFML.UnsupportedPlatform");
			});

			it("wheels engines rustcfml start exits non-zero", () => {
				expect(() => unsupportedModule().engines(arg1 = "rustcfml", arg2 = "start"))
					.toThrow(type = "Wheels.RustCFML.UnsupportedPlatform");
			});

		});

	}

}
