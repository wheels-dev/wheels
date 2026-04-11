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
