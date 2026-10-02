/**
 * #3994: `wheels stop` stops the project's running server whatever
 * registration name it runs under. After a lucee.json `name` change the
 * server can still run under its old name; a bare `server stop` resolves
 * the current name and left the old-name server running.
 *
 * Uses an owned temp LuCLI home and owned `sleep` processes, as
 * ServerRegistryAliveRegistrationSpec does; executeCommand() is mocked, so
 * nothing is actually stopped.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {
		var onWindows = findNoCase("win", createObject("java", "java.lang.System").getProperty("os.name")) > 0;

		describe("wheels stop — the project's live registration", () => {

			beforeEach(() => {
				variables.home = getTempDirectory() & "stop-live-home-" & createUUID();
				variables.project = getTempDirectory() & "stop-live-proj-" & createUUID();
				directoryCreate(home & "/servers", true, true);
				directoryCreate(project & "/config", true, true);
				directoryCreate(project & "/vendor/wheels", true, true);
				fileWrite(project & "/config/settings.cfm", "");
				fileWrite(project & "/lucee.json", '{"name":"current-name"}');
				variables.projectCanonical = createObject("java", "java.io.File").init(project).getCanonicalPath();
				variables.registry = new cli.lucli.tests.RecordingServerRegistry(lucliHome = home);
				variables.procs = [];
			});

			afterEach(() => {
				for (var p in procs) {
					try { p.destroyForcibly(); } catch (any e) {}
				}
				if (directoryExists(home)) directoryDelete(home, true);
				if (directoryExists(project)) directoryDelete(project, true);
			});

			it(title = "stops a live old-name server and deletes its token, not the stale current name's", skip = onWindows, body = () => {
				$register("current-name", $deadPid());
				$register("old-name", $livePid());
				var m = $stopModule(cwdMatch = "current-name");
				m.stop();
				expect($serverCalls(m)).toBe([["stop", "--name=old-name"]]);
				expect(registry.deletedTokens).toBe(["old-name"]);
			});

			it(title = "keeps a bare server stop when the current name is the live one", skip = onWindows, body = () => {
				$register("current-name", $livePid());
				$register("old-name", $deadPid());
				var m = $stopModule(cwdMatch = "old-name");
				m.stop();
				expect($serverCalls(m)).toBe([["stop"]]);
				expect(registry.deletedTokens).toBe(["current-name"]);
			});

			it(title = "falls back to the registered match when nothing is alive", skip = onWindows, body = () => {
				$register("current-name", $deadPid());
				var m = $stopModule(cwdMatch = "current-name");
				m.stop();
				expect($serverCalls(m)).toBe([["stop"]]);
				expect(registry.deletedTokens).toBe(["current-name"]);
			});
		});
	}

	private any function $stopModule(string cwdMatch = "") {
		createObject("java", "java.io.File").init(expandPath("/testbox/system/stubs")).mkdirs();
		var m = new cli.lucli.Module(cwd = variables.project);
		prepareMock(m);
		m.$(method = "executeCommand", returns = "");
		m.$(method = "getService", returns = variables.registry);
		m.$(method = "$rustcfmlEngine", returns = new cli.lucli.tests.RecordingRustEngineStub());
		m.$(method = "$findServerForProject", returns = arguments.cwdMatch);
		m.$(method = "$listRunningWheelsServers", returns = []);
		m.$(method = "$findStrandedLuceeProcesses", returns = []);
		m.$("out");
		return m;
	}

	private array function $serverCalls(required any m) {
		var calls = [];
		var callLog = arguments.m.$callLog();
		if (!structKeyExists(callLog, "executeCommand")) return calls;
		for (var entry in callLog.executeCommand) {
			arrayAppend(calls, structKeyExists(entry, "args") ? entry.args : entry[2]);
		}
		return calls;
	}

	private void function $register(required string name, required string pid) {
		var dir = variables.home & "/servers/" & arguments.name;
		directoryCreate(dir, true, true);
		fileWrite(dir & "/.project-path", variables.projectCanonical);
		fileWrite(dir & "/server.pid", arguments.pid & ":8999");
	}

	private string function $livePid() {
		var p = createObject("java", "java.lang.ProcessBuilder").init(["sleep", "60"]).start();
		arrayAppend(variables.procs, p);
		return toString(p.pid());
	}

	private string function $deadPid() {
		var p = createObject("java", "java.lang.ProcessBuilder").init(["true"]).start();
		p.waitFor();
		return toString(p.pid());
	}
}
