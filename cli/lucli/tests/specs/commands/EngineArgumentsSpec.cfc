/**
 * #3895: RustCFML engine commands. `wheels info` names the engine that is
 * serving, `--port N` (space form) means the same as `--port=N` for both
 * `wheels start` and `wheels engines rustcfml start`, an unknown engine or
 * action exits non-zero, and the first-run engine download is announced.
 *
 * LuCLI hands `--port 8931` over as port="true" plus a positional "8931" one
 * index past the gap the flag left (e.g. arg3 missing, arg4="8931"); the
 * calls below reproduce that shape.
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

	private any function moduleWith(required any rust) {
		var m = new cli.lucli.Module(cwd = variables.tempRoot);
		prepareMock(m);
		m.$(method = "$rustcfmlEngine", returns = arguments.rust);
		m.$(method = "$luceeServerAlive", returns = false);
		m.$(method = "$findServerForProject", returns = "");
		m.$(method = "executeCommand", returns = "");
		m.$("out");
		return m;
	}

	private string function printed(required any m) {
		var lines = [];
		for (var call in arguments.m.$callLog().out) {
			arrayAppend(lines, call[1]);
		}
		return arrayToList(lines, chr(10));
	}

	function run() {

		describe("ArgSpec.bindSpaceFormValue", () => {

			it("binds the positional after the flag's gap to a bare option", () => {
				var coll = new cli.lucli.services.ArgSpec().bindSpaceFormValue({arg1: "rustcfml", arg2: "start", port: "true", arg4: "8931"}, "port");
				expect(coll.port).toBe("8931");
				expect(structKeyExists(coll, "arg4")).toBeFalse();
				expect(coll.arg1).toBe("rustcfml");
				expect(coll.arg2).toBe("start");
			});

			it("leaves an option that already has a value alone", () => {
				var coll = new cli.lucli.services.ArgSpec().bindSpaceFormValue({arg1: "rustcfml", arg2: "start", port: "8931"}, "port");
				expect(coll.port).toBe("8931");
				expect(coll.arg2).toBe("start");
			});

			it("skips flags that sit right before another flag", () => {
				// start --force --port 8931 → force="true", port="true", arg3 = "8931"
				var coll = new cli.lucli.services.ArgSpec().bindSpaceFormValue({force: "true", port: "true", arg3: "8931"}, "port");
				expect(coll.port).toBe("8931");
				expect(coll.force).toBe("true");
				expect(structKeyExists(coll, "arg3")).toBeFalse();
			});

			it("does nothing when the positional cannot be tied to the option", () => {
				// --force rustcfml --port 8931: two gaps, each followed by a positional.
				var coll = new cli.lucli.services.ArgSpec().bindSpaceFormValue({force: "true", arg2: "rustcfml", port: "true", arg4: "8931"}, "port");
				expect(coll.port).toBe("true");
				expect(coll.arg4).toBe("8931");
			});
		});

		describe("engine arguments and errors", () => {

			it("engines rustcfml start --port 8931 starts on 8931", () => {
				var rust = new cli.lucli.tests.RecordingRustEngineStub();
				var m = moduleWith(rust);
				m.engines(arg1 = "rustcfml", arg2 = "start", port = "true", arg4 = "8931");
				expect(rust.calls.start).toBe(1);
				expect(rust.lastPort).toBe(8931);
			});

			it("start --engine=rustcfml --port 8931 starts on 8931", () => {
				var rust = new cli.lucli.tests.RecordingRustEngineStub();
				var m = moduleWith(rust);
				m.start(engine = "rustcfml", port = "true", arg3 = "8931");
				expect(rust.calls.start).toBe(1);
				expect(rust.lastPort).toBe(8931);
			});

			it("start --engine=bogus refuses instead of booting Lucee", () => {
				var rust = new cli.lucli.tests.RecordingRustEngineStub();
				var m = moduleWith(rust);
				expect(() => m.start(arg1 = "--engine=bogus")).toThrow("Wheels.InvalidArguments");
				expect(m.$count("executeCommand")).toBe(0);
				expect(rust.calls.start).toBe(0);
			});

			it("engines foo exits non-zero", () => {
				var m = moduleWith(new cli.lucli.tests.RecordingRustEngineStub());
				expect(() => m.engines(arg1 = "foo")).toThrow("Wheels.InvalidArguments");
			});

			it("engines rustcfml bogus exits non-zero", () => {
				var m = moduleWith(new cli.lucli.tests.RecordingRustEngineStub());
				expect(() => m.engines(arg1 = "rustcfml", arg2 = "bogus")).toThrow("Wheels.InvalidArguments");
			});

			it("a bare `wheels engines` still prints usage", () => {
				var m = moduleWith(new cli.lucli.tests.RecordingRustEngineStub());
				m.engines();
				expect(printed(m)).toInclude("Usage: wheels engines rustcfml");
			});
		});

		describe("engine reporting", () => {

			it("wheels info names RustCFML while it serves the project", () => {
				var m = moduleWith(new cli.lucli.tests.RecordingRustEngineStub(running = true));
				m.info();
				var text = printed(m);
				expect(text).toInclude("Engine:   RustCFML");
				expect(text).notToInclude("Lucee (LuCLI module)");
			});

			it("wheels info names Lucee otherwise", () => {
				var m = moduleWith(new cli.lucli.tests.RecordingRustEngineStub());
				m.info();
				expect(printed(m)).toInclude("Engine:   Lucee");
			});

			it("announces the first-run RustCFML download", () => {
				var rust = new cli.lucli.tests.RecordingRustEngineStub(installed = false);
				var m = moduleWith(rust);
				m.start(arg1 = "--engine=rustcfml", arg2 = "--port=8931");
				expect(printed(m)).toInclude("Downloading RustCFML");
				expect(rust.calls.install).toBe(1);
			});

			it("says nothing about a download when RustCFML is already installed", () => {
				var rust = new cli.lucli.tests.RecordingRustEngineStub();
				var m = moduleWith(rust);
				m.engines(arg1 = "rustcfml", arg2 = "start", port = "8931");
				expect(printed(m)).notToInclude("Downloading RustCFML");
				expect(rust.calls.install).toBe(0);
			});
		});
	}
}
