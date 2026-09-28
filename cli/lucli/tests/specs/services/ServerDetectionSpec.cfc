/**
 * Tests Module.cfc::detectServerPort() server-identity gating (issue #2878).
 *
 * Without a project-explicit port (lucee.json / .env), the helper used to
 * silently fall back to a hardcoded common-ports list ([8080, 60000, 3000,
 * 8500]). When a sibling app's server was running on one of those ports,
 * `wheels migrate` in a fresh project attached to the wrong instance and
 * ran migrations against the wrong database.
 *
 * The fix adds two parameters to the (still-private) detectServerPort():
 *   - `requireProjectConfig` — write-side guard; refuses the common-port
 *     fallback so write commands can only target a server bound to this
 *     project's own lucee.json/.env port.
 *   - `commonPorts` — injectable fallback list so this spec can simulate
 *     a 'sibling' app squatting a known port deterministically.
 *
 * detectServerPort() stays `private` so it is not auto-exposed on the MCP
 * tools/list or as a CLI subcommand; the spec reaches it via makePublic().
 *
 * The final describe block extends the guard to two more write-side
 * callers — `reload` and `generate admin` — verifying they opt into
 * requireProjectConfig=true so they refuse the common-port fallback too.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));

		// Repro state for #2878: a freshly-created project with no
		// inherited lucee.json or .env port config. scaffoldTempProject
		// copies repo root files when present, so strip them explicitly.
		if (fileExists(tempRoot & "/lucee.json")) fileDelete(tempRoot & "/lucee.json");
		if (fileExists(tempRoot & "/.env")) fileDelete(tempRoot & "/.env");

		directoryCreate(tempRoot & "/vendor/wheels", true, true);

		variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);

		// detectServerPort() is private so it never leaks onto the MCP
		// tools/list or the CLI subcommand surface (see Module.cfc). Expose
		// it on this instance only so the spec can call it directly — same
		// pattern as vendor/wheels mapper UtilsSpec / MatchingSpec.
		prepareMock(variables.mod);
		makePublic(variables.mod, "detectServerPort");
		// generateAdmin() is private (read-via-server + writes to cwd);
		// reload() is already public. Expose generateAdmin so the
		// call-site gating tests below can drive it directly.
		makePublic(variables.mod, "generateAdmin");
		makePublic(variables.mod, "$requireOwnRunningServer");
		makePublic(variables.mod, "$resolveLucliHome");
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	/**
	 * Capture the requireProjectConfig flag runMigration() hands to
	 * $requireRunningServer() for a given migrate action (#3080). The mocked
	 * guard throws so the command aborts before any HTTP probing — the call
	 * log then exposes the exact named arguments the call site passed.
	 */
	private boolean function capturedRequireProjectConfig(required string action) {
		// MockBox writes its generated method stubs to /testbox/system/stubs
		// (webroot-relative) and removes them after mixing in — make sure the
		// directory exists. java.io.File.mkdirs() recurses parents on every
		// engine and is a no-op when the directory already exists (same
		// workaround as vendor/wheels/tests/specs/controller/channelSpec.cfc).
		createObject("java", "java.io.File").init(expandPath("/testbox/system/stubs")).mkdirs();

		var m = new cli.lucli.Module(cwd = variables.tempRoot);
		prepareMock(m);
		m.$(
			method = "$requireRunningServer",
			throwException = true,
			throwType = "TestAbort.ServerGuard",
			throwMessage = "spec capture — abort before HTTP"
		);
		try {
			m.migrate(arg1 = arguments.action);
		} catch (any e) {
			// expected: the mocked guard throws TestAbort.ServerGuard
		}
		var log = m.$callLog()["$requireRunningServer"];
		expect(arrayLen(log)).toBeGTE(1, "migrate #arguments.action# never reached $requireRunningServer()");
		return log[1].requireProjectConfig;
	}

	/**
	 * Which server guard a command reaches: "own" ($requireOwnRunningServer,
	 * the registry ownership check) or "any" ($requireRunningServer, which
	 * trusts an open declared port and, read-side, the common-port fallback).
	 * Both guards are mocked to throw, so nothing is contacted.
	 */
	private string function guardReachedBy(required any invoker) {
		createObject("java", "java.io.File").init(expandPath("/testbox/system/stubs")).mkdirs();
		var m = new cli.lucli.Module(cwd = variables.tempRoot);
		prepareMock(m);
		m.$(method = "$requireOwnRunningServer", throwException = true, throwType = "TestAbort.OwnGuard", throwMessage = "own");
		m.$(method = "$requireRunningServer", throwException = true, throwType = "TestAbort.AnyGuard", throwMessage = "any");
		makePublic(m, "generateAdmin");
		makePublic(m, "browserTest");
		m.$("$browserVerifyPlaywright", true);
		var state = {type: ""};
		try {
			arguments.invoker(m);
		} catch (any e) {
			state.type = e.type;
		}
		if (state.type == "TestAbort.OwnGuard") return "own";
		if (state.type == "TestAbort.AnyGuard") return "any";
		return "neither (#state.type#)";
	}

	/**
	 * Fresh Module whose getService("serverRegistry") returns the supplied
	 * registry, with `$requireOwnRunningServer` exposed for direct calls.
	 * Each test gets its own instance so the getService mock never leaks
	 * into the shared `variables.mod`.
	 */
	private any function moduleWithRegistry(required any registry) {
		createObject("java", "java.io.File").init(expandPath("/testbox/system/stubs")).mkdirs();
		var m = new cli.lucli.Module(cwd = variables.tempRoot);
		prepareMock(m);
		makePublic(m, "$requireOwnRunningServer");
		m.$(method = "getService", returns = arguments.registry);
		return m;
	}

	function run() {

		describe("detectServerPort — server-identity guard (##2878)", () => {

			it("falls back to commonPorts for read-side detection when no project config exists", () => {
				// Open a ServerSocket on an ephemeral port to simulate a
				// 'sibling' app. Read-side commands (info, status) are
				// allowed to attach to it — the fallback is intentional
				// for non-mutating probes.
				var siblingSocket = createObject("java", "java.net.ServerSocket").init(0);
				try {
					var siblingPort = siblingSocket.getLocalPort();
					var detected = mod.detectServerPort(commonPorts = [siblingPort]);
					expect(detected).toBe(siblingPort);
				} finally {
					siblingSocket.close();
				}
			});

			it("skips the commonPorts fallback when the project opts out (WHEELS_SERVER_FALLBACK=false, ##3693)", () => {
				// A real "no server" mode: specs (and users) that must never
				// attach to a sibling app on a common port can say so, instead
				// of hoping a closed PORT=1 stops the scan (it does not).
				var siblingSocket = createObject("java", "java.net.ServerSocket").init(0);
				try {
					var siblingPort = siblingSocket.getLocalPort();
					fileWrite(tempRoot & "/.env", "WHEELS_SERVER_FALLBACK=false" & chr(10));
					expect(mod.detectServerPort(commonPorts = [siblingPort])).toBeFalse();
				} finally {
					siblingSocket.close();
					if (fileExists(tempRoot & "/.env")) fileDelete(tempRoot & "/.env");
				}
			});

			it("reads PORT, not DB_PORT or another *PORT key, from .env", () => {
				// The PORT match was unanchored: DB_PORT=<n> above PORT= won.
				var dbSocket = createObject("java", "java.net.ServerSocket").init(0);
				try {
					fileWrite(
						tempRoot & "/.env",
						"DB_PORT=" & dbSocket.getLocalPort() & chr(10) & "PORT=1" & chr(10) & "WHEELS_SERVER_FALLBACK=false" & chr(10)
					);
					expect(mod.detectServerPort(commonPorts = [])).toBeFalse();
				} finally {
					dbSocket.close();
					if (fileExists(tempRoot & "/.env")) fileDelete(tempRoot & "/.env");
				}
			});

			it("prints a not-verified notice whenever it falls back to a common port (GHSA-x3cm-2j3q-jgg4)", () => {
				var siblingSocket = createObject("java", "java.net.ServerSocket").init(0);
				try {
					var capture = new cli.lucli.tests._fixtures.commands.ModuleOutputCapture(cwd = variables.tempRoot);
					prepareMock(capture);
					makePublic(capture, "detectServerPort");
					var detected = capture.detectServerPort(commonPorts = [siblingSocket.getLocalPort()]);
					expect(detected).toBe(siblingSocket.getLocalPort());
					expect(capture.capturedOutput()).toInclude("not verified as this project's");
					expect(capture.capturedOutput()).toInclude(":#siblingSocket.getLocalPort()#");
				} finally {
					siblingSocket.close();
				}
			});

			it("says so when a read command uses a server on the configured port that is not this project's (GHSA-x3cm-2j3q-jgg4)", () => {
				var siblingSocket = createObject("java", "java.net.ServerSocket").init(0);
				try {
					fileWrite(tempRoot & "/lucee.json", serializeJSON({port: siblingSocket.getLocalPort()}));
					var capture = new cli.lucli.tests._fixtures.commands.ModuleOutputCapture(cwd = variables.tempRoot);
					prepareMock(capture);
					capture.$("$verifyOwnServer", {port: 0, reason: "not-registered", pid: "", hosts: []});
					makePublic(capture, "$requireRunningServer");
					expect(capture.$requireRunningServer()).toBe(siblingSocket.getLocalPort());
					expect(capture.capturedOutput()).toInclude("not verified as this project's");
				} finally {
					siblingSocket.close();
					if (fileExists(tempRoot & "/lucee.json")) fileDelete(tempRoot & "/lucee.json");
				}
			});

			it("prints no notice when the server on the configured port is this project's own", () => {
				var siblingSocket = createObject("java", "java.net.ServerSocket").init(0);
				try {
					fileWrite(tempRoot & "/lucee.json", serializeJSON({port: siblingSocket.getLocalPort()}));
					var capture = new cli.lucli.tests._fixtures.commands.ModuleOutputCapture(cwd = variables.tempRoot);
					prepareMock(capture);
					capture.$("$verifyOwnServer", {port: siblingSocket.getLocalPort(), reason: "", pid: "1", hosts: ["127.0.0.1"]});
					makePublic(capture, "$requireRunningServer");
					expect(capture.$requireRunningServer()).toBe(siblingSocket.getLocalPort());
					expect(capture.capturedOutput()).notToInclude("not verified");
				} finally {
					siblingSocket.close();
					if (fileExists(tempRoot & "/lucee.json")) fileDelete(tempRoot & "/lucee.json");
				}
			});

			it("refuses commonPorts fallback when requireProjectConfig is true", () => {
				// Same simulated sibling on an open port. Write-side
				// commands MUST refuse to attach — the #2878 root cause.
				var siblingSocket = createObject("java", "java.net.ServerSocket").init(0);
				try {
					var siblingPort = siblingSocket.getLocalPort();
					var detected = mod.detectServerPort(
						requireProjectConfig = true,
						commonPorts = [siblingPort]
					);
					expect(detected).toBeFalse();
				} finally {
					siblingSocket.close();
				}
			});

			it("returns the lucee.json port when project config exists and write-side mode is active", () => {
				// Sanity check: write-side mode still resolves a valid
				// project-bound port. We point lucee.json at an open
				// ephemeral socket so isPortOpen() returns true.
				var ourSocket = createObject("java", "java.net.ServerSocket").init(0);
				try {
					var ourPort = ourSocket.getLocalPort();
					fileWrite(tempRoot & "/lucee.json", serializeJSON({port: ourPort}));

					var detected = mod.detectServerPort(requireProjectConfig = true);
					expect(detected).toBe(ourPort);
				} finally {
					if (fileExists(tempRoot & "/lucee.json")) {
						fileDelete(tempRoot & "/lucee.json");
					}
					ourSocket.close();
				}
			});

		});

		describe("read-side migrate gating — info + doctor (##3080)", () => {

			// #2879 documented that read-side commands keep the legacy
			// common-port fallback, but runMigration() gated EVERY migrate
			// subcommand behind requireProjectConfig=true — so `migrate info`
			// and `migrate doctor` refused a server on 8080 (the first
			// documented fallback port). These specs pin the call-site wiring:
			// info/doctor pass requireProjectConfig=false, the schema-mutating
			// actions keep requireProjectConfig=true.

			it("migrate info keeps the read-side common-port fallback (requireProjectConfig=false)", () => {
				expect(capturedRequireProjectConfig("info")).toBeFalse();
			});

			it("migrate doctor keeps the read-side common-port fallback (requireProjectConfig=false)", () => {
				expect(capturedRequireProjectConfig("doctor")).toBeFalse();
			});

			// latest/up/down now require an OWNED server — see the
			// GHSA-x3cm-2j3q-jgg4 describe block below.

			it("migrate info in a no-config project never throws the project-bound refusal", () => {
				// Through the real guard, with every port reported closed so
				// the spec never contacts a real common port (the
				// fallback-port sentinel fails the run if it does). With
				// nothing listening it must throw the READ-SIDE
				// ServerNotRunning message, which names the probed common
				// ports, never the project-bound refusal.
				if (fileExists(tempRoot & "/lucee.json")) fileDelete(tempRoot & "/lucee.json");
				if (fileExists(tempRoot & "/.env")) fileDelete(tempRoot & "/.env");
				var closedMod = new cli.lucli.Module(cwd = variables.tempRoot);
				prepareMock(closedMod);
				closedMod.$("isPortOpen", false);
				var state = {type = "", message = ""};
				try {
					closedMod.migrate(arg1 = "info");
				} catch (any e) {
					state.type = e.type;
					state.message = e.message;
				}
				expect(state.type).toBe("Wheels.ServerNotRunning");
				expect(state.message).toInclude("8080", "expected the read-side message naming the probed ports: #state.message#");
			});

		});

		describe("commands that change state or run code require an OWNED server (GHSA-x3cm-2j3q-jgg4)", () => {

			// "The declared port is open" is not proof the server there is this
			// project's. Everything that mutates state, sends the reload
			// password, or evaluates code must pass the registry ownership check.

			it("migrate latest / up / down", () => {
				for (var action in ["latest", "up", "down"]) {
					var act = action;
					expect(guardReachedBy((m) => m.migrate(arg1 = act))).toBe("own", "migrate #act#");
				}
			});

			it("migrate forget / pretend / rename-system-tables / diff", () => {
				expect(guardReachedBy((m) => m.migrate(arg1 = "forget", arg2 = "20240101000000", yes = true))).toBe("own");
				expect(guardReachedBy((m) => m.migrate(arg1 = "pretend", arg2 = "20240101000000", yes = true))).toBe("own");
				expect(guardReachedBy((m) => m.migrate(arg1 = "rename-system-tables", "dry-run" = true))).toBe("own");
				expect(guardReachedBy((m) => m.migrate(arg1 = "diff", write = true))).toBe("own");
			});

			it("seed and db reset", () => {
				expect(guardReachedBy((m) => m.seed())).toBe("own");
				expect(guardReachedBy((m) => m.db(arg1 = "reset", force = true))).toBe("own");
			});

			it("reload and console (they send the reload password / evaluate code)", () => {
				expect(guardReachedBy((m) => m.reload())).toBe("own");
				expect(guardReachedBy((m) => m.console())).toBe("own");
			});

			it("browser test (runs the app suite, which evaluates code)", () => {
				expect(guardReachedBy((m) => m.browserTest([]))).toBe("own");
			});

			it("jobs work, generate admin and coverage", () => {
				expect(guardReachedBy((m) => m.jobs(arg1 = "work"))).toBe("own");
				expect(guardReachedBy((m) => m.generateAdmin(["Post"]))).toBe("own");
				expect(guardReachedBy((m) => m.coverage())).toBe("own");
			});

			it("read-only migrate info / doctor and db status keep the fallback guard", () => {
				expect(guardReachedBy((m) => m.migrate(arg1 = "info"))).toBe("any");
				expect(guardReachedBy((m) => m.migrate(arg1 = "doctor"))).toBe("any");
				expect(guardReachedBy((m) => m.db(arg1 = "status"))).toBe("any");
			});

		});

		describe("write-side command gating — reload + generate admin", () => {

			// Drive the real callers (not detectServerPort) to prove the call
			// sites opt into requireProjectConfig=true.

			it("reload() refuses the common-port fallback when no project config exists", () => {
				if (fileExists(tempRoot & "/lucee.json")) fileDelete(tempRoot & "/lucee.json");
				if (fileExists(tempRoot & "/.env")) fileDelete(tempRoot & "/.env");
				expect(() => mod.reload()).toThrow(type = "Wheels.ServerNotRunning");
			});

			it("generate admin refuses the common-port fallback when no project config exists", () => {
				if (fileExists(tempRoot & "/lucee.json")) fileDelete(tempRoot & "/lucee.json");
				if (fileExists(tempRoot & "/.env")) fileDelete(tempRoot & "/.env");
				expect(() => mod.generateAdmin(["Post"])).toThrow(type = "Wheels.ServerNotRunning");
			});

		});

		describe("wheels test server ownership — $requireOwnRunningServer", () => {

			// `wheels test` must hit THIS project's server. Attaching to a
			// sibling app squatting a common port (e.g. 8080) yields bogus
			// "spec failed to load" output from a different codebase. These
			// specs drive the ownership guard directly, with getService
			// mocked to a hermetic temp registry, so no live server is needed.

			it("returns the port of the project's own registered server", () => {
				var canonical = createObject("java", "java.io.File")
					.init(variables.tempRoot).getCanonicalPath();
				// Ownership is proven against the listener (GHSA-x3cm-2j3q-jgg4):
				// the registered pid (this JVM) must really hold the port.
				var listener = createObject("java", "java.net.ServerSocket").init(0);
				try {
					var registry = registryWithRegistration(canonical, listener.getLocalPort());
					var m = moduleWithRegistry(registry);
					expect(m.$requireOwnRunningServer(["hint"])).toBe(listener.getLocalPort());
				} finally {
					listener.close();
				}
			});

			it("throws when the registration belongs to a different project", () => {
				var registry = registryWithRegistration("/some/other/project", "8094");
				var m = moduleWithRegistry(registry);
				expect(() => m.$requireOwnRunningServer(["hint"])).toThrow(type = "Wheels.ServerNotRunning");
			});

			it("names the configured port when a server there is not this project's (GHSA-x3cm-2j3q-jgg4)", () => {
				// Something answers on this project's configured port, but the
				// registry says it belongs to another project: refuse, and say which
				// port and why, instead of a generic "no server".
				var squatter = createObject("java", "java.net.ServerSocket").init(0);
				try {
					var port = squatter.getLocalPort();
					fileWrite(tempRoot & "/lucee.json", serializeJSON({port: port}));
					var registry = registryWithRegistration("/some/other/project", port);
					var m = moduleWithRegistry(registry);
					var state = {type: "", message: ""};
					try {
						m.$requireOwnRunningServer(["hint"]);
					} catch (any e) {
						state.type = e.type;
						state.message = e.message;
					}
					expect(state.type).toBe("Wheels.ServerNotOwned");
					expect(state.message).toInclude("port #port#");
					expect(state.message).toInclude("wheels start");
				} finally {
					squatter.close();
					if (fileExists(tempRoot & "/lucee.json")) fileDelete(tempRoot & "/lucee.json");
				}
			});

			it("throws when no registration exists for this project", () => {
				var registry = registryWithRegistration("/some/other/project", "8094");
				// Wipe the registration so ownServerPort() resolves nothing.
				registry.clean(registry.serverNameFor(variables.tempRoot));
				var m = moduleWithRegistry(registry);
				expect(() => m.$requireOwnRunningServer(["hint"])).toThrow(type = "Wheels.ServerNotRunning");
			});

		});

		describe("LuCLI home resolution — $resolveLucliHome (##3733)", () => {

			// The server registry lives under <home>/servers/. LuCLI itself
			// ranks -Dlucli.home above $LUCLI_HOME (the documented way past the
			// brew launcher's LUCLI_HOME export), so the module must too — or
			// `wheels test` looks for the server in a different tree than the
			// one `server run` registered it in.

			it("prefers the lucli.home system property over the LUCLI_HOME env var", () => {
				var sys = createObject("java", "java.lang.System");
				var prior = sys.getProperty("lucli.home");
				var probe = getTempDirectory() & "wheels-lucli-home-" & createUUID();
				sys.setProperty("lucli.home", probe);
				try {
					expect(variables.mod.$resolveLucliHome()).toBe(probe);
				} finally {
					if (isNull(prior)) {
						sys.clearProperty("lucli.home");
					} else {
						sys.setProperty("lucli.home", prior);
					}
				}
			});

		});

	}

	/**
	 * Build a hermetic ServerRegistry whose registration for THIS temp
	 * project's server name records the given `.project-path` and a live pid
	 * (the JVM's own, so inspect() reports alive=true).
	 */
	private any function registryWithRegistration(required string projectPath, required string port) {
		var home = getTempDirectory() & "wheels-own-server-" & createUUID();
		directoryCreate(home & "/servers", true);
		var registry = new cli.lucli.services.ServerRegistry(lucliHome = home);
		// This JVM is not a registered LuCLI server, so its real command line
		// never matches; "" means "not exposed" and leaves the listener check.
		prepareMock(registry);
		registry.$("$processCommandLine", "");
		var serverName = registry.serverNameFor(variables.tempRoot);
		directoryCreate(home & "/servers/" & serverName, true);
		fileWrite(home & "/servers/" & serverName & "/.project-path", arguments.projectPath);
		var selfPid = createObject("java", "java.lang.ProcessHandle").current().pid();
		fileWrite(home & "/servers/" & serverName & "/server.pid", selfPid & ":" & arguments.port);
		return registry;
	}

}
