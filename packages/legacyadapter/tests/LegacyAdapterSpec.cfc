/**
 * wheels-legacy-adapter — TestBox BDD specs
 *
 * Tests the three core components:
 *   1. DeprecationLogger — mode behavior, deduplication, request tracking
 *   2. LegacyAdapter — shim method delegation and deprecation logging
 *   3. MigrationScanner — pattern detection in CFML source files
 */
component extends="wheels.WheelsTest" output="false" {

	function run() {

		/* ============================================================ */
		/*  DeprecationLogger                                           */
		/* ============================================================ */

		describe("DeprecationLogger", () => {

			beforeEach(() => {
				/* clean request scope before each test */
				if (StructKeyExists(request, "wheels") && StructKeyExists(request.wheels, "deprecations")) {
					StructDelete(request.wheels, "deprecations");
				}
			});

			it("initializes with default mode 'log'", () => {
				var logger = $createLogger();
				expect(logger.getMode()).toBe("log");
			});

			it("accepts a custom mode on init", () => {
				var logger = $createLogger("warn");
				expect(logger.getMode()).toBe("warn");
			});

			it("rejects invalid modes", () => {
				var logger = $createLogger();
				var threw = false;
				try {
					logger.setMode("banana");
				} catch (any e) {
					threw = true;
				}
				expect(threw).toBeTrue("setMode should throw for invalid mode");
			});

			it("logs nothing in silent mode", () => {
				var logger = $createLogger("silent");
				logger.logDeprecation(
					oldMethod = "oldFunc()",
					newMethod = "newFunc()"
				);
				expect(logger.getRequestDeprecationCount()).toBe(0);
			});

			it("logs entries in log mode", () => {
				var logger = $createLogger("log");
				logger.logDeprecation(
					oldMethod = "renderPage()",
					newMethod = "renderView()"
				);
				expect(logger.getRequestDeprecationCount()).toBe(1);
			});

			it("deduplicates within same request", () => {
				var logger = $createLogger("log");
				logger.logDeprecation(
					oldMethod = "renderPage()",
					newMethod = "renderView()"
				);
				logger.logDeprecation(
					oldMethod = "renderPage()",
					newMethod = "renderView()"
				);
				expect(logger.getRequestDeprecationCount()).toBe(1);
			});

			it("tracks distinct deprecations separately", () => {
				var logger = $createLogger("log");
				logger.logDeprecation(
					oldMethod = "renderPage()",
					newMethod = "renderView()"
				);
				logger.logDeprecation(
					oldMethod = "renderPageToString()",
					newMethod = "renderView(returnAs='string')"
				);
				expect(logger.getRequestDeprecationCount()).toBe(2);
			});

			it("throws in error mode", () => {
				var logger = $createLogger("error");
				var threw = false;
				try {
					logger.logDeprecation(
						oldMethod = "renderPage()",
						newMethod = "renderView()"
					);
				} catch (Wheels.LegacyAdapter.DeprecatedAPI e) {
					threw = true;
				}
				expect(threw).toBeTrue("error mode should throw DeprecatedAPI exception");
			});

			it("returns entries with correct structure", () => {
				var logger = $createLogger("warn");
				logger.logDeprecation(
					oldMethod = "renderPage()",
					newMethod = "renderView()",
					message = "Renamed in 3.0"
				);
				var entries = logger.getRequestDeprecations();
				expect(ArrayLen(entries)).toBe(1);
				expect(entries[1].oldMethod).toBe("renderPage()");
				expect(entries[1].newMethod).toBe("renderView()");
				expect(entries[1].message).toBe("Renamed in 3.0");
				expect(StructKeyExists(entries[1], "timestamp")).toBeTrue();
			});

			it("resets request deprecations cleanly", () => {
				var logger = $createLogger("log");
				logger.logDeprecation(
					oldMethod = "renderPage()",
					newMethod = "renderView()"
				);
				logger.resetRequestDeprecations();
				expect(logger.getRequestDeprecationCount()).toBe(0);
			});

		});

		/* ============================================================ */
		/*  LegacyAdapter                                               */
		/* ============================================================ */

		describe("LegacyAdapter", () => {

			it("initializes without error", () => {
				var threw = false;
				try {
					var adapter = $createAdapter();
				} catch (any e) {
					threw = true;
				}
				expect(threw).toBeFalse("LegacyAdapter init should not throw");
			});

			it("returns version string from package.json", () => {
				var adapter = $createAdapter();
				var version = adapter.$legacyAdapterVersion();
				/* version should be a valid semver-like string, not the old hardcoded fallback */
				expect(Len(version) > 0).toBeTrue("version should not be empty");
				expect(FindNoCase(".", version) > 0).toBeTrue("version should contain a dot (semver)");
			});

			it("returns status struct with required keys", () => {
				var adapter = $createAdapter();
				var status = adapter.$legacyAdapterStatus();
				expect(StructKeyExists(status, "version")).toBeTrue();
				expect(StructKeyExists(status, "mode")).toBeTrue();
				expect(StructKeyExists(status, "deprecationsThisRequest")).toBeTrue();
				expect(StructKeyExists(status, "entries")).toBeTrue();
			});

			it("returns plugin info struct", () => {
				var adapter = $createAdapter();
				var info = adapter.$legacyPluginInfo();
				expect(StructKeyExists(info, "plugins")).toBeTrue();
				expect(StructKeyExists(info, "hasLegacyPlugins")).toBeTrue();
				expect(IsArray(info.plugins)).toBeTrue();
			});

		});

		/* ============================================================ */
		/*  MigrationScanner                                            */
		/* ============================================================ */

		describe("MigrationScanner", () => {

			it("initializes without error", () => {
				var threw = false;
				try {
					var scanner = $createScanner();
				} catch (any e) {
					threw = true;
				}
				expect(threw).toBeFalse("MigrationScanner init should not throw");
			});

			it("returns error for non-existent directory", () => {
				var scanner = $createScanner();
				var report = scanner.scan(appPath = "/tmp/nonexistent-wheels-test-dir-#CreateUUID()#");
				expect(StructKeyExists(report, "error")).toBeTrue();
			});

			it("returns report struct with required keys", () => {
				var scanner = $createScanner();
				/* scan the adapter's own directory (small, known content) */
				var report = scanner.scan(appPath = ExpandPath("/wheels/tests/_assets"));
				expect(StructKeyExists(report, "scannedAt")).toBeTrue();
				expect(StructKeyExists(report, "totalFiles")).toBeTrue();
				expect(StructKeyExists(report, "totalFindings")).toBeTrue();
				expect(StructKeyExists(report, "findings")).toBeTrue();
				expect(StructKeyExists(report, "summary")).toBeTrue();
				expect(IsArray(report.findings)).toBeTrue();
			});

			it("detects renderPage pattern in source", () => {
				var scanner = $createScanner();
				var result = $scanContent(scanner, 'renderPage(template="home/index")', "app/controllers");
				expect(result.found).toBeTrue("Scanner should detect renderPage() call");
				expect(result.pattern).toBe("renderPage");
			});

			it("detects renderPageToString pattern", () => {
				var scanner = $createScanner();
				var result = $scanContent(scanner, 'var html = renderPageToString(action="show")', "app/controllers");
				expect(result.found).toBeTrue("Scanner should detect renderPageToString() call");
				expect(result.pattern).toBe("renderPageToString");
			});

			it("detects legacy plugin version declaration in plugins directory", () => {
				var scanner = $createScanner();
				var result = $scanContent(scanner, 'this.version = "1.0.0";', "plugins/MyPlugin");
				expect(result.found).toBeTrue("Scanner should detect this.version = in plugins/ dir");
				expect(result.pattern).toBe("legacyPluginVersion");
			});

			it("does NOT flag this.version outside plugins directory", () => {
				var scanner = $createScanner();
				var result = $scanContent(scanner, 'this.version = "1.0.0";', "app/models");
				expect(result.found).toBeFalse("Scanner should NOT flag this.version in app/models/");
			});

			it("detects legacy plugin dependency declaration in plugins directory", () => {
				var scanner = $createScanner();
				var result = $scanContent(scanner, 'this.dependency = "PluginA,PluginB";', "plugins/MyPlugin");
				expect(result.found).toBeTrue("Scanner should detect this.dependency = in plugins/ dir");
				expect(result.pattern).toBe("legacyPluginDependency");
			});

			it("does NOT flag this.dependency outside plugins directory", () => {
				var scanner = $createScanner();
				var result = $scanContent(scanner, 'this.dependency = "SomeLib";', "app/lib");
				expect(result.found).toBeFalse("Scanner should NOT flag this.dependency in app/lib/");
			});

			it("detects legacy test extends", () => {
				var scanner = $createScanner();
				var result = $scanContent(scanner, 'component extends="wheels.Test" {', "app/controllers");
				expect(result.found).toBeTrue("Scanner should detect extends=""wheels.Test""");
				expect(result.pattern).toBe("legacyTestExtends");
			});

			it("detects direct application scope access", () => {
				var scanner = $createScanner();
				var result = $scanContent(scanner, 'var env = application.wheels.environment;', "app/controllers");
				expect(result.found).toBeTrue("Scanner should detect application.wheels.* access");
				expect(result.pattern).toBe("directAppScopeAccess");
			});

			it("skips test directory files", () => {
				var scanner = $createScanner();
				var isTest = scanner.$isTestPath("/app/tests/specs/MySpec.cfc");
				expect(isTest).toBeTrue("paths containing /tests/ should be flagged as test paths");
			});

			it("does not flag non-test paths as test paths", () => {
				var scanner = $createScanner();
				var isTest = scanner.$isTestPath("/app/controllers/Users.cfc");
				expect(isTest).toBeFalse("controller paths should not be flagged as test paths");
			});

			it("builds correct summary by severity", () => {
				var scanner = $createScanner();
				var findings = [
					{severity: "critical", pattern: "renderPage"},
					{severity: "critical", pattern: "renderPage"},
					{severity: "warning", pattern: "legacyPluginVersion"},
					{severity: "info", pattern: "shortExtendsModel"}
				];
				var summary = scanner.$buildSummary(findings);
				expect(summary.bySeverity.critical).toBe(2);
				expect(summary.bySeverity.warning).toBe(1);
				expect(summary.bySeverity.info).toBe(1);
			});

			it("builds correct summary by pattern", () => {
				var scanner = $createScanner();
				var findings = [
					{severity: "critical", pattern: "renderPage"},
					{severity: "critical", pattern: "renderPage"},
					{severity: "warning", pattern: "legacyPluginVersion"}
				];
				var summary = scanner.$buildSummary(findings);
				expect(summary.byPattern.renderPage).toBe(2);
				expect(summary.byPattern.legacyPluginVersion).toBe(1);
			});

		});

	}

	/* ================================================================ */
	/*  Test Helpers                                                     */
	/* ================================================================ */

	/**
	 * Creates a DeprecationLogger with the given mode.
	 */
	private any function $createLogger(string mode = "log") {
		return new vendor.legacyadapter.DeprecationLogger(mode = arguments.mode);
	}

	/**
	 * Creates a LegacyAdapter instance.
	 */
	private any function $createAdapter() {
		return new vendor.legacyadapter.LegacyAdapter();
	}

	/**
	 * Creates a MigrationScanner instance.
	 */
	private any function $createScanner() {
		return new vendor.legacyadapter.MigrationScanner();
	}

	/**
	 * Scans a single line of content for patterns.
	 * Returns {found: boolean, pattern: string}.
	 *
	 * @scanner The scanner instance
	 * @content The source content to scan
	 * @subDir Subdirectory within temp dir to simulate file location (e.g. "plugins/MyPlugin" or "app/models")
	 */
	private struct function $scanContent(required any scanner, required string content, string subDir = "app") {
		/* Write content to a temp file, scan it, return first finding */
		var tempBase = GetTempDirectory() & "wheels-legacy-test-#CreateUUID()#";
		var tempDir = tempBase & "/" & arguments.subDir;
		DirectoryCreate(tempDir, true);
		var tempFile = tempDir & "/test.cfm";
		FileWrite(tempFile, arguments.content);

		var report = arguments.scanner.scan(appPath = tempBase);

		/* clean up */
		FileDelete(tempFile);
		DirectoryDelete(tempBase, true);

		if (ArrayLen(report.findings) > 0) {
			return {found: true, pattern: report.findings[1].pattern};
		}
		return {found: false, pattern: ""};
	}

}
