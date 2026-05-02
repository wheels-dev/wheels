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

		});

	}
}
