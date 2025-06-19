/**
 * Execute a script file in the Wheels application context
 *
 * Examples:
 * {code:bash}
 * wheels runner scripts/migrate-data.cfm
 * wheels runner scripts/cleanup.cfs
 * wheels runner /absolute/path/to/script.cfm environment=production
 * {code}
 **/
component extends="base" {

	property name="fileSystem" inject="fileSystem";

	/**
	 * @file Path to the script file to execute
	 * @environment Environment to run in (development, testing, production)
	 * @verbose Show detailed output
	 * @params Additional parameters to pass to the script (JSON format)
	 **/
	function run(
		required string file,
		string environment = "development",
		boolean verbose = false,
		string params
	) {
		// Check if we're in a Wheels application
		if (!isWheelsApp()) {
			print.redLine("This doesn't appear to be a Wheels application directory.");
			print.line("Looking for /vendor/wheels, /config, and /app folders");
			return;
		}

		// Resolve the script file path
		var scriptPath = fileSystemUtil.resolvePath(arguments.file);
		
		// Check if file exists
		if (!fileExists(scriptPath)) {
			print.redLine("Script file not found: #arguments.file#");
			print.line("Resolved path: #scriptPath#");
			return;
		}

		// Get file extension
		var fileExt = listLast(scriptPath, ".");
		if (!listFindNoCase("cfm,cfc,cfs", fileExt)) {
			print.redLine("Invalid file type. Script must be a .cfm, .cfc, or .cfs file");
			return;
		}

		// Get server info
		var serverInfo = getServerInfoSafe();
		if (!structKeyExists(serverInfo, "serverURL")) {
			print.redLine("Server must be running to execute scripts.");
			print.line("Start the server with: wheels server start");
			return;
		}

		print.boldLine("Wheels Script Runner");
		print.line("===================");
		print.line();
		print.line("Script: #arguments.file#");
		print.line("Environment: #arguments.environment#");
		
		// Parse additional parameters if provided
		var scriptParams = {};
		if (!isNull(arguments.params) && len(arguments.params)) {
			try {
				scriptParams = deserializeJSON(arguments.params);
				print.line("Parameters: #arguments.params#");
			} catch (any e) {
				print.yellowLine("Warning: Invalid JSON in params argument, ignoring parameters");
			}
		}
		
		print.line();
		print.line("Executing script...");
		print.line();

		try {
			// Read the script content
			var scriptContent = fileRead(scriptPath);
			
			// Build the execution URL
			var runnerURL = buildRunnerURL(serverInfo, arguments.environment);
			
			// Execute the script via HTTP
			var result = executeScript(runnerURL, scriptContent, scriptParams, arguments.verbose);
			
			// Display results
			if (result.success) {
				if (len(result.output)) {
					print.line(result.output);
				}
				print.line();
				print.greenLine("✓ Script executed successfully!");
				
				if (arguments.verbose && structKeyExists(result, "executionTime")) {
					print.line("Execution time: #result.executionTime#ms");
				}
			} else {
				print.redLine("✗ Script execution failed!");
				print.redLine("Error: #result.error#");
				if (len(result.detail)) {
					print.line("Detail: #result.detail#");
				}
				if (structKeyExists(result, "line")) {
					print.line("Line: #result.line#");
				}
			}
			
		} catch (any e) {
			print.redLine("Failed to execute script: #e.message#");
			print.line("Detail: #e.detail#");
		}
	}

	/**
	 * Build the runner URL
	 **/
	private string function buildRunnerURL(required struct serverInfo, required string environment) {
		var runnerURL = arguments.serverInfo.serverURL;
		
		// Add /public if needed (same logic as console)
		var serverJSON = fileSystemUtil.resolvePath("server.json");
		var addPublic = false;
		
		if (fileExists(serverJSON)) {
			try {
				var serverConfig = deserializeJSON(fileRead(serverJSON));
				if (!structKeyExists(serverConfig, "web") || !structKeyExists(serverConfig.web, "webroot") ||
					!findNoCase("public", serverConfig.web.webroot)) {
					if (fileExists(fileSystemUtil.resolvePath("public/index.cfm"))) {
						addPublic = true;
					}
				}
			} catch (any e) {
				if (fileExists(fileSystemUtil.resolvePath("public/index.cfm"))) {
					addPublic = true;
				}
			}
		}
		
		if (addPublic) {
			runnerURL &= "/public";
		}
		
		runnerURL &= "/?controller=wheels&action=wheels&view=runner&environment=#arguments.environment#";
		
		return runnerURL;
	}

	/**
	 * Execute the script via HTTP
	 **/
	private struct function executeScript(
		required string url,
		required string scriptContent,
		required struct params,
		boolean verbose = false
	) {
		var http = new Http(url=arguments.url, method="POST", timeout=300);
		
		// Add script content and params as form fields
		http.addParam(type="formfield", name="scriptContent", value=arguments.scriptContent);
		http.addParam(type="formfield", name="params", value=serializeJSON(arguments.params));
		http.addParam(type="formfield", name="verbose", value=arguments.verbose);
		
		var result = http.send().getPrefix();
		
		if (result.statusCode != 200) {
			throw(message="HTTP error #result.statusCode#", detail=result.statusText);
		}
		
		if (!isJSON(result.fileContent)) {
			throw(message="Invalid response from server", detail=left(result.fileContent, 500));
		}
		
		return deserializeJSON(result.fileContent);
	}

	/**
	 * Get server info with error handling
	 **/
	private struct function getServerInfoSafe() {
		try {
			return $getServerInfo();
		} catch (any e) {
			return {};
		}
	}

}