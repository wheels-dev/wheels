# CLI Tier 1 Porting Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port 8 high-value CLI commands from the CommandBox CLI to the LuCLI module, closing the feature gap for developers using `wheels` binary.

**Architecture:** 4 new service CFCs (`Destroy.cfc`, `Doctor.cfc`, `Stats.cfc`, `Admin.cfc`) in `cli/lucli/services/`, thin dispatch functions in `Module.cfc`, 1 new core endpoint in `vendor/wheels/public/views/cli.cfm`. Services follow the existing lazy-singleton pattern via `getService()`.

**Tech Stack:** CFML (Lucee 7), LuCLI module system, Wheels CLI bridge (`/wheels/cli?command=...`)

**Spec:** `docs/superpowers/specs/2026-04-11-cli-tier1-porting-design.md`

---

## File Structure

### New files to create:
- `cli/lucli/services/Destroy.cfc` — File deletion, route cleanup, migration generation
- `cli/lucli/services/Doctor.cfc` — Health checks (dirs, files, config, permissions, DB)
- `cli/lucli/services/Stats.cfc` — Code statistics + notes/annotation extraction
- `cli/lucli/services/Admin.cfc` — Admin CRUD generation via server introspection
- `cli/lucli/templates/admin/controller.txt` — Admin controller template
- `cli/lucli/templates/admin/index.txt` — Admin index view template
- `cli/lucli/templates/admin/show.txt` — Admin show view template
- `cli/lucli/templates/admin/new.txt` — Admin new view template
- `cli/lucli/templates/admin/edit.txt` — Admin edit view template
- `cli/lucli/templates/admin/_form.txt` — Admin form partial template
- `cli/lucli/templates/migrations/remove_table.txt` — Drop table migration template

### Existing files to modify:
- `cli/lucli/Module.cfc` — Add 8 public dispatch functions + `getService()` cases
- `vendor/wheels/public/views/cli.cfm` — Add `introspect` command handler
- `cli/lucli/services/MCP.cfc` — Add tool schemas for new commands

---

### Task 1: Destroy Service

**Files:**
- Create: `cli/lucli/services/Destroy.cfc`
- Create: `cli/lucli/templates/migrations/remove_table.txt`
- Modify: `cli/lucli/Module.cfc`

- [ ] **Step 1: Create the remove_table migration template**

```bash
mkdir -p cli/lucli/templates/migrations
```

Write `cli/lucli/templates/migrations/remove_table.txt`:

```
component extends="wheels.migrator.Migration" hint="Migration: {{className}}" {

	function up() {
		transaction {
			try {
				dropTable(tableName="{{tableName}}");
			} catch (any e) {
				local.exception = e;
			}
			if (StructKeyExists(local, "exception")) {
				transaction action="rollback";
				throw(object=local.exception);
			}
		}
	}

	function down() {
		transaction {
			try {
				// Re-create the table manually if needed
				// t = createTable(name="{{tableName}}", force="false");
				// t.timestamps();
				// t.create();
			} catch (any e) {
				local.exception = e;
			}
			if (StructKeyExists(local, "exception")) {
				transaction action="rollback";
				throw(object=local.exception);
			}
		}
	}

}
```

- [ ] **Step 2: Create Destroy.cfc**

Write `cli/lucli/services/Destroy.cfc`:

```cfml
/**
 * Service for destroying (removing) generated Wheels components.
 *
 * Handles file deletion, route cleanup, and migration generation
 * for resource, model, controller, and view destruction.
 */
component {

	public function init(
		required any helpers,
		required string projectRoot,
		required string moduleRoot
	) {
		variables.helpers = arguments.helpers;
		variables.projectRoot = arguments.projectRoot;
		variables.moduleRoot = arguments.moduleRoot;
		return this;
	}

	/**
	 * Destroy a complete resource (model + controller + views + tests + route + migration)
	 */
	public struct function destroyResource(required string name) {
		var result = {success: true, deleted: [], warnings: [], migrationPath: ""};
		var names = getNameVariants(arguments.name);

		// Model
		deleteFileIfExists(
			variables.projectRoot & "/app/models/" & names.singularCap & ".cfc",
			result
		);

		// Controller
		deleteFileIfExists(
			variables.projectRoot & "/app/controllers/" & names.pluralCap & ".cfc",
			result
		);

		// Views directory
		deleteDirIfExists(
			variables.projectRoot & "/app/views/" & names.plural,
			result
		);

		// Model test
		deleteFileIfExists(
			variables.projectRoot & "/tests/specs/models/" & names.singularCap & "Spec.cfc",
			result
		);

		// Controller test
		deleteFileIfExists(
			variables.projectRoot & "/tests/specs/controllers/" & names.pluralCap & "Spec.cfc",
			result
		);

		// View tests directory
		deleteDirIfExists(
			variables.projectRoot & "/tests/specs/views/" & names.plural,
			result
		);

		// Route cleanup
		removeRoute(names.plural, result);

		// Generate drop-table migration
		result.migrationPath = generateRemoveTableMigration(names.plural);

		return result;
	}

	/**
	 * Destroy a model and its test, generate drop-table migration
	 */
	public struct function destroyModel(required string name) {
		var result = {success: true, deleted: [], warnings: [], migrationPath: ""};
		var names = getNameVariants(arguments.name);

		deleteFileIfExists(
			variables.projectRoot & "/app/models/" & names.singularCap & ".cfc",
			result
		);
		deleteFileIfExists(
			variables.projectRoot & "/tests/specs/models/" & names.singularCap & "Spec.cfc",
			result
		);

		result.migrationPath = generateRemoveTableMigration(names.plural);

		return result;
	}

	/**
	 * Destroy a controller and its test
	 */
	public struct function destroyController(required string name) {
		var result = {success: true, deleted: [], warnings: []};
		var names = getNameVariants(arguments.name);

		deleteFileIfExists(
			variables.projectRoot & "/app/controllers/" & names.pluralCap & ".cfc",
			result
		);
		deleteFileIfExists(
			variables.projectRoot & "/tests/specs/controllers/" & names.pluralCap & "Spec.cfc",
			result
		);

		return result;
	}

	/**
	 * Destroy views — either a whole directory or a single file
	 * If name contains "/", treat as controller/view (single file).
	 * Otherwise, delete the entire views directory + test directory.
	 */
	public struct function destroyView(required string name) {
		var result = {success: true, deleted: [], warnings: []};

		if (find("/", arguments.name)) {
			// Single view file: "products/index"
			var parts = listToArray(arguments.name, "/");
			if (arrayLen(parts) != 2 || !len(parts[1]) || !len(parts[2])) {
				result.success = false;
				result.warnings = ["Invalid view path. Use: controller/viewname (e.g., products/index)"];
				return result;
			}
			var viewPath = variables.projectRoot & "/app/views/" & parts[1] & "/" & parts[2] & ".cfm";
			deleteFileIfExists(viewPath, result);
		} else {
			// Entire view directory
			var names = getNameVariants(arguments.name);
			deleteDirIfExists(
				variables.projectRoot & "/app/views/" & names.plural,
				result
			);
			deleteDirIfExists(
				variables.projectRoot & "/tests/specs/views/" & names.plural,
				result
			);
		}

		return result;
	}

	/**
	 * Build the list of files/dirs that would be deleted (for confirmation display)
	 */
	public array function previewDestroy(required string name, required string type) {
		var preview = [];
		var names = getNameVariants(arguments.name);

		switch (arguments.type) {
			case "resource":
				arrayAppend(preview, "app/models/" & names.singularCap & ".cfc");
				arrayAppend(preview, "app/controllers/" & names.pluralCap & ".cfc");
				arrayAppend(preview, "app/views/" & names.plural & "/");
				arrayAppend(preview, "tests/specs/models/" & names.singularCap & "Spec.cfc");
				arrayAppend(preview, "tests/specs/controllers/" & names.pluralCap & "Spec.cfc");
				arrayAppend(preview, "tests/specs/views/" & names.plural & "/");
				arrayAppend(preview, 'Route: .resources("' & names.plural & '") from config/routes.cfm');
				arrayAppend(preview, "Migration: drop table " & names.plural);
				break;
			case "model":
				arrayAppend(preview, "app/models/" & names.singularCap & ".cfc");
				arrayAppend(preview, "tests/specs/models/" & names.singularCap & "Spec.cfc");
				arrayAppend(preview, "Migration: drop table " & names.plural);
				break;
			case "controller":
				arrayAppend(preview, "app/controllers/" & names.pluralCap & ".cfc");
				arrayAppend(preview, "tests/specs/controllers/" & names.pluralCap & "Spec.cfc");
				break;
			case "view":
				if (find("/", arguments.name)) {
					var parts = listToArray(arguments.name, "/");
					arrayAppend(preview, "app/views/" & parts[1] & "/" & parts[2] & ".cfm");
				} else {
					arrayAppend(preview, "app/views/" & names.plural & "/");
					arrayAppend(preview, "tests/specs/views/" & names.plural & "/");
				}
				break;
		}

		return preview;
	}

	// ── Private helpers ──────────────────────────────────────

	private struct function getNameVariants(required string name) {
		var clean = variables.helpers.stripSpecialChars(trim(arguments.name));
		var singular = variables.helpers.singularize(lCase(clean));
		var plural = variables.helpers.pluralize(lCase(clean));
		return {
			singular: singular,
			plural: plural,
			singularCap: variables.helpers.capitalize(singular),
			pluralCap: variables.helpers.capitalize(plural)
		};
	}

	private void function deleteFileIfExists(required string path, required struct result) {
		if (fileExists(arguments.path)) {
			fileDelete(arguments.path);
			arrayAppend(arguments.result.deleted, arguments.path);
		} else {
			arrayAppend(arguments.result.warnings, "Not found: " & arguments.path);
		}
	}

	private void function deleteDirIfExists(required string path, required struct result) {
		if (directoryExists(arguments.path)) {
			directoryDelete(arguments.path, true);
			arrayAppend(arguments.result.deleted, arguments.path & "/");
		} else {
			arrayAppend(arguments.result.warnings, "Not found: " & arguments.path & "/");
		}
	}

	private void function removeRoute(required string pluralName, required struct result) {
		var routesPath = variables.projectRoot & "/config/routes.cfm";
		if (!fileExists(routesPath)) {
			arrayAppend(arguments.result.warnings, "config/routes.cfm not found");
			return;
		}

		var content = fileRead(routesPath);
		var nl = chr(10);
		var pattern = '.resources("' & arguments.pluralName & '")';

		if (!findNoCase(pattern, content)) {
			arrayAppend(arguments.result.warnings, "Route not found: " & pattern);
			return;
		}

		// Remove the line containing the resource route
		var lines = listToArray(content, nl, true);
		var filtered = [];
		for (var line in lines) {
			if (!findNoCase(pattern, line)) {
				arrayAppend(filtered, line);
			}
		}
		fileWrite(routesPath, arrayToList(filtered, nl));
		arrayAppend(arguments.result.deleted, "Route: " & pattern);
	}

	private string function generateRemoveTableMigration(required string tableName) {
		var timestamp = variables.helpers.generateMigrationTimestamp();
		var className = "remove_" & arguments.tableName & "_table";
		var fileName = timestamp & "_" & className & ".cfc";
		var migrationDir = variables.projectRoot & "/app/migrator/migrations";

		if (!directoryExists(migrationDir)) {
			directoryCreate(migrationDir, true);
		}

		// Read template and substitute
		var templatePath = variables.moduleRoot & "templates/migrations/remove_table.txt";
		var content = fileRead(templatePath);
		content = replaceNoCase(content, "{{className}}", className, "all");
		content = replaceNoCase(content, "{{tableName}}", arguments.tableName, "all");

		var migrationPath = migrationDir & "/" & fileName;
		fileWrite(migrationPath, content);
		return migrationPath;
	}

}
```

- [ ] **Step 3: Add destroy() dispatch to Module.cfc**

Add the public function and `getService("destroy")` case.

In Module.cfc, add after the last public command function (before the private helpers section):

```cfml
// ─────────────────────────────────────────────────
//  destroy — Remove generated components
// ─────────────────────────────────────────────────

/**
 * hint: Remove generated components (resource, model, controller, view)
 */
public string function destroy() {
	var args = __arguments ?: [];

	if (!arrayLen(args)) {
		out("Usage: wheels destroy <name> [type]", "yellow");
		out("");
		out("Types:", "bold");
		out("  resource    Remove model + controller + views + tests + route + migration (default)");
		out("  model       Remove model + test + generate drop-table migration");
		out("  controller  Remove controller + test");
		out("  view        Remove view directory (or single file with controller/view syntax)");
		out("");
		out("Examples:", "bold");
		out("  wheels destroy User");
		out("  wheels destroy Products controller");
		out("  wheels destroy Product model");
		out("  wheels destroy products/index view");
		return "";
	}

	var name = trim(args[1]);
	var type = arrayLen(args) > 1 ? lCase(trim(args[2])) : "resource";
	var force = false;
	for (var i = 1; i <= arrayLen(args); i++) {
		if (args[i] == "--force") force = true;
	}

	if (!listFindNoCase("resource,model,controller,view", type)) {
		out("Unknown type: #type#. Valid types: resource, model, controller, view", "red");
		return "";
	}

	var svc = getService("destroy");

	// Show preview and confirm
	var preview = svc.previewDestroy(name, type);
	if (!arrayLen(preview)) {
		out("Nothing to destroy.", "yellow");
		return "";
	}

	out("The following will be deleted:", "yellow");
	for (var item in preview) {
		out("  #item#");
	}
	out("");

	if (!force) {
		out("Proceed? [y/n] ", "yellow");
		// In LuCLI module context, we can't do interactive prompts.
		// The --force flag is required for non-interactive use.
		// For interactive use, LuCLI provides prompt support via the module system.
		var answer = prompt("Proceed? [y/n]: ");
		if (lCase(left(trim(answer), 1)) != "y") {
			out("Cancelled.", "red");
			return "";
		}
	}

	var result = {};
	switch (type) {
		case "resource":
			result = svc.destroyResource(name);
			break;
		case "model":
			result = svc.destroyModel(name);
			break;
		case "controller":
			result = svc.destroyController(name);
			break;
		case "view":
			result = svc.destroyView(name);
			break;
	}

	// Output results
	for (var deleted in result.deleted) {
		out("  delete  #deleted#", "red");
	}
	for (var warning in result.warnings) {
		out("  skip    #warning#", "yellow");
	}
	if (structKeyExists(result, "migrationPath") && len(result.migrationPath)) {
		out("");
		out("Migration generated: #result.migrationPath#", "cyan");
		out("Run 'wheels migrate latest' to apply.", "cyan");
	}
	return "";
}
```

In `getService()` switch, add before the `default` case:

```cfml
case "destroy":
	variables.services.destroy = new services.Destroy(
		helpers = getService("helpers"),
		projectRoot = variables.projectRoot,
		moduleRoot = variables.moduleRoot
	);
	break;
```

- [ ] **Step 4: Test destroy command**

```bash
# Start server if not running
wheels start

# Generate a test scaffold to destroy
wheels generate scaffold TestDestroy title body:text

# Verify files were created
ls app/models/TestDestroy.cfc
ls app/controllers/TestDestroys.cfc
ls app/views/testdestroys/

# Destroy it
wheels destroy TestDestroy --force

# Verify files are gone
ls app/models/TestDestroy.cfc 2>&1      # should not exist
ls app/controllers/TestDestroys.cfc 2>&1 # should not exist
ls app/views/testdestroys/ 2>&1          # should not exist

# Verify migration was generated
ls app/migrator/migrations/*remove_testdestroys_table*
```

- [ ] **Step 5: Commit**

```bash
git add cli/lucli/services/Destroy.cfc cli/lucli/templates/migrations/remove_table.txt cli/lucli/Module.cfc
git commit -m "feat(cli): add destroy command for removing generated components"
```

---

### Task 2: Doctor Service

**Files:**
- Create: `cli/lucli/services/Doctor.cfc`
- Modify: `cli/lucli/Module.cfc`

- [ ] **Step 1: Create Doctor.cfc**

Write `cli/lucli/services/Doctor.cfc`:

```cfml
/**
 * Health check service for diagnosing Wheels application issues.
 *
 * Performs 7 categories of checks: required dirs, recommended dirs,
 * required files, config validation, write permissions, database config,
 * and test coverage. All checks are local file operations — no running
 * server required.
 */
component {

	public function init(required string projectRoot) {
		variables.projectRoot = arguments.projectRoot;
		return this;
	}

	/**
	 * Run all health checks and return categorized results.
	 */
	public struct function runChecks() {
		var results = {issues: [], warnings: [], passed: []};

		checkRequiredDirs(results);
		checkRecommendedDirs(results);
		checkRequiredFiles(results);
		checkConfigValidation(results);
		checkWritePermissions(results);
		checkDatabaseConfig(results);
		checkTestCoverage(results);

		// Determine overall status
		if (arrayLen(results.issues)) {
			results.status = "CRITICAL";
		} else if (arrayLen(results.warnings)) {
			results.status = "WARNING";
		} else {
			results.status = "HEALTHY";
		}

		// Generate recommendations
		results.recommendations = buildRecommendations(results);

		return results;
	}

	// ── Check functions ──────────────────────────────────────

	private void function checkRequiredDirs(required struct results) {
		var dirs = [
			"app",
			"app/controllers",
			"app/models",
			"app/views",
			"config",
			"public"
		];
		for (var dir in dirs) {
			var fullPath = variables.projectRoot & "/" & dir;
			if (directoryExists(fullPath)) {
				arrayAppend(arguments.results.passed, "Required directory exists: #dir#/");
			} else {
				arrayAppend(arguments.results.issues, "Missing required directory: #dir#/");
			}
		}
	}

	private void function checkRecommendedDirs(required struct results) {
		var dirs = [
			{path: "tests", label: "tests/"},
			{path: "tests/specs", label: "tests/specs/"},
			{path: "app/migrator/migrations", label: "app/migrator/migrations/"}
		];
		for (var dir in dirs) {
			var fullPath = variables.projectRoot & "/" & dir.path;
			if (directoryExists(fullPath)) {
				arrayAppend(arguments.results.passed, "Recommended directory exists: #dir.label#");
			} else {
				arrayAppend(arguments.results.warnings, "Missing recommended directory: #dir.label#");
			}
		}
	}

	private void function checkRequiredFiles(required struct results) {
		var files = [
			"config/routes.cfm",
			"config/settings.cfm"
		];
		for (var f in files) {
			var fullPath = variables.projectRoot & "/" & f;
			if (fileExists(fullPath)) {
				arrayAppend(arguments.results.passed, "Required file exists: #f#");
			} else {
				arrayAppend(arguments.results.issues, "Missing required file: #f#");
			}
		}
	}

	private void function checkConfigValidation(required struct results) {
		// Check routes.cfm has content
		var routesPath = variables.projectRoot & "/config/routes.cfm";
		if (fileExists(routesPath)) {
			var routesContent = fileRead(routesPath);
			if (len(trim(routesContent)) < 10) {
				arrayAppend(arguments.results.warnings, "config/routes.cfm appears empty or minimal");
			} else {
				arrayAppend(arguments.results.passed, "config/routes.cfm has content");
			}
		}

		// Check settings.cfm exists and has content
		var settingsPath = variables.projectRoot & "/config/settings.cfm";
		if (fileExists(settingsPath)) {
			var settingsContent = fileRead(settingsPath);
			if (len(trim(settingsContent)) < 10) {
				arrayAppend(arguments.results.warnings, "config/settings.cfm appears empty or minimal");
			} else {
				arrayAppend(arguments.results.passed, "config/settings.cfm has content");
			}
		}
	}

	private void function checkWritePermissions(required struct results) {
		var dirs = [
			"app/migrator/migrations",
			"public/files"
		];
		for (var dir in dirs) {
			var fullPath = variables.projectRoot & "/" & dir;
			if (!directoryExists(fullPath)) continue;

			var testFile = fullPath & "/.write_test_" & createUUID();
			try {
				fileWrite(testFile, "test");
				fileDelete(testFile);
				arrayAppend(arguments.results.passed, "Write permission OK: #dir#/");
			} catch (any e) {
				arrayAppend(arguments.results.warnings, "No write permission: #dir#/");
			}
		}
	}

	private void function checkDatabaseConfig(required struct results) {
		// Check for datasource in settings.cfm
		var settingsPath = variables.projectRoot & "/config/settings.cfm";
		var envPath = variables.projectRoot & "/.env";
		var foundDatasource = false;

		if (fileExists(settingsPath)) {
			var content = fileRead(settingsPath);
			if (findNoCase("datasource", content) || findNoCase("dataSourceName", content)) {
				foundDatasource = true;
				arrayAppend(arguments.results.passed, "Datasource configured in config/settings.cfm");
			}
		}

		if (!foundDatasource && fileExists(envPath)) {
			var envContent = fileRead(envPath);
			if (reFindNoCase("(DATABASE|DB_)", envContent)) {
				foundDatasource = true;
				arrayAppend(arguments.results.passed, "Database config found in .env");
			}
		}

		if (!foundDatasource) {
			arrayAppend(arguments.results.warnings, "No datasource configuration found");
		}

		// Check for migrations
		var migrationDir = variables.projectRoot & "/app/migrator/migrations";
		if (directoryExists(migrationDir)) {
			var migrations = directoryList(migrationDir, false, "name", "*.cfc");
			if (arrayLen(migrations)) {
				arrayAppend(arguments.results.passed, "#arrayLen(migrations)# migration(s) found");
			} else {
				arrayAppend(arguments.results.warnings, "No migrations found in app/migrator/migrations/");
			}
		}
	}

	private void function checkTestCoverage(required struct results) {
		var testDir = variables.projectRoot & "/tests/specs";
		if (!directoryExists(testDir)) return;

		var testFiles = directoryList(testDir, true, "name", "*.cfc");
		if (arrayLen(testFiles)) {
			arrayAppend(arguments.results.passed, "#arrayLen(testFiles)# test file(s) found");
		} else {
			arrayAppend(arguments.results.warnings, "No test files found in tests/specs/");
		}
	}

	// ── Recommendations ──────────────────────────────────────

	private array function buildRecommendations(required struct results) {
		var recs = [];
		var allMessages = [];
		arrayAppend(allMessages, arguments.results.issues, true);
		arrayAppend(allMessages, arguments.results.warnings, true);
		var combined = arrayToList(allMessages, " ");

		if (findNoCase("datasource", combined) || findNoCase("No datasource", combined)) {
			arrayAppend(recs, "Configure your datasource in config/settings.cfm or .env");
		}
		if (findNoCase("No migrations", combined)) {
			arrayAppend(recs, "Run 'wheels generate migration' to create your first migration");
		}
		if (findNoCase("No test files", combined)) {
			arrayAppend(recs, "Run 'wheels generate test' to add test coverage");
		}
		if (findNoCase("Missing required directory", combined)) {
			arrayAppend(recs, "Run 'wheels new' to scaffold a complete project structure");
		}

		return recs;
	}

}
```

- [ ] **Step 2: Add doctor() dispatch to Module.cfc**

Add public function in Module.cfc:

```cfml
// ─────────────────────────────────────────────────
//  doctor — Application health checks
// ─────────────────────────────────────────────────

/**
 * hint: Run health checks on your Wheels application
 */
public string function doctor() {
	var args = __arguments ?: [];
	var verbose = false;
	for (var arg in args) {
		if (arg == "--verbose" || arg == "-v") verbose = true;
	}

	var svc = getService("doctor");
	var results = svc.runChecks();

	out("Wheels Health Check", "bold");
	out(repeatString("=", 40));
	out("");

	// Issues
	if (arrayLen(results.issues)) {
		out("Issues (#arrayLen(results.issues)#):", "red");
		for (var issue in results.issues) {
			out("  x #issue#", "red");
		}
		out("");
	}

	// Warnings
	if (arrayLen(results.warnings)) {
		out("Warnings (#arrayLen(results.warnings)#):", "yellow");
		for (var warning in results.warnings) {
			out("  ! #warning#", "yellow");
		}
		out("");
	}

	// Passed (verbose only, or when no issues)
	if (verbose || (results.status == "HEALTHY")) {
		out("Passed (#arrayLen(results.passed)#):", "green");
		for (var passed in results.passed) {
			out("  + #passed#", "green");
		}
		out("");
	}

	// Status
	switch (results.status) {
		case "CRITICAL":
			out("Status: CRITICAL", "red");
			break;
		case "WARNING":
			out("Status: WARNING", "yellow");
			break;
		case "HEALTHY":
			out("Status: HEALTHY", "green");
			break;
	}

	// Recommendations
	if (arrayLen(results.recommendations)) {
		out("");
		out("Recommendations:", "cyan");
		for (var rec in results.recommendations) {
			out("  * #rec#", "cyan");
		}
	}

	return "";
}
```

In `getService()` switch, add:

```cfml
case "doctor":
	variables.services.doctor = new services.Doctor(
		projectRoot = variables.projectRoot
	);
	break;
```

- [ ] **Step 3: Test doctor command**

```bash
# Run in a valid Wheels project
wheels doctor

# Expected: HEALTHY or WARNING status with check results

# Run with verbose
wheels doctor --verbose

# Expected: All passed checks also displayed
```

- [ ] **Step 4: Commit**

```bash
git add cli/lucli/services/Doctor.cfc cli/lucli/Module.cfc
git commit -m "feat(cli): add doctor command for application health checks"
```

---

### Task 3: Stats Service (stats + notes)

**Files:**
- Create: `cli/lucli/services/Stats.cfc`
- Modify: `cli/lucli/Module.cfc`

- [ ] **Step 1: Create Stats.cfc**

Write `cli/lucli/services/Stats.cfc`:

```cfml
/**
 * Code statistics and annotation extraction service.
 *
 * Scans project directories for file counts, lines of code, comments,
 * and developer annotations (TODO, FIXME, etc.). All operations are
 * local file reads — no running server required.
 */
component {

	public function init(
		required any helpers,
		required string projectRoot
	) {
		variables.helpers = arguments.helpers;
		variables.projectRoot = arguments.projectRoot;
		return this;
	}

	/**
	 * Gather code statistics across all project directories.
	 */
	public struct function getStats() {
		var categories = [
			{name: "Controllers", path: "app/controllers", extensions: "cfc"},
			{name: "Models", path: "app/models", extensions: "cfc"},
			{name: "Views", path: "app/views", extensions: "cfm"},
			{name: "Helpers", path: "app/helpers", extensions: "cfc"},
			{name: "Tests", path: "tests/specs", extensions: "cfc"},
			{name: "Migrations", path: "app/migrator/migrations", extensions: "cfc"},
			{name: "Config", path: "config", extensions: "cfm"}
		];

		var results = [];
		var totalFiles = 0;
		var totalLOC = 0;
		var totalComments = 0;
		var totalBlanks = 0;
		var totalLines = 0;
		var allFiles = [];

		for (var cat in categories) {
			var dirPath = variables.projectRoot & "/" & cat.path;
			var catResult = {
				name: cat.name,
				files: 0,
				loc: 0,
				comments: 0,
				blanks: 0,
				total: 0
			};

			if (directoryExists(dirPath)) {
				var fileList = directoryList(dirPath, true, "path", "*." & cat.extensions);
				catResult.files = arrayLen(fileList);

				for (var filePath in fileList) {
					try {
						var analysis = analyzeFile(filePath);
						catResult.loc += analysis.loc;
						catResult.comments += analysis.comments;
						catResult.blanks += analysis.blanks;
						catResult.total += analysis.total;
						arrayAppend(allFiles, {path: filePath, lines: analysis.total});
					} catch (any e) {
						// Skip unreadable files
					}
				}
			}

			totalFiles += catResult.files;
			totalLOC += catResult.loc;
			totalComments += catResult.comments;
			totalBlanks += catResult.blanks;
			totalLines += catResult.total;
			arrayAppend(results, catResult);
		}

		// Sort allFiles by line count descending for top-10
		arraySort(allFiles, function(a, b) { return b.lines - a.lines; });
		var topFiles = arrayLen(allFiles) > 10 ? allFiles.slice(1, 10) : allFiles;

		// Make paths relative
		for (var i = 1; i <= arrayLen(topFiles); i++) {
			topFiles[i].path = replace(topFiles[i].path, variables.projectRoot & "/", "");
		}

		var testLOC = 0;
		var codeLOC = 0;
		for (var cat in results) {
			if (cat.name == "Tests") {
				testLOC = cat.loc;
			} else {
				codeLOC += cat.loc;
			}
		}

		return {
			categories: results,
			totals: {
				files: totalFiles,
				loc: totalLOC,
				comments: totalComments,
				blanks: totalBlanks,
				total: totalLines
			},
			codeToTestRatio: codeLOC > 0 ? numberFormat(testLOC / codeLOC, "0.00") : "0.00",
			avgLinesPerFile: totalFiles > 0 ? round(totalLines / totalFiles) : 0,
			topFiles: topFiles
		};
	}

	/**
	 * Extract developer annotations (TODO, FIXME, etc.) from source files.
	 */
	public struct function getNotes(
		string annotations = "TODO,FIXME,OPTIMIZE",
		string custom = ""
	) {
		var allAnnotations = arguments.annotations;
		if (len(arguments.custom)) {
			allAnnotations = listAppend(allAnnotations, arguments.custom);
		}
		var annotationTypes = listToArray(uCase(allAnnotations));

		var scanDirs = ["app", "config", "tests"];
		var extensions = "cfc,cfm,js,css";
		var found = {};
		var totalCount = 0;

		// Initialize result buckets
		for (var aType in annotationTypes) {
			found[aType] = [];
		}

		for (var dir in scanDirs) {
			var dirPath = variables.projectRoot & "/" & dir;
			if (!directoryExists(dirPath)) continue;

			// Scan each extension
			for (var ext in listToArray(extensions)) {
				var fileList = directoryList(dirPath, true, "path", "*." & ext);
				for (var filePath in fileList) {
					try {
						scanFileForAnnotations(filePath, annotationTypes, found);
					} catch (any e) {
						// Skip unreadable files
					}
				}
			}
		}

		// Count totals
		for (var aType in annotationTypes) {
			totalCount += arrayLen(found[aType]);
		}

		return {
			annotations: found,
			types: annotationTypes,
			total: totalCount
		};
	}

	// ── Private helpers ──────────────────────────────────────

	private struct function analyzeFile(required string filePath) {
		var content = fileRead(arguments.filePath);
		var lines = listToArray(content, chr(10), true);
		var loc = 0;
		var comments = 0;
		var blanks = 0;
		var inBlockComment = false;

		for (var line in lines) {
			var trimmed = trim(line);

			if (!len(trimmed)) {
				blanks++;
				continue;
			}

			// CFML block comments: <!--- ... --->
			if (!inBlockComment && findNoCase("<!---", trimmed) && !findNoCase("--->", trimmed)) {
				inBlockComment = true;
				comments++;
				continue;
			}
			if (inBlockComment) {
				comments++;
				if (findNoCase("--->", trimmed)) {
					inBlockComment = false;
				}
				continue;
			}
			// Single-line CFML comment
			if (findNoCase("<!---", trimmed) && findNoCase("--->", trimmed)) {
				comments++;
				continue;
			}

			// JS/CSS block comments: /* ... */
			if (!inBlockComment && left(trimmed, 2) == "/*" && !find("*/", trimmed)) {
				inBlockComment = true;
				comments++;
				continue;
			}
			if (!inBlockComment && left(trimmed, 2) == "/*" && find("*/", trimmed)) {
				comments++;
				continue;
			}

			// Line comments
			if (left(trimmed, 2) == "//") {
				comments++;
				continue;
			}

			loc++;
		}

		return {loc: loc, comments: comments, blanks: blanks, total: arrayLen(lines)};
	}

	private void function scanFileForAnnotations(
		required string filePath,
		required array annotationTypes,
		required struct found
	) {
		var content = fileRead(arguments.filePath);
		var lines = listToArray(content, chr(10), true);
		var relativePath = replace(arguments.filePath, variables.projectRoot & "/", "");

		for (var lineNum = 1; lineNum <= arrayLen(lines); lineNum++) {
			var line = lines[lineNum];
			for (var aType in arguments.annotationTypes) {
				// Match annotation in comment context: // TODO: ..., <!--- FIXME: ... --->, /* OPTIMIZE: ... */
				var pattern = aType & "[\s:]+(.*)";
				var match = reFindNoCase(pattern, line, 1, true);
				if (match.pos[1] > 0) {
					var text = "";
					if (arrayLen(match.pos) > 1 && match.pos[2] > 0) {
						text = trim(mid(line, match.pos[2], match.len[2]));
						// Strip trailing comment delimiters
						text = reReplaceNoCase(text, "\s*--->.*$", "");
						text = reReplaceNoCase(text, "\s*\*/.*$", "");
					}
					arrayAppend(arguments.found[aType], {
						file: relativePath,
						line: lineNum,
						text: text
					});
				}
			}
		}
	}

}
```

- [ ] **Step 2: Add stats() and notes() dispatch to Module.cfc**

Add two public functions in Module.cfc:

```cfml
// ─────────────────────────────────────────────────
//  stats — Code statistics
// ─────────────────────────────────────────────────

/**
 * hint: Show code statistics for your Wheels application
 */
public string function stats() {
	var args = __arguments ?: [];
	var verbose = false;
	for (var arg in args) {
		if (arg == "--verbose" || arg == "-v") verbose = true;
	}

	var svc = getService("stats");
	var data = svc.getStats();

	out("Code Statistics", "bold");
	out(repeatString("=", 70));

	// Header
	var fmt = "%-14s %6s %7s %10s %8s %7s";
	out(sprintf(fmt, "Category", "Files", "LOC", "Comments", "Blanks", "Total"));
	out(repeatString("-", 70));

	// Rows
	for (var cat in data.categories) {
		out(sprintf(fmt,
			cat.name,
			cat.files,
			cat.loc,
			cat.comments,
			cat.blanks,
			cat.total
		));
	}

	out(repeatString("-", 70));
	out(sprintf(fmt,
		"Total",
		data.totals.files,
		data.totals.loc,
		data.totals.comments,
		data.totals.blanks,
		data.totals.total
	));
	out("");
	out("Code-to-test ratio: 1:#data.codeToTestRatio#");
	out("Average lines/file: #data.avgLinesPerFile#");

	if (verbose && arrayLen(data.topFiles)) {
		out("");
		out("Top 10 Largest Files:", "bold");
		for (var f in data.topFiles) {
			out("  #f.lines# lines  #f.path#");
		}
	}

	return "";
}

// ─────────────────────────────────────────────────
//  notes — Code annotations
// ─────────────────────────────────────────────────

/**
 * hint: Extract TODO, FIXME, and other annotations from your codebase
 */
public string function notes() {
	var args = __arguments ?: [];
	var annotations = "TODO,FIXME,OPTIMIZE";
	var custom = "";

	for (var i = 1; i <= arrayLen(args); i++) {
		var arg = args[i];
		if (reFindNoCase("^--annotations=", arg)) {
			annotations = valueAfterEquals(arg);
		} else if (reFindNoCase("^--custom=", arg)) {
			custom = valueAfterEquals(arg);
		}
	}

	var svc = getService("stats");
	var data = svc.getNotes(annotations, custom);

	if (data.total == 0) {
		out("No annotations found.", "green");
		return "";
	}

	for (var aType in data.types) {
		var items = data.annotations[aType];
		if (!arrayLen(items)) continue;

		out("#aType# (#arrayLen(items)#):", "yellow");
		for (var item in items) {
			var desc = len(item.text) ? " -- #item.text#" : "";
			out("  #item.file#:#item.line##desc#");
		}
		out("");
	}

	// Summary line
	var parts = [];
	for (var aType in data.types) {
		var count = arrayLen(data.annotations[aType]);
		if (count) arrayAppend(parts, "#count# #aType#");
	}
	out("Summary: #data.total# annotations (#arrayToList(parts, ', ')#)", "cyan");

	return "";
}
```

In `getService()` switch, add:

```cfml
case "stats":
	variables.services.stats = new services.Stats(
		helpers = getService("helpers"),
		projectRoot = variables.projectRoot
	);
	break;
```

- [ ] **Step 3: Add sprintf helper to Module.cfc**

The stats output uses `sprintf` for column formatting. Add this private helper:

```cfml
/**
 * Simple sprintf-like formatting for fixed-width columns.
 * Supports %-Ns (left-aligned string) and %Ns (right-aligned string).
 */
private string function sprintf(required string format) {
	var result = arguments.format;
	var argIndex = 2;
	// Replace each %... placeholder with the corresponding argument
	while (reFindNoCase("%-?\d+s", result) && argIndex <= structCount(arguments)) {
		var match = reFindNoCase("(%-?)(\d+)s", result, 1, true);
		if (match.pos[1] == 0) break;
		var leftAlign = len(mid(result, match.pos[2], match.len[2])) > 1;
		var width = val(mid(result, match.pos[3], match.len[3]));
		var value = toString(arguments[argIndex]);
		if (leftAlign) {
			value = value & repeatString(" ", max(0, width - len(value)));
		} else {
			value = repeatString(" ", max(0, width - len(value))) & value;
		}
		result = left(result, match.pos[1] - 1) & value & mid(result, match.pos[1] + match.len[1], len(result));
		argIndex++;
	}
	return result;
}
```

- [ ] **Step 4: Test stats and notes commands**

```bash
# Run stats
wheels stats

# Expected: Table showing file counts, LOC, etc. per category

wheels stats --verbose

# Expected: Same table + top 10 largest files

# Run notes
wheels notes

# Expected: Lists any TODO/FIXME/OPTIMIZE annotations found

wheels notes --custom=HACK,REVIEW

# Expected: Also searches for HACK and REVIEW annotations
```

- [ ] **Step 5: Commit**

```bash
git add cli/lucli/services/Stats.cfc cli/lucli/Module.cfc
git commit -m "feat(cli): add stats and notes commands for code analysis"
```

---

### Task 4: Database Commands (db reset, db status, db version)

**Files:**
- Modify: `cli/lucli/Module.cfc`

- [ ] **Step 1: Add db() dispatch function to Module.cfc**

```cfml
// ─────────────────────────────────────────────────
//  db — Database management
// ─────────────────────────────────────────────────

/**
 * hint: Database management commands (reset, status, version)
 */
public string function db() {
	var args = __arguments ?: [];

	if (!arrayLen(args)) {
		out("Usage: wheels db <command>", "yellow");
		out("");
		out("Commands:", "bold");
		out("  reset    Run pending migrations and reseed the database");
		out("  status   Show migration status (applied vs pending)");
		out("  version  Show current database schema version");
		out("");
		out("Examples:", "bold");
		out("  wheels db reset");
		out("  wheels db reset --skip-seed");
		out("  wheels db status");
		out("  wheels db status --pending");
		out("  wheels db version --detailed");
		return "";
	}

	var subcommand = lCase(args[1]);

	switch (subcommand) {
		case "reset":
			return dbReset(args);
		case "status":
			return dbStatus(args);
		case "version":
			return dbVersion(args);
		default:
			out("Unknown db command: #subcommand#", "red");
			out("Valid commands: reset, status, version");
			return "";
	}
}
```

- [ ] **Step 2: Add dbReset() private function**

```cfml
/**
 * Reset database: run pending migrations and reseed
 */
private string function dbReset(array args = []) {
	var force = false;
	var skipSeed = false;
	for (var arg in arguments.args) {
		if (arg == "--force") force = true;
		if (arg == "--skip-seed") skipSeed = true;
	}

	if (!force) {
		var answer = prompt("Reset database? This will run pending migrations and reseed. [y/n]: ");
		if (lCase(left(trim(answer), 1)) != "y") {
			out("Cancelled.", "red");
			return "";
		}
	}

	// Step 1: Migrate
	out("Running migrations...", "cyan");
	var migrateResult = runMigration("latest");

	// Step 2: Seed (unless skipped)
	if (!skipSeed) {
		out("Running seeds...", "cyan");
		runSeed("auto", "");
	}

	out("");
	out("Database reset complete.", "green");
	return "";
}
```

- [ ] **Step 3: Add dbStatus() private function**

```cfml
/**
 * Show migration status
 */
private string function dbStatus(array args = []) {
	var pendingOnly = false;
	for (var arg in arguments.args) {
		if (arg == "--pending") pendingOnly = true;
	}

	var serverPort = detectServerPort();
	if (!serverPort) {
		out("No running server detected. Start with 'wheels start' first.", "red");
		return "";
	}

	try {
		var statusUrl = "http://localhost:#serverPort#/wheels/cli?command=dbStatus&format=json";
		var response = makeHttpRequest(statusUrl);
		var data = deserializeJSON(response);

		if (!data.success) {
			out("Error: #data.message#", "red");
			return "";
		}

		out("Migration Status", "bold");
		out(repeatString("=", 70));

		var fmt = "%-16s %-30s %-10s %s";
		out(sprintf(fmt, "Version", "Description", "Status", "Applied"));
		out(repeatString("-", 70));

		for (var m in data.migrations) {
			if (pendingOnly && m.status != "pending") continue;

			var statusColor = m.status == "applied" ? "green" : "yellow";
			var appliedAt = structKeyExists(m, "appliedAt") && len(m.appliedAt) ? m.appliedAt : "-";
			out(sprintf(fmt, m.version, left(m.description, 30), m.status, appliedAt), statusColor);
		}

		out("");
		out("Total: #data.summary.total# | Applied: #data.summary.applied# | Pending: #data.summary.pending#", "cyan");

	} catch (any e) {
		out("Error fetching migration status: #e.message#", "red");
	}

	return "";
}
```

- [ ] **Step 4: Add dbVersion() private function**

```cfml
/**
 * Show current database schema version
 */
private string function dbVersion(array args = []) {
	var detailed = false;
	for (var arg in arguments.args) {
		if (arg == "--detailed") detailed = true;
	}

	var serverPort = detectServerPort();
	if (!serverPort) {
		out("No running server detected. Start with 'wheels start' first.", "red");
		return "";
	}

	try {
		var versionUrl = "http://localhost:#serverPort#/wheels/cli?command=dbVersion&format=json";
		var response = makeHttpRequest(versionUrl);
		var data = deserializeJSON(response);

		out("Database version: #data.version#", "bold");

		if (detailed) {
			// Also fetch status for extra detail
			var statusUrl = "http://localhost:#serverPort#/wheels/cli?command=dbStatus&format=json";
			var statusResponse = makeHttpRequest(statusUrl);
			var statusData = deserializeJSON(statusResponse);

			if (statusData.success && arrayLen(statusData.migrations)) {
				// Find last applied migration
				var lastApplied = "";
				for (var m in statusData.migrations) {
					if (m.status == "applied") lastApplied = m;
				}
				if (isStruct(lastApplied)) {
					var appliedAt = structKeyExists(lastApplied, "appliedAt") && len(lastApplied.appliedAt) ? lastApplied.appliedAt : "unknown";
					out("Last migration:   #lastApplied.description# (applied #appliedAt#)");
				}

				out("Total migrations: #statusData.summary.total#");
				out("Pending:          #statusData.summary.pending#");

				// Show next pending
				if (statusData.summary.pending > 0) {
					for (var m in statusData.migrations) {
						if (m.status == "pending") {
							out("Next:             #m.version# -- #m.description#");
							break;
						}
					}
				}
			}
		}

	} catch (any e) {
		out("Error fetching database version: #e.message#", "red");
	}

	return "";
}
```

- [ ] **Step 5: Test db commands**

```bash
# Start server
wheels start

# Test each command
wheels db status
wheels db status --pending
wheels db version
wheels db version --detailed
wheels db reset --force
```

- [ ] **Step 6: Commit**

```bash
git add cli/lucli/Module.cfc
git commit -m "feat(cli): add db reset, status, and version commands"
```

---

### Task 5: Upgrade Check Command

**Files:**
- Modify: `cli/lucli/Module.cfc`

- [ ] **Step 1: Add upgrade() public function to Module.cfc**

```cfml
// ─────────────────────────────────────────────────
//  upgrade — Upgrade assistance
// ─────────────────────────────────────────────────

/**
 * hint: Check for breaking changes before upgrading Wheels
 */
public string function upgrade() {
	var args = __arguments ?: [];

	if (!arrayLen(args) || lCase(args[1]) != "check") {
		out("Usage: wheels upgrade check [--to=<version>]", "yellow");
		out("");
		out("Scans your app for breaking changes between versions.");
		out("Does not perform the upgrade — use 'brew upgrade wheels' for that.");
		return "";
	}

	var targetVersion = "";
	for (var i = 2; i <= arrayLen(args); i++) {
		if (reFindNoCase("^--to=", args[i])) {
			targetVersion = valueAfterEquals(args[i]);
		}
	}

	return runUpgradeCheck(targetVersion);
}
```

- [ ] **Step 2: Add runUpgradeCheck() private function**

```cfml
/**
 * Scan app for breaking changes between current and target version.
 */
private string function runUpgradeCheck(string targetVersion = "") {
	// Detect current version
	var boxJsonPath = variables.projectRoot & "/vendor/wheels/box.json";
	var currentVersion = "unknown";
	if (fileExists(boxJsonPath)) {
		try {
			var boxData = deserializeJSON(fileRead(boxJsonPath));
			currentVersion = boxData.version ?: "unknown";
		} catch (any e) {}
	}

	// Determine target version
	var target = arguments.targetVersion;
	if (!len(target)) {
		try {
			var apiUrl = "https://api.github.com/repos/wheels-dev/wheels/releases/latest";
			var response = makeHttpRequest(apiUrl);
			var releaseData = deserializeJSON(response);
			target = replace(releaseData.tag_name, "v", "");
		} catch (any e) {
			out("Could not fetch latest version. Use --to=<version> to specify.", "yellow");
			return "";
		}
	}

	out("Current version: #currentVersion#", "bold");
	out("Target version:  #target#", "bold");
	out("");

	// Compare major versions
	var currentMajor = val(listFirst(currentVersion, "."));
	var targetMajor = val(listFirst(target, "."));

	if (currentMajor == targetMajor) {
		out("Same major version — no known breaking changes.", "green");
		out("Upgrade with: brew upgrade wheels");
		return "";
	}

	// Breaking changes database
	var checks = [];

	// 2.x -> 3.x
	if (currentMajor <= 2 && targetMajor >= 3) {
		arrayAppend(checks, {
			description: "Legacy plugin directory",
			pattern: "",
			checkType: "directory",
			path: "app/plugins",
			fix: "Migrate to packages/ + vendor/ activation model"
		});
		arrayAppend(checks, {
			description: "Old test base class (wheels.Test)",
			pattern: 'extends\s*=\s*"wheels\.Test"',
			checkType: "grep",
			scanDir: "tests",
			extensions: "cfc",
			fix: 'Change to extends="wheels.WheelsTest"'
		});
	}

	// 3.x -> 4.x
	if (currentMajor <= 3 && targetMajor >= 4) {
		arrayAppend(checks, {
			description: "Legacy plugin directory (deprecated in 4.x)",
			pattern: "",
			checkType: "directory",
			path: "plugins",
			fix: "Migrate to packages/ + vendor/ system"
		});
		arrayAppend(checks, {
			description: "Old test base class (wheels.Test)",
			pattern: 'extends\s*=\s*"wheels\.Test"',
			checkType: "grep",
			scanDir: "tests",
			extensions: "cfc",
			fix: 'Change to extends="wheels.WheelsTest"'
		});
		arrayAppend(checks, {
			description: "Direct WireBox references",
			pattern: "application\.wirebox",
			checkType: "grep",
			scanDir: "app",
			extensions: "cfc,cfm",
			fix: "Use service() or inject() from the DI container instead"
		});
	}

	// Run checks
	var issues = [];
	var passed = [];

	for (var check in checks) {
		if (check.checkType == "directory") {
			var dirPath = variables.projectRoot & "/" & check.path;
			if (directoryExists(dirPath)) {
				var contents = directoryList(dirPath, false, "name");
				if (arrayLen(contents)) {
					arrayAppend(issues, {description: check.description, fix: check.fix, matches: [check.path & "/"]});
				} else {
					arrayAppend(passed, check.description);
				}
			} else {
				arrayAppend(passed, check.description);
			}
		} else if (check.checkType == "grep") {
			var scanPath = variables.projectRoot & "/" & check.scanDir;
			if (!directoryExists(scanPath)) {
				arrayAppend(passed, check.description);
				continue;
			}
			var matches = [];
			for (var ext in listToArray(check.extensions)) {
				var files = directoryList(scanPath, true, "path", "*." & ext);
				for (var filePath in files) {
					var content = fileRead(filePath);
					var lines = listToArray(content, chr(10), true);
					for (var lineNum = 1; lineNum <= arrayLen(lines); lineNum++) {
						if (reFindNoCase(check.pattern, lines[lineNum])) {
							var relPath = replace(filePath, variables.projectRoot & "/", "");
							arrayAppend(matches, "#relPath#:#lineNum#");
						}
					}
				}
			}
			if (arrayLen(matches)) {
				arrayAppend(issues, {description: check.description, fix: check.fix, matches: matches});
			} else {
				arrayAppend(passed, check.description);
			}
		}
	}

	// Output
	if (arrayLen(issues)) {
		out("Breaking Changes (#arrayLen(issues)# found):", "yellow");
		for (var issue in issues) {
			out("  ! #issue.description#", "yellow");
			for (var match in issue.matches) {
				out("    #match#");
			}
			out("    -> #issue.fix#", "cyan");
			out("");
		}
	}

	if (arrayLen(passed)) {
		out("All Clear (#arrayLen(passed)# checks):", "green");
		for (var p in passed) {
			out("  + #p#", "green");
		}
	}

	out("");
	out("Upgrade with: brew upgrade wheels");

	return "";
}
```

- [ ] **Step 3: Test upgrade check**

```bash
wheels upgrade check

# Expected: Shows current version, fetches latest, runs breaking change checks

wheels upgrade check --to=4.0.0

# Expected: Shows checks for upgrading to 4.0.0
```

- [ ] **Step 4: Commit**

```bash
git add cli/lucli/Module.cfc
git commit -m "feat(cli): add upgrade check command for breaking changes detection"
```

---

### Task 6: Core Introspect Endpoint

**Files:**
- Modify: `vendor/wheels/public/views/cli.cfm`

- [ ] **Step 1: Add introspect command to CLI bridge**

In `vendor/wheels/public/views/cli.cfm`, add a new case inside the `switch (request.wheels.params.command)` block, after the existing `dbSchema` case and before the `dbSeed` case:

```cfml
case "introspect":
	// Return model metadata for admin generation
	data.success = false;
	if (!structKeyExists(request.wheels.params, "model") || !len(request.wheels.params.model)) {
		data.message = "Missing required parameter: model";
		break;
	}

	try {
		local.modelName = request.wheels.params.model;
		local.modelInstance = model(local.modelName);
		local.classData = local.modelInstance.$classData();

		data.model = local.modelName;
		data.tableName = local.classData.tableName ?: lCase(local.modelName) & "s";
		data.primaryKey = local.classData.keys ?: "id";

		// Extract columns from properties
		data.columns = [];
		if (structKeyExists(local.classData, "properties")) {
			for (local.propName in local.classData.properties) {
				local.prop = local.classData.properties[local.propName];
				local.colInfo = {
					name: local.propName,
					type: local.prop.type ?: "string",
					primaryKey: listFindNoCase(data.primaryKey, local.propName) > 0
				};
				if (structKeyExists(local.prop, "maxLength") && val(local.prop.maxLength) > 0) {
					local.colInfo.maxLength = local.prop.maxLength;
				}
				// Detect foreign keys
				if (right(local.propName, 2) == "Id" && len(local.propName) > 2) {
					local.colInfo.foreignKey = true;
					local.colInfo.referencedModel = variables.helpers.capitalize(
						left(local.propName, len(local.propName) - 2)
					);
				}
				arrayAppend(data.columns, local.colInfo);
			}
		}

		// Extract associations
		data.associations = [];
		if (structKeyExists(local.classData, "associations")) {
			for (local.assocName in local.classData.associations) {
				local.assoc = local.classData.associations[local.assocName];
				arrayAppend(data.associations, {
					type: local.assoc.type ?: "belongsTo",
					name: local.assocName,
					modelName: local.assoc.modelName ?: variables.helpers.capitalize(local.assocName)
				});
			}
		}

		data.success = true;
		data.message = "Model introspected successfully";
	} catch (any e) {
		data.message = "Error introspecting model: " & e.message;
	}
	break;
```

**Note:** The `capitalize` helper isn't available in this file's scope. Use inline CFML instead:

Replace `variables.helpers.capitalize(...)` with:
```cfml
uCase(left(local.refName, 1)) & mid(local.refName, 2, len(local.refName) - 1)
```

So the foreign key section becomes:
```cfml
if (right(local.propName, 2) == "Id" && len(local.propName) > 2) {
	local.colInfo.foreignKey = true;
	local.refName = left(local.propName, len(local.propName) - 2);
	local.colInfo.referencedModel = uCase(left(local.refName, 1)) & mid(local.refName, 2, len(local.refName) - 1);
}
```

And the associations section:
```cfml
local.assocModelName = local.assoc.modelName ?: local.assocName;
local.assocModelName = uCase(left(local.assocModelName, 1)) & mid(local.assocModelName, 2, len(local.assocModelName) - 1);
arrayAppend(data.associations, {
	type: local.assoc.type ?: "belongsTo",
	name: local.assocName,
	modelName: local.assocModelName
});
```

- [ ] **Step 2: Test the endpoint**

```bash
# Start server
wheels start

# Test introspection (requires a model to exist)
curl -s "http://localhost:8080/wheels/cli?command=introspect&model=User&format=json" | python3 -m json.tool

# Expected: JSON with model, tableName, primaryKey, columns, associations
```

- [ ] **Step 3: Commit**

```bash
git add vendor/wheels/public/views/cli.cfm
git commit -m "feat(cli): add model introspect endpoint to CLI bridge"
```

---

### Task 7: Admin Service and Templates

**Files:**
- Create: `cli/lucli/services/Admin.cfc`
- Create: `cli/lucli/templates/admin/controller.txt`
- Create: `cli/lucli/templates/admin/index.txt`
- Create: `cli/lucli/templates/admin/show.txt`
- Create: `cli/lucli/templates/admin/new.txt`
- Create: `cli/lucli/templates/admin/edit.txt`
- Create: `cli/lucli/templates/admin/_form.txt`
- Modify: `cli/lucli/Module.cfc`

- [ ] **Step 1: Create admin templates directory and template files**

```bash
mkdir -p cli/lucli/templates/admin
```

Write `cli/lucli/templates/admin/controller.txt`:

```
component extends="Controller" {

	function config() {
		protectsFromForgery();
{{beforeFilters}}
	}

{{foreignKeyLoaders}}
	function index() {
		{{plural}} = model("{{SingularCap}}").findAll(
			page=params.page ?: 1,
			perPage=25,
			order="{{primaryKey}} DESC"
		);
	}

	function show() {
		{{singular}} = model("{{SingularCap}}").findByKey(params.key);
		if (!IsObject({{singular}})) {
			redirectTo(route="admin~{{plural}}");
		}
	}

	function new() {
		{{singular}} = model("{{SingularCap}}").new();
	}

	function edit() {
		{{singular}} = model("{{SingularCap}}").findByKey(params.key);
		if (!IsObject({{singular}})) {
			redirectTo(route="admin~{{plural}}");
		}
	}

	function create() {
		{{singular}} = model("{{SingularCap}}").new(params.{{singular}});
		if ({{singular}}.save()) {
			flashInsert(success="{{SingularCap}} created.");
			redirectTo(route="admin~{{singular}}", key={{singular}}.key());
		} else {
			flashInsert(error="Could not create {{SingularCap}}.");
			renderView(action="new");
		}
	}

	function update() {
		{{singular}} = model("{{SingularCap}}").findByKey(params.key);
		if (!IsObject({{singular}})) {
			redirectTo(route="admin~{{plural}}");
			return;
		}
		if ({{singular}}.update(params.{{singular}})) {
			flashInsert(success="{{SingularCap}} updated.");
			redirectTo(route="admin~{{singular}}", key={{singular}}.key());
		} else {
			flashInsert(error="Could not update {{SingularCap}}.");
			renderView(action="edit");
		}
	}

	function delete() {
		{{singular}} = model("{{SingularCap}}").findByKey(params.key);
		if (IsObject({{singular}})) {
			{{singular}}.delete();
			flashInsert(success="{{SingularCap}} deleted.");
		}
		redirectTo(route="admin~{{plural}}");
	}

}
```

Write `cli/lucli/templates/admin/index.txt`:

```
<cfparam name="{{plural}}" default="">
<h1>{{PluralCap}} Admin</h1>
<p>#linkTo(text="New {{SingularCap}}", route="admin~new_{{singular}}")#</p>
<cfif {{plural}}.recordCount>
<table>
	<thead>
		<tr>
{{indexHeaders}}
			<th>Actions</th>
		</tr>
	</thead>
	<tbody>
		<cfloop query="{{plural}}">
		<tr>
{{indexCells}}
			<td>
				#linkTo(text="Show", route="admin~{{singular}}", key={{plural}}.id)#
				#linkTo(text="Edit", route="admin~edit_{{singular}}", key={{plural}}.id)#
			</td>
		</tr>
		</cfloop>
	</tbody>
</table>
<cfelse>
<p>No {{plural}} found.</p>
</cfif>
#paginationNav()#
```

Write `cli/lucli/templates/admin/show.txt`:

```
<cfparam name="{{singular}}" default="">
<h1>{{SingularCap}} Detail</h1>
<dl>
{{showFields}}
</dl>
<p>
	#linkTo(text="Edit", route="admin~edit_{{singular}}", key={{singular}}.key())#
	#linkTo(text="Back to list", route="admin~{{plural}}")#
</p>
```

Write `cli/lucli/templates/admin/new.txt`:

```
<cfparam name="{{singular}}" default="">
<h1>New {{SingularCap}}</h1>
#includePartial(partial="form")#
#linkTo(text="Back to list", route="admin~{{plural}}")#
```

Write `cli/lucli/templates/admin/edit.txt`:

```
<cfparam name="{{singular}}" default="">
<h1>Edit {{SingularCap}}</h1>
#includePartial(partial="form")#
#linkTo(text="Back to list", route="admin~{{plural}}")#
```

Write `cli/lucli/templates/admin/_form.txt`:

```
<cfparam name="{{singular}}" default="">
#errorMessagesFor(objectName="{{singular}}")#
#startFormTag(route="admin~{{plural}}", method="post", key={{singular}}.isPersisted() ? {{singular}}.key() : "")#
{{formFields}}
	<div>#submitTag(value="Save {{SingularCap}}")#</div>
#endFormTag()#
```

- [ ] **Step 2: Create Admin.cfc**

Write `cli/lucli/services/Admin.cfc`:

```cfml
/**
 * Admin CRUD generation service.
 *
 * Introspects a model via the running Wheels server to get column types
 * and associations, then generates an admin-scoped controller and views.
 */
component {

	public function init(
		required any helpers,
		required any templateService,
		required string projectRoot,
		required string moduleRoot
	) {
		variables.helpers = arguments.helpers;
		variables.templateService = arguments.templateService;
		variables.projectRoot = arguments.projectRoot;
		variables.moduleRoot = arguments.moduleRoot;
		return this;
	}

	/**
	 * Generate admin CRUD for a model using server introspection data.
	 */
	public struct function generateAdmin(
		required struct modelData,
		boolean force = false,
		boolean noRoutes = false
	) {
		var result = {success: true, generated: [], errors: []};
		var singular = lCase(arguments.modelData.model);
		var plural = variables.helpers.pluralize(singular);
		var singularCap = variables.helpers.capitalize(singular);
		var pluralCap = variables.helpers.capitalize(plural);

		// Filter out non-form columns
		var formColumns = [];
		var allColumns = [];
		for (var col in arguments.modelData.columns) {
			arrayAppend(allColumns, col);
			if (col.primaryKey ?: false) continue;
			if (listFindNoCase("createdAt,updatedAt,deletedAt", col.name)) continue;
			arrayAppend(formColumns, col);
		}

		// Build template context
		var context = {
			singular: singular,
			plural: plural,
			SingularCap: singularCap,
			PluralCap: pluralCap,
			primaryKey: arguments.modelData.primaryKey ?: "id"
		};

		// Build dynamic template sections
		context.beforeFilters = buildBeforeFilters(arguments.modelData.associations);
		context.foreignKeyLoaders = buildForeignKeyLoaders(arguments.modelData.associations);
		context.indexHeaders = buildIndexHeaders(formColumns);
		context.indexCells = buildIndexCells(formColumns, plural);
		context.showFields = buildShowFields(allColumns, singular);
		context.formFields = buildFormFields(formColumns, singular);

		// Generate controller
		var controllerDir = variables.projectRoot & "/app/controllers/admin";
		if (!directoryExists(controllerDir)) directoryCreate(controllerDir, true);
		var controllerPath = controllerDir & "/" & pluralCap & ".cfc";
		if (fileExists(controllerPath) && !arguments.force) {
			arrayAppend(result.errors, "Controller already exists: app/controllers/admin/#pluralCap#.cfc (use --force to overwrite)");
			result.success = false;
			return result;
		}
		var controllerTemplate = fileRead(variables.moduleRoot & "templates/admin/controller.txt");
		fileWrite(controllerPath, processTemplate(controllerTemplate, context));
		arrayAppend(result.generated, "app/controllers/admin/#pluralCap#.cfc");

		// Generate views
		var viewDir = variables.projectRoot & "/app/views/admin/" & plural;
		if (!directoryExists(viewDir)) directoryCreate(viewDir, true);

		var viewTemplates = ["index", "show", "new", "edit", "_form"];
		for (var viewName in viewTemplates) {
			var viewPath = viewDir & "/" & viewName & ".cfm";
			if (fileExists(viewPath) && !arguments.force) {
				arrayAppend(result.errors, "View already exists: app/views/admin/#plural#/#viewName#.cfm");
				continue;
			}
			var viewTemplate = fileRead(variables.moduleRoot & "templates/admin/" & viewName & ".txt");
			fileWrite(viewPath, processTemplate(viewTemplate, context));
			arrayAppend(result.generated, "app/views/admin/#plural#/#viewName#.cfm");
		}

		// Inject routes
		if (!arguments.noRoutes) {
			var routeResult = injectAdminRoute(plural);
			if (routeResult) {
				arrayAppend(result.generated, "Route: admin scope -> .resources(""#plural#"")");
			}
		}

		return result;
	}

	// ── Template builders ──────────────────────────────────────

	private string function buildBeforeFilters(required array associations) {
		var filters = "";
		var nl = chr(10);
		var t = chr(9);
		for (var assoc in arguments.associations) {
			if ((assoc.type ?: "") == "belongsTo") {
				var loaderName = "load" & variables.helpers.capitalize(variables.helpers.pluralize(assoc.name));
				filters &= t & t & 'filters(through="#loaderName#", only="new,edit,create,update");' & nl;
			}
		}
		return filters;
	}

	private string function buildForeignKeyLoaders(required array associations) {
		var loaders = "";
		var nl = chr(10);
		var t = chr(9);
		for (var assoc in arguments.associations) {
			if ((assoc.type ?: "") == "belongsTo") {
				var modelName = assoc.modelName ?: variables.helpers.capitalize(assoc.name);
				var pluralName = variables.helpers.pluralize(lCase(assoc.name));
				var loaderName = "load" & variables.helpers.capitalize(pluralName);
				loaders &= t & "private function #loaderName#() {" & nl;
				loaders &= t & t & '#pluralName# = model("#modelName#").findAll(order="id");' & nl;
				loaders &= t & "}" & nl & nl;
			}
		}
		return loaders;
	}

	private string function buildIndexHeaders(required array columns) {
		var headers = "";
		var nl = chr(10);
		var t = chr(9);
		for (var col in arguments.columns) {
			headers &= t & t & t & "<th>#variables.helpers.capitalize(col.name)#</th>" & nl;
		}
		return headers;
	}

	private string function buildIndexCells(required array columns, required string plural) {
		var cells = "";
		var nl = chr(10);
		var t = chr(9);
		for (var col in arguments.columns) {
			cells &= t & t & t & "<td>###arguments.plural#.#col.name###</td>" & nl;
		}
		return cells;
	}

	private string function buildShowFields(required array columns, required string singular) {
		var fields = "";
		var nl = chr(10);
		var t = chr(9);
		for (var col in arguments.columns) {
			fields &= t & "<dt>#variables.helpers.capitalize(col.name)#</dt>" & nl;
			fields &= t & "<dd>###arguments.singular#.#col.name###</dd>" & nl;
		}
		return fields;
	}

	private string function buildFormFields(required array columns, required string singular) {
		var fields = "";
		var nl = chr(10);
		var t = chr(9);
		for (var col in arguments.columns) {
			var helper = mapColumnToFormHelper(col);
			fields &= t & "<div>" & nl;
			fields &= t & t & '##' & helper & '(objectName="#arguments.singular#", property="#col.name#")##' & nl;
			fields &= t & "</div>" & nl;
		}
		return fields;
	}

	private string function mapColumnToFormHelper(required struct col) {
		var colType = lCase(col.type ?: "string");
		var colName = lCase(col.name);

		// Name-based conventions
		if (findNoCase("email", colName)) return "emailField";
		if (colName == "url" || colName == "website") return "urlField";
		if (findNoCase("phone", colName) || findNoCase("tel", colName)) return "telField";

		// Type-based mapping
		switch (colType) {
			case "text": case "clob": case "longtext":
				return "textArea";
			case "boolean": case "bit": case "cf_sql_bit":
				return "checkBox";
			case "integer": case "int": case "bigint": case "smallint": case "numeric":
				return "numberField";
			case "decimal": case "float": case "double": case "money":
				return "numberField";
			case "date":
				return "dateField";
			case "datetime": case "timestamp":
				return "dateTimeLocalField";
			default:
				return "textField";
		}
	}

	// ── Route injection ──────────────────────────────────────

	private boolean function injectAdminRoute(required string plural) {
		var routesPath = variables.projectRoot & "/config/routes.cfm";
		if (!fileExists(routesPath)) return false;

		var content = fileRead(routesPath);
		var nl = chr(10);
		var t = chr(9);
		var resourceLine = '.resources("' & arguments.plural & '")';

		// Check if this admin resource already exists
		if (findNoCase('scope(path="admin"', content) && findNoCase(resourceLine, content)) {
			return false;
		}

		// Try to find existing admin scope and append inside it
		if (reFindNoCase('\.scope\(\s*path\s*=\s*"admin"', content)) {
			// Find the admin scope opening and insert the resource before its .end()
			var adminScopePos = reFindNoCase('\.scope\(\s*path\s*=\s*"admin"[^)]*\)', content);
			if (adminScopePos > 0) {
				// Find the .end() that closes this scope — simple heuristic: first .end() after scope
				var afterScope = mid(content, adminScopePos, len(content));
				var endPos = findNoCase(".end()", afterScope);
				if (endPos > 0) {
					var insertAt = adminScopePos + endPos - 2;
					content = left(content, insertAt) & t & t & resourceLine & nl & t & mid(content, insertAt + 1, len(content));
					fileWrite(routesPath, content);
					return true;
				}
			}
		}

		// No existing admin scope — create one before CLI-Appends-Here or last .end()
		var marker = "// CLI-Appends-Here";
		var adminBlock = t & '.scope(path="admin", package="admin")' & nl;
		adminBlock &= t & t & resourceLine & nl;
		adminBlock &= t & ".end()" & nl & t;

		if (find(marker, content)) {
			content = replace(content, marker, adminBlock & marker);
		} else if (find(".end()", content)) {
			var lastEnd = content.lastIndexOf(".end()");
			if (lastEnd >= 0) {
				content = left(content, lastEnd) & adminBlock & mid(content, lastEnd + 1, len(content));
			}
		}

		fileWrite(routesPath, content);
		return true;
	}

	private string function processTemplate(required string template, required struct context) {
		var result = arguments.template;
		for (var key in arguments.context) {
			result = replaceNoCase(result, "{{#key#}}", arguments.context[key], "all");
		}
		return result;
	}

}
```

- [ ] **Step 3: Add generate admin subcommand to Module.cfc**

In the `generate()` function's switch statement, add a new case:

```cfml
case "admin":
	return generateAdmin(remaining);
```

Add the private handler function:

```cfml
/**
 * Generate admin CRUD interface for an existing model
 */
private string function generateAdmin(array args = []) {
	if (!arrayLen(arguments.args)) {
		out("Usage: wheels generate admin <modelName> [--force] [--no-routes]", "yellow");
		out("");
		out("Generates an admin controller and views by introspecting an existing model.");
		out("Requires a running server.");
		return "";
	}

	var modelName = capitalize(arguments.args[1]);
	var force = false;
	var noRoutes = false;
	for (var i = 2; i <= arrayLen(arguments.args); i++) {
		if (arguments.args[i] == "--force") force = true;
		if (arguments.args[i] == "--no-routes") noRoutes = true;
	}

	var serverPort = detectServerPort();
	if (!serverPort) {
		out("No running server detected. Start with 'wheels start' first.", "red");
		out("Admin generation requires a running server for model introspection.");
		return "";
	}

	// Introspect the model via the server
	out("Introspecting model: #modelName#...", "cyan");
	try {
		var introspectUrl = "http://localhost:#serverPort#/wheels/cli?command=introspect&model=#modelName#&format=json";
		var response = makeHttpRequest(introspectUrl);
		var modelData = deserializeJSON(response);

		if (!modelData.success) {
			out("Error: #modelData.message#", "red");
			return "";
		}
	} catch (any e) {
		out("Error introspecting model: #e.message#", "red");
		return "";
	}

	// Generate admin files
	var svc = getService("admin");
	var result = svc.generateAdmin(modelData=modelData, force=force, noRoutes=noRoutes);

	if (result.success) {
		for (var generated in result.generated) {
			printCreated(generated);
		}
		out("");
		out("Admin interface generated for #modelName#.", "green");
		out("Visit /admin/#lCase(variables.helpers.pluralize(modelName))# after reloading.", "cyan");
	} else {
		for (var err in result.errors) {
			out(err, "red");
		}
	}

	return "";
}
```

In `getService()` switch, add:

```cfml
case "admin":
	variables.services.admin = new services.Admin(
		helpers = getService("helpers"),
		templateService = getService("templates"),
		projectRoot = variables.projectRoot,
		moduleRoot = variables.moduleRoot
	);
	break;
```

Also update the `generate()` help text to include admin:

In the help output section of `generate()`, add:

```cfml
out("  admin         Generate admin CRUD interface for an existing model");
```

And in the examples:

```cfml
out("  wheels generate admin User");
```

- [ ] **Step 4: Test admin generation**

```bash
# Requires running server with at least one model
wheels start

# Generate admin for an existing model
wheels generate admin User

# Check generated files
ls app/controllers/admin/Users.cfc
ls app/views/admin/users/
cat app/controllers/admin/Users.cfc

# Check route was injected
grep -i "admin" config/routes.cfm
```

- [ ] **Step 5: Commit**

```bash
git add cli/lucli/services/Admin.cfc cli/lucli/templates/admin/ cli/lucli/Module.cfc
git commit -m "feat(cli): add generate admin command with model introspection"
```

---

### Task 8: MCP Tool Schemas

**Files:**
- Modify: `cli/lucli/services/MCP.cfc`

- [ ] **Step 1: Read current MCP.cfc**

Read `cli/lucli/services/MCP.cfc` to understand the existing tool schema format before adding new entries.

- [ ] **Step 2: Add tool schemas for new commands**

Add the following tool schemas to the `getToolSchemas()` return array in MCP.cfc:

```cfml
{
	name: "wheels_destroy",
	description: "Remove generated Wheels components (model, controller, view, resource) with cleanup",
	inputSchema: {
		type: "object",
		properties: {
			name: {type: "string", description: "Component name to destroy (e.g., User, Products)"},
			type: {type: "string", description: "Type to destroy: resource (default), model, controller, view", enum: ["resource", "model", "controller", "view"]}
		},
		required: ["name"]
	}
},
{
	name: "wheels_doctor",
	description: "Run health checks on Wheels application (directories, files, config, permissions, database)",
	inputSchema: {
		type: "object",
		properties: {
			verbose: {type: "boolean", description: "Show all passed checks (default: false)"}
		}
	}
},
{
	name: "wheels_stats",
	description: "Show code statistics (files, LOC, comments, blanks) across project directories",
	inputSchema: {
		type: "object",
		properties: {
			verbose: {type: "boolean", description: "Show top 10 largest files (default: false)"}
		}
	}
},
{
	name: "wheels_notes",
	description: "Extract TODO, FIXME, OPTIMIZE and other annotations from codebase",
	inputSchema: {
		type: "object",
		properties: {
			annotations: {type: "string", description: "Comma-separated annotation types (default: TODO,FIXME,OPTIMIZE)"},
			custom: {type: "string", description: "Additional custom annotation types to search"}
		}
	}
},
{
	name: "wheels_db",
	description: "Database management: reset (migrate + seed), status (migration status), version (schema version)",
	inputSchema: {
		type: "object",
		properties: {
			action: {type: "string", description: "Subcommand: reset, status, version", enum: ["reset", "status", "version"]},
			skipSeed: {type: "boolean", description: "Skip seeding on reset (default: false)"},
			pending: {type: "boolean", description: "Show only pending migrations for status"},
			detailed: {type: "boolean", description: "Show detailed version info"}
		},
		required: ["action"]
	}
},
{
	name: "wheels_upgrade_check",
	description: "Check for breaking changes before upgrading Wheels to a new version",
	inputSchema: {
		type: "object",
		properties: {
			to: {type: "string", description: "Target version (defaults to latest release)"}
		}
	}
}
```

- [ ] **Step 3: Test MCP discovery**

```bash
# Verify MCP tools include new commands
wheels mcp

# Expected: New tools listed in the output
```

- [ ] **Step 4: Commit**

```bash
git add cli/lucli/services/MCP.cfc
git commit -m "feat(cli): add MCP tool schemas for new commands"
```

---

## Self-Review

**Spec coverage check:**

| Spec Section | Task |
|-------------|------|
| Command 1: destroy | Task 1 |
| Command 2: doctor | Task 2 |
| Command 3: stats | Task 3 |
| Command 4: notes | Task 3 (same service) |
| Command 5: generate admin | Task 6 (core endpoint) + Task 7 |
| Command 6: db reset | Task 4 |
| Command 7: db status/version | Task 4 |
| Command 8: upgrade check | Task 5 |
| Core introspect endpoint | Task 6 |
| MCP integration | Task 8 |

All spec sections covered.

**Placeholder scan:** No TBD, TODO, or "implement later" found. All code blocks are complete.

**Type consistency check:**
- `getNameVariants()` returns `{singular, plural, singularCap, pluralCap}` — used consistently in Destroy.cfc and referenced in spec
- `getService("destroy")` matches constructor `new services.Destroy(helpers, projectRoot, moduleRoot)` — consistent
- `getService("doctor")` matches constructor `new services.Doctor(projectRoot)` — consistent
- `getService("stats")` matches constructor `new services.Stats(helpers, projectRoot)` — consistent
- `getService("admin")` matches constructor `new services.Admin(helpers, templateService, projectRoot, moduleRoot)` — consistent
- `sprintf()` helper used in Task 3 (stats) and Task 4 (db status) — defined in Task 3
- `prompt()` used in destroy and db reset — this is inherited from LuCLI BaseModule

**Note on `prompt()` and `out()` availability:** These are inherited from `modules.BaseModule` which Module.cfc extends. The `prompt()` function provides interactive input in LuCLI module context. The `out()` function outputs colored text. Both are confirmed available from the existing Module.cfc code.

**Note on `helpers` reference in `generateAdmin()`:** The private function references `variables.helpers` which isn't a direct variable — it should go through `getService("helpers")`. However, looking at existing code in Module.cfc, the `capitalize()` function is a local private helper. Update the `generateAdmin()` function to use `getService("helpers").pluralize()` instead of `variables.helpers.pluralize()`.
