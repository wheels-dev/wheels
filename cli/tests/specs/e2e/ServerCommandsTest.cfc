/**
 * E2E tests for LuCLI server-dependent commands: migrate, test, reload.
 *
 * These commands make HTTP requests to a running Wheels server. The tests
 * are structured in two layers:
 *
 *   1. Configuration detection & URL construction (always runs, no server needed)
 *   2. Live server integration (runs only when a Lucee server is reachable)
 *
 * The configuration tests replicate the private helper logic from Module.cfc
 * (detectServerPort, detectReloadPassword, migration URL building) to verify
 * correctness against scaffolded project fixtures.
 */
component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		var thisDir = getDirectoryFromPath(getCurrentTemplatePath());
		var File = createObject("java", "java.io.File");
		variables.cliRoot = File.init(thisDir & "../../../").getCanonicalPath();
		variables.lucliRoot = variables.cliRoot & "/lucli";
		variables.modulePath = variables.lucliRoot & "/Module.cfc";

		// Read Module.cfc source for URL pattern verification
		variables.moduleSource = fileRead(variables.modulePath);

		// Create a temp project directory for config detection tests
		variables.testDir = getTempDirectory() & "wheels_e2e_server_" & createUUID();
		scaffoldMinimalProject(variables.testDir);

		// Detect a live server for integration tests
		variables.livePort = detectLiveServer();
		variables.liveServerAvailable = (variables.livePort > 0);
	}

	function afterAll() {
		if (directoryExists(variables.testDir)) {
			directoryDelete(variables.testDir, true);
		}
	}

	function run() {

		// ─── Port Detection ─────────────────────────────

		describe("Port Detection (detectServerPort logic)", function() {

			it("reads port from lucee.json when present", function() {
				var luceeConfig = {
					"name": "testapp",
					"port": 9876,
					"configuration": {"mappings": {}}
				};
				fileWrite(variables.testDir & "/lucee.json", serializeJSON(luceeConfig));

				var result = detectPortFromLuceeJson(variables.testDir);
				expect(result).toBe(9876, "Should read port from lucee.json");
			});

			it("reads PORT from .env file", function() {
				fileWrite(variables.testDir & "/.env", "APP_NAME=testapp#chr(10)#PORT=4567#chr(10)#DEBUG=true");

				var result = detectPortFromEnv(variables.testDir);
				expect(result).toBe(4567, "Should read PORT from .env");
			});

			it("reads PORT with spaces around equals sign", function() {
				fileWrite(variables.testDir & "/.env", "PORT = 7890");

				var result = detectPortFromEnv(variables.testDir);
				expect(result).toBe(7890, "Should handle spaces around = in .env");
			});

			it("returns 0 when lucee.json has no port field", function() {
				var luceeConfig = {"name": "testapp"};
				fileWrite(variables.testDir & "/lucee.json", serializeJSON(luceeConfig));

				var result = detectPortFromLuceeJson(variables.testDir);
				expect(result).toBe(0, "Should return 0 when port is missing");
			});

			it("returns 0 when no .env exists", function() {
				var tmpDir = getTempDirectory() & "wheels_noenv_" & createUUID();
				directoryCreate(tmpDir);
				try {
					var result = detectPortFromEnv(tmpDir);
					expect(result).toBe(0, "Should return 0 when .env is missing");
				} finally {
					directoryDelete(tmpDir, true);
				}
			});

			it("returns 0 when .env has no PORT line", function() {
				fileWrite(variables.testDir & "/.env", "APP_NAME=testapp#chr(10)#DEBUG=true");

				var result = detectPortFromEnv(variables.testDir);
				expect(result).toBe(0, "Should return 0 when PORT not in .env");
			});

			it("Module.cfc checks lucee.json then .env then common ports", function() {
				// Verify the detection order is documented in Module.cfc source
				expect(variables.moduleSource).toInclude("lucee.json",
					"detectServerPort should check lucee.json"
				);
				expect(variables.moduleSource).toInclude('.env',
					"detectServerPort should check .env"
				);

				// Verify common port fallback list exists
				var commonPortPattern = "commonPorts\s*=\s*\[";
				expect(reFindNoCase(commonPortPattern, variables.moduleSource)).toBeGT(0,
					"detectServerPort should have a commonPorts fallback list"
				);
			});
		});

		// ─── Reload Password Detection ──────────────────

		describe("Reload Password Detection (detectReloadPassword logic)", function() {

			it("reads RELOAD_PASSWORD from .env", function() {
				fileWrite(variables.testDir & "/.env", "RELOAD_PASSWORD=secret123#chr(10)#PORT=8080");

				var result = detectReloadPasswordFromEnv(variables.testDir);
				expect(result).toBe("secret123");
			});

			it("reads RELOAD_PASSWORD with spaces around equals", function() {
				fileWrite(variables.testDir & "/.env", "RELOAD_PASSWORD = mysecret");

				var result = detectReloadPasswordFromEnv(variables.testDir);
				expect(result).toBe("mysecret");
			});

			it("reads reloadPassword from config/settings.cfm", function() {
				fileWrite(
					variables.testDir & "/config/settings.cfm",
					'<cfscript>#chr(10)#set(reloadPassword="configPw123");#chr(10)#</cfscript>'
				);

				var result = detectReloadPasswordFromSettings(variables.testDir);
				expect(result).toBe("configPw123");
			});

			it("returns empty string when no password configured", function() {
				var tmpDir = getTempDirectory() & "wheels_nopw_" & createUUID();
				directoryCreate(tmpDir);
				directoryCreate(tmpDir & "/config");
				fileWrite(tmpDir & "/config/settings.cfm",
					'<cfscript>#chr(10)#set(environment="development");#chr(10)#</cfscript>');
				try {
					var envResult = detectReloadPasswordFromEnv(tmpDir);
					var settingsResult = detectReloadPasswordFromSettings(tmpDir);
					expect(envResult).toBe("", "Should return empty from .env");
					expect(settingsResult).toBe("", "Should return empty from settings");
				} finally {
					directoryDelete(tmpDir, true);
				}
			});

			it("Module.cfc checks .env before config/settings.cfm", function() {
				// Verify the detection order in source: .env first, then settings.cfm
				var envPos = findNoCase("RELOAD_PASSWORD", variables.moduleSource);
				var settingsPos = findNoCase("reloadPassword", variables.moduleSource, envPos + 1);
				expect(envPos).toBeGT(0, "Should check .env for RELOAD_PASSWORD");
				expect(settingsPos).toBeGT(envPos,
					"Should check config/settings.cfm after .env"
				);
			});
		});

		// ─── Migration URL Construction ─────────────────

		describe("Migration URL Construction", function() {

			it("builds correct URL for 'latest' action", function() {
				var url = buildMigrationUrl(8080, "latest", "");
				expect(url).toInclude("migrateToLatest");
				expect(url).toInclude("localhost:8080");
				expect(url).toInclude("controller=wheels");
				expect(url).toInclude("view=migrate");
			});

			it("builds correct URL for 'up' action", function() {
				var url = buildMigrationUrl(8080, "up", "");
				expect(url).toInclude("migrateUp");
			});

			it("builds correct URL for 'down' action", function() {
				var url = buildMigrationUrl(8080, "down", "");
				expect(url).toInclude("migrateDown");
			});

			it("builds correct URL for 'info' action", function() {
				var url = buildMigrationUrl(8080, "info", "");
				expect(url).toInclude("type=info");
			});

			it("includes reload=true in all migration URLs", function() {
				var actions = ["latest", "up", "down", "info"];
				for (var action in actions) {
					var url = buildMigrationUrl(8080, action, "");
					expect(url).toInclude("reload=true",
						"Migration URL for '#action#' should include reload=true"
					);
				}
			});

			it("includes password parameter in migration URLs", function() {
				var url = buildMigrationUrl(8080, "latest", "secret");
				expect(url).toInclude("password=");
			});

			it("Module.cfc migrate() accepts latest, up, down, info actions", function() {
				// Verify the switch cases exist in Module.cfc
				var migrateSource = mid(variables.moduleSource,
					findNoCase("function migrate()", variables.moduleSource),
					500
				);
				expect(migrateSource).toInclude('case "latest"');
				expect(migrateSource).toInclude('case "up"');
				expect(migrateSource).toInclude('case "down"');
				expect(migrateSource).toInclude('case "info"');
			});

			it("Module.cfc migrate() defaults to 'latest' when no action given", function() {
				var migrateSource = mid(variables.moduleSource,
					findNoCase("function migrate()", variables.moduleSource),
					300
				);
				expect(migrateSource).toInclude('"latest"',
					"migrate() should default to 'latest' action"
				);
			});
		});

		// ─── Test URL Construction ──────────────────────

		describe("Test URL Construction", function() {

			it("builds correct base test URL", function() {
				var url = buildTestUrl(8080, "", "json");
				expect(url).toInclude("localhost:8080");
				expect(url).toInclude("/wheels/app/tests");
				expect(url).toInclude("format=json");
			});

			it("includes filter directory when specified", function() {
				var url = buildTestUrl(8080, "tests.specs.models", "json");
				expect(url).toInclude("directory=tests.specs.models");
			});

			it("does not include directory param when filter is empty", function() {
				var url = buildTestUrl(8080, "", "json");
				expect(url).notToInclude("directory=");
			});

			it("includes reload=true in test URL", function() {
				var url = buildTestUrl(8080, "", "json");
				expect(url).toInclude("reload=true");
			});

			it("Module.cfc test() parses --filter argument", function() {
				var testSource = mid(variables.moduleSource,
					findNoCase("function test()", variables.moduleSource),
					500
				);
				expect(testSource).toInclude("--filter");
				expect(testSource).toInclude("filter");
			});

			it("Module.cfc test() parses --reporter argument", function() {
				var testSource = mid(variables.moduleSource,
					findNoCase("function test()", variables.moduleSource),
					500
				);
				expect(testSource).toInclude("--reporter");
			});

			it("Module.cfc test() supports --verbose flag", function() {
				var testSource = mid(variables.moduleSource,
					findNoCase("function test()", variables.moduleSource),
					500
				);
				expect(testSource).toInclude("--verbose");
				expect(testSource).toInclude("-v");
			});
		});

		// ─── Reload URL Construction ────────────────────

		describe("Reload URL Construction", function() {

			it("builds correct reload URL with password", function() {
				var url = buildReloadUrl(8080, "mysecret");
				expect(url).toInclude("localhost:8080");
				expect(url).toInclude("reload=true");
				expect(url).toInclude("password=mysecret");
			});

			it("builds reload URL without password", function() {
				var url = buildReloadUrl(8080, "");
				expect(url).toInclude("reload=true");
				expect(url).toInclude("password=");
			});

			it("Module.cfc reload() detects port then password then makes request", function() {
				var reloadSource = mid(variables.moduleSource,
					findNoCase("function reload()", variables.moduleSource),
					500
				);
				expect(reloadSource).toInclude("detectServerPort");
				expect(reloadSource).toInclude("detectReloadPassword");
				expect(reloadSource).toInclude("makeHttpRequest");
			});
		});

		// ─── Test Result Parsing ────────────────────────

		describe("Test Result Parsing (displayTestResults logic)", function() {

			it("Module.cfc parses TestBox JSON result format", function() {
				// Verify displayTestResults handles the standard fields
				expect(variables.moduleSource).toInclude("totalPass");
				expect(variables.moduleSource).toInclude("totalFail");
				expect(variables.moduleSource).toInclude("totalError");
				expect(variables.moduleSource).toInclude("totalDuration");
			});

			it("Module.cfc handles bundleStats for verbose output", function() {
				expect(variables.moduleSource).toInclude("bundleStats");
				expect(variables.moduleSource).toInclude("suiteStats");
				expect(variables.moduleSource).toInclude("specStats");
			});

			it("Module.cfc detects HTML error pages from server", function() {
				// When the server returns HTML instead of JSON, it should be detected
				var testSource = mid(variables.moduleSource,
					findNoCase("function runTests(", variables.moduleSource),
					800
				);
				expect(testSource).toInclude("<html",
					"runTests should detect HTML error pages"
				);
			});

			it("correctly identifies all-passing test results", function() {
				var result = {
					totalPass: 42,
					totalFail: 0,
					totalError: 0,
					totalDuration: 1500,
					bundleStats: []
				};
				var summary = buildTestSummary(result);
				expect(summary.passed).toBe(42);
				expect(summary.failed).toBe(0);
				expect(summary.errors).toBe(0);
				expect(summary.allPassing).toBeTrue();
			});

			it("correctly identifies failing test results", function() {
				var result = {
					totalPass: 38,
					totalFail: 3,
					totalError: 1,
					totalDuration: 2300,
					bundleStats: []
				};
				var summary = buildTestSummary(result);
				expect(summary.passed).toBe(38);
				expect(summary.failed).toBe(3);
				expect(summary.errors).toBe(1);
				expect(summary.allPassing).toBeFalse();
			});

			it("handles alternate key names (totalPassed, totalFailed, etc.)", function() {
				var result = {
					totalPassed: 10,
					totalFailed: 2,
					totalErrors: 0,
					totalDuration: 500
				};
				var summary = buildTestSummary(result);
				expect(summary.passed).toBe(10);
				expect(summary.failed).toBe(2);
				expect(summary.errors).toBe(0);
			});

			it("extracts failure details from bundleStats", function() {
				var result = {
					totalPass: 5,
					totalFail: 1,
					totalError: 0,
					totalDuration: 800,
					bundleStats: [{
						name: "TestBundle",
						suiteStats: [{
							name: "MySuite",
							specStats: [
								{name: "passes correctly", status: "Passed"},
								{name: "fails on edge case", status: "Failed", failMessage: "Expected true but got false"}
							]
						}]
					}]
				};
				var failures = extractFailures(result);
				expect(arrayLen(failures)).toBe(1);
				expect(failures[1].name).toBe("fails on edge case");
				expect(failures[1].message).toInclude("Expected true");
			});

			it("extracts error details from bundleStats", function() {
				var result = {
					totalPass: 3,
					totalFail: 0,
					totalError: 1,
					totalDuration: 600,
					bundleStats: [{
						name: "ErrorBundle",
						suiteStats: [{
							name: "MySuite",
							specStats: [
								{name: "throws unexpectedly", status: "Error",
								 error: {message: "NullPointerException"}}
							]
						}]
					}]
				};
				var failures = extractFailures(result);
				expect(arrayLen(failures)).toBe(1);
				expect(failures[1].name).toBe("throws unexpectedly");
			});

			it("handles empty bundleStats gracefully", function() {
				var result = {
					totalPass: 0,
					totalFail: 0,
					totalError: 0,
					totalDuration: 0,
					bundleStats: []
				};
				var failures = extractFailures(result);
				expect(arrayLen(failures)).toBe(0);
			});
		});

		// ─── HTTP Request Helper ────────────────────────

		describe("HTTP Request Helper (makeHttpRequest logic)", function() {

			it("Module.cfc uses Java URL for HTTP requests", function() {
				expect(variables.moduleSource).toInclude("java.net.URL");
				expect(variables.moduleSource).toInclude("getInputStream");
			});

			it("Module.cfc sets connection timeouts", function() {
				expect(variables.moduleSource).toInclude("setConnectTimeout");
				expect(variables.moduleSource).toInclude("setReadTimeout");
			});

			it("Module.cfc uses GET method for server commands", function() {
				expect(variables.moduleSource).toInclude('setRequestMethod("GET")');
			});
		});

		// ─── Live Server Integration ────────────────────
		// Uses 127.0.0.1 instead of localhost to avoid IPv6 resolution issues
		// with Docker port mappings on macOS.

		describe("Live Server Integration", function() {

			beforeEach(function() {
				if (!variables.liveServerAvailable) {
					skip("No running Lucee server detected (check Docker containers)");
				}
			});

			it("server responds to health check", function() {
				var response = makeTestHttpRequest(
					"http://127.0.0.1:#variables.livePort#/"
				);
				expect(response.success).toBeTrue(
					"Server on port #variables.livePort# should respond to requests"
				);
				expect(response.statusCode).toBe(200);
			});

			it("reload endpoint accepts reload=true parameter", function() {
				var response = makeTestHttpRequest(
					"http://127.0.0.1:#variables.livePort#/?reload=true&password="
				);
				expect(response.success).toBeTrue(
					"Reload endpoint should respond"
				);
				// Reload typically returns 302 redirect, but 200 is also valid
				expect(listFind("200,302", response.statusCode)).toBeGT(0,
					"Reload should return 200 or 302, got #response.statusCode#"
				);
			});

			it("test endpoint returns JSON results", function() {
				// Use /wheels/core/tests which is the standard test runner path
				var response = makeTestHttpRequest(
					"http://127.0.0.1:#variables.livePort#/wheels/core/tests?format=json&db=h2"
				);
				expect(response.success).toBeTrue(
					"Test endpoint should respond"
				);
				if (response.success && len(response.body)) {
					if (isJSON(response.body)) {
						var result = deserializeJSON(response.body);
						expect(isStruct(result)).toBeTrue("Test results should be a struct");
						var hasPassField = structKeyExists(result, "totalPass")
							|| structKeyExists(result, "totalPassed");
						expect(hasPassField).toBeTrue(
							"Test results should have a totalPass or totalPassed field"
						);
					}
				}
			});

			it("migrate info endpoint returns response", function() {
				// Migration endpoints return HTML (Wheels admin pages), often via 302 redirect
				var response = makeTestHttpRequest(
					"http://127.0.0.1:#variables.livePort#/?controller=wheels&action=wheels&view=migrate&type=info&password=",
					true
				);
				expect(response.success).toBeTrue(
					"Migration info endpoint should respond"
				);
			});

			it("test endpoint accepts directory filter", function() {
				var response = makeTestHttpRequest(
					"http://127.0.0.1:#variables.livePort#/wheels/core/tests?format=json&db=h2&directory=tests.specs.controller"
				);
				expect(response.success).toBeTrue(
					"Test endpoint with directory filter should respond"
				);
			});

			it("test endpoint returns proper TestBox JSON format", function() {
				var response = makeTestHttpRequest(
					"http://127.0.0.1:#variables.livePort#/wheels/core/tests?format=json&db=h2"
				);

				if (response.success && isJSON(response.body)) {
					var result = deserializeJSON(response.body);
					var summary = buildTestSummary(result);

					expect(summary.passed).toBeGTE(0, "Should have a non-negative pass count");
					expect(summary.failed).toBeGTE(0, "Should have a non-negative fail count");
					expect(summary.errors).toBeGTE(0, "Should have a non-negative error count");
				}
			});
		});

		// ─── Module.cfc Server Command Contract ─────────

		describe("Module.cfc Server Command Contract", function() {

			it("migrate() requires a running server", function() {
				var migrateSource = mid(variables.moduleSource,
					findNoCase("function runMigration(", variables.moduleSource),
					300
				);
				expect(migrateSource).toInclude("detectServerPort",
					"runMigration should check for a running server"
				);
				expect(migrateSource).toInclude("No running Wheels server",
					"runMigration should warn when no server is running"
				);
			});

			it("test() requires a running server", function() {
				var testSource = mid(variables.moduleSource,
					findNoCase("function runTests(", variables.moduleSource),
					300
				);
				expect(testSource).toInclude("detectServerPort",
					"runTests should check for a running server"
				);
				expect(testSource).toInclude("No running Wheels server",
					"runTests should warn when no server is running"
				);
			});

			it("reload() requires a running server", function() {
				var reloadSource = mid(variables.moduleSource,
					findNoCase("function reload()", variables.moduleSource),
					300
				);
				expect(reloadSource).toInclude("detectServerPort",
					"reload should check for a running server"
				);
				expect(reloadSource).toInclude("No running Wheels server",
					"reload should warn when no server is running"
				);
			});

			it("all server commands use the same HTTP helper", function() {
				// All three commands should use makeHttpRequest()
				var runMigPos = findNoCase("function runMigration(", variables.moduleSource);
				var runTestPos = findNoCase("function runTests(", variables.moduleSource);
				var reloadPos = findNoCase("function reload()", variables.moduleSource);

				// Check makeHttpRequest appears in each function's body
				var migBody = mid(variables.moduleSource, runMigPos, 800);
				var testBody = mid(variables.moduleSource, runTestPos, 800);
				var reloadBody = mid(variables.moduleSource, reloadPos, 800);

				expect(migBody).toInclude("makeHttpRequest");
				expect(testBody).toInclude("makeHttpRequest");
				expect(reloadBody).toInclude("makeHttpRequest");
			});

			it("all server commands handle errors gracefully", function() {
				var runMigPos = findNoCase("function runMigration(", variables.moduleSource);
				var runTestPos = findNoCase("function runTests(", variables.moduleSource);
				var reloadPos = findNoCase("function reload()", variables.moduleSource);

				var migBody = mid(variables.moduleSource, runMigPos, 800);
				var testBody = mid(variables.moduleSource, runTestPos, 800);
				var reloadBody = mid(variables.moduleSource, reloadPos, 800);

				expect(migBody).toInclude("catch");
				expect(testBody).toInclude("catch");
				expect(reloadBody).toInclude("catch");
			});
		});
	}

	// ── Test helpers (replicate Module.cfc private logic) ──

	/**
	 * Replicate detectServerPort() — lucee.json extraction only (no socket check).
	 */
	private numeric function detectPortFromLuceeJson(required string projectRoot) {
		var luceeJson = arguments.projectRoot & "/lucee.json";
		if (fileExists(luceeJson)) {
			try {
				var config = deserializeJSON(fileRead(luceeJson));
				if (structKeyExists(config, "port") && isNumeric(config.port)) {
					return val(config.port);
				}
			} catch (any e) {
				// ignore
			}
		}
		return 0;
	}

	/**
	 * Replicate detectServerPort() — .env PORT extraction only.
	 */
	private numeric function detectPortFromEnv(required string projectRoot) {
		var envFile = arguments.projectRoot & "/.env";
		if (fileExists(envFile)) {
			var envContent = fileRead(envFile);
			var portMatch = reFindNoCase("PORT\s*=\s*(\d+)", envContent, 1, true);
			if (arrayLen(portMatch.match) > 1 && isNumeric(portMatch.match[2])) {
				return val(portMatch.match[2]);
			}
		}
		return 0;
	}

	/**
	 * Replicate detectReloadPassword() — .env extraction.
	 */
	private string function detectReloadPasswordFromEnv(required string projectRoot) {
		var envFile = arguments.projectRoot & "/.env";
		if (fileExists(envFile)) {
			var envContent = fileRead(envFile);
			var pwMatch = reFindNoCase("RELOAD_PASSWORD\s*=\s*(.+)", envContent, 1, true);
			if (arrayLen(pwMatch.match) > 1 && len(trim(pwMatch.match[2]))) {
				return trim(pwMatch.match[2]);
			}
		}
		return "";
	}

	/**
	 * Replicate detectReloadPassword() — config/settings.cfm extraction.
	 */
	private string function detectReloadPasswordFromSettings(required string projectRoot) {
		var settingsFile = arguments.projectRoot & "/config/settings.cfm";
		if (fileExists(settingsFile)) {
			var settingsContent = fileRead(settingsFile);
			var settingsMatch = reFindNoCase('reloadPassword\s*[=,]\s*"([^"]*)"', settingsContent, 1, true);
			if (arrayLen(settingsMatch.match) > 1) {
				return settingsMatch.match[2];
			}
		}
		return "";
	}

	/**
	 * Build migration URL matching Module.cfc runMigration() logic.
	 */
	private string function buildMigrationUrl(
		required numeric port,
		required string action,
		required string password
	) {
		var baseUrl = "http://localhost:#arguments.port#/?controller=wheels&action=wheels&view=migrate&reload=true&password=#arguments.password#";

		switch (arguments.action) {
			case "latest":
				return baseUrl & "&type=migrateToLatest";
			case "up":
				return baseUrl & "&type=migrateUp";
			case "down":
				return baseUrl & "&type=migrateDown";
			case "info":
				return baseUrl & "&type=info";
			default:
				return baseUrl;
		}
	}

	/**
	 * Build test URL matching Module.cfc runTests() logic.
	 */
	private string function buildTestUrl(
		required numeric port,
		required string filter,
		required string format
	) {
		var url = "http://localhost:#arguments.port#/wheels/app/tests?format=#arguments.format#";
		if (len(arguments.filter)) {
			url &= "&directory=#arguments.filter#";
		}
		url &= "&reload=true";
		return url;
	}

	/**
	 * Build reload URL matching Module.cfc reload() logic.
	 */
	private string function buildReloadUrl(required numeric port, required string password) {
		return "http://localhost:#arguments.port#/?reload=true&password=#arguments.password#";
	}

	/**
	 * Parse test results into a summary struct (mirrors displayTestResults logic).
	 */
	private struct function buildTestSummary(required struct result) {
		var totalPass = arguments.result.totalPass ?: (arguments.result.totalPassed ?: 0);
		var totalFail = arguments.result.totalFail ?: (arguments.result.totalFailed ?: 0);
		var totalError = arguments.result.totalError ?: (arguments.result.totalErrors ?: 0);

		return {
			passed: totalPass,
			failed: totalFail,
			errors: totalError,
			total: totalPass + totalFail + totalError,
			allPassing: (totalFail == 0 && totalError == 0)
		};
	}

	/**
	 * Extract failure/error details from bundleStats.
	 */
	private array function extractFailures(required struct result) {
		var failures = [];
		if (structKeyExists(arguments.result, "bundleStats") && isArray(arguments.result.bundleStats)) {
			for (var bundle in arguments.result.bundleStats) {
				if (structKeyExists(bundle, "suiteStats") && isArray(bundle.suiteStats)) {
					extractSuiteFailures(bundle.suiteStats, failures);
				}
			}
		}
		return failures;
	}

	/**
	 * Recursively extract failures from suite tree.
	 */
	private void function extractSuiteFailures(required array suites, required array failures) {
		for (var suite in arguments.suites) {
			if (structKeyExists(suite, "specStats") && isArray(suite.specStats)) {
				for (var spec in suite.specStats) {
					var status = spec.status ?: "unknown";
					if (status == "Failed" || status == "Error") {
						var failure = {name: spec.name ?: "unknown"};
						if (status == "Failed" && structKeyExists(spec, "failMessage")) {
							failure.message = spec.failMessage;
						} else if (status == "Error" && structKeyExists(spec, "error") && isStruct(spec.error)) {
							failure.message = spec.error.message ?: "Unknown error";
						} else {
							failure.message = "";
						}
						arrayAppend(arguments.failures, failure);
					}
				}
			}
			// Recurse into nested suites
			if (structKeyExists(suite, "suiteStats") && isArray(suite.suiteStats)) {
				extractSuiteFailures(suite.suiteStats, arguments.failures);
			}
		}
	}

	/**
	 * Detect a live Lucee/CFML server for integration tests.
	 * Returns the port number or 0 if no server found.
	 */
	private numeric function detectLiveServer() {
		// Check common Docker compose ports for Wheels engines
		var ports = [60006, 60005, 60007, 62025, 62023, 62021, 62018, 60001, 8080];
		for (var port in ports) {
			if (isPortListening(port)) return port;
		}
		return 0;
	}

	/**
	 * Check if a port is accepting connections (mirrors Module.cfc isPortOpen).
	 * Uses 127.0.0.1 to avoid IPv6 resolution issues on macOS Docker.
	 */
	private boolean function isPortListening(required numeric port) {
		try {
			var socket = createObject("java", "java.net.Socket");
			socket.init();
			var address = createObject("java", "java.net.InetSocketAddress")
				.init("127.0.0.1", javacast("int", arguments.port));
			socket.connect(address, javacast("int", 2000));
			socket.close();
			return true;
		} catch (any e) {
			return false;
		}
	}

	/**
	 * Make an HTTP GET request for test assertions.
	 * Returns struct with {success, statusCode, body}.
	 *
	 * @url          The URL to request
	 * @followRedirects  Whether to follow HTTP 3xx redirects (default: false)
	 */
	private struct function makeTestHttpRequest(required string url, boolean followRedirects = false) {
		try {
			var URL = createObject("java", "java.net.URL").init(arguments.url);
			var conn = URL.openConnection();
			conn.setRequestMethod("GET");
			conn.setConnectTimeout(javacast("int", 10000));
			conn.setReadTimeout(javacast("int", 60000));
			conn.setInstanceFollowRedirects(javacast("boolean", arguments.followRedirects));

			var statusCode = conn.getResponseCode();
			var body = "";

			try {
				var inputStream = (statusCode < 400) ? conn.getInputStream() : conn.getErrorStream();
				if (!isNull(inputStream)) {
					var scanner = createObject("java", "java.util.Scanner").init(inputStream, "UTF-8");
					while (scanner.hasNextLine()) {
						body &= scanner.nextLine() & chr(10);
					}
					scanner.close();
				}
			} catch (any e) {
				// May fail on error responses — that's OK
			}

			return {success: true, statusCode: statusCode, body: trim(body)};
		} catch (any e) {
			return {success: false, statusCode: 0, body: e.message};
		}
	}

	/**
	 * Scaffold a minimal project for config detection tests.
	 */
	private void function scaffoldMinimalProject(required string projectRoot) {
		var dirs = [
			"/app/controllers",
			"/app/models",
			"/app/views",
			"/app/migrator/migrations",
			"/config",
			"/public",
			"/tests/specs",
			"/vendor/wheels"
		];

		for (var dir in dirs) {
			directoryCreate(arguments.projectRoot & dir, true);
		}

		var nl = chr(10);
		var tab = chr(9);

		fileWrite(
			arguments.projectRoot & "/config/settings.cfm",
			'<cfscript>' & nl & tab & "set(environment='development');" & nl & '</cfscript>' & nl
		);

		fileWrite(
			arguments.projectRoot & "/lucee.json",
			serializeJSON({
				"name": "testapp",
				"port": 8080,
				"configuration": {"mappings": {"/wheels": "vendor/wheels", "/app": "app"}}
			})
		);

		fileWrite(
			arguments.projectRoot & "/.env",
			"APP_NAME=testapp" & nl & "PORT=8080" & nl & "RELOAD_PASSWORD=testapp" & nl
		);
	}

}
