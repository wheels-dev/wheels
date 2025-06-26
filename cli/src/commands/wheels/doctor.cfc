/**
 * Run health checks on your Wheels application
 *
 * {code:bash}
 * wheels doctor
 * wheels doctor verbose=true
 * {code}
 */
component extends="base" {

	property name="fileSystem" inject="fileSystem";

	/**
	 * @verbose Show detailed diagnostic information
	 * @help Run comprehensive health checks on your Wheels application
	 */
	public void function run(boolean verbose = false) {
		local.appPath = getCWD();
		
		if (!isWheelsApp(local.appPath)) {
			error("This command must be run from a Wheels application directory");
			return;
		}
		
		print.line();
		print.boldGreenLine("Wheels Application Health Check");
		print.line(RepeatString("=", 70));
		
		local.issues = [];
		local.warnings = [];
		local.passed = [];
		
		// Run checks
		checkRequiredDirectories(local.appPath, local.issues, local.warnings, local.passed);
		checkRequiredFiles(local.appPath, local.issues, local.warnings, local.passed);
		checkConfiguration(local.appPath, local.issues, local.warnings, local.passed);
		checkDatabase(local.appPath, local.issues, local.warnings, local.passed);
		checkPermissions(local.appPath, local.issues, local.warnings, local.passed);
		checkDependencies(local.appPath, local.issues, local.warnings, local.passed);
		checkEnvironment(local.appPath, local.issues, local.warnings, local.passed);
		
		// Display results
		if (ArrayLen(local.issues)) {
			print.line();
			print.boldRedLine("Issues Found (" & ArrayLen(local.issues) & "):");
			for (local.issue in local.issues) {
				print.redLine("  ✗ " & local.issue);
			}
		}
		
		if (ArrayLen(local.warnings)) {
			print.line();
			print.boldYellowLine("Warnings (" & ArrayLen(local.warnings) & "):");
			for (local.warning in local.warnings) {
				print.yellowLine("  ⚠ " & local.warning);
			}
		}
		
		if (arguments.verbose || (!ArrayLen(local.issues) && !ArrayLen(local.warnings))) {
			print.line();
			print.boldGreenLine("Checks Passed (" & ArrayLen(local.passed) & "):");
			for (local.pass in local.passed) {
				print.greenLine("  ✓ " & local.pass);
			}
		}
		
		// Summary
		print.line();
		print.line(RepeatString("=", 70));
		
		local.totalChecks = ArrayLen(local.issues) + ArrayLen(local.warnings) + ArrayLen(local.passed);
		
		if (ArrayLen(local.issues)) {
			print.boldRedLine("Health Status: CRITICAL");
			print.redLine("Found " & ArrayLen(local.issues) & " critical issues that need immediate attention.");
		} else if (ArrayLen(local.warnings)) {
			print.boldYellowLine("Health Status: WARNING");
			print.yellowLine("Found " & ArrayLen(local.warnings) & " warnings that should be addressed.");
		} else {
			print.boldGreenLine("Health Status: HEALTHY");
			print.greenLine("All " & local.totalChecks & " checks passed!");
		}
		
		print.line();
		
		// Provide recommendations
		if (ArrayLen(local.issues) || ArrayLen(local.warnings)) {
			print.boldLine("Recommendations:");
			
			if (ArrayFind(local.issues, function(i) { return FindNoCase("database", i); })) {
				print.cyanLine("  • Configure your database connection in config/settings.cfm");
			}
			
			if (ArrayFind(local.issues, function(i) { return FindNoCase("directory", i); })) {
				print.cyanLine("  • Run 'wheels g app' to create missing directories");
			}
			
			if (ArrayFind(local.warnings, function(w) { return FindNoCase("test", w); })) {
				print.cyanLine("  • Add tests to improve code quality and reliability");
			}
			
			if (ArrayFind(local.warnings, function(w) { return FindNoCase("migration", w); })) {
				print.cyanLine("  • Run 'wheels dbmigrate latest' to apply pending migrations");
			}
			
			print.line();
		}
	}

	private void function checkRequiredDirectories(
		required string appPath,
		required array issues,
		required array warnings,
		required array passed
	) {
		local.requiredDirs = [
			{path: "app", critical: true},
			{path: "app/controllers", critical: true},
			{path: "app/models", critical: true},
			{path: "app/views", critical: true},
			{path: "config", critical: true},
			{path: "db", critical: false},
			{path: "db/migrate", critical: false},
			{path: "public", critical: true},
			{path: "tests", critical: false}
		];
		
		for (local.dir in local.requiredDirs) {
			local.fullPath = arguments.appPath & "/" & local.dir.path;
			if (DirectoryExists(local.fullPath)) {
				ArrayAppend(arguments.passed, "Directory exists: " & local.dir.path);
			} else if (local.dir.critical) {
				ArrayAppend(arguments.issues, "Missing critical directory: " & local.dir.path);
			} else {
				ArrayAppend(arguments.warnings, "Missing recommended directory: " & local.dir.path);
			}
		}
	}

	private void function checkRequiredFiles(
		required string appPath,
		required array issues,
		required array warnings,
		required array passed
	) {
		local.requiredFiles = [
			{path: "Application.cfc", critical: true},
			{path: "config/routes.cfm", critical: true},
			{path: "config/settings.cfm", critical: true},
			{path: "box.json", critical: false},
			{path: ".gitignore", critical: false},
			{path: "README.md", critical: false}
		];
		
		for (local.file in local.requiredFiles) {
			local.fullPath = arguments.appPath & "/" & local.file.path;
			if (FileExists(local.fullPath)) {
				ArrayAppend(arguments.passed, "File exists: " & local.file.path);
			} else if (local.file.critical) {
				ArrayAppend(arguments.issues, "Missing critical file: " & local.file.path);
			} else {
				ArrayAppend(arguments.warnings, "Missing recommended file: " & local.file.path);
			}
		}
	}

	private void function checkConfiguration(
		required string appPath,
		required array issues,
		required array warnings,
		required array passed
	) {
		// Check Application.cfc
		local.appFile = arguments.appPath & "/Application.cfc";
		if (FileExists(local.appFile)) {
			try {
				local.appContent = FileRead(local.appFile);
				
				// Check for required settings
				if (!FindNoCase("this.name", local.appContent)) {
					ArrayAppend(arguments.warnings, "Application.cfc missing 'this.name' setting");
				} else {
					ArrayAppend(arguments.passed, "Application name is configured");
				}
				
				if (!FindNoCase("this.sessionManagement", local.appContent)) {
					ArrayAppend(arguments.warnings, "Session management not configured");
				} else {
					ArrayAppend(arguments.passed, "Session management is configured");
				}
				
			} catch (any e) {
				ArrayAppend(arguments.issues, "Unable to read Application.cfc: " & e.message);
			}
		}
		
		// Check routes
		local.routesFile = arguments.appPath & "/config/routes.cfm";
		if (FileExists(local.routesFile)) {
			try {
				local.routesContent = FileRead(local.routesFile);
				if (Len(Trim(local.routesContent)) < 10) {
					ArrayAppend(arguments.warnings, "Routes file appears to be empty");
				} else {
					ArrayAppend(arguments.passed, "Routes are configured");
				}
			} catch (any e) {
				ArrayAppend(arguments.warnings, "Unable to read routes file");
			}
		}
	}

	private void function checkDatabase(
		required string appPath,
		required array issues,
		required array warnings,
		required array passed
	) {
		// Check for database configuration
		local.hasDB = false;
		
		// Check settings.cfm
		local.settingsFile = arguments.appPath & "/config/settings.cfm";
		if (FileExists(local.settingsFile)) {
			try {
				local.content = FileRead(local.settingsFile);
				if (FindNoCase("datasource", local.content) || FindNoCase("dataSourceName", local.content)) {
					local.hasDB = true;
					ArrayAppend(arguments.passed, "Database configuration found");
				}
			} catch (any e) {
				// Continue
			}
		}
		
		// Check .env file
		local.envFile = arguments.appPath & "/.env";
		if (FileExists(local.envFile)) {
			try {
				local.content = FileRead(local.envFile);
				if (FindNoCase("DATABASE", local.content) || FindNoCase("DB_", local.content)) {
					local.hasDB = true;
					ArrayAppend(arguments.passed, "Database environment variables found");
				}
			} catch (any e) {
				// Continue
			}
		}
		
		if (!local.hasDB) {
			ArrayAppend(arguments.warnings, "No database configuration found");
		}
		
		// Check for migrations
		local.migrationsPath = arguments.appPath & "/db/migrate";
		if (DirectoryExists(local.migrationsPath)) {
			try {
				local.migrations = DirectoryList(local.migrationsPath, false, "name", "*.cfc");
				if (ArrayLen(local.migrations) == 0) {
					ArrayAppend(arguments.warnings, "No database migrations found");
				} else {
					ArrayAppend(arguments.passed, "Found " & ArrayLen(local.migrations) & " database migrations");
				}
			} catch (any e) {
				// Continue
			}
		}
	}

	private void function checkPermissions(
		required string appPath,
		required array issues,
		required array warnings,
		required array passed
	) {
		// Check write permissions on key directories
		local.writableDirs = [
			"db/migrate",
			"public/files",
			"tmp",
			"logs"
		];
		
		for (local.dir in local.writableDirs) {
			local.fullPath = arguments.appPath & "/" & local.dir;
			if (DirectoryExists(local.fullPath)) {
				try {
					// Try to create a test file
					local.testFile = local.fullPath & "/.write_test_" & CreateUUID();
					FileWrite(local.testFile, "test");
					FileDelete(local.testFile);
					ArrayAppend(arguments.passed, "Write permission OK: " & local.dir);
				} catch (any e) {
					ArrayAppend(arguments.warnings, "No write permission: " & local.dir);
				}
			}
		}
	}

	private void function checkDependencies(
		required string appPath,
		required array issues,
		required array warnings,
		required array passed
	) {
		// Check box.json
		local.boxJsonPath = arguments.appPath & "/box.json";
		if (FileExists(local.boxJsonPath)) {
			try {
				local.boxJson = DeserializeJSON(FileRead(local.boxJsonPath));
				
				// Check for wheels dependency
				if (StructKeyExists(local.boxJson, "dependencies")) {
					if (StructKeyExists(local.boxJson.dependencies, "wheels-core") || StructKeyExists(local.boxJson.dependencies, "cfwheels")) {
						ArrayAppend(arguments.passed, "Wheels dependency declared");
					} else {
						ArrayAppend(arguments.warnings, "Wheels not listed in dependencies");
					}
				}
				
				// Check if modules are installed
				local.modulesPath = arguments.appPath & "/modules";
				if (DirectoryExists(local.modulesPath)) {
					ArrayAppend(arguments.passed, "Modules directory exists");
				} else {
					ArrayAppend(arguments.warnings, "Modules not installed (run 'box install')");
				}
				
			} catch (any e) {
				ArrayAppend(arguments.warnings, "Unable to parse box.json");
			}
		}
	}

	private void function checkEnvironment(
		required string appPath,
		required array issues,
		required array warnings,
		required array passed
	) {
		// Check CFML engine compatibility
		try {
			local.engineVersion = server.lucee.version ?: server.coldfusion.productversion;
			ArrayAppend(arguments.passed, "CFML Engine version: " & local.engineVersion);
		} catch (any e) {
			ArrayAppend(arguments.warnings, "Unable to determine CFML engine version");
		}
		
		// Check for test suite
		local.testsPath = arguments.appPath & "/tests";
		if (DirectoryExists(local.testsPath)) {
			try {
				local.tests = DirectoryList(local.testsPath, true, "name", "*.cfc");
				if (ArrayLen(local.tests) == 0) {
					ArrayAppend(arguments.warnings, "No tests found");
				} else {
					ArrayAppend(arguments.passed, "Found " & ArrayLen(local.tests) & " test files");
				}
			} catch (any e) {
				// Continue
			}
		}
		
		// Check for security files
		if (!FileExists(arguments.appPath & "/.gitignore")) {
			ArrayAppend(arguments.warnings, "No .gitignore file (sensitive files may be committed)");
		} else {
			ArrayAppend(arguments.passed, ".gitignore file exists");
		}
	}

}