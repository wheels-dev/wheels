/**
 * Regression coverage for onboarding findings F1, F2 (2026-05-01 fresh-VM
 * tutorial run) — `wheels start` was emitting LuCLI's "Server 'foo' already
 * exists" prompt with `lucli ...` recovery hints the user couldn't follow
 * (`lucli` isn't on PATH after `brew install wheels`). Module.cfc's start()
 * now mediates via this service: detect stale registrations, classify them
 * as ours-vs-theirs, wipe-or-warn, then delegate to LuCLI cleanly.
 *
 * Tests use a temp `lucliHome` so they're hermetic — no env vars, no JVM
 * system properties, no risk of touching the user's real `~/.wheels/`.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.tempHome = getTempDirectory() & "wheels-registry-#createUUID()#";
		directoryCreate(variables.tempHome & "/servers", true);
		variables.registry = new cli.lucli.services.ServerRegistry(lucliHome = variables.tempHome);

		// A canonical project path for "ours" comparisons — needs to be a real
		// directory so File.getCanonicalPath() resolves consistently across runs.
		variables.tempProject = getTempDirectory() & "wheels-registry-project-#createUUID()#";
		directoryCreate(variables.tempProject, true);
		variables.canonicalProject = createObject("java", "java.io.File")
			.init(variables.tempProject).getCanonicalPath();
	}

	function afterAll() {
		if (directoryExists(variables.tempHome)) directoryDelete(variables.tempHome, true);
		if (directoryExists(variables.tempProject)) directoryDelete(variables.tempProject, true);
	}

	/**
	 * A registry (same temp lucliHome) whose $processCommandLine returns
	 * `cmdLine` for any pid; "" means "the OS does not expose it".
	 */
	private any function selfCommandLineRegistry(required string cmdLine) {
		var reg = new cli.lucli.services.ServerRegistry(lucliHome = variables.tempHome);
		prepareMock(reg);
		reg.$("$processCommandLine", arguments.cmdLine);
		return reg;
	}

	/**
	 * A separate OS process listening on an ephemeral localhost port.
	 * Returns {process, pid, port}; callers destroy() the process.
	 */
	private struct function startForeignListener() {
		var pb = createObject("java", "java.lang.ProcessBuilder").init([
			"python3", "-c",
			"import socket,time" & chr(10)
				& "s=socket.socket()" & chr(10)
				& "s.bind(('127.0.0.1',0))" & chr(10)
				& "s.listen(1)" & chr(10)
				& "print(s.getsockname()[1],flush=True)" & chr(10)
				& "time.sleep(60)"
		]);
		var proc = pb.start();
		var reader = createObject("java", "java.io.BufferedReader").init(
			createObject("java", "java.io.InputStreamReader").init(proc.getInputStream())
		);
		var line = reader.readLine();
		return {process: proc, pid: proc.pid(), port: val(line)};
	}

	private string function makeRegistration(
		required string name,
		string projectPath = "",
		string pidContent = ""
	) {
		var dir = variables.tempHome & "/servers/" & arguments.name;
		directoryCreate(dir, true);
		if (len(arguments.projectPath)) fileWrite(dir & "/.project-path", arguments.projectPath);
		if (len(arguments.pidContent)) fileWrite(dir & "/server.pid", arguments.pidContent);
		return dir;
	}

	private void function dropRegistration(required string name) {
		var dir = variables.tempHome & "/servers/" & arguments.name;
		if (directoryExists(dir)) directoryDelete(dir, true);
	}

	/**
	 * A fresh project directory (canonical path) whose basename is NOT the
	 * lucee.json name — the worktree / renamed-clone shape from #3679.
	 * Pass `luceeJson = ""` to create the directory without a lucee.json.
	 */
	private string function makeProject(string luceeJson = "") {
		var dir = getTempDirectory() & "wheels-registry-dir-#createUUID()#";
		directoryCreate(dir, true);
		if (len(arguments.luceeJson)) fileWrite(dir & "/lucee.json", arguments.luceeJson);
		return createObject("java", "java.io.File").init(dir).getCanonicalPath();
	}

	private void function dropProject(required string dir) {
		if (directoryExists(arguments.dir)) directoryDelete(arguments.dir, true);
	}

	function run() {

		describe("ServerRegistry.serverNameFor", () => {

			it("returns the basename of a forward-slash path", () => {
				expect(variables.registry.serverNameFor("/Users/peter/projects/blog")).toBe("blog");
			});

			it("returns the basename of a Windows-style path", () => {
				// File.getName() handles platform-native separators; on POSIX a
				// path with backslashes is treated as one filename. Fall through
				// to the listLast branch, which strips both kinds of separators.
				var name = variables.registry.serverNameFor("/projects/blog");
				expect(name).toBe("blog");
			});

			it("returns empty string for empty input", () => {
				expect(variables.registry.serverNameFor("")).toBe("");
			});

			it("strips trailing slash", () => {
				// File.getName() of /tmp/foo/ returns "foo" (canonical form drops it).
				var name = variables.registry.serverNameFor("/tmp/foo/");
				expect(name).toBe("foo");
			});

			it("uses lucee.json's name when it differs from the directory name (##3679)", () => {
				var dir = makeProject('{"name": "wheels-registry-configured", "port": 8097}');
				try {
					expect(variables.registry.serverNameFor(dir)).toBe("wheels-registry-configured");
				} finally {
					dropProject(dir);
				}
			});

			it("falls back to the directory name when lucee.json has no name", () => {
				var dir = makeProject('{"port": 8097}');
				try {
					expect(variables.registry.serverNameFor(dir)).toBe(listLast(dir, "/\"));
				} finally {
					dropProject(dir);
				}
			});

			it("falls back to the directory name when lucee.json's name is blank", () => {
				var dir = makeProject('{"name": "  "}');
				try {
					expect(variables.registry.serverNameFor(dir)).toBe(listLast(dir, "/\"));
				} finally {
					dropProject(dir);
				}
			});

			it("falls back to the directory name when lucee.json is malformed", () => {
				var dir = makeProject("{ not json");
				try {
					expect(variables.registry.serverNameFor(dir)).toBe(listLast(dir, "/\"));
				} finally {
					dropProject(dir);
				}
			});

		});

		describe("ServerRegistry.inspect", () => {

			it("returns exists=false when registration directory is missing", () => {
				var r = variables.registry.inspect("ghost", variables.canonicalProject);
				expect(r.exists).toBeFalse();
				expect(r.alive).toBeFalse();
				expect(r.ours).toBeFalse();
				expect(r.registeredPath).toBe("");
			});

			it("returns exists=false on empty serverName", () => {
				var r = variables.registry.inspect("", variables.canonicalProject);
				expect(r.exists).toBeFalse();
			});

			it("flags exists=true when only the directory is present (no .project-path, no pid)", () => {
				makeRegistration("bare");
				try {
					var r = variables.registry.inspect("bare", variables.canonicalProject);
					expect(r.exists).toBeTrue();
					expect(r.alive).toBeFalse();
					expect(r.ours).toBeFalse();
					expect(r.registeredPath).toBe("");
				} finally {
					dropRegistration("bare");
				}
			});

			it("flags ours=true when .project-path matches the canonical cwd", () => {
				makeRegistration(name = "matching", projectPath = variables.canonicalProject);
				try {
					var r = variables.registry.inspect("matching", variables.canonicalProject);
					expect(r.exists).toBeTrue();
					expect(r.ours).toBeTrue();
					expect(r.registeredPath).toBe(variables.canonicalProject);
				} finally {
					dropRegistration("matching");
				}
			});

			it("flags ours=false when .project-path points to a different project", () => {
				makeRegistration(name = "foreign", projectPath = "/some/other/project");
				try {
					var r = variables.registry.inspect("foreign", variables.canonicalProject);
					expect(r.exists).toBeTrue();
					expect(r.ours).toBeFalse();
					expect(r.registeredPath).toBe("/some/other/project");
				} finally {
					dropRegistration("foreign");
				}
			});

			it("flags alive=false when server.pid points at a non-existent pid", () => {
				// Pid 99999999 is well above the typical max_pid; even on systems
				// that allow large pids, the chance of collision in a transient
				// test run is negligible. The value is intentionally numeric so
				// it gets through the isNumeric() guard.
				makeRegistration(name = "dead", projectPath = variables.canonicalProject, pidContent = "99999999:8080");
				try {
					var r = variables.registry.inspect("dead", variables.canonicalProject);
					expect(r.exists).toBeTrue();
					expect(r.alive).toBeFalse();
				} finally {
					dropRegistration("dead");
				}
			});

			it("flags alive=true when server.pid points at this JVM (a guaranteed-live pid)", () => {
				// Use this JVM's own pid — `kill -0 $(pgrep myself)` is always true.
				var selfPid = createObject("java", "java.lang.ProcessHandle").current().pid();
				makeRegistration(name = "selfpid", projectPath = variables.canonicalProject, pidContent = selfPid & ":8080");
				try {
					var r = variables.registry.inspect("selfpid", variables.canonicalProject);
					expect(r.alive).toBeTrue();
				} finally {
					dropRegistration("selfpid");
				}
			});

			it("ignores garbage in server.pid without throwing", () => {
				makeRegistration(name = "garbage", projectPath = variables.canonicalProject, pidContent = "this-is-not-a-pid");
				try {
					var r = variables.registry.inspect("garbage", variables.canonicalProject);
					expect(r.exists).toBeTrue();
					expect(r.alive).toBeFalse();
				} finally {
					dropRegistration("garbage");
				}
			});

		});

		describe("ServerRegistry.clean", () => {

			it("removes the registration directory", () => {
				var dir = makeRegistration(name = "doomed", projectPath = variables.canonicalProject);
				expect(directoryExists(dir)).toBeTrue();
				variables.registry.clean("doomed");
				expect(directoryExists(dir)).toBeFalse();
			});

			it("is a no-op when the registration is already gone (idempotent)", () => {
				expect(directoryExists(variables.tempHome & "/servers/never-registered")).toBeFalse();
				variables.registry.clean("never-registered");
				expect(directoryExists(variables.tempHome & "/servers/never-registered")).toBeFalse();
			});

			it("is a no-op for an empty serverName (defensive guard)", () => {
				// We don't want clean("") to wipe the whole servers/ dir if a bug
				// upstream produces an empty name — this test locks that in.
				makeRegistration(name = "survivor", projectPath = variables.canonicalProject);
				try {
					variables.registry.clean("");
					expect(directoryExists(variables.tempHome & "/servers/survivor")).toBeTrue();
				} finally {
					dropRegistration("survivor");
				}
			});

		});

		describe("ServerRegistry.ownServerPort", () => {

			// Ownership is proven against the LISTENER on the recorded port
			// (GHSA-x3cm-2j3q-jgg4): these specs bind a real socket in this JVM
			// so the recorded pid (this JVM) really is the process listening.
			// $processCommandLine is stubbed: this JVM is not a registered
			// LuCLI server, so its real command line would never match.

			it("returns the port when the project's own server is registered, alive and listening", () => {
				var selfPid = createObject("java", "java.lang.ProcessHandle").current().pid();
				var listener = createObject("java", "java.net.ServerSocket").init(0);
				var reg = selfCommandLineRegistry("");
				var name = reg.serverNameFor(variables.canonicalProject);
				makeRegistration(name = name, projectPath = variables.canonicalProject, pidContent = selfPid & ":" & listener.getLocalPort());
				try {
					expect(reg.ownServerPort(variables.canonicalProject)).toBe(listener.getLocalPort());
				} finally {
					listener.close();
					dropRegistration(name);
				}
			});

			it("accepts a recorded pid whose command line is this registration's server", () => {
				var selfPid = createObject("java", "java.lang.ProcessHandle").current().pid();
				var listener = createObject("java", "java.net.ServerSocket").init(0);
				var name = variables.registry.serverNameFor(variables.canonicalProject);
				var reg = selfCommandLineRegistry("java -Dcatalina.base=" & variables.tempHome & "/servers/" & name & " org.apache.catalina.startup.Bootstrap start");
				makeRegistration(name = name, projectPath = variables.canonicalProject, pidContent = selfPid & ":" & listener.getLocalPort());
				try {
					expect(reg.ownServerPort(variables.canonicalProject)).toBe(listener.getLocalPort());
				} finally {
					listener.close();
					dropRegistration(name);
				}
			});

			it("refuses a live recorded pid that is some other process (stale, reused pid)", () => {
				var selfPid = createObject("java", "java.lang.ProcessHandle").current().pid();
				var listener = createObject("java", "java.net.ServerSocket").init(0);
				var reg = selfCommandLineRegistry("java -Dcatalina.base=/elsewhere/servers/other-app org.apache.catalina.startup.Bootstrap start");
				var name = reg.serverNameFor(variables.canonicalProject);
				makeRegistration(name = name, projectPath = variables.canonicalProject, pidContent = selfPid & ":" & listener.getLocalPort());
				try {
					var verdict = reg.verifyOwnServer(variables.canonicalProject);
					expect(verdict.port).toBe(0);
					expect(verdict.reason).toBe("pid-not-server");
				} finally {
					listener.close();
					dropRegistration(name);
				}
			});

			it("refuses when a DIFFERENT process is listening on the recorded port", () => {
				// The registry records this JVM (alive) against a port that a
				// separate process holds: the password must not go there.
				var selfPid = createObject("java", "java.lang.ProcessHandle").current().pid();
				var holder = startForeignListener();
				var reg = selfCommandLineRegistry("");
				var name = reg.serverNameFor(variables.canonicalProject);
				makeRegistration(name = name, projectPath = variables.canonicalProject, pidContent = selfPid & ":" & holder.port);
				try {
					var verdict = reg.verifyOwnServer(variables.canonicalProject);
					expect(verdict.port).toBe(0);
					expect(verdict.reason).toBe("listener-mismatch");
					expect(reg.listenerOwnedBy(holder.port, holder.pid)).toBe("yes");
				} finally {
					holder.process.destroy();
					dropRegistration(name);
				}
			});

			it("refuses when nothing is listening on the recorded port", () => {
				var selfPid = createObject("java", "java.lang.ProcessHandle").current().pid();
				var probe = createObject("java", "java.net.ServerSocket").init(0);
				var closedPort = probe.getLocalPort();
				probe.close();
				var reg = selfCommandLineRegistry("");
				var name = reg.serverNameFor(variables.canonicalProject);
				makeRegistration(name = name, projectPath = variables.canonicalProject, pidContent = selfPid & ":" & closedPort);
				try {
					expect(reg.ownServerPort(variables.canonicalProject)).toBe(0);
				} finally {
					dropRegistration(name);
				}
			});

			it("listenerOwnedBy tells this JVM's listener from another pid's", () => {
				var selfPid = createObject("java", "java.lang.ProcessHandle").current().pid();
				var listener = createObject("java", "java.net.ServerSocket").init(0);
				try {
					expect(variables.registry.listenerOwnedBy(listener.getLocalPort(), selfPid)).toBe("yes");
					expect(variables.registry.listenerOwnedBy(listener.getLocalPort(), 1)).toBe("no");
				} finally {
					listener.close();
				}
			});

			it("returns 0 when the registration belongs to a different project", () => {
				var selfPid = createObject("java", "java.lang.ProcessHandle").current().pid();
				var name = variables.registry.serverNameFor(variables.canonicalProject);
				makeRegistration(name = name, projectPath = "/some/other/project", pidContent = selfPid & ":8094");
				try {
					expect(variables.registry.ownServerPort(variables.canonicalProject)).toBe(0);
				} finally {
					dropRegistration(name);
				}
			});

			it("returns 0 when the recorded pid is not alive", () => {
				var name = variables.registry.serverNameFor(variables.canonicalProject);
				makeRegistration(name = name, projectPath = variables.canonicalProject, pidContent = "99999999:8094");
				try {
					expect(variables.registry.ownServerPort(variables.canonicalProject)).toBe(0);
				} finally {
					dropRegistration(name);
				}
			});

			it("returns 0 when server.pid has no port segment", () => {
				var selfPid = createObject("java", "java.lang.ProcessHandle").current().pid();
				var name = variables.registry.serverNameFor(variables.canonicalProject);
				makeRegistration(name = name, projectPath = variables.canonicalProject, pidContent = selfPid);
				try {
					expect(variables.registry.ownServerPort(variables.canonicalProject)).toBe(0);
				} finally {
					dropRegistration(name);
				}
			});

			it("returns 0 when no registration exists", () => {
				expect(variables.registry.ownServerPort(variables.canonicalProject)).toBe(0);
			});

			it("finds the server registered under lucee.json's name when the directory name differs (##3679)", () => {
				// Repro: a worktree at .../wheels-2963f whose lucee.json says
				// "name": "wheels" — LuCLI registers servers/wheels/, not
				// servers/wheels-2963f/.
				var selfPid = createObject("java", "java.lang.ProcessHandle").current().pid();
				var listener = createObject("java", "java.net.ServerSocket").init(0);
				var reg = selfCommandLineRegistry("");
				var dir = makeProject('{"name": "wheels-registry-renamed"}');
				makeRegistration(name = "wheels-registry-renamed", projectPath = dir, pidContent = selfPid & ":" & listener.getLocalPort());
				try {
					expect(reg.ownServerPort(dir)).toBe(listener.getLocalPort());
				} finally {
					listener.close();
					dropRegistration("wheels-registry-renamed");
					dropProject(dir);
				}
			});

			it("finds a registration under any name whose .project-path points at this project", () => {
				// lucee.json's name edited after the server started: the live
				// registration still sits under the old name.
				var selfPid = createObject("java", "java.lang.ProcessHandle").current().pid();
				var listener = createObject("java", "java.net.ServerSocket").init(0);
				var reg = selfCommandLineRegistry("");
				var dir = makeProject('{"name": "wheels-registry-new-name"}');
				makeRegistration(name = "wheels-registry-old-name", projectPath = dir, pidContent = selfPid & ":" & listener.getLocalPort());
				try {
					expect(reg.ownServerPort(dir)).toBe(listener.getLocalPort());
				} finally {
					listener.close();
					dropRegistration("wheels-registry-old-name");
					dropProject(dir);
				}
			});

			it("holds a registration under another name to the same proof (GHSA-x3cm-2j3q-jgg4)", () => {
				// The #3679 fallback must not become a way around the listener
				// check: a registration under the old name that points at this
				// project, with a live pid, is still refused when a different
				// process holds the recorded port.
				var selfPid = createObject("java", "java.lang.ProcessHandle").current().pid();
				var holder = startForeignListener();
				var reg = selfCommandLineRegistry("");
				var dir = makeProject('{"name": "wheels-registry-fresh-name"}');
				makeRegistration(name = "wheels-registry-stale-name", projectPath = dir, pidContent = selfPid & ":" & holder.port);
				try {
					var verdict = reg.verifyOwnServer(dir);
					expect(verdict.port).toBe(0);
					expect(verdict.reason).toBe("listener-mismatch");
				} finally {
					holder.process.destroy();
					dropRegistration("wheels-registry-stale-name");
					dropProject(dir);
				}
			});

			it("still returns 0 when the lucee.json-named registration belongs to another project", () => {
				var selfPid = createObject("java", "java.lang.ProcessHandle").current().pid();
				var dir = makeProject('{"name": "wheels-registry-shared"}');
				makeRegistration(name = "wheels-registry-shared", projectPath = "/some/other/project", pidContent = selfPid & ":8099");
				try {
					expect(variables.registry.ownServerPort(dir)).toBe(0);
				} finally {
					dropRegistration("wheels-registry-shared");
					dropProject(dir);
				}
			});

		});

		describe("ServerRegistry constructed without a lucliHome", () => {

			it("inspect() returns exists=false instead of crashing", () => {
				var orphanRegistry = new cli.lucli.services.ServerRegistry(lucliHome = "");
				var r = orphanRegistry.inspect("anything", variables.canonicalProject);
				expect(r.exists).toBeFalse();
			});

			it("clean() is a no-op instead of crashing", () => {
				var orphanRegistry = new cli.lucli.services.ServerRegistry(lucliHome = "");
				orphanRegistry.clean("anything");  // should not throw
			});

			it("ownServerPort() returns 0 instead of crashing", () => {
				var orphanRegistry = new cli.lucli.services.ServerRegistry(lucliHome = "");
				expect(orphanRegistry.ownServerPort(variables.canonicalProject)).toBe(0);
			});

		});

	}
}
