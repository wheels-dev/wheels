/**
 * Simple Task Runner for Wheels Framework Development
 * Provides basic Docker functionality without dependencies
 */
component {

	// Default settings
	variables.defaultEngine = "lucee6";
	variables.defaultDatabase = "h2";
	variables.supportedEngines = ["lucee5", "lucee6", "lucee7", "adobe2018", "adobe2021", "adobe2023", "adobe2025"];
	variables.supportedDatabases = ["h2", "mysql", "postgresql", "sqlserver"];
	
	// Engine-specific default ports
	variables.enginePorts = {
		"lucee5": 60005,
		"lucee6": 60006,
		"lucee7": 60007,
		"adobe2018": 62018,
		"adobe2021": 62021,
		"adobe2023": 62023,
		"adobe2025": 62025
	};

	/**
	 * Start the development server
	 */
	function run(
		string engine = variables.defaultEngine,
		string database = variables.defaultDatabase,
		numeric port = 0
	) {
		// Validate engine
		if (!arrayContains(variables.supportedEngines, arguments.engine)) {
			print.redLine("Unsupported engine: #arguments.engine#");
			print.line("Supported engines: #arrayToList(variables.supportedEngines)#");
			return;
		}

		// Validate database
		if (!arrayContains(variables.supportedDatabases, arguments.database)) {
			print.redLine("Unsupported database: #arguments.database#");
			print.line("Supported databases: #arrayToList(variables.supportedDatabases)#");
			return;
		}

		// Use engine-specific port if not specified
		if (arguments.port == 0) {
			arguments.port = variables.enginePorts[arguments.engine];
		}

		print.boldGreenLine("Starting Wheels development server...");
		print.line("Engine: #arguments.engine#");
		print.line("Database: #arguments.database#");
		print.line("Port: #arguments.port#");

		// Generate docker-compose.yml
		generateDockerCompose(arguments.engine, arguments.database, arguments.port);

		// Start containers
		command("!docker compose up -d").run();
		
		print.greenLine("Server starting...");
		print.line("Access your application at: http://localhost:#arguments.port#");
		print.line("");
		print.yellowLine("To stop server: box task run stop");
	}

	/**
	 * Stop the development server
	 */
	function stop() {
		print.yellowLine("Stopping Wheels development server...");
		command("!docker compose down").run();
		print.greenLine("Server stopped!");
	}

	/**
	 * Show logs
	 */
	function logs(boolean follow = false, numeric tail = 100) {
		var cmd = "docker compose logs";
		
		if (arguments.follow) {
			cmd &= " -f";
		}
		
		if (arguments.tail > 0) {
			cmd &= " --tail #arguments.tail#";
		}
		
		command("!" & cmd).run();
	}

	/**
	 * Clean up containers and volumes
	 */
	function clean() {
		print.yellowLine("Cleaning up Docker resources...");
		command("!docker compose down -v").run();
		print.greenLine("Cleanup completed!");
	}

	/**
	 * Check status
	 */
	function status() {
		print.boldLine("Checking server status...");
		command("!docker compose ps").run();
	}

	/**
	 * Run application tests
	 */
	function test(string reporter = "text") {
		print.boldBlueLine("Running application tests...");
		
		// Check if server is running
		if (!isServerRunning()) {
			print.redLine("Server is not running. Start it with: box task run start");
			return;
		}
		
		// Get port from docker-compose.yml
		var port = getPort();
		var testUrl = "http://localhost:#port#/index.cfm/tests/runner?reporter=#arguments.reporter#";
		
		print.line("Running tests at: #testUrl#");
		print.line();
		
		// Make HTTP request to run tests
		try {
			cfhttp(url=testUrl, method="GET", timeout=30, result="testResult");
			
			if (testResult.statusCode contains "200") {
				// For text reporter, strip HTML if present
				var output = testResult.fileContent;
				if (arguments.reporter == "text" && output contains "<") {
					// Try to extract just the text content
					output = reReplace(output, "<[^>]*>", "", "all");
					output = reReplace(output, "[\t\r\n]+", chr(10), "all");
					output = trim(output);
				}
				print.line(output);
			} else {
				print.redLine("Failed to run tests. Status: #testResult.statusCode#");
			}
		} catch (any e) {
			print.redLine("Error running tests: #e.message#");
			print.line("You can manually access the tests at: #testUrl#");
		}
	}
	
	/**
	 * Run core framework tests
	 */
	function testCore(string format = "txt") {
		print.boldBlueLine("Running core framework tests...");
		
		// Check if server is running
		if (!isServerRunning()) {
			print.redLine("Server is not running. Start it with: box task run start");
			return;
		}
		
		// Get port from docker-compose.yml
		var port = getPort();
		var testUrl = "http://localhost:#port#/core-tests/runner.cfm?format=#arguments.format#";
		
		print.line("Running core tests at: #testUrl#");
		print.line();
		
		// Make HTTP request to run tests
		try {
			cfhttp(url=testUrl, method="GET", timeout=60, result="testResult");
			
			if (testResult.statusCode contains "200") {
				// For text format, the output should already be plain text
				print.line(testResult.fileContent);
			} else {
				print.redLine("Failed to run core tests. Status: #testResult.statusCode#");
				print.line("Make sure the core framework is properly mounted in Docker.");
			}
		} catch (any e) {
			print.redLine("Error running core tests: #e.message#");
			print.line("You can manually access the tests at: #testUrl#");
		}
	}
	
	/**
	 * Restart the server
	 */
	function restart() {
		stop();
		run();
	}
	
	/**
	 * Show help
	 */
	function help() {
		print.line();
		print.boldBlueLine("Wheels Development Task Runner");
		print.line("==============================");
		print.line();
		print.yellowLine("Available Commands:");
		print.line();
		print.greenLine("  box task run start [--engine=lucee6] [--database=h2] [--port=auto]");
		print.line("    Start the development server");
		print.line("    Default ports by engine:");
		print.line("      lucee5: 60005, lucee6: 60006, lucee7: 60007");
		print.line("      adobe2018: 62018, adobe2021: 62021, adobe2023: 62023, adobe2025: 62025");
		print.line();
		print.greenLine("  box task run stop");
		print.line("    Stop the development server");
		print.line();
		print.greenLine("  box task run restart");
		print.line("    Restart the development server");
		print.line();
		print.greenLine("  box task run status");
		print.line("    Check server status");
		print.line();
		print.greenLine("  box task run logs [--follow] [--tail=100]");
		print.line("    View server logs");
		print.line();
		print.greenLine("  box task run test [--reporter=text|simple|json|junit|html]");
		print.line("    Run application tests");
		print.line();
		print.greenLine("  box task run testCore [--format=txt|json|html]");
		print.line("    Run core framework tests (requires core tests to be mounted)");
		print.line();
		print.greenLine("  box task run clean");
		print.line("    Remove containers and volumes");
		print.line();
	}

	// Private helper methods
	
	private function isServerRunning() {
		// For now, just check if docker-compose.yml exists
		// A more robust check would use docker compose ps
		var cwd = getCWD();
		return fileExists(cwd & "/docker-compose.yml");
	}
	
	private function getPort() {
		// Try to read from docker-compose.yml
		var cwd = getCWD();
		var dockerComposePath = cwd & "/docker-compose.yml";
		
		if (fileExists(dockerComposePath)) {
			var content = fileRead(dockerComposePath);
			// Look for port mapping like "60006:60006"
			var portPattern = '- "(\d+):\d+"';
			var matches = reMatchNoCase(portPattern, content);
			if (arrayLen(matches)) {
				// Extract just the numbers from the first match
				var portMatch = matches[1];
				var portNum = reReplace(portMatch, '[^0-9:]', '', 'all');
				// Get the first port (before the colon)
				if (find(":", portNum)) {
					return listFirst(portNum, ":");
				}
				return portNum;
			}
		}
		return 60006; // default
	}

	private function generateDockerCompose(required string engine, required string database, required numeric port) {
		// Get current working directory using getCWD()
		var cwd = getCWD();
		var templatePath = cwd & "/docker-compose.yml.template";
		var outputPath = cwd & "/docker-compose.yml";
		
		// Debug path
		print.line("Looking for template at: #templatePath#");
		
		// Check if template exists
		if (!fileExists(templatePath)) {
			print.redLine("Docker compose template not found!");
			print.line("Current directory: #cwd#");
			return;
		}
		
		// Read template
		var template = fileRead(templatePath);
		
		// Get root directory (2 levels up from current working directory)
		// cwd is like /Users/peter/projects/wheels/templates/default
		// We need /Users/peter/projects/wheels
		var pathParts = listToArray(cwd, "/");
		// Remove last 2 parts (default and templates)
		arrayDeleteAt(pathParts, arrayLen(pathParts));
		arrayDeleteAt(pathParts, arrayLen(pathParts));
		var rootDir = "/" & arrayToList(pathParts, "/");
		
		// Map engine names to directory names
		var engineDirMap = {
			"lucee5": "lucee@5",
			"lucee6": "lucee@6",
			"lucee7": "lucee@7",
			"adobe2018": "adobe@2018",
			"adobe2021": "adobe@2021",
			"adobe2023": "adobe@2023",
			"adobe2025": "adobe@2025"
		};
		
		// Replace placeholders
		template = replace(template, "{{ENGINE}}", arguments.engine, "all");
		template = replace(template, "{{ENGINE_DIR}}", engineDirMap[arguments.engine], "all");
		template = replace(template, "{{DATABASE}}", arguments.database, "all");
		template = replace(template, "{{PORT}}", arguments.port, "all");
		template = replace(template, "{{ROOT_DIR}}", rootDir, "all");
		
		// Add database service if needed
		if (arguments.database != "h2" || !arguments.engine contains "lucee") {
			var dbTemplatePath = cwd & "/docker-compose-#arguments.database#.yml.template";
			if (fileExists(dbTemplatePath)) {
				var dbTemplate = fileRead(dbTemplatePath);
				dbTemplate = replace(dbTemplate, "{{ROOT_DIR}}", rootDir, "all");
				template &= chr(10) & chr(10) & dbTemplate;
				
				// Add depends_on
				template = replace(template, "networks:
      - wheels-dev", "networks:
      - wheels-dev
    depends_on:
      - #arguments.database#_db", "all");
				
				// Add database environment variables
				var dbEnv = getDBEnvironment(arguments.database);
				template = replace(template, "- BOX_SERVER_APP_CFENGINE={{ENGINE}}", "- BOX_SERVER_APP_CFENGINE={{ENGINE}}
#dbEnv#", "all");
				template = replace(template, "{{ENGINE}}", arguments.engine, "all");
			}
		}
		
		// Write generated file
		fileWrite(outputPath, template);
		
		print.greenLine("Generated docker-compose.yml");
	}

	private function getDBEnvironment(required string database) {
		switch(arguments.database) {
			case "mysql":
				return "      - DB_HOST=mysql_db
      - DB_PORT=3306
      - DB_NAME=wheelstestdb
      - DB_USER=wheels
      - DB_PASSWORD=wheels";
			case "postgresql":
				return "      - DB_HOST=postgresql_db
      - DB_PORT=5432
      - DB_NAME=wheelstestdb
      - DB_USER=wheels
      - DB_PASSWORD=wheels";
			case "sqlserver":
				return "      - DB_HOST=sqlserver_db
      - DB_PORT=1433
      - DB_NAME=wheelstestdb
      - DB_USER=sa
      - DB_PASSWORD=Wheels2023!Strong";
			default:
				return "";
		}
	}

}