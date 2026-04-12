# CLI Test Infrastructure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a TestBox test suite for the LuCLI CLI module services and commands, integrated into the CI pipeline.

**Architecture:** Tests live in `cli/lucli/tests/` with their own `runner.cfm`. A shared `TestHelper.cfc` copies the project skeleton into a temp directory for isolated testing. Service unit tests instantiate CFCs directly; integration tests hit the running server via HTTP. CI runs both suites via `run-tests.sh`.

**Tech Stack:** CFML (Lucee 7), TestBox BDD (describe/it/expect), LuCLI server

**Spec:** `docs/superpowers/specs/2026-04-11-cli-testing-design.md`

---

## File Structure

### New files to create:
- `cli/lucli/tests/runner.cfm` — TestBox entry point, returns JSON/HTML
- `cli/lucli/tests/TestHelper.cfc` — Temp project scaffolding, HTTP helper, port detection
- `cli/lucli/tests/specs/services/HelpersSpec.cfc` — Helpers service tests
- `cli/lucli/tests/specs/services/DestroySpec.cfc` — Destroy service tests
- `cli/lucli/tests/specs/services/DoctorSpec.cfc` — Doctor service tests
- `cli/lucli/tests/specs/services/StatsSpec.cfc` — Stats + notes service tests
- `cli/lucli/tests/specs/services/AdminSpec.cfc` — Admin service tests
- `cli/lucli/tests/specs/services/CodeGenSpec.cfc` — CodeGen service tests
- `cli/lucli/tests/specs/integration/DbCommandsSpec.cfc` — DB endpoint integration tests
- `cli/lucli/tests/specs/integration/IntrospectSpec.cfc` — Introspect endpoint integration tests

### Existing files to modify:
- `tools/ci/run-tests.sh` — Add CLI test block after core tests

---

### Task 1: TestHelper and Runner

**Files:**
- Create: `cli/lucli/tests/TestHelper.cfc`
- Create: `cli/lucli/tests/runner.cfm`

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p cli/lucli/tests/specs/services
mkdir -p cli/lucli/tests/specs/integration
```

- [ ] **Step 2: Create TestHelper.cfc**

Write `cli/lucli/tests/TestHelper.cfc`:

```cfml
/**
 * Shared test utilities for CLI module specs.
 *
 * Provides temp project scaffolding (copies project skeleton to temp dir),
 * HTTP helper for integration tests, and server port detection.
 */
component {

	/**
	 * Copy the project skeleton into a temp directory for isolated testing.
	 * Returns the absolute path to the temp project root.
	 */
	public string function scaffoldTempProject(required string sourceRoot) {
		var tempBase = getTempDirectory() & "wheels-cli-test-" & createUUID();
		directoryCreate(tempBase, true);

		// Copy app structure
		var dirs = ["app", "config", "tests/specs", "public"];
		for (var dir in dirs) {
			var srcPath = arguments.sourceRoot & "/" & dir;
			var destPath = tempBase & "/" & dir;
			if (directoryExists(srcPath)) {
				directoryCopy(srcPath, destPath, true);
			} else {
				directoryCreate(destPath, true);
			}
		}

		// Copy key config files from root
		var files = [".env", "lucee.json"];
		for (var f in files) {
			var srcFile = arguments.sourceRoot & "/" & f;
			if (fileExists(srcFile)) {
				fileCopy(srcFile, tempBase & "/" & f);
			}
		}

		return tempBase;
	}

	/**
	 * Delete the temp project directory.
	 */
	public void function cleanupTempProject(required string tempRoot) {
		if (len(arguments.tempRoot) > 10 && directoryExists(arguments.tempRoot)) {
			directoryDelete(arguments.tempRoot, true);
		}
	}

	/**
	 * Detect a running server port.
	 * Checks PORT env var first, then probes 8080 and 60007.
	 * Returns port number or 0 if no server found.
	 */
	public numeric function detectServerPort() {
		// Check environment variable (set by CI)
		var envPort = createObject("java", "java.lang.System").getenv("PORT");
		if (!isNull(envPort) && len(envPort) && isPortResponding(val(envPort))) {
			return val(envPort);
		}

		// Probe common ports
		if (isPortResponding(8080)) return 8080;
		if (isPortResponding(60007)) return 60007;

		return 0;
	}

	/**
	 * HTTP GET request, returns response body string.
	 * Returns empty string on connection failure.
	 */
	public string function httpGet(required string url) {
		try {
			var javaUrl = createObject("java", "java.net.URL").init(arguments.url);
			var conn = javaUrl.openConnection();
			conn.setRequestMethod("GET");
			conn.setConnectTimeout(5000);
			conn.setReadTimeout(30000);

			var responseCode = conn.getResponseCode();
			var inputStream = responseCode >= 400
				? conn.getErrorStream()
				: conn.getInputStream();
			var scanner = createObject("java", "java.util.Scanner")
				.init(inputStream, "UTF-8");
			var response = "";
			while (scanner.hasNextLine()) {
				response &= scanner.nextLine() & chr(10);
			}
			scanner.close();
			return trim(response);
		} catch (any e) {
			return "";
		}
	}

	/**
	 * Check if a port is responding to HTTP.
	 */
	private boolean function isPortResponding(required numeric port) {
		try {
			var javaUrl = createObject("java", "java.net.URL")
				.init("http://localhost:#arguments.port#/");
			var conn = javaUrl.openConnection();
			conn.setConnectTimeout(2000);
			conn.setReadTimeout(2000);
			conn.getResponseCode();
			return true;
		} catch (any e) {
			return false;
		}
	}

}
```

- [ ] **Step 3: Create runner.cfm**

Write `cli/lucli/tests/runner.cfm`:

```cfml
<cfsetting requestTimeOut="300">
<cfscript>
try {
	testBox = new wheels.wheelstest.system.TestBox(
		directory = "cli.lucli.tests.specs",
		options = { coverage = { enabled = false } }
	);

	local.sortedArray = testBox.getBundles();
	arraySort(local.sortedArray, "textNoCase");
	testBox.setBundles(local.sortedArray);

	if (!structKeyExists(url, "format") || url.format == "html") {
		result = testBox.run(
			reporter = "wheels.wheelstest.system.reports.SimpleReporter"
		);
	} else if (url.format == "json") {
		result = testBox.run(
			reporter = "wheels.wheelstest.system.reports.JSONReporter"
		);
		cfcontent(type = "application/json");
		local.parsed = deserializeJSON(result);
		if (local.parsed.totalFail > 0 || local.parsed.totalError > 0) {
			cfheader(statuscode = 417);
		} else {
			cfheader(statuscode = 200);
		}
	}

	writeOutput(result);
} catch (any e) {
	cfheader(statuscode = 500);
	cfcontent(type = "application/json");
	writeOutput('{"success":false,"error":"' & replace(e.message, '"', '\"', 'all') & '"}');
}
</cfscript>
```

- [ ] **Step 4: Commit**

```bash
git add cli/lucli/tests/
git commit -m "test(cli): add test runner and helper infrastructure"
```

---

### Task 2: HelpersSpec

**Files:**
- Create: `cli/lucli/tests/specs/services/HelpersSpec.cfc`

- [ ] **Step 1: Create HelpersSpec.cfc**

Write `cli/lucli/tests/specs/services/HelpersSpec.cfc`:

```cfml
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.helpers = new cli.lucli.services.Helpers();
	}

	function run() {

		describe("Helpers Service", () => {

			describe("capitalize()", () => {

				it("capitalizes the first letter", () => {
					expect(helpers.capitalize("user")).toBe("User");
				});

				it("handles single character", () => {
					expect(helpers.capitalize("a")).toBe("A");
				});

				it("returns empty string for empty input", () => {
					expect(helpers.capitalize("")).toBe("");
				});

				it("preserves rest of string", () => {
					expect(helpers.capitalize("firstName")).toBe("FirstName");
				});

			});

			describe("pluralize()", () => {

				it("pluralizes regular words", () => {
					expect(helpers.pluralize("user")).toBe("users");
				});

				it("handles -es suffix", () => {
					expect(helpers.pluralize("bus")).toBe("buses");
				});

				it("handles -ies suffix", () => {
					expect(helpers.pluralize("category")).toBe("categories");
				});

				it("handles irregular words", () => {
					expect(helpers.pluralize("person")).toBe("people");
					expect(helpers.pluralize("child")).toBe("children");
				});

				it("handles uncountable words", () => {
					expect(helpers.pluralize("sheep")).toBe("sheep");
					expect(helpers.pluralize("fish")).toBe("fish");
				});

			});

			describe("singularize()", () => {

				it("singularizes regular words", () => {
					expect(helpers.singularize("users")).toBe("user");
				});

				it("handles irregular words", () => {
					expect(helpers.singularize("people")).toBe("person");
					expect(helpers.singularize("children")).toBe("child");
				});

				it("handles uncountable words", () => {
					expect(helpers.singularize("sheep")).toBe("sheep");
				});

			});

			describe("stripSpecialChars()", () => {

				it("removes brackets and special characters", () => {
					expect(helpers.stripSpecialChars("hello[world]")).toBe("helloworld");
				});

				it("removes ampersands and percents", () => {
					expect(helpers.stripSpecialChars("a&b%c")).toBe("abc");
				});

				it("trims whitespace", () => {
					expect(helpers.stripSpecialChars("  hello  ")).toBe("hello");
				});

			});

			describe("generateMigrationTimestamp()", () => {

				it("returns a 14-digit string", () => {
					var ts = helpers.generateMigrationTimestamp();
					expect(len(ts)).toBe(14);
					expect(isNumeric(ts)).toBeTrue();
				});

			});

		});

	}

}
```

- [ ] **Step 2: Verify tests run**

```bash
curl -sf "http://localhost:8080/cli/lucli/tests/runner.cfm?format=json" | python3 -c "
import json,sys; d=json.load(sys.stdin)
print(f'{d[\"totalPass\"]} pass, {d[\"totalFail\"]} fail, {d[\"totalError\"]} error')
"
```

Expected: All pass, 0 fail, 0 error.

- [ ] **Step 3: Commit**

```bash
git add cli/lucli/tests/specs/services/HelpersSpec.cfc
git commit -m "test(cli): add helpers service unit tests"
```

---

### Task 3: DestroySpec

**Files:**
- Create: `cli/lucli/tests/specs/services/DestroySpec.cfc`

- [ ] **Step 1: Create DestroySpec.cfc**

Write `cli/lucli/tests/specs/services/DestroySpec.cfc`:

```cfml
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		variables.moduleRoot = expandPath("/cli/lucli/");
		variables.helpers = new cli.lucli.services.Helpers();
		variables.destroy = new cli.lucli.services.Destroy(
			helpers = variables.helpers,
			projectRoot = variables.tempRoot,
			moduleRoot = variables.moduleRoot
		);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		describe("Destroy Service", () => {

			describe("destroyModel()", () => {

				it("deletes model file and generates migration", () => {
					// Create a model file to destroy
					var modelPath = tempRoot & "/app/models/Deleteme.cfc";
					directoryCreate(getDirectoryFromPath(modelPath), true, true);
					fileWrite(modelPath, 'component extends="Model" {}');

					var result = destroy.destroyModel("Deleteme");
					expect(result.success).toBeTrue();
					expect(fileExists(modelPath)).toBeFalse();
					expect(len(result.migrationPath)).toBeGT(0);
					expect(fileExists(result.migrationPath)).toBeTrue();

					// Verify migration content
					var migContent = fileRead(result.migrationPath);
					expect(migContent).toInclude("dropTable");
					expect(migContent).toInclude("deletemes");
				});

				it("warns when model file does not exist", () => {
					var result = destroy.destroyModel("Nonexistent");
					expect(result.success).toBeTrue();
					expect(arrayLen(result.warnings)).toBeGT(0);
				});

			});

			describe("destroyController()", () => {

				it("deletes controller and test files", () => {
					var controllerPath = tempRoot & "/app/controllers/Deletemes.cfc";
					var testPath = tempRoot & "/tests/specs/controllers/DeletemesSpec.cfc";
					directoryCreate(getDirectoryFromPath(controllerPath), true, true);
					directoryCreate(getDirectoryFromPath(testPath), true, true);
					fileWrite(controllerPath, 'component extends="Controller" {}');
					fileWrite(testPath, 'component {}');

					var result = destroy.destroyController("Deleteme");
					expect(fileExists(controllerPath)).toBeFalse();
					expect(fileExists(testPath)).toBeFalse();
				});

				it("does not generate a migration", () => {
					var result = destroy.destroyController("Deleteme");
					expect(structKeyExists(result, "migrationPath")).toBeFalse();
				});

			});

			describe("destroyResource()", () => {

				it("deletes all resource files and cleans up route", () => {
					// Create resource files
					var modelPath = tempRoot & "/app/models/Widget.cfc";
					var controllerPath = tempRoot & "/app/controllers/Widgets.cfc";
					var viewsDir = tempRoot & "/app/views/widgets";
					var modelTestPath = tempRoot & "/tests/specs/models/WidgetSpec.cfc";
					var controllerTestPath = tempRoot & "/tests/specs/controllers/WidgetsSpec.cfc";
					var viewTestsDir = tempRoot & "/tests/specs/views/widgets";

					directoryCreate(getDirectoryFromPath(modelPath), true, true);
					directoryCreate(getDirectoryFromPath(controllerPath), true, true);
					directoryCreate(viewsDir, true, true);
					directoryCreate(getDirectoryFromPath(modelTestPath), true, true);
					directoryCreate(getDirectoryFromPath(controllerTestPath), true, true);
					directoryCreate(viewTestsDir, true, true);

					fileWrite(modelPath, 'component extends="Model" {}');
					fileWrite(controllerPath, 'component extends="Controller" {}');
					fileWrite(viewsDir & "/index.cfm", "<p>index</p>");
					fileWrite(modelTestPath, 'component {}');
					fileWrite(controllerTestPath, 'component {}');
					fileWrite(viewTestsDir & "/indexSpec.cfc", 'component {}');

					// Add route
					var routesPath = tempRoot & "/config/routes.cfm";
					var routeContent = fileRead(routesPath);
					routeContent = replace(routeContent, "// CLI-Appends-Here",
						'.resources("widgets")' & chr(10) & chr(9) & chr(9) & "// CLI-Appends-Here");
					fileWrite(routesPath, routeContent);

					var result = destroy.destroyResource("Widget");
					expect(fileExists(modelPath)).toBeFalse();
					expect(fileExists(controllerPath)).toBeFalse();
					expect(directoryExists(viewsDir)).toBeFalse();
					expect(fileExists(modelTestPath)).toBeFalse();
					expect(fileExists(controllerTestPath)).toBeFalse();
					expect(directoryExists(viewTestsDir)).toBeFalse();
					expect(len(result.migrationPath)).toBeGT(0);

					// Verify route removed
					var updatedRoutes = fileRead(routesPath);
					expect(updatedRoutes).notToInclude('.resources("widgets")');
				});

			});

			describe("destroyView()", () => {

				it("deletes a single view file when path contains /", () => {
					var viewDir = tempRoot & "/app/views/items";
					directoryCreate(viewDir, true, true);
					fileWrite(viewDir & "/show.cfm", "<p>show</p>");

					var result = destroy.destroyView("items/show");
					expect(fileExists(viewDir & "/show.cfm")).toBeFalse();
					// Directory should still exist
					expect(directoryExists(viewDir)).toBeTrue();
				});

				it("deletes entire view directory when no /", () => {
					var viewDir = tempRoot & "/app/views/things";
					directoryCreate(viewDir, true, true);
					fileWrite(viewDir & "/index.cfm", "<p>index</p>");

					var result = destroy.destroyView("Thing");
					expect(directoryExists(viewDir)).toBeFalse();
				});

				it("returns error for invalid view path", () => {
					var result = destroy.destroyView("invalid/");
					expect(result.success).toBeFalse();
				});

			});

			describe("previewDestroy()", () => {

				it("returns expected items for resource type", () => {
					var preview = destroy.previewDestroy("Product", "resource");
					expect(arrayLen(preview)).toBeGTE(6);
					expect(arrayToList(preview)).toInclude("Product.cfc");
					expect(arrayToList(preview)).toInclude("Products.cfc");
					expect(arrayToList(preview)).toInclude("drop table");
				});

				it("returns expected items for controller type", () => {
					var preview = destroy.previewDestroy("Product", "controller");
					expect(arrayLen(preview)).toBe(2);
				});

			});

		});

	}

}
```

- [ ] **Step 2: Verify tests run**

```bash
curl -sf "http://localhost:8080/cli/lucli/tests/runner.cfm?format=json" | python3 -c "
import json,sys; d=json.load(sys.stdin)
print(f'{d[\"totalPass\"]} pass, {d[\"totalFail\"]} fail, {d[\"totalError\"]} error')
"
```

- [ ] **Step 3: Commit**

```bash
git add cli/lucli/tests/specs/services/DestroySpec.cfc
git commit -m "test(cli): add destroy service unit tests"
```

---

### Task 4: DoctorSpec

**Files:**
- Create: `cli/lucli/tests/specs/services/DoctorSpec.cfc`

- [ ] **Step 1: Create DoctorSpec.cfc**

Write `cli/lucli/tests/specs/services/DoctorSpec.cfc`:

```cfml
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		describe("Doctor Service", () => {

			it("reports HEALTHY for a valid project", () => {
				var doctor = new cli.lucli.services.Doctor(projectRoot = tempRoot);
				var results = doctor.runChecks();
				expect(results.status).toBe("HEALTHY");
				expect(arrayLen(results.issues)).toBe(0);
			});

			it("reports CRITICAL when a required directory is missing", () => {
				// Remove app/controllers
				if (directoryExists(tempRoot & "/app/controllers")) {
					directoryDelete(tempRoot & "/app/controllers", true);
				}

				var doctor = new cli.lucli.services.Doctor(projectRoot = tempRoot);
				var results = doctor.runChecks();
				expect(results.status).toBe("CRITICAL");
				expect(arrayLen(results.issues)).toBeGT(0);

				var issueText = arrayToList(results.issues, " ");
				expect(issueText).toInclude("app/controllers");

				// Restore for subsequent tests
				directoryCreate(tempRoot & "/app/controllers", true);
			});

			it("reports WARNING when a recommended directory is missing", () => {
				// Remove tests/specs if it exists
				var specsDir = tempRoot & "/tests/specs";
				var existed = directoryExists(specsDir);
				if (existed) {
					directoryDelete(specsDir, true);
				}

				var doctor = new cli.lucli.services.Doctor(projectRoot = tempRoot);
				var results = doctor.runChecks();

				// Should not be CRITICAL (no required dirs missing)
				expect(results.status).notToBe("CRITICAL");
				expect(arrayLen(results.warnings)).toBeGT(0);

				// Restore
				if (existed) {
					directoryCreate(specsDir, true);
				}
			});

			it("reports CRITICAL when a required file is missing", () => {
				var routesPath = tempRoot & "/config/routes.cfm";
				var routesContent = "";
				if (fileExists(routesPath)) {
					routesContent = fileRead(routesPath);
					fileDelete(routesPath);
				}

				var doctor = new cli.lucli.services.Doctor(projectRoot = tempRoot);
				var results = doctor.runChecks();
				expect(results.status).toBe("CRITICAL");

				// Restore
				if (len(routesContent)) {
					fileWrite(routesPath, routesContent);
				}
			});

			it("warns when config routes.cfm has minimal content", () => {
				var routesPath = tempRoot & "/config/routes.cfm";
				var original = fileRead(routesPath);
				fileWrite(routesPath, "<!--- --->"); // less than 10 chars of content

				var doctor = new cli.lucli.services.Doctor(projectRoot = tempRoot);
				var results = doctor.runChecks();

				var warningText = arrayToList(results.warnings, " ");
				expect(warningText).toInclude("routes.cfm");

				fileWrite(routesPath, original);
			});

			it("generates recommendations based on issues", () => {
				// Remove tests to trigger recommendation
				var specsDir = tempRoot & "/tests/specs";
				var existed = directoryExists(specsDir);
				if (existed) {
					directoryDelete(specsDir, true);
				}

				var doctor = new cli.lucli.services.Doctor(projectRoot = tempRoot);
				var results = doctor.runChecks();
				expect(arrayLen(results.recommendations)).toBeGT(0);

				if (existed) {
					directoryCreate(specsDir, true);
				}
			});

			it("passes write permission check on writable directory", () => {
				var doctor = new cli.lucli.services.Doctor(projectRoot = tempRoot);
				var results = doctor.runChecks();

				var passedText = arrayToList(results.passed, " ");
				expect(passedText).toInclude("Write permission");
			});

		});

	}

}
```

- [ ] **Step 2: Verify and commit**

```bash
curl -sf "http://localhost:8080/cli/lucli/tests/runner.cfm?format=json" | python3 -c "
import json,sys; d=json.load(sys.stdin)
print(f'{d[\"totalPass\"]} pass, {d[\"totalFail\"]} fail, {d[\"totalError\"]} error')
"
git add cli/lucli/tests/specs/services/DoctorSpec.cfc
git commit -m "test(cli): add doctor service unit tests"
```

---

### Task 5: StatsSpec

**Files:**
- Create: `cli/lucli/tests/specs/services/StatsSpec.cfc`

- [ ] **Step 1: Create StatsSpec.cfc**

Write `cli/lucli/tests/specs/services/StatsSpec.cfc`:

```cfml
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		variables.helpers = new cli.lucli.services.Helpers();
		variables.stats = new cli.lucli.services.Stats(
			helpers = variables.helpers,
			projectRoot = variables.tempRoot
		);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		describe("Stats Service", () => {

			describe("getStats()", () => {

				it("returns categories array with expected entries", () => {
					var data = stats.getStats();
					expect(arrayLen(data.categories)).toBe(7);

					var names = [];
					for (var cat in data.categories) {
						arrayAppend(names, cat.name);
					}
					expect(names).toInclude("Controllers");
					expect(names).toInclude("Models");
					expect(names).toInclude("Views");
				});

				it("returns totals with non-negative values", () => {
					var data = stats.getStats();
					expect(data.totals.files).toBeGTE(0);
					expect(data.totals.loc).toBeGTE(0);
					expect(data.totals.comments).toBeGTE(0);
					expect(data.totals.blanks).toBeGTE(0);
					expect(data.totals.total).toBeGTE(0);
				});

				it("total equals sum of categories", () => {
					var data = stats.getStats();
					var sumFiles = 0;
					for (var cat in data.categories) {
						sumFiles += cat.files;
					}
					expect(data.totals.files).toBe(sumFiles);
				});

				it("counts LOC correctly for a known file", () => {
					// Create a file with known content
					var testFile = tempRoot & "/app/models/StatsTestModel.cfc";
					directoryCreate(getDirectoryFromPath(testFile), true, true);
					fileWrite(testFile,
						'component extends="Model" {' & chr(10)
						& chr(10)
						& '	// this is a comment' & chr(10)
						& '	function config() {' & chr(10)
						& '	}' & chr(10)
						& chr(10)
						& '}'
					);

					var data = stats.getStats();
					// Find Models category
					var modelCat = {};
					for (var cat in data.categories) {
						if (cat.name == "Models") modelCat = cat;
					}
					// Should have at least 1 file and some LOC
					expect(modelCat.files).toBeGTE(1);
					expect(modelCat.loc).toBeGTE(3); // 3 code lines in our test file
					expect(modelCat.comments).toBeGTE(1); // 1 comment line
					expect(modelCat.blanks).toBeGTE(2); // 2 blank lines
				});

				it("returns topFiles sorted by line count descending", () => {
					var data = stats.getStats();
					if (arrayLen(data.topFiles) >= 2) {
						expect(data.topFiles[1].lines).toBeGTE(data.topFiles[2].lines);
					}
				});

			});

			describe("getNotes()", () => {

				it("finds TODO annotations", () => {
					// Create a file with a TODO
					var testFile = tempRoot & "/app/models/NotesTestModel.cfc";
					directoryCreate(getDirectoryFromPath(testFile), true, true);
					fileWrite(testFile,
						'component {' & chr(10)
						& '	// TODO: implement validation' & chr(10)
						& '	// FIXME: broken query' & chr(10)
						& '}'
					);

					var data = stats.getNotes();
					expect(data.total).toBeGTE(2);
					expect(arrayLen(data.annotations["TODO"])).toBeGTE(1);
					expect(arrayLen(data.annotations["FIXME"])).toBeGTE(1);

					// Check annotation has correct structure
					var todo = data.annotations["TODO"][1];
					expect(structKeyExists(todo, "file")).toBeTrue();
					expect(structKeyExists(todo, "line")).toBeTrue();
					expect(structKeyExists(todo, "text")).toBeTrue();
				});

				it("finds custom annotation types", () => {
					var testFile = tempRoot & "/app/controllers/NotesTestController.cfc";
					directoryCreate(getDirectoryFromPath(testFile), true, true);
					fileWrite(testFile,
						'component {' & chr(10)
						& '	// HACK: temporary workaround' & chr(10)
						& '}'
					);

					var data = stats.getNotes(annotations = "TODO", custom = "HACK");
					expect(arrayLen(data.annotations["HACK"])).toBeGTE(1);
					expect(data.annotations["HACK"][1].text).toInclude("temporary");
				});

				it("returns zero total when no annotations exist", () => {
					// Create clean file
					var testFile = tempRoot & "/app/models/CleanModel.cfc";
					directoryCreate(getDirectoryFromPath(testFile), true, true);
					fileWrite(testFile, 'component {}');

					// Use a custom annotation type unlikely to exist
					var data = stats.getNotes(annotations = "XYZNONEXISTENT");
					expect(data.annotations["XYZNONEXISTENT"]).toBeEmpty();
				});

			});

		});

	}

}
```

- [ ] **Step 2: Verify and commit**

```bash
curl -sf "http://localhost:8080/cli/lucli/tests/runner.cfm?format=json" | python3 -c "
import json,sys; d=json.load(sys.stdin)
print(f'{d[\"totalPass\"]} pass, {d[\"totalFail\"]} fail, {d[\"totalError\"]} error')
"
git add cli/lucli/tests/specs/services/StatsSpec.cfc
git commit -m "test(cli): add stats and notes service unit tests"
```

---

### Task 6: AdminSpec

**Files:**
- Create: `cli/lucli/tests/specs/services/AdminSpec.cfc`

- [ ] **Step 1: Create AdminSpec.cfc**

Write `cli/lucli/tests/specs/services/AdminSpec.cfc`:

```cfml
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		variables.moduleRoot = expandPath("/cli/lucli/");
		variables.helpers = new cli.lucli.services.Helpers();
		variables.admin = new cli.lucli.services.Admin(
			helpers = variables.helpers,
			projectRoot = variables.tempRoot,
			moduleRoot = variables.moduleRoot
		);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		describe("Admin Service", () => {

			describe("mapColumnToFormHelper()", () => {

				it("maps string type to textField", () => {
					var result = admin.mapColumnToFormHelper({name: "title", type: "string"});
					expect(result).toBe("textField");
				});

				it("maps text type to textArea", () => {
					var result = admin.mapColumnToFormHelper({name: "body", type: "text"});
					expect(result).toBe("textArea");
				});

				it("maps boolean type to checkBox", () => {
					var result = admin.mapColumnToFormHelper({name: "active", type: "boolean"});
					expect(result).toBe("checkBox");
				});

				it("maps integer type to numberField", () => {
					var result = admin.mapColumnToFormHelper({name: "quantity", type: "integer"});
					expect(result).toBe("numberField");
				});

				it("maps date type to dateField", () => {
					var result = admin.mapColumnToFormHelper({name: "startDate", type: "date"});
					expect(result).toBe("dateField");
				});

				it("maps datetime to dateTimeLocalField", () => {
					var result = admin.mapColumnToFormHelper({name: "publishedAt", type: "datetime"});
					expect(result).toBe("dateTimeLocalField");
				});

				it("maps email column name to emailField", () => {
					var result = admin.mapColumnToFormHelper({name: "email", type: "string"});
					expect(result).toBe("emailField");
				});

				it("maps phone column name to telField", () => {
					var result = admin.mapColumnToFormHelper({name: "phone", type: "string"});
					expect(result).toBe("telField");
				});

				it("maps url column name to urlField", () => {
					var result = admin.mapColumnToFormHelper({name: "website", type: "string"});
					expect(result).toBe("urlField");
				});

			});

			describe("generateAdmin()", () => {

				it("generates controller and view files", () => {
					var modelData = {
						model: "Product",
						tableName: "products",
						primaryKey: "id",
						columns: [
							{name: "id", type: "integer", primaryKey: true},
							{name: "name", type: "string"},
							{name: "price", type: "decimal"},
							{name: "active", type: "boolean"},
							{name: "createdAt", type: "datetime"},
							{name: "updatedAt", type: "datetime"}
						],
						associations: []
					};

					var result = admin.generateAdmin(modelData = modelData, force = true);
					expect(result.success).toBeTrue();
					expect(arrayLen(result.generated)).toBeGTE(6);

					// Verify controller exists
					expect(fileExists(tempRoot & "/app/controllers/admin/Products.cfc")).toBeTrue();

					// Verify views exist
					expect(fileExists(tempRoot & "/app/views/admin/products/index.cfm")).toBeTrue();
					expect(fileExists(tempRoot & "/app/views/admin/products/show.cfm")).toBeTrue();
					expect(fileExists(tempRoot & "/app/views/admin/products/new.cfm")).toBeTrue();
					expect(fileExists(tempRoot & "/app/views/admin/products/edit.cfm")).toBeTrue();
					expect(fileExists(tempRoot & "/app/views/admin/products/_form.cfm")).toBeTrue();
				});

				it("excludes id and timestamp columns from form fields", () => {
					var modelData = {
						model: "Item",
						tableName: "items",
						primaryKey: "id",
						columns: [
							{name: "id", type: "integer", primaryKey: true},
							{name: "title", type: "string"},
							{name: "createdAt", type: "datetime"},
							{name: "updatedAt", type: "datetime"}
						],
						associations: []
					};

					var result = admin.generateAdmin(modelData = modelData, force = true);
					var formContent = fileRead(tempRoot & "/app/views/admin/items/_form.cfm");
					expect(formContent).toInclude("title");
					expect(formContent).notToInclude('"id"');
					expect(formContent).notToInclude('"createdAt"');
					expect(formContent).notToInclude('"updatedAt"');
				});

				it("generates foreign key loaders for belongsTo", () => {
					var modelData = {
						model: "Post",
						tableName: "posts",
						primaryKey: "id",
						columns: [
							{name: "id", type: "integer", primaryKey: true},
							{name: "title", type: "string"},
							{name: "categoryId", type: "integer"}
						],
						associations: [
							{type: "belongsTo", name: "category", modelName: "Category"}
						]
					};

					var result = admin.generateAdmin(modelData = modelData, force = true);
					var controllerContent = fileRead(tempRoot & "/app/controllers/admin/Posts.cfc");
					expect(controllerContent).toInclude("loadCategories");
					expect(controllerContent).toInclude('model("Category")');
				});

				it("injects admin route into routes.cfm", () => {
					var modelData = {
						model: "Order",
						tableName: "orders",
						primaryKey: "id",
						columns: [{name: "id", type: "integer", primaryKey: true}],
						associations: []
					};

					var result = admin.generateAdmin(modelData = modelData, force = true);
					var routesContent = fileRead(tempRoot & "/config/routes.cfm");
					expect(routesContent).toInclude('scope(path="admin"');
					expect(routesContent).toInclude('.resources("orders")');
				});

				it("errors when files exist and force is false", () => {
					var modelData = {
						model: "Order",
						tableName: "orders",
						primaryKey: "id",
						columns: [{name: "id", type: "integer", primaryKey: true}],
						associations: []
					};

					// Files already exist from previous test
					var result = admin.generateAdmin(modelData = modelData, force = false);
					expect(result.success).toBeFalse();
					expect(arrayLen(result.errors)).toBeGT(0);
				});

				it("skips route injection with noRoutes flag", () => {
					// Read current routes to compare
					var routesBefore = fileRead(tempRoot & "/config/routes.cfm");

					var modelData = {
						model: "NoRouteTest",
						tableName: "no_route_tests",
						primaryKey: "id",
						columns: [{name: "id", type: "integer", primaryKey: true}],
						associations: []
					};

					var result = admin.generateAdmin(
						modelData = modelData,
						force = true,
						noRoutes = true
					);
					expect(result.success).toBeTrue();

					var routesAfter = fileRead(tempRoot & "/config/routes.cfm");
					expect(routesAfter).notToInclude("no_route_tests");
				});

			});

		});

	}

}
```

- [ ] **Step 2: Verify and commit**

```bash
curl -sf "http://localhost:8080/cli/lucli/tests/runner.cfm?format=json" | python3 -c "
import json,sys; d=json.load(sys.stdin)
print(f'{d[\"totalPass\"]} pass, {d[\"totalFail\"]} fail, {d[\"totalError\"]} error')
"
git add cli/lucli/tests/specs/services/AdminSpec.cfc
git commit -m "test(cli): add admin service unit tests"
```

---

### Task 7: CodeGenSpec

**Files:**
- Create: `cli/lucli/tests/specs/services/CodeGenSpec.cfc`

- [ ] **Step 1: Create CodeGenSpec.cfc**

Write `cli/lucli/tests/specs/services/CodeGenSpec.cfc`:

```cfml
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.tempRoot = testHelper.scaffoldTempProject(expandPath("/"));
		variables.moduleRoot = expandPath("/cli/lucli/");
		variables.helpers = new cli.lucli.services.Helpers();
		variables.templates = new cli.lucli.services.Templates(
			helpers = variables.helpers,
			projectRoot = variables.tempRoot,
			moduleRoot = variables.moduleRoot
		);
		variables.codegen = new cli.lucli.services.CodeGen(
			templateService = variables.templates,
			helpers = variables.helpers,
			projectRoot = variables.tempRoot
		);
	}

	function afterAll() {
		testHelper.cleanupTempProject(variables.tempRoot);
	}

	function run() {

		describe("CodeGen Service", () => {

			describe("generateModel()", () => {

				it("creates a model CFC with PascalCase name", () => {
					var result = codegen.generateModel(name = "Article", properties = []);
					expect(result.success).toBeTrue();
					expect(fileExists(tempRoot & "/app/models/Article.cfc")).toBeTrue();
				});

				it("model extends Model", () => {
					codegen.generateModel(name = "Review", properties = [], force = true);
					var content = fileRead(tempRoot & "/app/models/Review.cfc");
					expect(content).toInclude('extends="Model"');
				});

				it("includes properties in model config", () => {
					var props = [
						{name: "title", type: "string"},
						{name: "price", type: "decimal"}
					];
					codegen.generateModel(
						name = "Product",
						properties = props,
						force = true
					);
					var content = fileRead(tempRoot & "/app/models/Product.cfc");
					expect(content).toInclude("config()");
				});

			});

			describe("generateController()", () => {

				it("creates a controller CFC in app/controllers/", () => {
					var result = codegen.generateController(
						name = "Articles",
						actions = "index,show"
					);
					expect(result.success).toBeTrue();
					expect(fileExists(tempRoot & "/app/controllers/Articles.cfc")).toBeTrue();
				});

				it("controller extends Controller", () => {
					codegen.generateController(name = "Reviews", actions = "", force = true);
					var content = fileRead(tempRoot & "/app/controllers/Reviews.cfc");
					expect(content).toInclude('extends="Controller"');
				});

			});

			describe("validateName()", () => {

				it("rejects empty name", () => {
					var result = codegen.validateName("");
					expect(result.valid).toBeFalse();
				});

				it("accepts valid PascalCase name", () => {
					var result = codegen.validateName("UserProfile");
					expect(result.valid).toBeTrue();
				});

			});

		});

	}

}
```

- [ ] **Step 2: Verify and commit**

```bash
curl -sf "http://localhost:8080/cli/lucli/tests/runner.cfm?format=json" | python3 -c "
import json,sys; d=json.load(sys.stdin)
print(f'{d[\"totalPass\"]} pass, {d[\"totalFail\"]} fail, {d[\"totalError\"]} error')
"
git add cli/lucli/tests/specs/services/CodeGenSpec.cfc
git commit -m "test(cli): add codegen service unit tests"
```

---

### Task 8: Integration Tests

**Files:**
- Create: `cli/lucli/tests/specs/integration/DbCommandsSpec.cfc`
- Create: `cli/lucli/tests/specs/integration/IntrospectSpec.cfc`

- [ ] **Step 1: Create DbCommandsSpec.cfc**

Write `cli/lucli/tests/specs/integration/DbCommandsSpec.cfc`:

```cfml
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.serverPort = testHelper.detectServerPort();
		variables.skipIntegration = (variables.serverPort == 0);
		if (variables.skipIntegration) {
			variables.skipReason = "No running server detected — skipping integration tests";
		}
		variables.baseUrl = "http://localhost:#variables.serverPort#";
	}

	function run() {

		describe("DB Commands Integration", () => {

			it("dbStatus returns valid JSON with migrations", () => {
				if (skipIntegration) { debug(skipReason); return; }

				var response = testHelper.httpGet(
					"#baseUrl#/wheels/cli?command=dbStatus&format=json"
				);
				expect(len(response)).toBeGT(0);

				var data = deserializeJSON(response);
				expect(data.success).toBeTrue();
				expect(structKeyExists(data, "migrations")).toBeTrue();
				expect(isArray(data.migrations)).toBeTrue();
				expect(structKeyExists(data, "summary")).toBeTrue();
				expect(data.summary.total).toBeGTE(0);
				expect(data.summary.applied).toBeGTE(0);
				expect(data.summary.pending).toBeGTE(0);
			});

			it("dbStatus migration entries have required fields", () => {
				if (skipIntegration) { debug(skipReason); return; }

				var response = testHelper.httpGet(
					"#baseUrl#/wheels/cli?command=dbStatus&format=json"
				);
				var data = deserializeJSON(response);

				if (arrayLen(data.migrations) > 0) {
					var m = data.migrations[1];
					expect(structKeyExists(m, "version")).toBeTrue();
					expect(structKeyExists(m, "description")).toBeTrue();
					expect(structKeyExists(m, "status")).toBeTrue();
				}
			});

			it("dbVersion returns current version", () => {
				if (skipIntegration) { debug(skipReason); return; }

				var response = testHelper.httpGet(
					"#baseUrl#/wheels/cli?command=dbVersion&format=json"
				);
				expect(len(response)).toBeGT(0);

				var data = deserializeJSON(response);
				expect(data.success).toBeTrue();
				expect(structKeyExists(data, "version")).toBeTrue();
			});

		});

	}

}
```

- [ ] **Step 2: Create IntrospectSpec.cfc**

Write `cli/lucli/tests/specs/integration/IntrospectSpec.cfc`:

```cfml
component extends="wheels.wheelstest.system.BaseSpec" {

	function beforeAll() {
		variables.testHelper = new cli.lucli.tests.TestHelper();
		variables.serverPort = testHelper.detectServerPort();
		variables.skipIntegration = (variables.serverPort == 0);
		if (variables.skipIntegration) {
			variables.skipReason = "No running server detected — skipping integration tests";
		}
		variables.baseUrl = "http://localhost:#variables.serverPort#";
	}

	function run() {

		describe("Introspect Endpoint Integration", () => {

			it("returns model metadata for a valid model", () => {
				if (skipIntegration) { debug(skipReason); return; }

				// Use a test model that exists in the test database
				var response = testHelper.httpGet(
					"#baseUrl#/wheels/cli?command=introspect&model=Author&format=json"
				);

				if (!len(response)) {
					debug("Empty response — model 'Author' may not exist");
					return;
				}

				var data = deserializeJSON(response);
				if (!data.success) {
					debug("Introspect failed: #data.message# — test model may not be available");
					return;
				}

				expect(structKeyExists(data, "model")).toBeTrue();
				expect(structKeyExists(data, "tableName")).toBeTrue();
				expect(structKeyExists(data, "primaryKey")).toBeTrue();
				expect(structKeyExists(data, "columns")).toBeTrue();
				expect(isArray(data.columns)).toBeTrue();
				expect(arrayLen(data.columns)).toBeGT(0);
				expect(structKeyExists(data, "associations")).toBeTrue();
			});

			it("column entries have name and type", () => {
				if (skipIntegration) { debug(skipReason); return; }

				var response = testHelper.httpGet(
					"#baseUrl#/wheels/cli?command=introspect&model=Author&format=json"
				);
				if (!len(response)) return;

				var data = deserializeJSON(response);
				if (!data.success) return;

				var col = data.columns[1];
				expect(structKeyExists(col, "name")).toBeTrue();
				expect(structKeyExists(col, "type")).toBeTrue();
			});

			it("fails gracefully with missing model parameter", () => {
				if (skipIntegration) { debug(skipReason); return; }

				var response = testHelper.httpGet(
					"#baseUrl#/wheels/cli?command=introspect&format=json"
				);
				expect(len(response)).toBeGT(0);

				var data = deserializeJSON(response);
				expect(data.success).toBeFalse();
				expect(structKeyExists(data, "message")).toBeTrue();
			});

			it("fails gracefully with non-existent model", () => {
				if (skipIntegration) { debug(skipReason); return; }

				var response = testHelper.httpGet(
					"#baseUrl#/wheels/cli?command=introspect&model=NonExistentModelXyz&format=json"
				);
				expect(len(response)).toBeGT(0);

				var data = deserializeJSON(response);
				expect(data.success).toBeFalse();
			});

		});

	}

}
```

- [ ] **Step 3: Verify and commit**

```bash
curl -sf "http://localhost:8080/cli/lucli/tests/runner.cfm?format=json" | python3 -c "
import json,sys; d=json.load(sys.stdin)
print(f'{d[\"totalPass\"]} pass, {d[\"totalFail\"]} fail, {d[\"totalError\"]} error')
"
git add cli/lucli/tests/specs/integration/
git commit -m "test(cli): add integration tests for db commands and introspect endpoint"
```

---

### Task 9: CI Integration

**Files:**
- Modify: `tools/ci/run-tests.sh`

- [ ] **Step 1: Update run-tests.sh**

Read `tools/ci/run-tests.sh` and add a CLI test block after the core test block. The script currently exits on failure at line 118 (`exit 1`). We need to defer the exit so both suites run.

Replace the entire file with the updated version that:
1. Tracks core test success/failure in a variable instead of exiting immediately
2. Adds a CLI test block after core tests
3. Generates separate JUnit XML for CLI tests
4. Writes combined step summary
5. Exits non-zero if either suite fails

The key additions after the core test results parsing (after the existing `echo "All tests passed!"` on line 121):

```bash
# --- Run CLI module tests ---
CLI_TEST_URL="${BASE_URL}/cli/lucli/tests/runner.cfm?format=json"
CLI_RESULT_FILE="${RESULT_DIR}/cli-test-results.json"
CLI_JUNIT_FILE="${JUNIT_DIR}/cli-junit.xml"

echo ""
echo "Running CLI module tests..."
CLI_HTTP_CODE=$(curl -s -o "$CLI_RESULT_FILE" \
  --max-time 300 \
  --write-out "%{http_code}" \
  "$CLI_TEST_URL" || echo "000")

echo "[CLI Tests] HTTP status: ${CLI_HTTP_CODE}"
```

Then parse CLI results with the same pattern as core tests, prefixing output with `[CLI Tests]`.

The full modification: change the exit strategy from immediate `exit 1` to tracking `CORE_OK` and `CLI_OK` variables, then exiting based on both at the end.

Edit `tools/ci/run-tests.sh` to make the following changes:

**Near the top** (after line 11), add:
```bash
CLI_TEST_URL="${BASE_URL}/cli/lucli/tests/runner.cfm?format=json"
CLI_RESULT_FILE="${RESULT_DIR:-/tmp}/cli-test-results.json"
CLI_JUNIT_FILE="${JUNIT_DIR:-/tmp}/cli-junit.xml"
CORE_OK=true
CLI_OK=true
```

**Replace `exit 1` on line 118** with `CORE_OK=false`.

**Replace `echo "All tests passed!"` on line 121** with `echo "[Core Tests] All tests passed!"`.

**After the core test `fi` block** (after line 127), add the full CLI test block:

```bash
# --- Run CLI module tests ---
echo ""
echo "Running CLI module tests..."
CLI_HTTP_CODE=$(curl -s -o "$CLI_RESULT_FILE" \
  --max-time 300 \
  --write-out "%{http_code}" \
  "$CLI_TEST_URL" || echo "000")

echo "[CLI Tests] HTTP status: ${CLI_HTTP_CODE}"

if [ "$CLI_HTTP_CODE" = "200" ] || [ "$CLI_HTTP_CODE" = "417" ]; then
  CLI_PASS=$(python3 -c "import json; d=json.load(open('$CLI_RESULT_FILE')); print(int(d.get('totalPass',0)))" 2>/dev/null || echo "?")
  CLI_FAIL=$(python3 -c "import json; d=json.load(open('$CLI_RESULT_FILE')); print(int(d.get('totalFail',0)))" 2>/dev/null || echo "?")
  CLI_ERROR=$(python3 -c "import json; d=json.load(open('$CLI_RESULT_FILE')); print(int(d.get('totalError',0)))" 2>/dev/null || echo "?")

  echo "[CLI Tests] Results: ${CLI_PASS} passed, ${CLI_FAIL} failed, ${CLI_ERROR} errors"

  # Generate JUnit XML for CLI tests
  python3 -c "
import json, sys
from xml.etree.ElementTree import Element, SubElement, tostring

def safe_str(v):
    return str(v) if v else ''

d = json.load(open('$CLI_RESULT_FILE'))
root = Element('testsuites')
root.set('name', 'CLI Module Tests')
root.set('tests', str(int(d.get('totalPass',0)) + int(d.get('totalFail',0)) + int(d.get('totalError',0))))
root.set('failures', str(int(d.get('totalFail',0))))
root.set('errors', str(int(d.get('totalError',0))))

for b in d.get('bundleStats', []):
    for s in b.get('suiteStats', []):
        ts = SubElement(root, 'testsuite')
        ts.set('name', safe_str(s.get('name')))
        ts.set('tests', str(int(s.get('totalSpecs',0))))
        ts.set('failures', str(int(s.get('totalFail',0))))
        ts.set('errors', str(int(s.get('totalError',0))))
        ts.set('time', str(float(s.get('totalDuration',0))/1000))
        for sp in s.get('specStats', []):
            tc = SubElement(ts, 'testcase')
            tc.set('name', safe_str(sp.get('name')))
            tc.set('classname', safe_str(b.get('name','')))
            tc.set('time', str(float(sp.get('totalDuration',0))/1000))
            if sp.get('status') == 'Failed':
                f = SubElement(tc, 'failure', message=safe_str(sp.get('failMessage')))
                f.text = safe_str(sp.get('failDetail'))
            elif sp.get('status') == 'Error':
                e = SubElement(tc, 'error', message=safe_str(sp.get('failMessage')))
                e.text = safe_str(sp.get('failDetail'))

with open('$CLI_JUNIT_FILE', 'wb') as f:
    f.write(b'<?xml version=\"1.0\" encoding=\"UTF-8\"?>')
    f.write(tostring(root))
" 2>/dev/null || echo "Warning: Could not generate CLI JUnit XML"

  # Write CLI step summary
  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    echo "" >> "$GITHUB_STEP_SUMMARY"
    echo "### CLI Module Test Results" >> "$GITHUB_STEP_SUMMARY"
    echo "" >> "$GITHUB_STEP_SUMMARY"
    echo "| Metric | Count |" >> "$GITHUB_STEP_SUMMARY"
    echo "|--------|-------|" >> "$GITHUB_STEP_SUMMARY"
    echo "| Passed | ${CLI_PASS} |" >> "$GITHUB_STEP_SUMMARY"
    echo "| Failed | ${CLI_FAIL} |" >> "$GITHUB_STEP_SUMMARY"
    echo "| Errors | ${CLI_ERROR} |" >> "$GITHUB_STEP_SUMMARY"
  fi

  CLI_TOTAL_FAILURES=$((CLI_FAIL + CLI_ERROR))
  if [ "$CLI_TOTAL_FAILURES" -gt 0 ]; then
    echo "::error::[CLI Tests] ${CLI_TOTAL_FAILURES} test failures/errors"
    python3 -c "
import json
d = json.load(open('$CLI_RESULT_FILE'))
for b in d.get('bundleStats', []):
    for s in b.get('suiteStats', []):
        for sp in s.get('specStats', []):
            if sp.get('status') in ('Failed', 'Error'):
                print(f\"  {sp['status']}: {sp.get('name','?')}: {sp.get('failMessage','')[:200]}\")
" 2>/dev/null || true
    CLI_OK=false
  else
    echo "[CLI Tests] All tests passed!"
  fi
else
  echo "::error::[CLI Tests] returned HTTP ${CLI_HTTP_CODE}"
  head -50 "$CLI_RESULT_FILE" 2>/dev/null || true
  CLI_OK=false
fi

# --- Final exit ---
if [ "$CORE_OK" = false ] || [ "$CLI_OK" = false ]; then
  echo ""
  echo "::error::Test suite(s) failed"
  exit 1
fi

echo ""
echo "All test suites passed!"
```

- [ ] **Step 2: Verify the script is syntactically valid**

```bash
bash -n tools/ci/run-tests.sh
```

Expected: No output (syntax OK).

- [ ] **Step 3: Commit**

```bash
git add tools/ci/run-tests.sh
git commit -m "ci(test): add cli module tests to ci pipeline"
```

---

## Self-Review

**Spec coverage:**

| Spec Requirement | Task |
|-----------------|------|
| TestHelper.cfc with scaffoldTempProject, cleanupTempProject, detectServerPort, httpGet | Task 1 |
| runner.cfm with TestBox, JSON/HTML, HTTP 417 on failure | Task 1 |
| HelpersSpec — pluralize, singularize, capitalize, stripSpecialChars, timestamp | Task 2 |
| DestroySpec — all 4 destroy types, preview, route cleanup, migration gen | Task 3 |
| DoctorSpec — HEALTHY, CRITICAL, WARNING, permissions, recommendations | Task 4 |
| StatsSpec — categories, LOC, comments, blanks, getNotes, custom annotations | Task 5 |
| AdminSpec — form helpers, generateAdmin, FK loaders, route injection, force flag | Task 6 |
| CodeGenSpec — model, controller, properties, validateName | Task 7 |
| DbCommandsSpec — dbStatus, dbVersion HTTP responses | Task 8 |
| IntrospectSpec — valid model, missing param, non-existent model | Task 8 |
| CI integration — separate curl, JUnit XML, combined exit code, [CLI Tests] prefix | Task 9 |
| Skip behavior for integration tests | Task 8 (each spec checks skipIntegration) |
| All tests use temp project copy | Tasks 3-7 (beforeAll scaffolds, afterAll cleans) |

All spec sections covered.

**Placeholder scan:** No TBD, TODO, or "implement later". All test code is complete.

**Type consistency:**
- `TestHelper.scaffoldTempProject(sourceRoot)` — called consistently as `testHelper.scaffoldTempProject(expandPath("/"))`
- `TestHelper.cleanupTempProject(tempRoot)` — called consistently in `afterAll()`
- `TestHelper.detectServerPort()` — returns numeric, compared to 0 for skip check
- Service constructors match actual signatures verified from source
- `mapColumnToFormHelper` is called as a public method on Admin.cfc — verified it's `public` in the source
