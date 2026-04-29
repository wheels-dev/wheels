/**
 * In-process test runner for Wheels applications.
 *
 * Designed to be invoked by LuCLI's LuceeScriptEngine, sharing the same
 * JVM and Lucee context as the application. This eliminates HTTP round-trips
 * for test execution.
 *
 * Usage from LuceeScriptEngine:
 *   var runner = new modules.wheels.services.TestRunner(projectRoot);
 *   var result = runner.run(options);
 *
 * Usage from HTTP fallback (Module.cfc delegates here when server is available):
 *   var runner = new modules.wheels.services.TestRunner(projectRoot);
 *   var result = runner.runViaHttp(serverPort, options);
 */
component {

	/**
	 * @projectRoot Absolute path to the project root (where vendor/wheels lives)
	 */
	function init(required string projectRoot) {
		variables.projectRoot = arguments.projectRoot;
		return this;
	}

	/**
	 * Run tests in-process by invoking the Wheels test runner directly.
	 *
	 * Requires the Wheels application context (application.wheels) to be initialized.
	 * This is the Phase 4 path — LuCLI's ScriptEngine loads the app context first.
	 *
	 * @options Struct with keys: type (core|app), db, directory, format, reload
	 * @return Struct with test results (same shape as TestBox JSON output)
	 */
	public struct function run(struct options = {}) {
		var opts = {
			type: options.type ?: "core",
			db: options.db ?: "sqlite",
			format: options.format ?: "json",
			directory: options.directory ?: "",
			reload: options.reload ?: true
		};

		// Ensure application context exists
		if (!structKeyExists(application, "wheels")) {
			throw(
				type="Wheels.TestRunner.NoContext",
				message="Wheels application context not initialized. Run wheels server start or load the app context first."
			);
		}

		// Build the params struct that $WheelsRunner expects
		var params = {
			type: opts.type,
			format: "json",
			db: opts.db,
			reload: opts.reload
		};
		if (len(opts.directory)) {
			params.directory = opts.directory;
		}

		// Invoke the Wheels test runner directly
		var testResult = $createObjectFromRoot(
			fileName="Test",
			method="$WheelsRunner",
			options=params,
			path=application.wheels.wheelsComponentPath
		);

		// Parse JSON result into struct
		if (isSimpleValue(testResult) && isJSON(testResult)) {
			return deserializeJSON(testResult);
		}
		if (isStruct(testResult)) {
			return testResult;
		}

		return {
			success: false,
			message: "Unexpected test result format",
			raw: isSimpleValue(testResult) ? testResult : serializeJSON(testResult)
		};
	}

	/**
	 * Run tests via HTTP to a running Wheels server.
	 *
	 * This is the Phase 2-3 path — used when a server is running.
	 *
	 * @serverPort Port of the running Wheels server
	 * @options Struct with keys: coreTests, db, filter, format
	 * @return Struct with test results
	 */
	public struct function runViaHttp(required numeric serverPort, struct options = {}) {
		var coreTests = options.coreTests ?: true;
		var db = options.db ?: "sqlite";
		var filter = options.filter ?: "";
		var format = options.format ?: "json";

		var testPath = coreTests ? "/wheels/core/tests" : "/wheels/app/tests";
		var testUrl = "http://localhost:#serverPort##testPath#?format=#format#&db=#db#&reload=true";
		if (len(filter)) {
			testUrl &= "&directory=#filter#";
		}

		var httpService = new http(url=testUrl, method="GET", timeout=600);
		var httpResult = httpService.send().getPrefix();

		if (httpResult.statusCode contains "200" && isJSON(httpResult.fileContent)) {
			return deserializeJSON(httpResult.fileContent);
		}

		return {
			success: false,
			message: "HTTP #httpResult.statusCode#",
			raw: httpResult.fileContent
		};
	}

	/**
	 * Determine whether tests should run as core (framework) or app tests.
	 *
	 * Always returns "app" — every Wheels app has the framework's tests
	 * vendored at vendor/wheels/tests/, so that signal can't tell user apps
	 * apart from the framework repo. Callers that explicitly want to run
	 * framework specs should pass `--core` (CLI) or `type: "core"` (service).
	 *
	 * @return "app" — the safe default for user apps
	 */
	public string function detectTestType() {
		return "app";
	}

	/**
	 * Get the test directory path based on type and filter.
	 *
	 * @type "core" or "app"
	 * @filter Optional directory/file filter (e.g., "model", "controller")
	 * @return Dot-delimited directory path for TestBox
	 */
	public string function resolveTestDirectory(required string type, string filter = "") {
		var basePath = type == "core" ? "wheels.tests.specs" : "tests.specs";
		if (!len(filter)) {
			return basePath;
		}
		// If filter is a simple name, treat as subdirectory
		if (!find("/", filter) && !find(".", filter)) {
			return basePath & "." & filter;
		}
		// If filter contains path separators, convert to dots
		return replace(filter, "/", ".", "all");
	}

	/**
	 * Count *Spec.cfc files on disk in the given test directory.
	 *
	 * Used by the CLI to detect TestBox silently swallowing unloadable
	 * specs: when this count exceeds the TestBox bundle count, at least
	 * one spec failed to compile.
	 *
	 * @testDirectory Dotted-path directory (e.g. "tests.specs" or
	 *                "wheels.tests.specs.model")
	 * @return Numeric count, or 0 if the directory doesn't exist.
	 */
	public numeric function countSpecsOnDisk(required string testDirectory) {
		// Resolve dotted path -> filesystem path under projectRoot.
		var fsPath = variables.projectRoot & "/" & replace(arguments.testDirectory, ".", "/", "all");
		if (!directoryExists(fsPath)) {
			return 0;
		}
		var specs = directoryList(fsPath, true, "name", "*Spec.cfc");
		return arrayLen(specs);
	}

	/**
	 * List the on-disk spec file paths as dotted bundle names.
	 *
	 * Returned paths are dotted, matching TestBox's bundle-name convention,
	 * so a caller can compute "specs-on-disk minus bundles-loaded" to find
	 * which specific specs failed to compile.
	 *
	 * @testDirectory Dotted-path directory.
	 * @return Array of dotted bundle names.
	 */
	public array function listSpecsOnDisk(required string testDirectory) {
		var fsPath = variables.projectRoot & "/" & replace(arguments.testDirectory, ".", "/", "all");
		if (!directoryExists(fsPath)) {
			return [];
		}
		var specs = directoryList(fsPath, true, "path", "*Spec.cfc");
		var rv = [];
		for (var spec in specs) {
			// Convert filesystem path back to dotted bundle name.
			var rel = replace(spec, fsPath, "");
			rel = reReplace(rel, "^[\\/]+", "");
			rel = reReplace(rel, "\.cfc$", "");
			rel = replace(rel, "/", ".", "all");
			rel = replace(rel, "\", ".", "all");
			arrayAppend(rv, arguments.testDirectory & "." & rel);
		}
		return rv;
	}

}
