/**
 * Display or switch the current Wheels environment
 *
 * Examples:
 * {code:bash}
 * wheels environment
 * wheels environment set development
 * wheels environment set production
 * wheels environment list
 * {code}
 **/
component extends="base" {

	/**
	 * @action Action to perform (show, set, list)
	 * @value Environment value when using set action
	 * @reload Reload application after changing environment
	 **/
	function run(
		string action = "show",
		string value,
		boolean reload = true
	) {
		// Check if we're in a Wheels application
		if (!isWheelsApp()) {
			print.redLine("This doesn't appear to be a Wheels application directory.");
			print.line("Looking for /vendor/wheels, /config, and /app folders");
			return;
		}

		switch (lCase(arguments.action)) {
			case "show":
			case "current":
				showCurrentEnvironment();
				break;
				
			case "set":
			case "switch":
				if (isNull(arguments.value) || !len(arguments.value)) {
					print.redLine("Please specify an environment to set.");
					print.line("Usage: wheels environment set [development|testing|production|maintenance]");
					return;
				}
				setEnvironment(arguments.value, arguments.reload);
				break;
				
			case "list":
			case "available":
				listEnvironments();
				break;
				
			default:
				// If action looks like an environment name, assume they want to set it
				if (listFindNoCase("development,testing,production,maintenance", arguments.action)) {
					setEnvironment(arguments.action, arguments.reload);
				} else {
					print.redLine("Unknown action: #arguments.action#");
					print.line();
					showHelp();
				}
		}
	}

	/**
	 * Show the current environment
	 **/
	private void function showCurrentEnvironment() {
		try {
			// Try to get from server if running
			var serverInfo = $getServerInfo();
			if (structKeyExists(serverInfo, "serverURL")) {
				var envURL = serverInfo.serverURL;
				
				// Add /public if needed
				if (needsPublicPath()) {
					envURL &= "/public";
				}
				
				envURL &= "/?controller=wheels&action=wheels&view=environment&command=get";
				
				var http = new Http(url=envURL);
				var result = http.send().getPrefix();
				
				if (result.statusCode == 200 && isJSON(result.fileContent)) {
					var data = deserializeJSON(result.fileContent);
					if (data.success) {
						displayEnvironmentInfo(data);
						return;
					}
				}
			}
		} catch (any e) {
			// Fall back to reading from files
		}
		
		// Read from config files
		var env = detectEnvironmentFromConfig();
		print.boldLine("Current Wheels Environment");
		print.line("=========================");
		print.line();
		print.line("Environment: #env#");
		print.line("Detected from: Configuration files");
		print.line();
		print.grayLine("Note: Start the server to see the active runtime environment");
	}

	/**
	 * Display environment information
	 **/
	private void function displayEnvironmentInfo(required struct data) {
		print.boldLine("Current Wheels Environment");
		print.line("=========================");
		print.line();
		print.line("Environment: " & data.environment);
		print.line("Wheels Version: " & data.wheelsVersion);
		print.line("Data Source: " & data.datasource);
		
		if (structKeyExists(data, "serverName")) {
			print.line("Server: " & data.serverName);
		}
		
		print.line();
		
		// Show environment-specific settings
		print.boldLine("Environment Settings:");
		if (structKeyExists(data, "settings")) {
			for (var key in data.settings) {
				print.indentedLine("#key#: #data.settings[key]#");
			}
		}
		
		print.line();
		print.grayLine("To change environment, use: wheels environment set [environment]");
	}

	/**
	 * Set the environment
	 **/
	private void function setEnvironment(required string environment, boolean reload = true) {
		var validEnvironments = "development,testing,production,maintenance";
		
		if (!listFindNoCase(validEnvironments, arguments.environment)) {
			print.redLine("Invalid environment: #arguments.environment#");
			print.line("Valid environments are: #replace(validEnvironments, ',', ', ', 'all')#");
			return;
		}
		
		print.yellowLine("Changing environment to: #arguments.environment#");
		print.line();
		
		// Update environment setting
		try {
			// First, try to update via running server
			var serverInfo = $getServerInfo();
			if (structKeyExists(serverInfo, "serverURL")) {
				var setURL = serverInfo.serverURL;
				
				if (needsPublicPath()) {
					setURL &= "/public";
				}
				
				setURL &= "/?controller=wheels&action=wheels&view=environment&command=set&value=#arguments.environment#";
				
				var http = new Http(url=setURL);
				var result = http.send().getPrefix();
				
				if (result.statusCode == 200 && isJSON(result.fileContent)) {
					var data = deserializeJSON(result.fileContent);
					if (data.success) {
						print.greenLine("✓ Environment changed successfully!");
						
						if (arguments.reload) {
							print.line();
							print.line("Reloading application...");
							command("wheels reload").params(arguments.environment).run();
						}
						
						return;
					}
				}
			}
		} catch (any e) {
			// Fall back to file-based update
		}
		
		// Update environment in configuration files
		updateEnvironmentConfig(arguments.environment);
		
		print.greenLine("✓ Environment configuration updated!");
		print.line();
		print.yellowLine("Note: Restart your server for changes to take effect");
		print.line("Run: wheels server restart");
	}

	/**
	 * List available environments
	 **/
	private void function listEnvironments() {
		print.boldLine("Available Wheels Environments");
		print.line("============================");
		print.line();
		
		var environments = [
			{
				name: "development",
				description: "Development mode with debugging enabled, no caching",
				use: "Local development and debugging"
			},
			{
				name: "testing", 
				description: "Testing mode for running automated tests",
				use: "Running test suites and CI/CD pipelines"
			},
			{
				name: "production",
				description: "Production mode with caching enabled, debugging disabled",
				use: "Live production servers"
			},
			{
				name: "maintenance",
				description: "Maintenance mode to show maintenance page",
				use: "During deployments or maintenance windows"
			}
		];
		
		// Try to detect current environment
		var currentEnv = detectEnvironmentFromConfig();
		
		for (var env in environments) {
			var marker = (env.name == currentEnv) ? " (current)" : "";
			print.boldLine("#env.name##marker#");
			print.indentedLine("Description: #env.description#");
			print.indentedLine("Use for: #env.use#");
			print.line();
		}
		
		print.line("To switch environments, use:");
		print.line("wheels environment set [environment]");
	}

	/**
	 * Show help information
	 **/
	private void function showHelp() {
		print.boldLine("Wheels Environment Command");
		print.line("=========================");
		print.line();
		print.line("Usage:");
		print.indentedLine("wheels environment              - Show current environment");
		print.indentedLine("wheels environment set [env]    - Change environment");
		print.indentedLine("wheels environment list         - List available environments");
		print.line();
		print.line("Shortcuts:");
		print.indentedLine("wheels environment development  - Switch to development");
		print.indentedLine("wheels environment production   - Switch to production");
		print.line();
		print.line("Options:");
		print.indentedLine("--reload=false                  - Don't reload after changing");
	}

	/**
	 * Detect environment from configuration files
	 **/
	private string function detectEnvironmentFromConfig() {
		// Check for environment variable
		if (structKeyExists(server, "WHEELS_ENV") && len(server.WHEELS_ENV)) {
			return server.WHEELS_ENV;
		}
		
		// Check for .env file
		var envFile = fileSystemUtil.resolvePath(".env");
		if (fileExists(envFile)) {
			var envContent = fileRead(envFile);
			var envMatch = reFindNoCase("WHEELS_ENV\s*=\s*([^\s]+)", envContent, 1, true);
			if (arrayLen(envMatch.pos) >= 2 && envMatch.pos[2] > 0) {
				return mid(envContent, envMatch.pos[2], envMatch.len[2]);
			}
		}
		
		// Default to development
		return "development";
	}

	/**
	 * Update environment configuration
	 **/
	private void function updateEnvironmentConfig(required string environment) {
		// Update .env file if it exists
		var envFile = fileSystemUtil.resolvePath(".env");
		if (fileExists(envFile)) {
			var envContent = fileRead(envFile);
			
			// Check if WHEELS_ENV exists
			if (findNoCase("WHEELS_ENV", envContent)) {
				// Update existing
				envContent = reReplaceNoCase(envContent, "WHEELS_ENV\s*=\s*[^\s]+", "WHEELS_ENV=#arguments.environment#");
			} else {
				// Add new
				if (len(envContent) && right(envContent, 1) != chr(10)) {
					envContent &= chr(10);
				}
				envContent &= "WHEELS_ENV=#arguments.environment#" & chr(10);
			}
			
			fileWrite(envFile, envContent);
			print.line("Updated .env file");
		} else {
			// Create .env file
			fileWrite(envFile, "WHEELS_ENV=#arguments.environment#" & chr(10));
			print.line("Created .env file");
		}
	}

	/**
	 * Check if we need to add /public to URLs
	 **/
	private boolean function needsPublicPath() {
		var serverJSON = fileSystemUtil.resolvePath("server.json");
		if (fileExists(serverJSON)) {
			try {
				var serverConfig = deserializeJSON(fileRead(serverJSON));
				if (!structKeyExists(serverConfig, "web") || !structKeyExists(serverConfig.web, "webroot") ||
					!findNoCase("public", serverConfig.web.webroot)) {
					if (fileExists(fileSystemUtil.resolvePath("public/index.cfm"))) {
						return true;
					}
				}
			} catch (any e) {
				// Ignore
			}
		}
		return false;
	}

}