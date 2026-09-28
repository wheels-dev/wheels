/**
 * `wheels stop` forwards --name / --config / --all to LuCLI's `server stop`
 * (issue #3680).
 *
 * stop() used to declare no arguments and always run a bare
 * `executeCommand("server", ["stop"])`, so `wheels stop --name wsapp` in a
 * directory with two registered servers failed with LuCLI's "Use --name
 * <server-name> to disambiguate" while the server kept running.
 *
 * executeCommand() is mocked so the spec reads the exact argv stop() hands
 * LuCLI; the registry/process discovery helpers are mocked so no spec path
 * probes the machine's real servers.
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

	/**
	 * Fresh Module with executeCommand() and the cwd discovery helpers mocked.
	 * `cwdMatch` is what $findServerForProject() reports for the project dir.
	 */
	private any function stopModule(string cwdMatch = "") {
		// MockBox writes its generated stubs under /testbox/system/stubs —
		// same workaround as ServerDetectionSpec.
		createObject("java", "java.io.File").init(expandPath("/testbox/system/stubs")).mkdirs();
		var m = new cli.lucli.Module(cwd = variables.tempRoot);
		prepareMock(m);
		m.$(method = "executeCommand", returns = "");
		m.$(method = "$findServerForProject", returns = arguments.cwdMatch);
		m.$(method = "$listRunningWheelsServers", returns = []);
		m.$(method = "$findStrandedLuceeProcesses", returns = []);
		return m;
	}

	/**
	 * The argv arrays stop() passed to executeCommand("server", ...), one per call.
	 */
	private array function serverCalls(required any m) {
		var calls = [];
		var callLog = arguments.m.$callLog();
		if (!structKeyExists(callLog, "executeCommand")) {
			return calls;
		}
		for (var entry in callLog.executeCommand) {
			var argv = structKeyExists(entry, "args") ? entry.args : entry[2];
			arrayAppend(calls, argv);
		}
		return calls;
	}

	function run() {

		describe("wheels stop — explicit server target (##3680)", () => {

			it("forwards --name=<server> to server stop", () => {
				var m = stopModule();
				m.stop(name = "wsapp");
				var calls = serverCalls(m);
				expect(arrayLen(calls)).toBe(1);
				expect(calls[1]).toBe(["stop", "--name=wsapp"]);
			});

			it("binds the space form --name <server> (bare flag + positional)", () => {
				// LuCLI delivers `--name wsapp` as name=true plus a positional.
				var m = stopModule();
				m.stop(name = "true", arg2 = "wsapp");
				var calls = serverCalls(m);
				expect(arrayLen(calls)).toBe(1);
				expect(calls[1]).toBe(["stop", "--name=wsapp"]);
			});

			it("forwards --config and --all", () => {
				var m = stopModule();
				m.stop(config = "lucee-docker.json");
				var calls = serverCalls(m);
				expect(calls[1]).toBe(["stop", "--config=lucee-docker.json"]);

				var m2 = stopModule();
				m2.stop(all = "true");
				expect(serverCalls(m2)[1]).toBe(["stop", "--all"]);
			});

			it("stops a named server even when no registration matches the cwd", () => {
				// The cwd discovery cannot pick between several servers
				// registered to one directory; an explicit name bypasses it.
				var m = stopModule(cwdMatch = "");
				m.stop(name = "wsapp");
				expect(serverCalls(m)).toBe([["stop", "--name=wsapp"]]);
			});

			it("rejects a bare --name with no value instead of stopping the cwd server", () => {
				var m = stopModule(cwdMatch = "tempapp");
				expect(() => m.stop(name = "true")).toThrow(type = "Wheels.InvalidArguments");
				expect(arrayLen(serverCalls(m))).toBe(0);
			});

			it("rejects stray positionals and unknown flags", () => {
				var m = stopModule(cwdMatch = "tempapp");
				expect(() => m.stop(arg1 = "wsapp")).toThrow(type = "Wheels.InvalidArguments");
				expect(() => m.stop(nme = "wsapp")).toThrow(type = "Wheels.InvalidArguments");
				expect(arrayLen(serverCalls(m))).toBe(0);
			});

		});

		describe("wheels stop — no arguments", () => {

			it("still runs a bare server stop for the project's registered server", () => {
				var m = stopModule(cwdMatch = "tempapp");
				m.stop();
				expect(serverCalls(m)).toBe([["stop"]]);
			});

			it("prints usage for --help without stopping anything", () => {
				var m = stopModule(cwdMatch = "tempapp");
				m.stop(help = "true");
				expect(arrayLen(serverCalls(m))).toBe(0);
			});

			it("does not call server stop when nothing is registered for the cwd", () => {
				var m = stopModule(cwdMatch = "");
				m.stop();
				expect(arrayLen(serverCalls(m))).toBe(0);
			});

		});
	}
}
