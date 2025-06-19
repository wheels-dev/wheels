/**
 * Start an interactive REPL console with Wheels application context
 *
 * Examples:
 * {code:bash}
 * wheels console
 * wheels console environment=testing
 * wheels console execute="model('User').count()"
 * {code}
 **/
component extends="base" {

	property name="fileSystem" inject="fileSystem";
	property name="shell" inject="shell";
	property name="print" inject="print";
	property name="CR" inject="CR";

	/**
	 * @environment Environment to load (development, testing, production)
	 * @execute Execute a single command and exit
	 * @script Use CFScript mode (default: true)
	 * @directory Application directory (defaults to current)
	 **/
	function run(
		string environment = "development",
		string execute,
		boolean script = true,
		string directory = getCWD()
	) {
		// Check if we're in a Wheels application
		if (!isWheelsApp(arguments.directory)) {
			print.redLine("This doesn't appear to be a Wheels application directory.");
			print.line("Looking for /vendor/wheels, /config, and /app folders in: #arguments.directory#");
			print.line();
			print.yellowLine("Did you mean to run 'wheels generate app' first?");
			return;
		}

		// Get server info to build URL
		var serverInfo = getServerInfoSafe();
		
		print.line();
		print.boldGreenLine("Starting Wheels Console...");
		print.line("=========================");
		print.line();
		print.line("Environment: #arguments.environment#");
		print.line("Directory: #arguments.directory#");
		print.line("Mode: " & (arguments.script ? "CFScript" : "Tag"));
		
		// If server is running, we'll use HTTP to initialize context
		if (structKeyExists(serverInfo, "serverURL")) {
			print.line("Server URL: #serverInfo.serverURL#");
		}
		
		print.line();
		print.yellowLine("Loading Wheels application context...");
		
		// Initialize the Wheels context
		try {
			var contextURL = initializeWheelsContext(arguments.environment, serverInfo);
			
			print.greenLine("✓ Wheels context loaded successfully!");
			print.line();
			
			// If single command execution
			if (!isNull(arguments.execute) && len(arguments.execute)) {
				print.line("Executing: #arguments.execute#");
				print.line();
				executeCommand(arguments.execute, contextURL, arguments.script);
				return;
			}
			
			// Start interactive REPL
			startInteractiveREPL(contextURL, arguments.script);
			
		} catch (any e) {
			print.redLine("Failed to initialize Wheels context: #e.message#");
			print.line("Detail: #e.detail#");
			print.line();
			print.line("Make sure your server is running: wheels server start");
		}
	}

	/**
	 * Initialize Wheels context via HTTP bridge
	 **/
	private string function initializeWheelsContext(required string environment, required struct serverInfo) {
		if (!structKeyExists(arguments.serverInfo, "serverURL")) {
			throw(message="Server must be running to use console", detail="Start server with: wheels server start");
		}
		
		// Build console bridge URL
		var consoleURL = arguments.serverInfo.serverURL;
		
		// Add /public if needed (same logic as in base.cfc)
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
			consoleURL &= "/public";
		}
		
		consoleURL &= "/?controller=wheels&action=wheels&view=console&environment=#arguments.environment#";
		
		// Test the connection
		var http = new Http(url=consoleURL & "&command=test");
		var result = http.send().getPrefix();
		
		if (result.statusCode != 200 || !isJSON(result.fileContent)) {
			throw(message="Failed to connect to Wheels console bridge", detail="URL: #consoleURL#");
		}
		
		return consoleURL;
	}

	/**
	 * Execute a single command
	 **/
	private void function executeCommand(required string code, required string contextURL, boolean script = true) {
		var encodedCode = urlEncodedFormat(arguments.code);
		var executeURL = arguments.contextURL & "&command=execute&code=#encodedCode#&script=#arguments.script#";
		
		var http = new Http(url=executeURL);
		var result = http.send().getPrefix();
		
		if (isJSON(result.fileContent)) {
			var response = deserializeJSON(result.fileContent);
			if (response.success) {
				print.line(response.output);
			} else {
				print.redLine("Error: #response.error#");
				if (structKeyExists(response, "detail")) {
					print.line("Detail: #response.detail#");
				}
			}
		} else {
			print.line(result.fileContent);
		}
	}

	/**
	 * Start interactive REPL
	 **/
	private void function startInteractiveREPL(required string contextURL, boolean script = true) {
		print.line("Interactive console ready. Type 'help' for commands, 'exit' to quit.");
		print.line();
		
		// Show some example commands
		showExamples();
		
		var continueREPL = true;
		var history = [];
		
		while (continueREPL) {
			var prompt = arguments.script ? "wheels:script> " : "wheels:tag> ";
			var code = shell.ask(prompt);
			
			// Handle special commands
			switch (lCase(trim(code))) {
				case "exit":
				case "quit":
				case "q":
					continueREPL = false;
					print.line("Goodbye!");
					break;
					
				case "help":
				case "?":
					showHelp();
					break;
					
				case "examples":
					showExamples();
					break;
					
				case "clear":
				case "cls":
					shell.clearScreen();
					break;
					
				case "script":
					arguments.script = true;
					print.line("Switched to CFScript mode");
					break;
					
				case "tag":
					arguments.script = false;
					print.line("Switched to Tag mode");
					break;
					
				case "history":
					showHistory(history);
					break;
					
				default:
					if (len(trim(code))) {
						arrayAppend(history, code);
						executeCommand(code, arguments.contextURL, arguments.script);
						print.line();
					}
			}
		}
	}

	/**
	 * Show help information
	 **/
	private void function showHelp() {
		print.line();
		print.boldLine("Wheels Console Commands:");
		print.line("========================");
		print.indentedLine("help, ?      - Show this help");
		print.indentedLine("examples     - Show usage examples");
		print.indentedLine("script       - Switch to CFScript mode");
		print.indentedLine("tag          - Switch to Tag mode");
		print.indentedLine("clear, cls   - Clear screen");
		print.indentedLine("history      - Show command history");
		print.indentedLine("exit, quit   - Exit console");
		print.line();
		print.line("You have access to all Wheels functions and components:");
		print.indentedLine("- model() function to access models");
		print.indentedLine("- All Wheels helper functions");
		print.indentedLine("- Direct database queries");
		print.line();
	}

	/**
	 * Show usage examples
	 **/
	private void function showExamples() {
		print.line();
		print.boldLine("Example Commands:");
		print.line("================");
		print.line();
		print.grayLine("// Working with models:");
		print.line('user = model("User").findByKey(1)');
		print.line('users = model("User").findAll(where="active=1")');
		print.line('newUser = model("User").create(name="John", email="john@example.com")');
		print.line();
		print.grayLine("// Using helpers:");
		print.line('pluralize("person")');
		print.line('timeAgoInWords(now())');
		print.line();
		print.grayLine("// Direct queries:");
		print.line('query("SELECT COUNT(*) as total FROM users")');
		print.line();
	}

	/**
	 * Show command history
	 **/
	private void function showHistory(required array history) {
		print.line();
		print.boldLine("Command History:");
		print.line("===============");
		if (arrayLen(arguments.history)) {
			for (var i = 1; i <= arrayLen(arguments.history); i++) {
				print.line("#i#: #arguments.history[i]#");
			}
		} else {
			print.line("No commands in history yet.");
		}
		print.line();
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