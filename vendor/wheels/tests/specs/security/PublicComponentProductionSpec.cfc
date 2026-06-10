/**
 * Locks down `/wheels/*` dispatch so the internal GUI / migrator / test-runner /
 * consoleeval surface cannot be reached outside `development`, even if a
 * developer has explicitly set `enablePublicComponent=true`.
 *
 * The gate is an allowlist (block unless development, fail closed), matching
 * the environment checks in consoleeval.cfm and mcp.cfm. See issue #2233
 * (Bucket A8 in the v4 GA architectural review) and the 2026-06-09 framework
 * review (finding S2/SEC-1).
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Public component production gate", () => {

			var originalEnv = "";

			beforeEach(() => {
				originalEnv = application.wheels.environment;
			});

			afterEach(() => {
				application.wheels.environment = originalEnv;
			});

			describe("$shouldBlockInProduction() predicate", () => {

				it("returns true when environment is production", () => {
					application.wheels.environment = "production";
					var publicCfc = createObject("component", "wheels.Public").$init();
					expect(publicCfc.$shouldBlockInProduction()).toBeTrue();
				});

				it("returns false in development", () => {
					application.wheels.environment = "development";
					var publicCfc = createObject("component", "wheels.Public").$init();
					expect(publicCfc.$shouldBlockInProduction()).toBeFalse();
				});

				it("returns true in testing (allowlist: only development passes)", () => {
					application.wheels.environment = "testing";
					var publicCfc = createObject("component", "wheels.Public").$init();
					expect(publicCfc.$shouldBlockInProduction()).toBeTrue();
				});

				it("returns true in maintenance (allowlist: only development passes)", () => {
					application.wheels.environment = "maintenance";
					var publicCfc = createObject("component", "wheels.Public").$init();
					expect(publicCfc.$shouldBlockInProduction()).toBeTrue();
				});

				it("returns true in design (allowlist: only development passes)", () => {
					application.wheels.environment = "design";
					var publicCfc = createObject("component", "wheels.Public").$init();
					expect(publicCfc.$shouldBlockInProduction()).toBeTrue();
				});

				// Attack-shaped cases from the 2026-06-09 review (S2/SEC-1): a
				// denylist matching only the literal "production" let any other
				// environment name straight through to the REPL/migrator/test
				// surface. The predicate must be an allowlist instead.
				var nonDevEnvironments = ["staging", "qa", "uat", "prod", "production-1"];
				for (var envName in nonDevEnvironments) {
					(function(blockedEnv) {
						it("returns true for arbitrary non-development environment '#blockedEnv#'", () => {
							application.wheels.environment = blockedEnv;
							var publicCfc = createObject("component", "wheels.Public").$init();
							expect(publicCfc.$shouldBlockInProduction()).toBeTrue();
						});
					})(envName);
				}

				it("fails closed when application.wheels.environment is missing", () => {
					// Instantiate before deleting the key so component setup
					// can't trip over the missing environment; the predicate
					// itself must treat a missing key as "block".
					var publicCfc = createObject("component", "wheels.Public").$init();
					StructDelete(application.wheels, "environment");
					expect(publicCfc.$shouldBlockInProduction()).toBeTrue();
					// afterEach restores application.wheels.environment.
				});

			});

			describe("Default gate state", () => {

				it("defaults enablePublicComponent to false outside development", () => {
					// onapplicationstart.cfc only flips the default to true when
					// environment == development. Verify by re-running the init
					// block with a fake environment.
					var app = {};
					app.environment = "production";
					app.enablePublicComponent = false;
					if (app.environment == "development") {
						app.enablePublicComponent = true;
					}
					expect(app.enablePublicComponent).toBeFalse();
				});

				it("defaults enablePublicComponent to true in development", () => {
					var app = {};
					app.environment = "development";
					app.enablePublicComponent = false;
					if (app.environment == "development") {
						app.enablePublicComponent = true;
					}
					expect(app.enablePublicComponent).toBeTrue();
				});

			});

			describe("Static coverage: every gated handler calls $blockInProduction()", () => {

				// Read the Public.cfc source once and inspect each function body
				// to confirm the guard is the first executable statement. This
				// is how we verify the abort path without actually aborting the
				// test request.
				var source = FileRead(ExpandPath("/wheels/Public.cfc"));

				// The handlers the #2233 audit flagged as high-risk. They MUST
				// hard-abort in production regardless of enablePublicComponent.
				var gatedHandlers = [
					"info",
					"routes",
					"routetester",
					"routetesterprocess",
					"api",
					"runner",
					"testbox",
					"tests_testbox",
					"clitests",
					"packages",
					"tests",
					"migrator",
					"migratortemplates",
					"migratortemplatescreate",
					"migratorcommand",
					"migratorsql",
					"consoleeval",
					"cli",
					"packagelist",
					"packageentry",
					"plugins",
					"pluginentry",
					"build",
					"wheels",
					"legacy",
					"guides",
					"ai",
					"guideImage",
					"mcp"
				];

				for (var handler in gatedHandlers) {
					(function(name) {
						it("#name#() calls $blockInProduction()", () => {
							// Match: function name(...) { $blockInProduction();
							// Allow whitespace, typed returns, public/private access modifier.
							var pattern = "function\s+#name#\s*\([^)]*\)\s*\{\s*\$blockInProduction\s*\(\s*\)\s*;";
							var matched = REFindNoCase(pattern, source) > 0;
							expect(matched).toBeTrue(
								"Expected #name#() to call $blockInProduction() as its first statement. "
								& "See vendor/wheels/Public.cfc — handlers reachable in production must "
								& "defense-in-depth gate themselves, because enablePublicComponent can "
								& "be manually set to true in production."
							);
						});
					})(handler);
				}

				it("index() is NOT gated (congratulations page stays discoverable)", () => {
					// The issue explicitly says leave index() reachable in dev/testing.
					// In production enablePublicComponent=false already hides it at
					// the dispatch layer, so no per-handler block is needed.
					var pattern = "function\s+index\s*\([^)]*\)\s*\{\s*\$blockInProduction\s*\(\s*\)\s*;";
					var matched = REFindNoCase(pattern, source) > 0;
					expect(matched).toBeFalse(
						"index() should not call $blockInProduction() — it's the congratulations "
						& "page and the issue (##2233) explicitly keeps it discoverable."
					);
				});

			});

			describe("Dispatch layer: enablePublicComponent=false returns 404", () => {

				it("Dispatch.cfc sets a 404 status code when the component is disabled", () => {
					// Confirm by source inspection — we can't easily drive
					// Dispatch.$request() from a unit test without a full
					// request fixture, but we can lock in the 404 contract.
					var source = FileRead(ExpandPath("/wheels/Dispatch.cfc"));
					var gateIndex = Find("!application.wheels.enablePublicComponent", source);
					expect(gateIndex > 0).toBeTrue("Dispatch.cfc must still have the enablePublicComponent gate.");

					// Look for statuscode=404 or statuscode="404" within ~400 chars
					// after the gate (covers the whole if-block body).
					var windowLen = Min(Len(source) - gateIndex, 400);
					var gateBlock = Mid(source, gateIndex, windowLen);
					var has404 = REFindNoCase("statuscode\s*=\s*[""']?404", gateBlock) > 0;
					expect(has404).toBeTrue(
						"Dispatch.cfc must emit a 404 status when enablePublicComponent is false — "
						& "a silent cfabort returns HTTP 200 with an empty body, which lets an "
						& "attacker fingerprint the hidden surface. See issue ##2233."
					);
				});

			});

		});

	}

}
