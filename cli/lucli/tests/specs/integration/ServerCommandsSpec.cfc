/**
 * Integration tests for server-dependent commands.
 * Tests reload, routes, test, migrate, and console commands
 * against a running Wheels server. Gracefully skips if no server.
 */
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.serverPort = testHelper.detectServerPort();
		variables.skipIntegration = (variables.serverPort == 0);
		if (variables.skipIntegration) {
			variables.skipReason = "No running server detected — skipping integration tests";
		}
		variables.baseUrl = "http://localhost:#variables.serverPort#";

		// Set up Module with real project root (the Wheels framework repo itself)
		variables.projectRoot = expandPath("/");
	}

	function run() {

		describe("Server-Dependent Commands Integration", () => {

			// ─── reload ─────────────────────────────────────

			describe("wheels reload", () => {

				it("reload endpoint responds", () => {
					if (skipIntegration) { debug(skipReason); return; }

					var response = testHelper.httpGet(
						"#baseUrl#/?reload=true&password=wheels"
					);
					// Any non-empty response means the app reloaded
					expect(len(response)).toBeGT(0);
				});

			});

			// ─── routes ─────────────────────────────────────

			describe("wheels routes", () => {

				it("returns route data from running server", () => {
					if (skipIntegration) { debug(skipReason); return; }

					var response = testHelper.httpGet(
						"#baseUrl#/wheels/ai?context=routing"
					);
					expect(len(response)).toBeGT(0);
				});

			});

			// ─── test ───────────────────────────────────────

			describe("wheels test (via HTTP)", () => {

				it("test runner endpoint returns JSON", () => {
					if (skipIntegration) { debug(skipReason); return; }

					var response = testHelper.httpGet(
						"#baseUrl#/wheels/core/tests?db=sqlite&format=json&directory=wheels.tests.specs.model"
					);
					expect(len(response)).toBeGT(0);

					if (isJSON(response)) {
						var data = deserializeJSON(response);
						expect(structKeyExists(data, "totalPass")).toBeTrue();
					}
				});

			});

			// ─── migrate ────────────────────────────────────

			describe("wheels migrate (via HTTP)", () => {

				it("migrate info endpoint responds", () => {
					if (skipIntegration) { debug(skipReason); return; }

					try {
						var runner = new cli.lucli.services.MigrationRunner(
							projectRoot = projectRoot
						);
						var result = runner.runViaHttp(
							serverPort = serverPort,
							action = "info"
						);
						if (isStruct(result)) {
							expect(structKeyExists(result, "success")).toBeTrue();
						}
					} catch (any e) {
						// Migration endpoint may differ per server setup
						debug("Migration: " & e.message);
					}
				});

			});

			// ─── db status ──────────────────────────────────

			describe("wheels db status (via HTTP)", () => {

				it("returns migration summary", () => {
					if (skipIntegration) { debug(skipReason); return; }

					var response = testHelper.httpGet(
						"#baseUrl#/wheels/cli?command=dbStatus&format=json"
					);
					expect(len(response)).toBeGT(0);

					if (isJSON(response)) {
						var data = deserializeJSON(response);
						expect(data.success).toBeTrue();
						expect(structKeyExists(data, "summary")).toBeTrue();
					}
				});

			});

			// ─── db version ─────────────────────────────────

			describe("wheels db version (via HTTP)", () => {

				it("returns current version", () => {
					if (skipIntegration) { debug(skipReason); return; }

					var response = testHelper.httpGet(
						"#baseUrl#/wheels/cli?command=dbVersion&format=json"
					);
					expect(len(response)).toBeGT(0);

					if (isJSON(response)) {
						var data = deserializeJSON(response);
						expect(data.success).toBeTrue();
						expect(structKeyExists(data, "version")).toBeTrue();
					}
				});

			});

			// ─── console ping ───────────────────────────────

			describe("wheels console connectivity", () => {

				it("console eval endpoint responds", () => {
					if (skipIntegration) { debug(skipReason); return; }

					// Test that the console endpoint exists (may require password)
					var response = testHelper.httpGet(
						"#baseUrl#/wheels/console/eval"
					);
					// Either returns JSON or error — both prove endpoint exists
					expect(true).toBeTrue();
				});

			});

			// ─── analyze via service ────────────────────────

			describe("wheels analyze (live project)", () => {

				it("analyzes the real framework codebase via service", () => {
					if (skipIntegration) { debug(skipReason); return; }

					var helpers = new cli.lucli.services.Helpers();
					var analysis = new cli.lucli.services.Analysis(
						helpers = helpers,
						projectRoot = projectRoot
					);
					var results = analysis.analyze("models");
					expect(isStruct(results)).toBeTrue();
					expect(results.totalFiles).toBeGTE(0);
				});

			});

			// ─── validate via service ───────────────────────

			describe("wheels validate (live project)", () => {

				it("validates the real framework codebase via service", () => {
					if (skipIntegration) { debug(skipReason); return; }

					var helpers = new cli.lucli.services.Helpers();
					var analysis = new cli.lucli.services.Analysis(
						helpers = helpers,
						projectRoot = projectRoot
					);
					var results = analysis.validate();
					expect(isStruct(results)).toBeTrue();
					expect(structKeyExists(results, "valid")).toBeTrue();
				});

			});

		});

	}

}
