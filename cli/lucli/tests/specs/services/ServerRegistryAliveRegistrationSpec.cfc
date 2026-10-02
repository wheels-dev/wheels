/**
 * aliveRegistrationFor() finds the project's running Lucee server under ANY
 * registration whose .project-path is this project, not only the name
 * serverNameFor() derives today. After a lucee.json `name` change the server
 * can still run under its old name; the one-engine-per-project check (#3913)
 * must not miss it. Uses an owned temp LuCLI home and owned `sleep`
 * processes; nothing outside the temp dir is read or signalled.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {
		// The specs start `sleep`/`true` processes and read POSIX pids: skipped on Windows.
		var onWindows = findNoCase("win", createObject("java", "java.lang.System").getProperty("os.name")) > 0;

		describe("ServerRegistry.aliveRegistrationFor", () => {
			beforeEach(() => {
				variables.home = getTempDirectory() & "alive-reg-home-" & createUUID();
				variables.project = getTempDirectory() & "alive-reg-proj-" & createUUID();
				directoryCreate(home & "/servers", true, true);
				directoryCreate(project, true, true);
				variables.projectCanonical = createObject("java", "java.io.File").init(project).getCanonicalPath();
				// serverNameFor() falls back to the basename when lucee.json has no name.
				fileWrite(project & "/lucee.json", '{"name":"current-name"}');
				variables.registry = new cli.lucli.services.ServerRegistry(lucliHome = home);
				variables.procs = [];
			});

			afterEach(() => {
				for (var p in procs) {
					try { p.destroyForcibly(); } catch (any e) {}
				}
				if (directoryExists(home)) directoryDelete(home, true);
				if (directoryExists(project)) directoryDelete(project, true);
			});

			it(title = "finds a live registration under an older name whose project-path is this project", skip = onWindows, body = () => {
				$register("old-name", $livePid());
				expect(registry.serverNameFor(project)).toBe("current-name");
				expect(registry.aliveRegistrationFor(project)).toBe("old-name");
			});

			it(title = "skips a stale current-name registration and finds the live alternate", skip = onWindows, body = () => {
				$register("current-name", $deadPid());
				$register("old-name", $livePid());
				expect(registry.aliveRegistrationFor(project)).toBe("old-name");
			});

			it(title = "prefers the current name when it is live", skip = onWindows, body = () => {
				$register("current-name", $livePid());
				$register("old-name", $livePid());
				expect(registry.aliveRegistrationFor(project)).toBe("current-name");
			});

			it(title = "returns empty when only stale registrations point at the project", skip = onWindows, body = () => {
				$register("current-name", $deadPid());
				$register("old-name", $deadPid());
				expect(registry.aliveRegistrationFor(project)).toBe("");
			});

			it(title = "ignores a live registration that belongs to another project", skip = onWindows, body = () => {
				$register("other-app", $livePid(), getTempDirectory() & "some-other-project");
				expect(registry.aliveRegistrationFor(project)).toBe("");
			});
		});
	}

	private void function $register(required string name, required string pid, string projectPath = variables.projectCanonical) {
		var dir = variables.home & "/servers/" & arguments.name;
		directoryCreate(dir, true, true);
		fileWrite(dir & "/.project-path", arguments.projectPath);
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
