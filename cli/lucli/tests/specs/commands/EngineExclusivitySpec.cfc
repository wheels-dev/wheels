/**
 * One dev-server engine per project (#3913). `wheels start --engine=rustcfml`
 * and `wheels start` both started for the same project with no warning, the
 * CLI's port detection then picked one of them, and `wheels stop` stopped only
 * RustCFML and left Lucee up. start (and `engines rustcfml start`) now refuse
 * while the other engine runs for the project; stop stops both.
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

	private any function moduleWith(required any rust, boolean luceeAlive = false, string luceeMatch = "") {
		var m = new cli.lucli.Module(cwd = variables.tempRoot);
		prepareMock(m);
		m.$(method = "$rustcfmlEngine", returns = arguments.rust);
		m.$(method = "$luceeServerAlive", returns = arguments.luceeAlive);
		m.$(method = "$findServerForProject", returns = arguments.luceeMatch);
		m.$(method = "executeCommand", returns = "");
		return m;
	}

	function run() {
		describe("one dev-server engine per project", () => {

			it("start --engine=rustcfml refuses while a Lucee server runs for the project", () => {
				var rust = new cli.lucli.tests.RecordingRustEngineStub();
				var m = moduleWith(rust = rust, luceeAlive = true);
				expect(() => m.start(arg1 = "--engine=rustcfml", arg2 = "--port=8931")).toThrow("Wheels.EngineConflict");
				expect(rust.calls.start).toBe(0);
			});

			it("engines rustcfml start refuses while a Lucee server runs for the project", () => {
				var rust = new cli.lucli.tests.RecordingRustEngineStub();
				var m = moduleWith(rust = rust, luceeAlive = true);
				expect(() => m.engines(arg1 = "rustcfml", arg2 = "start")).toThrow("Wheels.EngineConflict");
				expect(rust.calls.start).toBe(0);
			});

			it("start (Lucee) refuses while RustCFML runs for the project", () => {
				var rust = new cli.lucli.tests.RecordingRustEngineStub(running = true);
				var m = moduleWith(rust = rust);
				expect(() => m.start(arg1 = "--port=8934")).toThrow("Wheels.EngineConflict");
				expect(m.$count("executeCommand")).toBe(0);
			});

			it("start --engine=rustcfml still starts when nothing else runs", () => {
				var rust = new cli.lucli.tests.RecordingRustEngineStub();
				var m = moduleWith(rust = rust);
				m.start(arg1 = "--engine=rustcfml", arg2 = "--port=8931");
				expect(rust.calls.start).toBe(1);
			});

			it("stop stops RustCFML and then the project's Lucee server too", () => {
				var rust = new cli.lucli.tests.RecordingRustEngineStub(running = true);
				var m = moduleWith(rust = rust, luceeMatch = "wheels-exclusivity-spec");
				m.stop();
				expect(rust.calls.stop).toBe(1);
				expect(m.$count("executeCommand")).toBe(1);
			});

			it("stop with only RustCFML running stops it and reports nothing else", () => {
				var rust = new cli.lucli.tests.RecordingRustEngineStub(running = true);
				var m = moduleWith(rust = rust);
				m.stop();
				expect(rust.calls.stop).toBe(1);
				expect(m.$count("executeCommand")).toBe(0);
			});
		});
	}

}
