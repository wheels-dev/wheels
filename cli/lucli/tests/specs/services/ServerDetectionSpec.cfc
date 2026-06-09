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
 * requireProjectConfig=true so they refuse the common-port fallback too
 * (follow-up to #2879, which gated migrate/seed/reconcile).
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

		describe("write-side command gating — reload + generate admin (##2878 follow-up)", () => {

			// reload() and generate-admin both reach the project's own server
			// — reload to reset app state, generate-admin to introspect the
			// schema before scaffolding files into cwd. Attaching to a sibling
			// app squatting a common port reloads the wrong app / generates
			// admin from the wrong schema (the #2878 failure mode applied to
			// non-migration commands). Both now pass requireProjectConfig=true,
			// so with no project-bound port they refuse the common-port probe
			// and throw Wheels.ServerNotRunning instead of silently attaching.
			//
			// These drive the real command functions (not detectServerPort
			// directly) so the assertion proves the call sites actually opt
			// into the guard. Each test re-strips lucee.json/.env to stay
			// isolated from the lucee.json the detectServerPort suite writes.

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
