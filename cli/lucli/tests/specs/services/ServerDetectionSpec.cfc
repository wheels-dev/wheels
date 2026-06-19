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

			it("migrate latest still refuses the common-port fallback (requireProjectConfig=true)", () => {
				expect(capturedRequireProjectConfig("latest")).toBeTrue();
			});

			it("migrate up still refuses the common-port fallback (requireProjectConfig=true)", () => {
				expect(capturedRequireProjectConfig("up")).toBeTrue();
			});

			it("migrate down still refuses the common-port fallback (requireProjectConfig=true)", () => {
				expect(capturedRequireProjectConfig("down")).toBeTrue();
			});

			it("migrate info in a no-config project never throws the project-bound refusal", () => {
				// End-to-end through the real (unmocked) guard. Environment
				// tolerant: when something IS listening on a common port the
				// command proceeds past the guard (and fails later on HTTP /
				// response parsing — fine); when nothing is listening it must
				// throw the READ-SIDE ServerNotRunning message (which names
				// the probed ports), never the project-bound refusal.
				if (fileExists(tempRoot & "/lucee.json")) fileDelete(tempRoot & "/lucee.json");
				if (fileExists(tempRoot & "/.env")) fileDelete(tempRoot & "/.env");
				var state = {sawProjectBoundRefusal = false};
				try {
					mod.migrate(arg1 = "info");
				} catch (any e) {
					if (e.type == "Wheels.ServerNotRunning" && !findNoCase("8080", e.message)) {
						state.sawProjectBoundRefusal = true;
					}
				}
				expect(state.sawProjectBoundRefusal).toBeFalse();
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

	}

}
