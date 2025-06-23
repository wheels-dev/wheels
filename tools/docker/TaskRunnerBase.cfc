/**
 * Base Task Runner for Wheels Framework Development
 * Provides common functionality for running Docker containers
 */
component {

	property name="fileSystemUtil" inject="FileSystem";
	property name="configService" inject="ConfigService";
	property name="InteractiveJob" inject="InteractiveJob";
	property name="job" inject="jobmanager";
	property name="print" inject="print";
	property name="consoleLogger" inject="logbox:logger:console";

	// Default settings
	variables.defaultEngine = "lucee6";
	variables.defaultDatabase = "h2";
	variables.supportedEngines = ["lucee5", "lucee6", "lucee7", "adobe2018", "adobe2021", "adobe2023", "adobe2025"];
	variables.supportedDatabases = ["h2", "mysql", "postgresql", "sqlserver"];

	/**
	 * Start the development server
	 * @engine The CFML engine to use
	 * @database The database to use
	 * @port The port to run on
	 */
	function run(
		string engine = variables.defaultEngine,
		string database = variables.defaultDatabase,
		numeric port = 8080
	) {
		// Validate engine
		if (!arrayContains(variables.supportedEngines, arguments.engine)) {
			error("Unsupported engine: #arguments.engine#. Supported engines: #arrayToList(variables.supportedEngines)#");
		}

		// Validate database
		if (!arrayContains(variables.supportedDatabases, arguments.database)) {
			error("Unsupported database: #arguments.database#. Supported databases: #arrayToList(variables.supportedDatabases)#");
		}

		// For Lucee engines, default to H2 if no database specified
		if (arguments.engine contains "lucee" && arguments.database == variables.defaultDatabase) {
			print.greenLine("Using built-in H2 database for Lucee");
		}

		print.boldGreenLine("Starting Wheels development server...");
		print.line("Engine: #arguments.engine#");
		print.line("Database: #arguments.database#");
		print.line("Port: #arguments.port#");

		// Generate docker-compose.yml from template
		generateDockerCompose(arguments.engine, arguments.database, arguments.port);

		// Start the containers
		var result = runCommand("docker compose up -d");
		
		if (result.exitCode == 0) {
			print.greenLine("Server started successfully!");
			print.line("Access your application at: http://localhost:#arguments.port#");
			print.line("");
			print.yellowLine("To view logs: box task run logs");
			print.yellowLine("To stop server: box task run stop");
		} else {
			error("Failed to start server: #result.error#");
		}
	}

	/**
	 * Stop the development server
	 */
	function stop() {
		print.yellowLine("Stopping Wheels development server...");
		
		var result = runCommand("docker compose down");
		
		if (result.exitCode == 0) {
			print.greenLine("Server stopped successfully!");
		} else {
			error("Failed to stop server: #result.error#");
		}
	}

	/**
	 * Show logs from the containers
	 * @follow Follow log output
	 * @tail Number of lines to show
	 */
	function logs(boolean follow = false, numeric tail = 100) {
		var cmd = "docker compose logs";
		
		if (arguments.follow) {
			cmd &= " -f";
		}
		
		if (arguments.tail > 0) {
			cmd &= " --tail #arguments.tail#";
		}
		
		runCommand(cmd, true);
	}

	/**
	 * Clean up containers and volumes
	 */
	function clean() {
		print.yellowLine("Cleaning up Docker resources...");
		
		var result = runCommand("docker compose down -v");
		
		if (result.exitCode == 0) {
			print.greenLine("Cleanup completed successfully!");
		} else {
			error("Failed to clean up: #result.error#");
		}
	}

	/**
	 * Run application tests
	 */
	function test() {
		print.boldBlueLine("Running application tests...");
		
		// Check if server is running
		if (!isServerRunning()) {
			error("Server is not running. Start it with: box task run");
		}
		
		// Run tests via HTTP request
		var testUrl = "http://localhost:#getPort()#/tests/runner.cfm";
		print.line("Running tests at: #testUrl#");
		
		// Open browser to test runner
		runCommand("open #testUrl#", true);
	}

	/**
	 * Run core framework tests
	 */
	function testCore() {
		print.boldBlueLine("Running core framework tests...");
		
		// Check if server is running
		if (!isServerRunning()) {
			error("Server is not running. Start it with: box task run");
		}
		
		// Run core tests via HTTP request
		var testUrl = "http://localhost:#getPort()#/wheels/testbox";
		print.line("Running core tests at: #testUrl#");
		
		// Open browser to test runner
		runCommand("open #testUrl#", true);
	}

	/**
	 * Restart the server
	 */
	function restart() {
		stop();
		run();
	}

	/**
	 * Get status of the server
	 */
	function status() {
		print.boldLine("Checking server status...");
		
		var result = runCommand("docker compose ps");
		
		if (result.output contains "Up") {
			print.greenLine("Server is running");
			print.line(result.output);
		} else {
			print.redLine("Server is not running");
		}
	}

	// Private helper methods

	private function generateDockerCompose(required string engine, required string database, required numeric port) {
		var templatePath = fileSystemUtil.resolvePath("docker-compose.yml.template");
		var outputPath = fileSystemUtil.resolvePath("docker-compose.yml");
		
		// Check if template exists
		if (!fileExists(templatePath)) {
			error("Docker compose template not found at: #templatePath#");
		}
		
		// Read main template
		var template = fileRead(templatePath);
		
		// Get root directory (2 levels up from template/example directory)
		var rootDir = fileSystemUtil.resolvePath("../..");
		
		// Replace placeholders
		template = replace(template, "{{ENGINE}}", arguments.engine, "all");
		template = replace(template, "{{DATABASE}}", arguments.database, "all");
		template = replace(template, "{{PORT}}", arguments.port, "all");
		template = replace(template, "{{ROOT_DIR}}", rootDir, "all");
		
		// Add database service if needed
		if (arguments.database != "h2" || !arguments.engine contains "lucee") {
			var dbTemplatePath = fileSystemUtil.resolvePath("docker-compose-#arguments.database#.yml.template");
			if (fileExists(dbTemplatePath)) {
				var dbTemplate = fileRead(dbTemplatePath);
				dbTemplate = replace(dbTemplate, "{{ROOT_DIR}}", rootDir, "all");
				template &= chr(10) & chr(10) & dbTemplate;
				
				// Add depends_on to cfml service
				template = replace(template, "networks:
      - wheels-dev", "networks:
      - wheels-dev
    depends_on:
      - #arguments.database#_db", "all");
				
				// Add database connection info to environment
				var dbEnv = getDBEnvironment(arguments.database);
				template = replace(template, "- BOX_SERVER_APP_CFENGINE={{ENGINE}}", "- BOX_SERVER_APP_CFENGINE={{ENGINE}}
#dbEnv#", "all");
				template = replace(template, "{{ENGINE}}", arguments.engine, "all");
			}
		}
		
		// Write generated file
		fileWrite(outputPath, template);
		
		print.greenLine("Generated docker-compose.yml for #arguments.engine# with #arguments.database#");
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

	private function runCommand(required string command, boolean interactive = false) {
		if (arguments.interactive) {
			// For interactive commands, use the shell
			shell(arguments.command).run();
			return { exitCode: 0, output: "", error: "" };
		} else {
			// For non-interactive commands, capture output
			var result = command(arguments.command).run(returnOutput = true);
			return {
				exitCode: result.exitCode ?: 0,
				output: result.output ?: "",
				error: result.error ?: ""
			};
		}
	}

	private function isServerRunning() {
		var result = runCommand("docker compose ps -q");
		return len(trim(result.output)) > 0;
	}

	private function getPort() {
		// Try to read from docker-compose.yml
		if (fileExists("docker-compose.yml")) {
			var content = fileRead("docker-compose.yml");
			var matches = reMatch("- ""(\d+):\d+""", content);
			if (arrayLen(matches)) {
				return reReplace(matches[1], "[^\d]", "", "all");
			}
		}
		return 8080; // default
	}

	private function error(required string message) {
		print.redLine(arguments.message);
		// Exit with error code
		setExitCode(1);
	}

}