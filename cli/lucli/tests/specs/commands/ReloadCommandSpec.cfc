/**
 * `wheels reload` — output hints, response honesty, and exit-code contract.
 *
 * Source-scan blocks assert output wiring that is impractical to capture from
 * a spec (see finding #8 in
 * docs/superpowers/plans/2026-04-29-fresh-vm-onboarding-findings.md).
 *
 * Contract (verified live on Lucee 7, see #3110): an authorized
 * `?reload=true&password=...` calls applicationStop(), so the next request
 * re-fires onApplicationStart in full — config/services.cfm and the
 * PackageLoader re-run. The earlier "does NOT re-fire" note was wrong; it
 * stemmed from reloads whose password never resolved (a missing/wrong
 * password silently skips the restart, see #3059 / #3062).
 *
 * The #3059 blocks cover reporting honesty: reload() used to print
 * "Application reloaded successfully." whenever the HTTP exchange completed,
 * never inspecting the status code. The framework's reload gate restarts the
 * app and then `location()`-redirects (public/Application.cfc ::
 * $handleRestartAppRequest), so a SUCCESSFUL reload is always a 302; a wrong
 * password falls through to normal page serving (200/404), and the #3053
 * Adobe regression 500s — both were reported as success.
 *
 * Failure-path integration tests drive the real reload() against a raw-socket
 * HTTP stub (cli.lucli.tests.StubHttpServer) on an ephemeral port (lucee.json
 * points the temp project at it), per the issue's "stub server returning 500"
 * acceptance criterion.
 * Module instantiation mirrors MigrationExitCodeSpec/ServerDetectionSpec.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));

		// Create vendor/wheels stub so the module treats this as a Wheels app.
		directoryCreate(tempRoot & "/vendor/wheels", true, true);

		// No inherited port config: each integration test writes its own
		// lucee.json pointing at the stub server's ephemeral port.
		if (fileExists(tempRoot & "/lucee.json")) fileDelete(tempRoot & "/lucee.json");
		if (fileExists(tempRoot & "/.env")) fileDelete(tempRoot & "/.env");

		variables.mod = new cli.lucli.Module(cwd = variables.tempRoot);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	/**
	 * Boot a fixed-status HTTP stub on an ephemeral port and point the temp
	 * project's lucee.json at it so detectServerPort() resolves it as the
	 * project's dev server. Callers stop it via stopStubServer() in `finally`.
	 */
	private any function startStubServer(required numeric statusCode) {
		var stubServer = new cli.lucli.tests.StubHttpServer(arguments.statusCode);
		fileWrite(tempRoot & "/lucee.json", serializeJSON({port: stubServer.getPort()}));
		return stubServer;
	}

	private void function stopStubServer(required any stubServer) {
		arguments.stubServer.stop();
		if (fileExists(tempRoot & "/lucee.json")) fileDelete(tempRoot & "/lucee.json");
	}

	function run() {

		describe("wheels reload — output hints", () => {

			it("emits a note that an authorized reload re-fires onApplicationStart", () => {
				var moduleSource = fileRead(expandPath("/cli/lucli/Module.cfc"));
				expect(moduleSource).toInclude("re-fires onApplicationStart");
				// The old, false claim must be gone.
				expect(moduleSource).notToInclude("onApplicationStart does NOT re-fire");
			});

			it("honors an explicit --password override before falling back to auto-detect", () => {
				// reload() parses --password via parseConsoleArgs and only
				// auto-detects when no override is supplied (parity with
				// `wheels console`). Source-scanned for the same reason as above:
				// reload() makes a live HTTP call, so we assert the wiring rather
				// than exercise it. Window the reload() body and confirm the
				// override-wins-then-fallback shape.
				var moduleSource = fileRead(expandPath("/cli/lucli/Module.cfc"));
				var startIdx = reFindNoCase("(?m)^[ \t]*public\s+string\s+function\s+reload\s*\(", moduleSource);
				expect(startIdx).toBeGT(0);
				var body = mid(moduleSource, startIdx, 1600);
				expect(body).toInclude("parseConsoleArgs(structuredArgs(arguments))");
				expect(body).toInclude("detectReloadPassword()");
				expect(reFindNoCase("len\(\s*reloadOpts\.password\s*\)\s*\?", body)).toBeGT(0);
			});

		});

		describe("$evaluateReloadResponse — 302-vs-200 reload contract (##3059)", () => {

			it("treats the reload redirect (302) as success", () => {
				var verdict = mod.$evaluateReloadResponse(302);
				expect(verdict.success).toBeTrue();
			});

			it("treats a normal page render (200) as NOT reloaded and points at the password", () => {
				// Wrong reload password: the warm-path gate falls through and
				// the framework serves the page normally — no restart happened.
				var verdict = mod.$evaluateReloadResponse(200);
				expect(verdict.success).toBeFalse();
				expect(verdict.message).toInclude("200");
				expect(verdict.message).toInclude("NOT reloaded");
				expect(lCase(verdict.message)).toInclude("password");
			});

			it("treats a 404 page render as NOT reloaded", () => {
				// Same fall-through as 200 when the app has no root route.
				var verdict = mod.$evaluateReloadResponse(404);
				expect(verdict.success).toBeFalse();
				expect(verdict.message).toInclude("404");
			});

			it("treats a 500 as a failed reload and surfaces the status", () => {
				// The #3053 Adobe `local.url` shadowing regression 500s on
				// every ?reload=true — the CLI used to report it as success.
				var verdict = mod.$evaluateReloadResponse(500);
				expect(verdict.success).toBeFalse();
				expect(verdict.message).toInclude("500");
				expect(verdict.message).toInclude("NOT reloaded");
			});

		});

		describe("reload() against a stub dev server — exit-code honesty (##3059)", () => {

			it("throws Wheels.ReloadFailed when the reload endpoint returns 500", () => {
				var stubServer = startStubServer(500);
				try {
					expect(() => mod.reload(password = "testpw"))
						.toThrow(type = "Wheels.ReloadFailed");
				} finally {
					stopStubServer(stubServer);
				}
			});

			it("throws Wheels.ReloadFailed when the server serves the page normally (200, wrong password)", () => {
				var stubServer = startStubServer(200);
				try {
					expect(() => mod.reload(password = "wrongpw"))
						.toThrow(type = "Wheels.ReloadFailed");
				} finally {
					stopStubServer(stubServer);
				}
			});

			it("succeeds quietly on the reload redirect (302)", () => {
				var stubServer = startStubServer(302);
				try {
					expect(mod.reload(password = "testpw")).toBe("");
				} finally {
					stopStubServer(stubServer);
				}
			});

		});

	}

}
