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

		// Ensure all required and recommended directories exist in the temp project.
		// directoryCopy skips empty source directories, so we create them explicitly.
		var requiredDirs = [
			"app",
			"app/controllers",
			"app/models",
			"app/views",
			"app/helpers",
			"app/migrator",
			"app/migrator/migrations",
			"config",
			"public",
			"public/files",
			"tests",
			"tests/specs",
			"tests/specs/models",
			"tests/specs/controllers",
			"tests/specs/views"
		];
		for (var reqDir in requiredDirs) {
			var fullPath = tempBase & "/" & reqDir;
			if (!directoryExists(fullPath)) {
				directoryCreate(fullPath, true);
			}
		}

		// Ensure config/routes.cfm exists with minimal valid content
		var routesPath = tempBase & "/config/routes.cfm";
		if (!fileExists(routesPath)) {
			var nl = chr(10);
			var t = chr(9);
			var routesContent = "// routes" & nl & "mapper()" & nl & t & "// CLI-Appends-Here" & nl & t & ".wildcard()" & nl & ".end();";
			fileWrite(routesPath, routesContent);
		}

		// Ensure config/settings.cfm exists with datasource config (satisfies Doctor health check)
		var settingsPath = tempBase & "/config/settings.cfm";
		if (!fileExists(settingsPath)) {
			var nl = chr(10);
			var settingsContent = "// settings" & nl & "set(dataSourceName=" & chr(34) & "wheels" & chr(34) & ");";
			fileWrite(settingsPath, settingsContent);
		}

		// Create a placeholder migration so Doctor doesn't warn about missing migrations
		var migrationPlaceholderPath = tempBase & "/app/migrator/migrations/00000000000000_placeholder.cfc";
		if (!fileExists(migrationPlaceholderPath)) {
			fileWrite(migrationPlaceholderPath, "component extends=" & chr(34) & "wheels.migrator.Migration" & chr(34) & " {}");
		}

		// Create a placeholder test spec so Doctor doesn't warn about missing tests
		var testPlaceholderPath = tempBase & "/tests/specs/PlaceholderSpec.cfc";
		if (!fileExists(testPlaceholderPath)) {
			fileWrite(testPlaceholderPath, "component extends=" & chr(34) & "wheels.WheelsTest" & chr(34) & " {}");
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
