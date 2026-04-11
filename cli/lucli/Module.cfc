/**
 * Wheels CLI Module for LuCLI
 *
 * Provides code generation, migrations, testing, and server management
 * for Wheels applications. Each public function is a subcommand:
 *
 *   wheels new myapp
 *   wheels create app myapp --port=3000
 *   wheels generate model User name email
 *   wheels migrate latest
 *   wheels test --filter=models
 *   wheels start
 *
 * hint: Wheels framework CLI - create, generate, migrate, test, and manage your app
 */
component extends="modules.BaseModule" {

	function init(
		boolean verboseEnabled = false,
		boolean timingEnabled = false,
		string cwd = "",
		any timer = nullValue(),
		struct moduleConfig = {}
	) {
		super.init(argumentCollection = arguments);

		// Resolve project root (where lucee.json / vendor/wheels lives)
		variables.projectRoot = resolveProjectRoot(arguments.cwd);

		// Module root for template resolution
		variables.moduleRoot = getDirectoryFromPath(getCurrentTemplatePath());

		// Lazy-init service instances
		variables.services = {};

		return this;
	}

	// ─────────────────────────────────────────────────
	//  generate — Code generation
	// ─────────────────────────────────────────────────

	/**
	 * hint: Generate Wheels components (model, controller, view, migration, scaffold, route, test, property, api-resource, helper, snippets)
	 */
	public string function generate() {
		var args = __arguments ?: [];

		if (!arrayLen(args)) {
			out("Usage: wheels generate <type> <name> [attributes...]", "yellow");
			out("");
			out("Types:", "bold");
			out("  app           Create a new Wheels application (alias for 'wheels new')");
			out("  model         Generate a model CFC");
			out("  controller    Generate a controller CFC");
			out("  view          Generate a view template");
			out("  migration     Generate a database migration");
			out("  scaffold      Generate model + controller + views + migration + tests + routes");
			out("  api-resource  Generate API-only model + controller + migration + tests + routes (no views)");
			out("  route         Add a resource route to config/routes.cfm");
			out("  test          Generate a test spec file");
			out("  property      Generate an add-column migration for a model property");
			out("  helper        Generate a helper file in app/helpers/");
			out("  snippets      Generate common code pattern snippets (auth, soft-delete, api, etc.)");
			out("  admin         Generate admin CRUD interface for an existing model");
			out("");
			out("Examples:", "bold");
			out("  wheels generate app myapp");
			out("  wheels generate model User name email:string active:boolean");
			out("  wheels generate controller Users index show create");
			out("  wheels generate migration CreateUsers");
			out("  wheels generate scaffold Post title body:text publishedAt:datetime");
			out("  wheels generate api-resource Product name price:decimal sku:string");
			out("  wheels generate route posts");
			out("  wheels generate test model User");
			out("  wheels generate property User email:string");
			out("  wheels generate helper formatting");
			out("  wheels generate snippets auth");
			out("  wheels generate admin User");
			return "";
		}

		var type = args[1];
		var remaining = args.len() > 1 ? args.slice(2) : [];

		switch (lCase(type)) {
			case "app":
			case "a":
				// Delegate to wheels new — pass remaining args as __arguments
				__arguments = remaining;
				return new();
			case "model":
			case "m":
				return generateModel(remaining);
			case "controller":
			case "c":
				return generateController(remaining);
			case "view":
			case "v":
				return generateView(remaining);
			case "migration":
			case "migrate":
				return generateMigration(remaining);
			case "scaffold":
			case "s":
				return generateScaffold(remaining);
			case "api-resource":
			case "api":
				return generateApiResource(remaining);
			case "route":
			case "r":
				return generateRoute(remaining);
			case "test":
				return generateTest(remaining);
			case "property":
			case "prop":
				return generateProperty(remaining);
			case "helper":
			case "h":
				return generateHelper(remaining);
			case "snippets":
				return generateSnippets(remaining);
			case "admin":
				return generateAdmin(remaining);
			default:
				out("Unknown generator type: #type#", "red");
				out("Run 'wheels generate' for available types.");
				return "";
		}
	}

	// ─────────────────────────────────────────────────
	//  migrate — Database migration management
	// ─────────────────────────────────────────────────

	/**
	 * hint: Run database migrations (latest, up, down, info)
	 */
	public string function migrate() {
		var args = __arguments ?: [];
		var action = arrayLen(args) ? lCase(args[1]) : "latest";

		switch (action) {
			case "latest":
			case "up":
			case "down":
			case "info":
				return runMigration(action);
			default:
				out("Unknown migration action: #action#", "red");
				out("Usage: wheels migrate [latest|up|down|info]");
				return "";
		}
	}

	// ─────────────────────────────────────────────────
	//  seed — Database seeding
	// ─────────────────────────────────────────────────

	/**
	 * hint: Run database seeds (convention-based or generated)
	 */
	public string function seed() {
		var args = __arguments ?: [];
		var environment = "";
		var mode = "auto";

		for (var i = 1; i <= arrayLen(args); i++) {
			var arg = args[i];
			if (reFindNoCase("^--environment=", arg)) {
				environment = valueAfterEquals(arg);
			} else if (reFindNoCase("^--mode=", arg)) {
				mode = valueAfterEquals(arg);
			} else if (arg == "--generate") {
				mode = "generate";
			}
		}

		return runSeed(mode, environment);
	}

	// ─────────────────────────────────────────────────
	//  test — Run test suite
	// ─────────────────────────────────────────────────

	/**
	 * hint: Run test suite with optional filter and reporter
	 */
	public string function test() {
		var args = __arguments ?: [];
		var filter = "";
		var reporter = "simple";
		var format = "json";
		var verboseOutput = false;
		var ciMode = false;
		var coreTests = false;
		var db = "sqlite";

		// Parse named arguments from --key=value or --key value
		for (var i = 1; i <= arrayLen(args); i++) {
			var arg = args[i];
			if (arg == "--filter" && i < arrayLen(args)) {
				filter = args[++i];
			} else if (reFindNoCase("^--filter=", arg)) {
				filter = valueAfterEquals(arg);
			} else if (arg == "--reporter" && i < arrayLen(args)) {
				reporter = args[++i];
			} else if (reFindNoCase("^--reporter=", arg)) {
				reporter = valueAfterEquals(arg);
			} else if (arg == "--db" && i < arrayLen(args)) {
				db = args[++i];
			} else if (reFindNoCase("^--db=", arg)) {
				db = valueAfterEquals(arg);
			} else if (arg == "--verbose" || arg == "-v") {
				verboseOutput = true;
			} else if (arg == "--ci") {
				ciMode = true;
			} else if (arg == "--core") {
				coreTests = true;
			} else if (!arg.startsWith("--")) {
				// Positional arg is the filter directory
				filter = arg;
			}
		}

		// Auto-detect: if vendor/wheels/tests/ exists, default to core tests
		if (!coreTests && len(variables.projectRoot)) {
			if (directoryExists(variables.projectRoot & "/vendor/wheels/tests")) {
				coreTests = true;
			}
		}

		return runTests(filter, reporter, format, verboseOutput, coreTests, db, ciMode);
	}

	// ─────────────────────────────────────────────────
	//  reload — Reload application
	// ─────────────────────────────────────────────────

	/**
	 * hint: Reload the running Wheels application
	 */
	public string function reload() {
		var serverPort = detectServerPort();
		if (!serverPort) {
			out("No running Wheels server detected. Start one with: wheels start", "red");
			return "";
		}

		var password = detectReloadPassword();

		try {
			var reloadUrl = "http://localhost:#serverPort#/?reload=true&password=#password#";
			var httpResult = makeHttpRequest(reloadUrl);
			out("Application reloaded successfully.", "green");
			verbose("URL: http://localhost:#serverPort#/?reload=true&password=***");
		} catch (any e) {
			out("Failed to reload: #e.message#", "red");
			if (!len(password)) {
				out("Hint: Set RELOAD_PASSWORD in .env or config/settings.cfm", "yellow");
			}
		}
		return "";
	}

	// ─────────────────────────────────────────────────
	//  start / stop — Dev server management
	// ─────────────────────────────────────────────────

	/**
	 * hint: Start the Wheels development server via LuCLI
	 */
	public string function start() {
		var args = __arguments ?: [];

		out("Starting Wheels server...", "cyan");

		// Delegate to LuCLI's server start command
		var cmdArgs = ["start"];

		// Pass through any extra args (--port, --version, etc.)
		cmdArgs.append(args, true);

		executeCommand("server", cmdArgs, variables.projectRoot);
		return "";
	}

	/**
	 * hint: Stop the running Wheels development server
	 */
	public string function stop() {
		out("Stopping Wheels server...", "cyan");
		executeCommand("server", ["stop"], variables.projectRoot);
		return "";
	}

	// ─────────────────────────────────────────────────
	//  new — Scaffold a new Wheels project
	// ─────────────────────────────────────────────────

	/**
	 * hint: Scaffold a new Wheels project directory
	 */
	public string function new() {
		var args = __arguments ?: [];

		if (!arrayLen(args)) {
			out("Usage: wheels new <appname> [options]", "yellow");
			out("");
			out("Creates a new Wheels application in the specified directory.");
			out("By default, SQLite is configured as the zero-config database.");
			out("");
			out("Options:", "bold");
			out("  --port=<number>           Server port (default: 8080)");
			out("  --datasource=<name>       Datasource name (default: app name)");
			out("  --reload-password=<pw>    Reload password (default: app name)");
			out("  --no-sqlite               Skip default SQLite database setup");
			out("  --setup-h2                Use H2 embedded database instead of SQLite");
			out("  --no-open-browser         Don't open browser on server start");
			out("");
			out("Examples:", "bold");
			out("  wheels new myapp");
			out("  wheels new myapp --port=3000 --setup-h2");
			out("  wheels new myapp --datasource=mydb --no-sqlite");
			return "";
		}

		var appName = "";
		var options = {
			port: 8080,
			datasource: "",
			reloadPassword: "",
			setupH2: false,
			noSQLite: false,
			openBrowser: true
		};

		// Parse arguments: first non-flag arg is app name, flags are options
		for (var i = 1; i <= arrayLen(args); i++) {
			var arg = args[i];
			if (reFindNoCase("^--port=", arg)) {
				options.port = val(valueAfterEquals(arg));
			} else if (reFindNoCase("^--datasource=", arg)) {
				options.datasource = valueAfterEquals(arg);
			} else if (reFindNoCase("^--reload-password=", arg)) {
				options.reloadPassword = valueAfterEquals(arg);
			} else if (arg == "--setup-h2") {
				options.setupH2 = true;
			} else if (arg == "--no-sqlite") {
				options.noSQLite = true;
			} else if (arg == "--no-open-browser") {
				options.openBrowser = false;
			} else if (!arg.startsWith("--") && !len(appName)) {
				appName = arg;
			}
		}

		if (!len(appName)) {
			out("Error: app name is required.", "red");
			out("Usage: wheels new <appname>");
			return "";
		}

		// Default datasource to app name, generate random reload password
		if (!len(options.datasource)) options.datasource = lCase(appName);
		if (!len(options.reloadPassword)) options.reloadPassword = generateRandomPassword();

		return scaffoldNewApp(appName, options);
	}

	// ─────────────────────────────────────────────────
	//  create — Create application components
	// ─────────────────────────────────────────────────

	/**
	 * hint: Create application components (wheels create app <name> [options])
	 */
	public string function create() {
		var args = __arguments ?: [];

		if (!arrayLen(args)) {
			out("Usage: wheels create <type> <name> [options]", "yellow");
			out("");
			out("Types:", "bold");
			out("  app    Create a new Wheels application");
			out("");
			out("Examples:", "bold");
			out("  wheels create app myapp");
			out("  wheels create app myapp --port=3000 --setup-h2");
			return "";
		}

		var type = lCase(args[1]);
		var remaining = args.len() > 1 ? args.slice(2) : [];

		switch (type) {
			case "app":
				__arguments = remaining;
				return new();
			default:
				out("Unknown create type: #type#", "red");
				out("Run 'wheels create' for available types.");
				return "";
		}
	}

	// ─────────────────────────────────────────────────
	//  routes — List application routes
	// ─────────────────────────────────────────────────

	/**
	 * hint: List all configured routes with method, path, and controller action
	 */
	public string function routes() {
		var serverPort = detectServerPort();
		if (!serverPort) {
			out("No running Wheels server detected. Start one with: wheels start", "red");
			return "";
		}

		try {
			var routesUrl = "http://localhost:#serverPort#/wheels/ai?context=routing";
			var httpResult = makeHttpRequest(routesUrl);

			out(httpResult);
		} catch (any e) {
			out("Failed to fetch routes: #e.message#", "red");
		}
		return "";
	}

	// ─────────────────────────────────────────────────
	//  info — Show environment info
	// ─────────────────────────────────────────────────

	/**
	 * hint: Show framework version, environment, and configuration
	 */
	public string function info() {
		out("Wheels CLI v#version()#", "bold");
		out("");

		if (len(variables.projectRoot) && directoryExists(variables.projectRoot & "/vendor/wheels")) {
			out("Project:  #variables.projectRoot#");

			// Detect Wheels version from vendor
			var versionFile = variables.projectRoot & "/vendor/wheels/events/onapplicationstart/settings.cfm";
			if (fileExists(versionFile)) {
				try {
					var vContent = fileRead(versionFile);
					var vMatch = reFindNoCase('version[^"]*"([^"]+)"', vContent, 1, true);
					if (arrayLen(vMatch.match) > 1) {
						out("Wheels:   v#vMatch.match[2]#");
					}
				} catch (any e) { /* skip */ }
			}

			// CFML engine
			out("Engine:   Lucee (LuCLI module)");

			// Datasource
			var settingsFile = variables.projectRoot & "/config/settings.cfm";
			if (fileExists(settingsFile)) {
				try {
					var sContent = fileRead(settingsFile);
					var dsMatch = reFindNoCase('dataSourceName\s*[=,]\s*"([^"]+)"', sContent, 1, true);
					if (arrayLen(dsMatch.match) > 1) {
						out("Database: #dsMatch.match[2]#");
					}
				} catch (any e) { /* skip */ }
			}

			// Environment file
			var envFile = variables.projectRoot & "/.env";
			if (fileExists(envFile)) {
				out("Env file: .env found", "green");
			}

			// lucee.json
			var luceeJson = variables.projectRoot & "/lucee.json";
			if (fileExists(luceeJson)) {
				out("Config:   lucee.json found", "green");
			}

			// Count routes
			var routesFile = variables.projectRoot & "/config/routes.cfm";
			if (fileExists(routesFile)) {
				var routeContent = fileRead(routesFile);
				var resourceCount = 0;
				var pos = 1;
				while (pos > 0) {
					pos = findNoCase(".resources(", routeContent, pos);
					if (pos > 0) { resourceCount++; pos++; }
				}
				if (resourceCount > 0) {
					out("Routes:   #resourceCount# resource route(s)");
				}
			}

			// Count models
			var modelsDir = variables.projectRoot & "/app/models";
			if (directoryExists(modelsDir)) {
				var modelCount = arrayLen(directoryList(modelsDir, false, "name", "*.cfc"));
				if (modelCount > 0) {
					out("Models:   #modelCount# model(s)");
				}
			}

			// Server status
			var serverPort = detectServerPort();
			if (serverPort) {
				out("Server:   running on port #serverPort#", "green");
			} else {
				out("Server:   not running", "yellow");
			}
		} else {
			out("Not in a Wheels project directory.", "yellow");
		}
		return "";
	}

	// ─────────────────────────────────────────────────
	//  mcp — MCP server instructions
	// ─────────────────────────────────────────────────

	/**
	 * hint: Show MCP server configuration instructions
	 */
	public string function mcp() {
		out("MCP is built into LuCLI. Run:", "bold");
		out("  lucli mcp wheels");
		out("");
		out("Configure in Claude Code (.claude/claude_project_config.json):", "bold");
		out('  {"mcpServers":{"wheels":{"command":"lucli","args":["mcp","wheels"]}}}');
		out("");
		out("All public commands in this module are auto-discovered as MCP tools.");
		out("Tools are prefixed with the module name: wheels_generate, wheels_migrate, etc.");
		return "";
	}

	// ─────────────────────────────────────────────────
	//  console — Interactive REPL
	// ─────────────────────────────────────────────────

	/**
	 * hint: Launch interactive CFML console with Wheels app context (model, service, get)
	 */
	public string function console() {
		var args = __arguments ?: [];
		var password = "";

		// Parse --password=value
		for (var i = 1; i <= arrayLen(args); i++) {
			var arg = args[i];
			if (reFindNoCase("^--password=", arg)) {
				password = valueAfterEquals(arg);
			} else if (arg == "--password" && i < arrayLen(args)) {
				password = args[++i];
			}
		}

		// Detect server
		var serverPort = detectServerPort();
		if (!serverPort) {
			out("No running Wheels server detected.", "red");
			out("The console requires a running server. Start with: wheels start");
			return "";
		}

		// Auto-detect reload password if not provided
		if (!len(password)) {
			password = detectReloadPassword();
		}

		// Verify connectivity with a ping
		var evalUrl = "http://localhost:#serverPort#/wheels/console/eval";
		try {
			var pingResult = makeHttpPost(evalUrl, serializeJSON({expression: "__ping__", password: password}));
			if (isJSON(pingResult)) {
				var pingData = deserializeJSON(pingResult);
				if (!pingData.success) {
					out("Console connection failed: #pingData.error#", "red");
					return "";
				}
				var wheelsVersion = pingData.version ?: "unknown";
				var wheelsEnv = pingData.environment ?: "unknown";
			} else {
				out("Server returned unexpected response. Is this a Wheels 3.x application?", "red");
				return "";
			}
		} catch (any e) {
			out("Cannot connect to console endpoint at #evalUrl#", "red");
			out("Ensure your Wheels app is v3.1+ with console support.", "yellow");
			out("Error: #e.message#", "yellow");
			return "";
		}

		// Banner
		out("", "");
		out("Wheels Console v#version()#", "bold");
		out("Connected to localhost:#serverPort# (#wheelsEnv#) — Wheels #wheelsVersion#", "cyan");
		out("Type expressions to evaluate in your app context. /help for commands.", "");
		out("", "");

		// Interactive REPL loop
		var System = createObject("java", "java.lang.System");
		var reader = createObject("java", "java.io.BufferedReader").init(
			createObject("java", "java.io.InputStreamReader").init(System.in)
		);

		var running = true;
		while (running) {
			// Print prompt
			System.out.print("wheels> ");
			System.out.flush();

			// Read input
			var line = reader.readLine();

			// Handle EOF (Ctrl+D)
			if (isNull(line)) {
				out("");
				out("Bye!", "cyan");
				break;
			}

			line = trim(line);

			// Skip empty lines
			if (!len(line)) continue;

			// Handle REPL commands
			switch (lCase(line)) {
				case "/exit":
				case "/quit":
				case "/q":
					out("Bye!", "cyan");
					running = false;
					continue;

				case "/help":
				case "/h":
					printConsoleHelp();
					continue;

				case "/env":
					consoleExec(evalUrl, "__env__", password);
					continue;

				case "/reload":
					out("Reloading application...", "cyan");
					try {
						var reloadUrl = "http://localhost:#serverPort#/?reload=true&password=#password#";
						makeHttpRequest(reloadUrl);
						out("Application reloaded.", "green");
					} catch (any e) {
						out("Reload failed: #e.message#", "red");
					}
					continue;

				case "/clear":
					// ANSI clear screen
					System.out.print(chr(27) & "[2J" & chr(27) & "[H");
					System.out.flush();
					continue;

				case "/models":
					consoleExec(evalUrl, "structKeyArray(application.wheels.models).sort('textnocase')", password);
					continue;

				case "/routes":
					consoleExec(evalUrl, "application.wheels.routes.map(function(r){ return r.pattern & ' -> ' & r.controller & '##' & r.action; })", password);
					continue;

				case "/version":
					consoleExec(evalUrl, "application.wheels.version", password);
					continue;

				case "/ds":
				case "/datasource":
					consoleExec(evalUrl, "application.wheels.dataSourceName", password);
					continue;
			}

			// Evaluate expression
			consoleExec(evalUrl, line, password);
		}

		return "";
	}

	/**
	 * Execute a single expression and display the result
	 */
	private void function consoleExec(required string url, required string expression, string password = "") {
		try {
			var body = serializeJSON({expression: expression, password: password});
			var httpResult = makeHttpPost(url, body);

			if (!isJSON(httpResult)) {
				out("Server returned non-JSON response.", "red");
				verbose(httpResult);
				return;
			}

			var result = deserializeJSON(httpResult);

			// Display captured output (from writeOutput calls)
			if (len(result.output ?: "")) {
				out(result.output);
			}

			if (!result.success) {
				out("Error: #result.error#", "red");
				return;
			}

			// Display result based on type
			var resultType = result.type ?: "void";
			var resultValue = result.result ?: "";

			if (resultType == "void" && !len(resultValue)) {
				// No return value and no output — nothing to display
				return;
			}

			switch (resultType) {
				case "query":
					displayQueryResult(resultValue);
					break;

				case "model":
					displayModelResult(resultValue);
					break;

				case "struct":
				case "array":
					displayJsonResult(resultValue, resultType);
					break;

				case "number":
				case "boolean":
				case "string":
					out("=> #resultValue#", "green");
					break;

				case "object":
					out("=> [#resultValue#]", "cyan");
					break;

				default:
					if (len(resultValue)) {
						out("=> #resultValue#");
					}
			}

		} catch (any e) {
			out("Request failed: #e.message#", "red");
		}
	}

	/**
	 * Display a query result as a formatted table
	 */
	private void function displayQueryResult(required string jsonResult) {
		try {
			var data = deserializeJSON(jsonResult);
			var columns = data.columns ?: [];
			var rows = data.data ?: [];
			var recordCount = data.recordCount ?: 0;

			if (!arrayLen(columns)) {
				out("(empty query)", "yellow");
				return;
			}

			// Calculate column widths
			var widths = {};
			for (var col in columns) {
				widths[col] = len(col);
			}
			for (var row in rows) {
				for (var col in columns) {
					var val = toString(row[col] ?: "");
					if (len(val) > 40) val = left(val, 37) & "...";
					widths[col] = max(widths[col], len(val));
				}
			}

			// Header
			var header = "";
			var separator = "";
			for (var col in columns) {
				var w = widths[col];
				header &= " " & lCase(col) & repeatString(" ", w - len(col)) & " |";
				separator &= repeatString("-", w + 2) & "+";
			}
			out(header, "bold");
			out(separator, "");

			// Rows
			for (var row in rows) {
				var line = "";
				for (var col in columns) {
					var w = widths[col];
					var val = toString(row[col] ?: "");
					if (len(val) > 40) val = left(val, 37) & "...";
					line &= " " & val & repeatString(" ", w - len(val)) & " |";
				}
				out(line);
			}

			// Footer
			if (recordCount > arrayLen(rows)) {
				out("(#recordCount# rows, showing first #arrayLen(rows)#)", "yellow");
			} else {
				out("(#recordCount# row#recordCount != 1 ? 's' : ''#)", "yellow");
			}

		} catch (any e) {
			// Fallback: show raw JSON
			out(jsonResult);
		}
	}

	/**
	 * Display a model result as key-value pairs
	 */
	private void function displayModelResult(required string jsonResult) {
		try {
			var props = deserializeJSON(jsonResult);
			out("=> {", "green");
			var keys = structKeyArray(props);
			arraySort(keys, "textnocase");
			for (var key in keys) {
				if (left(key, 1) == "_") continue; // Skip meta keys in main display
				var val = isNull(props[key]) ? "null" : toString(props[key]);
				if (len(val) > 80) val = left(val, 77) & "...";
				out("    #lCase(key)#: #val#");
			}
			// Show meta info
			if (structKeyExists(props, "_key")) {
				out("    _key: #props._key#", "cyan");
			}
			if (structKeyExists(props, "_isNew")) {
				out("    _isNew: #props._isNew#", "cyan");
			}
			out("  }", "green");
		} catch (any e) {
			out("=> #jsonResult#");
		}
	}

	/**
	 * Display a struct or array result as indented JSON
	 */
	private void function displayJsonResult(required string jsonResult, required string type) {
		try {
			// Simple indentation for readability
			var formatted = jsonResult;
			// Basic pretty-print: add newlines after { [ , and before } ]
			formatted = replace(formatted, "{", "{#chr(10)#  ", "all");
			formatted = replace(formatted, "}", "#chr(10)#}", "all");
			formatted = replace(formatted, "[", "[#chr(10)#  ", "all");
			formatted = replace(formatted, "]", "#chr(10)#]", "all");
			formatted = replace(formatted, ",", ",#chr(10)#  ", "all");
			out("=> #formatted#", "green");
		} catch (any e) {
			out("=> #jsonResult#");
		}
	}

	/**
	 * Print console help text
	 */
	private void function printConsoleHelp() {
		out("");
		out("Wheels Console Commands:", "bold");
		out("  /help, /h       Show this help");
		out("  /env            Show environment info");
		out("  /models         List all registered models");
		out("  /routes         List all routes");
		out("  /version        Show Wheels version");
		out("  /ds             Show current datasource");
		out("  /reload         Reload the application");
		out("  /clear          Clear the screen");
		out("  /exit, /quit    Exit the console");
		out("");
		out("Expression Examples:", "bold");
		out('  model("User").findAll()                      Query all users');
		out('  model("User").findByKey(1)                   Find user by ID');
		out('  model("User").findByKey(1).properties()      Get user properties');
		out('  model("User").count()                        Count records');
		out('  model("Post").findAll(where="status=''draft''")  Filtered query');
		out('  get("environment")                           Framework setting');
		out('  service("emailService")                      Resolve a service');
		out('  application.wheels.version                   Wheels version');
		out("");
	}

	// ─────────────────────────────────────────────────
	//  analyze — Code analysis
	// ─────────────────────────────────────────────────

	/**
	 * hint: Analyze Wheels application code for quality issues, anti-patterns, and complexity metrics
	 */
	public string function analyze() {
		var args = __arguments ?: [];
		var target = arrayLen(args) ? lCase(args[1]) : "all";

		if (!arrayLen(args) && !directoryExists(variables.projectRoot & "/app")) {
			out("No app/ directory found. Are you in a Wheels project?", "red");
			return "";
		}

		out("Analyzing code...", "cyan");
		out("");

		try {
			var analysis = getService("analysis");
			var results = analysis.analyze(target);

			// Display metrics
			out("Code Analysis Results", "bold");
			out("────────────────────────────────────");
			out("Files:      #results.totalFiles#");
			out("Lines:      #results.totalLines#");
			out("Functions:  #results.totalFunctions#");
			out("Grade:      #results.metrics.grade# (#results.metrics.healthScore#/100)");
			out("");

			// Anti-patterns
			if (arrayLen(results.antiPatterns)) {
				out("Anti-Patterns (#arrayLen(results.antiPatterns)#)", "red");
				for (var issue in results.antiPatterns) {
					var fileName = listLast(issue.file, "/\");
					var severity = issue.severity == "error" ? "red" : "yellow";
					out("  [#uCase(issue.severity)#] #fileName#:#issue.line ?: 1# — #issue.message#", severity);
				}
				out("");
			}

			// Complex functions
			if (arrayLen(results.complexFunctions)) {
				out("Complex Functions (#arrayLen(results.complexFunctions)#)", "yellow");
				for (var f in results.complexFunctions) {
					var fName = listLast(f.file, "/\");
					out("  #fName#:#f.functionName# — complexity #f.complexity#", "yellow");
				}
				out("");
			}

			// Code smells
			if (arrayLen(results.codeSmells)) {
				out("Code Smells (#arrayLen(results.codeSmells)#)", "yellow");
				for (var smell in results.codeSmells) {
					var sName = listLast(smell.file, "/\");
					out("  #sName# — #smell.message#", "yellow");
				}
				out("");
			}

			if (!arrayLen(results.antiPatterns) && !arrayLen(results.complexFunctions) && !arrayLen(results.codeSmells)) {
				out("No issues found!", "green");
			}

			out("Completed in #numberFormat(results.executionTime, '0.00')#s");
		} catch (any e) {
			out("Analysis failed: #e.message#", "red");
		}

		return "";
	}

	// ─────────────────────────────────────────────────
	//  validate — Quick validation
	// ─────────────────────────────────────────────────

	/**
	 * hint: Validate Wheels application code for common errors and anti-patterns
	 */
	public string function validate() {
		if (!directoryExists(variables.projectRoot & "/app")) {
			out("No app/ directory found. Are you in a Wheels project?", "red");
			return "";
		}

		out("Validating...", "cyan");
		out("");

		try {
			var analysis = getService("analysis");
			var results = analysis.validate();

			if (results.valid) {
				out("Validation passed — no errors found (#results.totalIssues# warnings)", "green");
			} else {
				out("Validation found #results.totalIssues# issue(s):", "red");
			}

			for (var issue in results.issues) {
				var fileName = listLast(issue.file, "/\");
				var severity = issue.severity == "error" ? "red" : "yellow";
				out("  [#uCase(issue.severity)#] #fileName# — #issue.message#", severity);
			}
		} catch (any e) {
			out("Validation failed: #e.message#", "red");
		}

		return "";
	}

	// ─────────────────────────────────────────────────
	//  destroy — Remove generated components
	// ─────────────────────────────────────────────────

	/**
	 * hint: Remove generated components (resource, model, controller, view)
	 */
	public string function destroy() {
		var args = __arguments ?: [];

		var positional = [];
		var force = false;
		for (var a in args) {
			if (a == "--force") { force = true; }
			else { arrayAppend(positional, a); }
		}
		if (!arrayLen(positional)) {
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
		var name = trim(positional[1]);
		var type = arrayLen(positional) > 1 ? lCase(trim(positional[2])) : "resource";

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
			out("Use --force to confirm deletion.", "yellow");
			return "";
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

	// ═════════════════════════════════════════════════
	//  PRIVATE — Implementation details
	// ═════════════════════════════════════════════════

	// ── Code Generation ──────────────────────────────

	private string function generateModel(required array args) {
		if (!arrayLen(args)) {
			out("Usage: wheels generate model <Name> [properties...]", "yellow");
			out("  Example: wheels generate model User name email:string active:boolean");
			return "";
		}

		var modelName = capitalize(args[1]);
		var properties = args.len() > 1 ? args.slice(2) : [];

		// Parse properties and associations from args
		var parsed = parseGeneratorArgs(properties);

		// Use CodeGen service with template files
		var codegen = getService("codegen");
		var validation = codegen.validateName(modelName, "model");
		if (!validation.valid) {
			out("Invalid model name: #arrayToList(validation.errors, '; ')#", "red");
			return "";
		}

		var result = codegen.generateModel(
			name = modelName,
			properties = parsed.properties,
			belongsTo = arrayToList(parsed.belongsTo),
			hasMany = arrayToList(parsed.hasMany),
			hasOne = arrayToList(parsed.hasOne)
		);

		if (result.success) {
			printCreated("app/models/#modelName#.cfc");
		} else {
			out(result.error, "red");
			return "";
		}

		// Also generate migration if properties provided
		if (arrayLen(parsed.properties)) {
			var scaffold = getService("scaffold");
			var migrationPath = scaffold.createMigrationWithProperties(modelName, parsed.properties);
			var migrationFileName = listLast(migrationPath, "/\");
			printCreated("app/migrator/migrations/#migrationFileName#");
		}

		return "";
	}

	private string function generateController(required array args) {
		if (!arrayLen(args)) {
			out("Usage: wheels generate controller <Name> [actions...]", "yellow");
			out("  Example: wheels generate controller Users index show create");
			return "";
		}

		var controllerName = capitalize(args[1]);
		var actions = args.len() > 1 ? args.slice(2) : [];

		var codegen = getService("codegen");
		var result = codegen.generateController(name = controllerName, actions = actions);

		if (result.success) {
			printCreated("app/controllers/#controllerName#.cfc");
		} else {
			out(result.error, "red");
			return "";
		}

		// Create view files for non-mutation actions
		var viewDir = variables.projectRoot & "/app/views/#lCase(controllerName)#";
		ensureDirectory(viewDir);

		for (var action in actions) {
			if (!listFindNoCase("create,update,delete,destroy", action)) {
				var viewResult = codegen.generateView(name = controllerName, action = action);
				if (viewResult.success) {
					printCreated("app/views/#lCase(controllerName)#/#lCase(action)#.cfm");
				}
			}
		}

		return "";
	}

	private string function generateView(required array args) {
		if (arrayLen(args) < 2) {
			out("Usage: wheels generate view <controller> <action>", "yellow");
			return "";
		}

		var controllerName = args[1];
		var actionName = lCase(args[2]);

		var codegen = getService("codegen");
		var result = codegen.generateView(name = controllerName, action = actionName);

		if (result.success) {
			printCreated("app/views/#lCase(controllerName)#/#actionName#.cfm");
		} else {
			out(result.error, "red");
		}
		return "";
	}

	private string function generateMigration(required array args) {
		if (!arrayLen(args)) {
			out("Usage: wheels generate migration <Name>", "yellow");
			out("  Example: wheels generate migration AddEmailToUsers");
			return "";
		}

		var migrationName = args[1];
		var timestamp = getService("helpers").generateMigrationTimestamp();
		var fileName = "#timestamp#_#migrationName#.cfc";
		var migrationDir = variables.projectRoot & "/app/migrator/migrations";
		var filePath = migrationDir & "/#fileName#";

		ensureDirectory(migrationDir);

		// Use the DBMigrate template if available, otherwise inline
		var templates = getService("templates");
		var result = templates.generateFromTemplate(
			template = "dbmigrate/blank.txt",
			destination = "app/migrator/migrations/#fileName#",
			context = {migrationName: migrationName}
		);

		if (!result.success) {
			// Fallback to inline empty migration
			var content = buildEmptyMigration(migrationName);
			fileWrite(filePath, content);
		}

		printCreated("app/migrator/migrations/#fileName#");
		return "";
	}

	private string function generateScaffold(required array args) {
		if (!arrayLen(args)) {
			out("Usage: wheels generate scaffold <Name> [properties...]", "yellow");
			out("  Example: wheels generate scaffold Post title body:text publishedAt:datetime");
			return "";
		}

		var modelName = capitalize(args[1]);
		var controllerName = getService("helpers").pluralize(modelName);
		var properties = args.len() > 1 ? args.slice(2) : [];

		out("Scaffolding #modelName#...", "cyan");
		out("");

		// Parse properties
		var parsed = parseGeneratorArgs(properties);

		var scaffold = getService("scaffold");
		var results = scaffold.generateScaffold(
			name = modelName,
			properties = parsed.properties,
			belongsTo = arrayToList(parsed.belongsTo),
			hasMany = arrayToList(parsed.hasMany)
		);

		if (results.success) {
			for (var item in results.generated) {
				var relPath = listLast(item.path, "/\");
				printCreated("#item.type#: #relPath#");
			}

			out("");
			out("Scaffold complete! Next steps:", "green");
			out("  1. Run migrations: wheels migrate latest");
			out("  2. Start server: wheels start");
		} else {
			out("Scaffold failed:", "red");
			for (var err in results.errors) {
				out("  #err#", "red");
			}
		}

		return "";
	}

	private string function generateRoute(required array args) {
		if (!arrayLen(args)) {
			out("Usage: wheels generate route <name>", "yellow");
			out("  Example: wheels generate route posts");
			return "";
		}

		var routeName = lCase(args[1]);
		var routesPath = variables.projectRoot & "/config/routes.cfm";

		if (!fileExists(routesPath)) {
			out("config/routes.cfm not found.", "red");
			return "";
		}

		// Check for duplicate before delegating
		var content = fileRead(routesPath);
		var resourceRoute = '.resources("' & routeName & '")';
		if (findNoCase(resourceRoute, content)) {
			out("Route already exists: #resourceRoute#", "yellow");
			return "";
		}

		// Delegate to Scaffold service for the actual route insertion
		var scaffold = getService("scaffold");
		var inserted = scaffold.updateRoutes(routeName);

		if (inserted) {
			out("  route   #resourceRoute# added to config/routes.cfm", "green");
		} else {
			out("Could not find insertion point in routes.cfm. Add manually:", "yellow");
			out("  #resourceRoute#");
		}

		return "";
	}

	private string function generateTest(required array args) {
		if (arrayLen(args) < 2) {
			out("Usage: wheels generate test <type> <Name>", "yellow");
			out("  Types: model, controller");
			out("  Example: wheels generate test model User");
			return "";
		}

		var testType = lCase(args[1]);
		var testName = capitalize(args[2]);

		if (!listFindNoCase("model,controller", testType)) {
			out("Unknown test type: #testType#. Use 'model' or 'controller'.", "red");
			return "";
		}

		var codegen = getService("codegen");
		var result = codegen.generateTest(type = testType, name = testName);

		if (result.success) {
			var relPath = listLast(result.path, "/\");
			printCreated(relPath);
		} else {
			out(result.error, "red");
		}

		return "";
	}

	private string function generateProperty(required array args) {
		if (arrayLen(args) < 2) {
			out("Usage: wheels generate property <ModelName> <property:type>", "yellow");
			out("  Example: wheels generate property User email:string");
			return "";
		}

		var modelName = capitalize(args[1]);
		var propArg = args[2];
		var parts = listToArray(propArg, ":");
		var propName = parts[1];
		var propType = arrayLen(parts) > 1 ? parts[2] : "string";

		var tableName = getService("helpers").pluralize(lCase(modelName));
		var timestamp = getService("helpers").generateMigrationTimestamp();
		var migrationName = "Add#capitalize(propName)#To#capitalize(tableName)#";
		var fileName = "#timestamp#_#migrationName#.cfc";
		var migrationDir = variables.projectRoot & "/app/migrator/migrations";

		ensureDirectory(migrationDir);

		var colType = mapPropertyType(propType);
		var nl = chr(10);
		var tab = chr(9);
		var content = 'component extends="wheels.migrator.Migration" {' & nl & nl;
		content &= tab & 'function up() {' & nl;
		content &= tab & tab & 'transaction {' & nl;
		content &= tab & tab & tab & 't = changeTable(name="#tableName#");' & nl;
		content &= tab & tab & tab & 't.#colType#(columnNames="#propName#");' & nl;
		content &= tab & tab & tab & 't.change();' & nl;
		content &= tab & tab & '}' & nl;
		content &= tab & '}' & nl & nl;

		content &= tab & 'function down() {' & nl;
		content &= tab & tab & 'transaction {' & nl;
		content &= tab & tab & tab & 'removeColumn(table="#tableName#", columnName="#propName#");' & nl;
		content &= tab & tab & '}' & nl;
		content &= tab & '}' & nl & nl;

		content &= '}' & nl;

		fileWrite(migrationDir & "/" & fileName, content);
		printCreated("app/migrator/migrations/#fileName#");
		out("");
		out("Remember to add validation in app/models/#modelName#.cfc config():", "yellow");
		out('  validatesPresenceOf("#propName#");');

		return "";
	}

	private string function generateApiResource(required array args) {
		if (!arrayLen(args)) {
			out("Usage: wheels generate api-resource <Name> [properties...]", "yellow");
			out("  Example: wheels generate api-resource Product name price:decimal sku:string");
			out("");
			out("Generates:");
			out("  Model:      app/models/<Name>.cfc");
			out("  Controller: app/controllers/api/<Names>.cfc (JSON-only, no views)");
			out("  Migration:  app/migrator/migrations/<timestamp>_create_<names>_table.cfc");
			out("  Tests:      tests/specs/models/<Name>Spec.cfc");
			out("              tests/specs/controllers/Api<Names>ControllerSpec.cfc");
			out("  Routes:     .namespace(""api"").resources(name=""<names>"", except=""new,edit"")");
			return "";
		}

		var modelName = capitalize(args[1]);
		var controllerName = getService("helpers").pluralize(modelName);
		var properties = args.len() > 1 ? args.slice(2) : [];

		out("Generating API resource #modelName#...", "cyan");
		out("");

		// Parse properties and associations
		var parsed = parseGeneratorArgs(properties);

		var scaffold = getService("scaffold");
		var results = scaffold.generateApiResource(
			name = modelName,
			properties = parsed.properties,
			belongsTo = arrayToList(parsed.belongsTo),
			hasMany = arrayToList(parsed.hasMany)
		);

		if (results.success) {
			for (var item in results.generated) {
				var relPath = listLast(item.path, "/\");
				printCreated("#item.type#: #relPath#");
			}

			out("");
			out("API resource complete! Next steps:", "green");
			out("  1. Run migrations: wheels migrate latest");
			out("  2. Start server: wheels start");
			out("  3. Test: curl http://localhost:8080/api/#lCase(controllerName)#.json");
		} else {
			out("API resource generation failed:", "red");
			for (var err in results.errors) {
				out("  #err#", "red");
			}
		}

		return "";
	}

	private string function generateHelper(required array args) {
		if (!arrayLen(args)) {
			out("Usage: wheels generate helper <name> [functions...]", "yellow");
			out("  Example: wheels generate helper formatting truncateText formatCurrency");
			return "";
		}

		var helperName = capitalize(args[1]);
		var functions = args.len() > 1 ? args.slice(2) : [];

		// Parse --force flag from functions list
		var force = false;
		var cleanFunctions = [];
		for (var f in functions) {
			if (f == "--force") {
				force = true;
			} else {
				arrayAppend(cleanFunctions, f);
			}
		}

		var codegen = getService("codegen");
		var validation = codegen.validateName(helperName, "helper");
		if (!validation.valid) {
			out("Invalid helper name: #arrayToList(validation.errors, '; ')#", "red");
			return "";
		}

		var result = codegen.generateHelper(
			name = helperName,
			functions = cleanFunctions,
			force = force
		);

		if (result.success) {
			// Derive the actual file name (CodeGen appends "Helper" suffix)
			var fileName = listLast(result.path, "/\");
			printCreated("app/helpers/#fileName#");
		} else {
			out(result.error, "red");
			return "";
		}

		out("");
		out("Helper created! Next steps:", "green");
		out("  1. Edit app/helpers/#fileName# to add your logic");
		out("  2. Include in your controller: new app.helpers.#reReplace(fileName, '\.cfc$', '')#()");
		return "";
	}

	private string function generateSnippets(required array args) {
		var force = false;
		var positional = [];
		for (var arg in args) {
			if (arg == "--force") {
				force = true;
			} else if (left(arg, 2) != "--") {
				arrayAppend(positional, arg);
			}
		}

		// No args or --list: show available snippets
		if (!arrayLen(positional)) {
			return listSnippets();
		}

		var pattern = lCase(positional[1]);

		// "templates" subcommand: copy raw template files (old behavior)
		if (pattern == "templates") {
			return copySnippetTemplates(force);
		}

		// Look up the named snippet pattern
		var snippets = getSnippetRegistry();
		if (!structKeyExists(snippets, pattern)) {
			out("Unknown snippet pattern: #pattern#", "red");
			out("Run 'wheels generate snippets' for available patterns.");
			return "";
		}

		var snippet = snippets[pattern];
		var files = snippet.generate(variables.projectRoot, force);

		out("");
		if (arrayLen(files)) {
			out("#snippet.name# snippet generated (#arrayLen(files)# file(s)):", "green");
			for (var f in files) {
				printCreated(f);
			}
		} else {
			out("All files already exist (use --force to overwrite).", "yellow");
		}

		if (structKeyExists(snippet, "hint") && len(snippet.hint)) {
			out("");
			out(snippet.hint, "cyan");
		}
		return "";
	}

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
			out("Visit /admin/#lCase(getService(""helpers"").pluralize(modelName))# after reloading.", "cyan");
		} else {
			for (var err in result.errors) {
				out(err, "red");
			}
		}

		return "";
	}

	/**
	 * List all available snippet patterns
	 */
	private string function listSnippets() {
		out("Usage: wheels generate snippets <pattern> [--force]", "yellow");
		out("");
		out("Available snippet patterns:", "bold");
		out("");
		var snippets = getSnippetRegistry();
		var keys = structKeyArray(snippets);
		arraySort(keys, "textnocase");
		for (var key in keys) {
			var s = snippets[key];
			out("  #key##repeatString(' ', 20 - len(key))##s.description#");
		}
		out("");
		out("Special commands:", "bold");
		out("  templates           Copy raw generator templates to app/snippets/ for customization");
		out("");
		out("Examples:", "bold");
		out("  wheels generate snippets auth");
		out("  wheels generate snippets soft-delete");
		out("  wheels generate snippets api-controller --force");
		out("  wheels generate snippets templates");
		return "";
	}

	/**
	 * Registry of named snippet patterns.
	 * Each entry has: name, description, hint, generate(projectRoot, force) -> array of relative paths
	 */
	private struct function getSnippetRegistry() {
		var snippetDir = getDirectoryFromPath(getCurrentTemplatePath()) & "templates/snippets/";

		return {
			"auth": {
				name: "Authentication",
				description: "Session controller, login view, and auth filter",
				hint: "Add filters(through=""authenticate"") to controllers that need protection.",
				generate: function(string projectRoot, boolean force) {
					var created = [];

					var sessionCtrl = fileRead(snippetDir & "auth-sessions-controller.txt");
					var p = writeSnippetFile(projectRoot, "app/controllers/Sessions.cfc", sessionCtrl, force);
					if (len(p)) arrayAppend(created, p);

					var loginView = fileRead(snippetDir & "auth-login-view.txt");
					p = writeSnippetFile(projectRoot, "app/views/sessions/new.cfm", loginView, force);
					if (len(p)) arrayAppend(created, p);

					var authFilter = fileRead(snippetDir & "auth-filter.txt");
					p = writeSnippetFile(projectRoot, "app/snippets/auth-filter.cfm", authFilter, force);
					if (len(p)) arrayAppend(created, p);

					return created;
				}
			},
			"soft-delete": {
				name: "Soft Delete",
				description: "Model callbacks for soft delete instead of hard delete",
				hint: "Add this to any model: include(template=""/app/snippets/soft-delete.cfm"").",
				generate: function(string projectRoot, boolean force) {
					var created = [];

					var content = fileRead(snippetDir & "soft-delete-mixin.txt");
					var p = writeSnippetFile(projectRoot, "app/snippets/soft-delete.cfm", content, force);
					if (len(p)) arrayAppend(created, p);

					var migration = fileRead(snippetDir & "soft-delete-migration.txt");
					p = writeSnippetFile(projectRoot, "app/snippets/soft-delete-migration.cfc", migration, force);
					if (len(p)) arrayAppend(created, p);

					return created;
				}
			},
			"api-controller": {
				name: "API Controller",
				description: "JSON API controller with error handling and content negotiation",
				hint: "Rename the component and model references, then add a route: .resources(name=""items"").",
				generate: function(string projectRoot, boolean force) {
					var created = [];

					var content = fileRead(snippetDir & "api-controller.txt");
					var p = writeSnippetFile(projectRoot, "app/snippets/api-controller.cfc", content, force);
					if (len(p)) arrayAppend(created, p);

					return created;
				}
			},
			"crud-controller": {
				name: "CRUD Controller",
				description: "Full CRUD controller with flash messages and error handling",
				hint: "Rename the component and model references. Add route: .resources(name=""items"").",
				generate: function(string projectRoot, boolean force) {
					var created = [];

					var content = fileRead(snippetDir & "crud-controller.txt");
					var p = writeSnippetFile(projectRoot, "app/snippets/crud-controller.cfc", content, force);
					if (len(p)) arrayAppend(created, p);

					return created;
				}
			},
			"flash-messages": {
				name: "Flash Messages",
				description: "Partial view for displaying flash messages with Bootstrap styling",
				hint: "Include in your layout: ##includePartial(partial=""/shared/flash"")##.",
				generate: function(string projectRoot, boolean force) {
					var created = [];

					var content = fileRead(snippetDir & "flash-messages.txt");
					var p = writeSnippetFile(projectRoot, "app/views/shared/_flash.cfm", content, force);
					if (len(p)) arrayAppend(created, p);

					return created;
				}
			},
			"pagination": {
				name: "Pagination",
				description: "Paginated list view with navigation controls",
				hint: "Use with: records = model(""Item"").findAll(page=params.page, perPage=25).",
				generate: function(string projectRoot, boolean force) {
					var created = [];

					var content = fileRead(snippetDir & "pagination-view.txt");
					var p = writeSnippetFile(projectRoot, "app/snippets/pagination-view.cfm", content, force);
					if (len(p)) arrayAppend(created, p);

					return created;
				}
			},
			"seed-data": {
				name: "Seed Data",
				description: "Database seeding template with seedOnce() examples",
				hint: "Run seeds with: wheels db:seed.",
				generate: function(string projectRoot, boolean force) {
					var created = [];

					var content = fileRead(snippetDir & "seeds.txt");
					var p = writeSnippetFile(projectRoot, "app/snippets/seeds.cfm", content, force);
					if (len(p)) arrayAppend(created, p);

					var devContent = fileRead(snippetDir & "seeds-development.txt");
					p = writeSnippetFile(projectRoot, "app/snippets/seeds-development.cfm", devContent, force);
					if (len(p)) arrayAppend(created, p);

					return created;
				}
			},
			"mailer": {
				name: "Mailer",
				description: "Email sending with Wheels mailer pattern",
				hint: "Call from controller: new app.mailers.UserMailer().sendWelcome(user).",
				generate: function(string projectRoot, boolean force) {
					var created = [];

					var content = fileRead(snippetDir & "user-mailer.txt");
					var p = writeSnippetFile(projectRoot, "app/snippets/user-mailer.cfc", content, force);
					if (len(p)) arrayAppend(created, p);

					return created;
				}
			}
		};
	}

	/**
	 * Write a snippet file, respecting the force flag.
	 * Returns the relative path if written, empty string if skipped.
	 */
	private string function writeSnippetFile(
		required string projectRoot,
		required string relativePath,
		required string content,
		boolean force = false
	) {
		var fullPath = arguments.projectRoot & "/" & arguments.relativePath;
		if (fileExists(fullPath) && !arguments.force) {
			return "";
		}
		var dir = getDirectoryFromPath(fullPath);
		if (!directoryExists(dir)) {
			directoryCreate(dir, true);
		}
		fileWrite(fullPath, arguments.content);
		return arguments.relativePath;
	}

	/**
	 * Copy raw generator template files to app/snippets/ for customization (original behavior)
	 */
	private string function copySnippetTemplates(boolean force = false) {
		var snippetsDir = variables.projectRoot & "/app/snippets";
		var templates = getService("templates");
		var templateDir = templates.getTemplateDir();

		if (!len(templateDir) || !directoryExists(templateDir)) {
			out("Template directory not found.", "red");
			return "";
		}

		ensureDirectory(snippetsDir);

		var copied = 0;
		var skipped = 0;
		var entries = directoryList(templateDir, false, "name");

		for (var entry in entries) {
			var sourcePath = templateDir & "/" & entry;
			var destPath = snippetsDir & "/" & entry;

			if (directoryExists(sourcePath)) {
				copySnippetDir(sourcePath, destPath, force);
				continue;
			}

			if (fileExists(destPath) && !force) {
				skipped++;
				continue;
			}

			fileCopy(sourcePath, destPath);
			printCreated("app/snippets/#entry#");
			copied++;
		}

		out("");
		if (copied > 0) {
			out("#copied# template(s) copied to app/snippets/", "green");
		}
		if (skipped > 0) {
			out("#skipped# existing file(s) skipped (use --force to overwrite)", "yellow");
		}
		if (copied == 0 && skipped == 0) {
			out("No templates found to copy.", "yellow");
		}

		out("");
		out("Customize templates in app/snippets/ to change generated code.");
		out("Templates in app/snippets/ override defaults for all generators.");
		return "";
	}

	/**
	 * Recursively copy a snippet template subdirectory
	 */
	private void function copySnippetDir(required string source, required string dest, boolean force = false) {
		ensureDirectory(arguments.dest);
		var entries = directoryList(arguments.source, false, "name");
		for (var entry in entries) {
			var sourcePath = arguments.source & "/" & entry;
			var destPath = arguments.dest & "/" & entry;
			if (directoryExists(sourcePath)) {
				copySnippetDir(sourcePath, destPath, arguments.force);
			} else {
				if (!fileExists(destPath) || arguments.force) {
					fileCopy(sourcePath, destPath);
					var relPath = replace(destPath, variables.projectRoot & "/", "");
					printCreated(relPath);
				}
			}
		}
	}

	// ── Migration Execution ──────────────────────────

	private string function runMigration(required string action) {
		var serverPort = detectServerPort();
		if (!serverPort) {
			out("No running Wheels server detected.", "red");
			out("Migrations require a running server. Start with: wheels server start");
			return "";
		}

		out("Running migration: #action#...", "cyan");

		try {
			var command = "";
			switch (action) {
				case "latest": command = "migrateTo"; break;
				case "up":     command = "migrateUp"; break;
				case "down":   command = "migrateDown"; break;
				case "info":   command = "info"; break;
			}

			var migrateUrl = "http://localhost:#serverPort#/wheels/cli?command=#command#&format=json";
			if (action == "latest") {
				// migrateTo needs a version — omitting it runs to latest
				migrateUrl &= "&version=";
			}

			var httpResult = makeHttpRequest(migrateUrl);

			try {
				var result = deserializeJSON(httpResult);
				if (structKeyExists(result, "message") && len(result.message)) {
					out(result.message, "green");
				} else {
					out("Migration #action# completed.", "green");
				}
			} catch (any jsonErr) {
				out("Migration #action# completed.", "green");
				verbose(httpResult);
			}
		} catch (any e) {
			rethrow;
		}

		return "";
	}

	// ── Seed Execution ──────────────────────────────

	private string function runSeed(string mode = "auto", string environment = "") {
		var serverPort = detectServerPort();
		if (!serverPort) {
			out("No running Wheels server detected.", "red");
			out("Seeding requires a running server. Start with: wheels server start");
			return "";
		}

		out("Running database seeds...", "cyan");

		try {
			var seedUrl = "http://localhost:#serverPort#/wheels/cli?command=dbSeed&format=json&mode=#mode#";
			if (len(environment)) {
				seedUrl &= "&environment=#environment#";
			}

			var httpResult = makeHttpRequest(seedUrl);

			try {
				var result = deserializeJSON(httpResult);
				if (structKeyExists(result, "success") && result.success) {
					if (structKeyExists(result, "totalCreated")) {
						out("Seeded: #result.totalCreated# created, #result.totalSkipped# skipped", "green");
					} else {
						out("Seeding completed.", "green");
					}
				} else {
					out("Seeding failed: #result.message ?: 'unknown error'#", "red");
				}
			} catch (any jsonErr) {
				out("Seeding completed.", "green");
				verbose(httpResult);
			}
		} catch (any e) {
			out("Seeding failed: #e.message#", "red");
		}

		return "";
	}

	// ── DB Commands ─────────────────────────────────

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
			out("This will run pending migrations and reseed the database.", "yellow");
			out("Use --force to confirm: wheels db reset --force", "yellow");
			return "";
		}

		// Step 1: Migrate
		try {
			out("Running migrations...", "cyan");
			runMigration("latest");
		} catch (any e) {
			out("Migration failed: #e.message#", "red");
			return "";
		}

		// Step 2: Seed (unless skipped)
		if (!skipSeed) {
			out("Running seeds...", "cyan");
			runSeed("auto", "");
		}

		out("");
		out("Database reset complete.", "green");
		return "";
	}

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

	// ── Upgrade Check ────────────────────────────────

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

	// ── Test Execution ───────────────────────────────

	private string function runTests(
		string filter = "",
		string reporter = "simple",
		string format = "json",
		boolean verboseOutput = false,
		boolean coreTests = false,
		string db = "sqlite",
		boolean ciMode = false
	) {
		var serverPort = detectServerPort();
		if (!serverPort) {
			out("No running Wheels server detected.", "red");
			out("Start with: wheels start", "yellow");
			out("Or use: bash tools/test-local.sh (auto-manages server)", "yellow");
			return "";
		}

		var testPath = coreTests ? "/wheels/core/tests" : "/wheels/app/tests";
		out("Running #(coreTests ? 'core' : 'app')# tests (#db#)...", "cyan");

		try {
			var testUrl = "http://localhost:#serverPort##testPath#?format=#format#&db=#db#";
			if (len(filter)) {
				testUrl &= "&directory=#filter#";
			}

			var httpResult = makeHttpRequest(testUrl);

			// Try to parse JSON result
			if (isJSON(httpResult)) {
				var result = deserializeJSON(httpResult);
				displayTestResults(result, verboseOutput);
			} else {
				// Could be an HTML error page
				if (reFindNoCase("<html", httpResult)) {
					out("Server returned HTML instead of JSON — possible error page.", "red");
					out("Check server logs or visit the test URL directly.", "yellow");
					verbose(httpResult);
				} else {
					out(httpResult);
				}
			}
		} catch (any e) {
			out("Test execution failed: #e.message#", "red");
		}

		return "";
	}

	private void function displayTestResults(required any result, boolean verboseOutput = false) {
		if (!isStruct(result)) {
			out(serializeJSON(result));
			return;
		}

		// Parse TestBox JSON format
		var totalPass = result.totalPass ?: (result.totalPassed ?: 0);
		var totalFail = result.totalFail ?: (result.totalFailed ?: 0);
		var totalError = result.totalError ?: (result.totalErrors ?: 0);
		var totalDuration = result.totalDuration ?: 0;
		var total = totalPass + totalFail + totalError;

		// Display bundle/suite/spec tree if verbose and bundles exist
		if (arguments.verboseOutput && structKeyExists(result, "bundleStats") && isArray(result.bundleStats)) {
			for (var bundle in result.bundleStats) {
				out("Bundle: #bundle.name ?: 'Unknown'#", "bold");
				if (structKeyExists(bundle, "suiteStats") && isArray(bundle.suiteStats)) {
					for (var suite in bundle.suiteStats) {
						displaySuite(suite, "  ");
					}
				}
			}
			out("");
		}

		// Summary line
		var duration = totalDuration > 0 ? " (#numberFormat(totalDuration / 1000, '0.00')#s)" : "";

		if (totalFail == 0 && totalError == 0) {
			out("#totalPass# passed#duration#", "green");
		} else {
			out("#totalPass# passed, #totalFail# failed, #totalError# error(s)#duration#", "red");
			out("");

			// Show failure details (skip if verbose already displayed them via displaySuite)
			if (!arguments.verboseOutput) {
				if (structKeyExists(result, "bundleStats") && isArray(result.bundleStats)) {
					for (var bundle in result.bundleStats) {
						if (structKeyExists(bundle, "suiteStats") && isArray(bundle.suiteStats)) {
							displayFailures(bundle.suiteStats);
						}
					}
				}

				// Fallback: check for flat failures array
				if (structKeyExists(result, "failures") && isArray(result.failures)) {
					for (var failure in result.failures) {
						out("  FAIL: #failure.name ?: 'unknown'#", "red");
						if (structKeyExists(failure, "message")) {
							out("    #failure.message#", "yellow");
						}
					}
				}
			}
		}
	}

	private void function displaySuite(required struct suite, string indent = "") {
		out("#indent##suite.name ?: 'Suite'#", "bold");
		if (structKeyExists(suite, "specStats") && isArray(suite.specStats)) {
			for (var spec in suite.specStats) {
				var status = spec.status ?: "unknown";
				switch (status) {
					case "Passed":
						out("#indent#  [PASS] #spec.name#", "green");
						break;
					case "Failed":
						out("#indent#  [FAIL] #spec.name#", "red");
						if (structKeyExists(spec, "failMessage") && len(spec.failMessage)) {
							out("#indent#         #spec.failMessage#", "yellow");
						}
						break;
					case "Error":
						out("#indent#  [ERR]  #spec.name#", "red");
						if (structKeyExists(spec, "error") && isStruct(spec.error) && structKeyExists(spec.error, "message")) {
							out("#indent#         #spec.error.message#", "yellow");
						}
						break;
					default:
						out("#indent#  [#uCase(status)#] #spec.name#");
				}
			}
		}
		// Nested suites
		if (structKeyExists(suite, "suiteStats") && isArray(suite.suiteStats)) {
			for (var child in suite.suiteStats) {
				displaySuite(child, indent & "  ");
			}
		}
	}

	private void function displayFailures(required array suites) {
		for (var suite in arguments.suites) {
			if (structKeyExists(suite, "specStats") && isArray(suite.specStats)) {
				for (var spec in suite.specStats) {
					var status = spec.status ?: "";
					if (status == "Failed" || status == "Error") {
						out("  FAIL: #spec.name ?: 'unknown'#", "red");
						if (structKeyExists(spec, "failMessage") && len(spec.failMessage)) {
							out("    #spec.failMessage#", "yellow");
						}
						if (structKeyExists(spec, "failOrigin") && isStruct(spec.failOrigin) && structKeyExists(spec.failOrigin, "template")) {
							out("    at #spec.failOrigin.template#:#spec.failOrigin.line ?: '?'#", "yellow");
						}
					}
				}
			}
			// Recurse into nested suites
			if (structKeyExists(suite, "suiteStats") && isArray(suite.suiteStats)) {
				displayFailures(suite.suiteStats);
			}
		}
	}


	// ── New App Scaffolding ──────────────────────────

	private string function scaffoldNewApp(required string appName, struct options = {}) {
		var targetDir = variables.cwd & "/" & appName;

		if (directoryExists(targetDir)) {
			out("Directory already exists: #appName#", "red");
			return "";
		}

		// Merge defaults for any missing options
		var opts = {
			port: structKeyExists(options, "port") ? options.port : 8080,
			datasource: structKeyExists(options, "datasource") ? options.datasource : lCase(appName),
			reloadPassword: structKeyExists(options, "reloadPassword") ? options.reloadPassword : generateRandomPassword(),
			setupH2: structKeyExists(options, "setupH2") ? options.setupH2 : false,
			noSQLite: structKeyExists(options, "noSQLite") ? options.noSQLite : false,
			openBrowser: structKeyExists(options, "openBrowser") ? options.openBrowser : true
		};

		out("Creating new Wheels application: #appName#...", "cyan");
		out("");

		// Locate the project template directory
		var templateDir = variables.moduleRoot & "templates/app";
		if (!directoryExists(templateDir)) {
			out("Project template not found at: #templateDir#", "red");
			return "";
		}

		// Template variable context — all config values flow through here
		var context = {
			"appName": appName,
			"datasourceName": opts.datasource,
			"reloadPassword": opts.reloadPassword,
			"port": opts.port,
			"shutdownPort": opts.port + 1,
			"openBrowser": opts.openBrowser ? "true" : "false"
		};

		// Copy template directory tree to target, processing placeholders
		copyTemplateDir(templateDir, targetDir, appName, context);

		// Install Wheels framework into vendor/wheels/
		installWheelsFramework(targetDir, appName);

		// Set up embedded database: H2 if explicitly requested, SQLite by default
		if (opts.setupH2) {
			configureH2Database(targetDir, appName, opts.datasource);
		} else if (!opts.noSQLite) {
			configureSQLiteDatabase(targetDir, appName, opts.datasource);
		}

		// Create the default Main controller and index view (not in template
		// because they are app-specific starter content, not framework structure)
		ensureDirectory(targetDir & "/app/views/main");
		var nl = chr(10);
		var tab = chr(9);
		fileWrite(
			targetDir & "/app/controllers/Main.cfc",
			'component extends="Controller" {' & nl & nl & tab & 'function index() {' & nl & tab & tab & '// Default action' & nl & tab & '}' & nl & nl & '}'& nl
		);
		printCreated(appName & "/app/controllers/Main.cfc");

		fileWrite(
			targetDir & "/app/views/main/index.cfm",
			'<h1>Welcome to ' & appName & '</h1>' & nl & '<p>Your Wheels application is running. Edit this file at app/views/main/index.cfm</p>' & nl
		);
		printCreated(appName & "/app/views/main/index.cfm");

		out("");
		out("Application created!", "green");
		out("");
		out("Configuration:", "bold");
		out("  Port:            #opts.port#");
		out("  Datasource:      #opts.datasource#");
		out("  Reload password: #opts.reloadPassword#");
		if (opts.setupH2) {
			out("  Database:        H2 embedded (db/h2/)", "green");
		} else if (!opts.noSQLite) {
			out("  Database:        SQLite (db/development.sqlite)", "green");
		}
		out("");
		out("Next steps:", "bold");
		out("  cd #appName#");
		out("  wheels server start");
		return "";
	}

	/**
	 * Configure H2 embedded database by creating the db directory
	 * and injecting datasource configuration into config/app.cfm.
	 */
	private void function configureH2Database(
		required string targetDir,
		required string appName,
		required string datasourceName
	) {
		var nl = chr(10);
		var tab = chr(9);

		// Create db/h2 directory for H2 data files
		var dbDir = targetDir & "/db/h2";
		ensureDirectory(dbDir);
		printCreated(appName & "/db/h2/");

		// Build H2 datasource configuration for config/app.cfm
		var h2Config = "";
		h2Config &= tab & "// H2 embedded database (configured by wheels new --setup-h2)" & nl;
		h2Config &= tab & 'this.datasources["#datasourceName#"] = {' & nl;
		h2Config &= tab & tab & 'class: "org.h2.Driver",' & nl;
		h2Config &= tab & tab & 'connectionString: "jdbc:h2:file:" & expandPath("../db/h2/#datasourceName#") & ";MODE=MySQL",' & nl;
		h2Config &= tab & tab & 'username: "sa"' & nl;
		h2Config &= tab & "};";

		// Also add a test database datasource
		h2Config &= nl & tab & 'this.datasources["wheelstestdb"] = {' & nl;
		h2Config &= tab & tab & 'class: "org.h2.Driver",' & nl;
		h2Config &= tab & tab & 'connectionString: "jdbc:h2:file:" & expandPath("../db/h2/wheelstestdb") & ";MODE=MySQL",' & nl;
		h2Config &= tab & tab & 'username: "sa"' & nl;
		h2Config &= tab & "};";

		// Inject into config/app.cfm at the CLI-Appends-Here marker
		var appCfmPath = targetDir & "/config/app.cfm";
		if (fileExists(appCfmPath)) {
			var content = fileRead(appCfmPath);
			var marker = tab & "// CLI-Appends-Here";
			if (find(marker, content)) {
				content = replace(content, marker, h2Config & nl & nl & marker, "one");
				fileWrite(appCfmPath, content);
				out("  config  #appName#/config/app.cfm (H2 datasource)", "green");
			}
		}
	}

	/**
	 * Configure SQLite as the zero-config default database by creating the db
	 * directory and injecting datasource configuration into config/app.cfm.
	 * Lucee auto-downloads the SQLite JDBC bundle via the bundleName hint.
	 */
	private void function configureSQLiteDatabase(
		required string targetDir,
		required string appName,
		required string datasourceName
	) {
		var nl = chr(10);
		var tab = chr(9);

		// Create db directory and empty SQLite files
		var dbDir = targetDir & "/db";
		ensureDirectory(dbDir);
		fileWrite(dbDir & "/development.sqlite", "");
		fileWrite(dbDir & "/test.sqlite", "");
		printCreated(appName & "/db/");
		printCreated(appName & "/db/development.sqlite");
		printCreated(appName & "/db/test.sqlite");

		// Build SQLite datasource configuration for config/app.cfm
		var sqliteConfig = "";
		sqliteConfig &= tab & "// SQLite zero-config database (configured by wheels new)" & nl;
		sqliteConfig &= tab & 'this.datasources["#datasourceName#"] = {' & nl;
		sqliteConfig &= tab & tab & 'class: "org.sqlite.JDBC",' & nl;
		sqliteConfig &= tab & tab & 'bundleName: "org.xerial.sqlite-jdbc",' & nl;
		sqliteConfig &= tab & tab & 'connectionString: "jdbc:sqlite:" & expandPath("../db/development.sqlite")' & nl;
		sqliteConfig &= tab & "};";

		// Also add a test database datasource
		sqliteConfig &= nl & tab & 'this.datasources["#datasourceName#_test"] = {' & nl;
		sqliteConfig &= tab & tab & 'class: "org.sqlite.JDBC",' & nl;
		sqliteConfig &= tab & tab & 'bundleName: "org.xerial.sqlite-jdbc",' & nl;
		sqliteConfig &= tab & tab & 'connectionString: "jdbc:sqlite:" & expandPath("../db/test.sqlite")' & nl;
		sqliteConfig &= tab & "};";

		// Inject into config/app.cfm at the CLI-Appends-Here marker
		var appCfmPath = targetDir & "/config/app.cfm";
		if (fileExists(appCfmPath)) {
			var content = fileRead(appCfmPath);
			var marker = tab & "// CLI-Appends-Here";
			if (find(marker, content)) {
				content = replace(content, marker, sqliteConfig & nl & nl & marker, "one");
				fileWrite(appCfmPath, content);
				out("  config  #appName#/config/app.cfm (SQLite datasource)", "green");
			}
		}
	}

	/**
	 * Copy the Wheels framework into the new application's vendor/wheels/ directory.
	 * Resolves the framework source from the current project installation.
	 */
	private void function installWheelsFramework(required string targetDir, required string appName) {
		var wheelsSource = "";

		// Look for vendor/wheels in the resolved project root
		if (len(variables.projectRoot) && directoryExists(variables.projectRoot & "/vendor/wheels")) {
			wheelsSource = variables.projectRoot & "/vendor/wheels";
		}

		if (!len(wheelsSource)) {
			out("  Warning: Could not locate Wheels framework source.", "yellow");
			out("  You will need to install the framework manually into vendor/wheels/");
			out("  See: https://guides.wheels.dev/docs/getting-started");
			return;
		}

		out("Installing Wheels framework...");
		var vendorDir = targetDir & "/vendor/wheels";
		ensureDirectory(vendorDir);
		directoryCopy(wheelsSource, vendorDir, true);
		printCreated(appName & "/vendor/wheels/");
	}

	/**
	 * Recursively copy a template directory to a target, processing {{variable}}
	 * placeholders in file contents and renaming underscore-prefixed dot files
	 * (e.g. _env -> .env, _gitignore -> .gitignore).
	 */
	private void function copyTemplateDir(
		required string sourceDir,
		required string targetDir,
		required string appName,
		required struct context
	) {
		ensureDirectory(arguments.targetDir);

		var entries = directoryList(arguments.sourceDir, false, "query");

		for (var entry in entries) {
			var sourcePath = arguments.sourceDir & "/" & entry.name;
			var targetName = entry.name;

			// Rename _env -> .env, _gitignore -> .gitignore
			if (targetName == "_env") targetName = ".env";
			else if (targetName == "_gitignore") targetName = ".gitignore";

			var targetPath = arguments.targetDir & "/" & targetName;
			var relativePath = arguments.appName & replace(targetPath, arguments.targetDir, "");

			if (entry.type == "Dir") {
				ensureDirectory(targetPath);
				printCreated(relativePath & "/");
				// Recurse into subdirectory
				copyTemplateDir(sourcePath, targetPath, arguments.appName, arguments.context);
			} else {
				// Skip .gitkeep files — they exist only to keep empty dirs in git
				if (entry.name == ".gitkeep") {
					continue;
				}
				// Read template, process placeholders, write to target
				var content = fileRead(sourcePath);
				content = processPlaceholders(content, arguments.context);
				fileWrite(targetPath, content);
				printCreated(relativePath);
			}
		}
	}

	/**
	 * Replace {{key}} placeholders in content with context values.
	 */
	private string function processPlaceholders(required string content, required struct context) {
		var result = arguments.content;
		for (var key in arguments.context) {
			result = replace(result, "{{#key#}}", arguments.context[key], "all");
		}
		return result;
	}

	// ── Inline Template Fallback ─────────────────────

	private string function buildEmptyMigration(required string migrationName) {
		var nl = chr(10);
		var tab = chr(9);
		var content = "component extends=""wheels.migrator.Migration"" {" & nl & nl;
		content &= tab & "function up() {" & nl;
		content &= tab & tab & "transaction {" & nl;
		content &= tab & tab & tab & "// TODO: Implement migration" & nl;
		content &= tab & tab & "}" & nl;
		content &= tab & "}" & nl & nl;

		content &= tab & "function down() {" & nl;
		content &= tab & tab & "transaction {" & nl;
		content &= tab & tab & tab & "// TODO: Implement rollback" & nl;
		content &= tab & tab & "}" & nl;
		content &= tab & "}" & nl & nl;

		content &= "}" & nl;
		return content;
	}

	// ── Utility Methods ──────────────────────────────

	/**
	 * Parse generator arguments into properties and associations
	 * E.g., ["name", "email:string", "--belongsTo=user", "active:boolean"]
	 */
	private struct function parseGeneratorArgs(required array args) {
		var result = {
			properties: [],
			belongsTo: [],
			hasMany: [],
			hasOne: []
		};

		for (var arg in args) {
			// Named association flags
			if (reFindNoCase("^--belongsTo=", arg)) {
				var rels = listToArray(valueAfterEquals(arg));
				result.belongsTo.append(rels, true);
			} else if (reFindNoCase("^--hasMany=", arg)) {
				var rels = listToArray(valueAfterEquals(arg));
				result.hasMany.append(rels, true);
			} else if (reFindNoCase("^--hasOne=", arg)) {
				var rels = listToArray(valueAfterEquals(arg));
				result.hasOne.append(rels, true);
			} else if (!arg.startsWith("--")) {
				// Property: name or name:type
				var parts = listToArray(arg, ":");
				arrayAppend(result.properties, {
					name: parts[1],
					type: arrayLen(parts) > 1 ? parts[2] : "string"
				});
			}
		}

		return result;
	}

	/**
	 * Map user-friendly property types to migration column types
	 */
	private string function mapPropertyType(required string type) {
		switch (lCase(type)) {
			case "string": case "varchar": return "string";
			case "text": case "longtext": return "text";
			case "integer": case "int": return "integer";
			case "biginteger": case "bigint": return "bigInteger";
			case "boolean": case "bool": return "boolean";
			case "date": return "date";
			case "datetime": case "timestamp": return "datetime";
			case "time": return "time";
			case "decimal": case "float": case "numeric": return "decimal";
			case "binary": return "binary";
			default: return "string";
		}
	}

	/**
	 * Resolve the Wheels project root from the current working directory.
	 * Walks up from cwd looking for vendor/wheels/ as the marker.
	 */
	private string function resolveProjectRoot(required string cwd) {
		var dir = len(trim(cwd)) ? cwd : ".";
		var File = createObject("java", "java.io.File");

		// Walk up at most 5 levels
		for (var i = 0; i < 5; i++) {
			var candidate = File.init(dir).getCanonicalPath();
			if (directoryExists(candidate & "/vendor/wheels")) {
				return candidate;
			}
			// Go up one level
			var parent = File.init(candidate).getParent();
			if (isNull(parent) || parent == candidate) break;
			dir = parent;
		}

		// Fallback: use cwd as-is
		return len(trim(cwd)) ? File.init(cwd).getCanonicalPath() : File.init(".").getCanonicalPath();
	}

	/**
	 * Detect the port of a running Wheels dev server.
	 * Checks lucee.json, .env, and common default ports.
	 */
	private any function detectServerPort() {
		// 1. Check lucee.json
		var luceeJson = variables.projectRoot & "/lucee.json";
		if (fileExists(luceeJson)) {
			try {
				var config = deserializeJSON(fileRead(luceeJson));
				if (structKeyExists(config, "port") && isPortOpen(config.port)) {
					return config.port;
				}
			} catch (any e) {
				// ignore parse errors
			}
		}

		// 2. Check .env for PORT
		var envFile = variables.projectRoot & "/.env";
		if (fileExists(envFile)) {
			var envContent = fileRead(envFile);
			var portMatch = reFindNoCase("PORT\s*=\s*(\d+)", envContent, 1, true);
			if (arrayLen(portMatch.match) > 1 && isNumeric(portMatch.match[2])) {
				var port = val(portMatch.match[2]);
				if (isPortOpen(port)) return port;
			}
		}

		// 3. Try common ports
		var commonPorts = [8080, 60000, 3000, 8500];
		for (var port in commonPorts) {
			if (isPortOpen(port)) return port;
		}

		return false;
	}

	/**
	 * Detect the reload password from .env or config/settings.cfm
	 */
	private string function detectReloadPassword() {
		// 1. Check .env for RELOAD_PASSWORD
		var envFile = variables.projectRoot & "/.env";
		if (fileExists(envFile)) {
			var envContent = fileRead(envFile);
			var pwMatch = reFindNoCase("RELOAD_PASSWORD\s*=\s*(.+)", envContent, 1, true);
			if (arrayLen(pwMatch.match) > 1 && len(trim(pwMatch.match[2]))) {
				return trim(pwMatch.match[2]);
			}
		}

		// 2. Check config/settings.cfm
		var settingsFile = variables.projectRoot & "/config/settings.cfm";
		if (fileExists(settingsFile)) {
			var settingsContent = fileRead(settingsFile);
			var settingsMatch = reFindNoCase('reloadPassword\s*[=,]\s*"([^"]*)"', settingsContent, 1, true);
			if (arrayLen(settingsMatch.match) > 1) {
				return settingsMatch.match[2];
			}
		}

		return "";
	}

	/**
	 * Check if a port is responding to HTTP requests
	 */
	private boolean function isPortOpen(required numeric port) {
		try {
			var socket = createObject("java", "java.net.Socket");
			socket.init();
			var address = createObject("java", "java.net.InetSocketAddress").init("localhost", javacast("int", port));
			socket.connect(address, javacast("int", 1000));
			socket.close();
			return true;
		} catch (any e) {
			return false;
		}
	}

	/**
	 * Make an HTTP GET request and return the response body
	 */
	private string function makeHttpRequest(required string requestUrl) {
		var javaUrl = createObject("java", "java.net.URL").init(arguments.requestUrl);
		var conn = javaUrl.openConnection();
		conn.setRequestMethod("GET");
		conn.setConnectTimeout(5000);
		conn.setReadTimeout(120000);

		var responseCode = conn.getResponseCode();
		var inputStream = responseCode >= 400 ? conn.getErrorStream() : conn.getInputStream();
		var scanner = createObject("java", "java.util.Scanner").init(inputStream, "UTF-8");
		var response = "";
		while (scanner.hasNextLine()) {
			response &= scanner.nextLine() & chr(10);
		}
		scanner.close();
		return trim(response);
	}

	/**
	 * Make an HTTP POST request with a JSON body and return the response
	 */
	private string function makeHttpPost(required string requestUrl, required string body) {
		var javaUrl = createObject("java", "java.net.URL").init(arguments.requestUrl);
		var conn = javaUrl.openConnection();
		conn.setRequestMethod("POST");
		conn.setConnectTimeout(5000);
		conn.setReadTimeout(30000);
		conn.setDoOutput(true);
		conn.setRequestProperty("Content-Type", "application/json");

		// Write request body
		var writer = createObject("java", "java.io.OutputStreamWriter").init(conn.getOutputStream(), "UTF-8");
		writer.write(body);
		writer.flush();
		writer.close();

		// Read response (handle both success and error streams)
		var responseCode = conn.getResponseCode();
		var inputStream = responseCode >= 400 ? conn.getErrorStream() : conn.getInputStream();
		var scanner = createObject("java", "java.util.Scanner").init(inputStream, "UTF-8");
		var response = "";
		while (scanner.hasNextLine()) {
			response &= scanner.nextLine() & chr(10);
		}
		scanner.close();
		return trim(response);
	}

	/**
	 * Get or create a service instance (lazy-loaded with constructor wiring)
	 */
	private any function getService(required string name) {
		if (!structKeyExists(variables.services, name)) {
			switch (name) {
				case "helpers":
					variables.services.helpers = new services.Helpers();
					break;
				case "templates":
					variables.services.templates = new services.Templates(
						helpers = getService("helpers"),
						projectRoot = variables.projectRoot,
						moduleRoot = variables.moduleRoot
					);
					break;
				case "codegen":
					variables.services.codegen = new services.CodeGen(
						templateService = getService("templates"),
						helpers = getService("helpers"),
						projectRoot = variables.projectRoot
					);
					break;
				case "scaffold":
					variables.services.scaffold = new services.Scaffold(
						codeGenService = getService("codegen"),
						helpers = getService("helpers"),
						projectRoot = variables.projectRoot
					);
					break;
				case "analysis":
					variables.services.analysis = new services.Analysis(
						helpers = getService("helpers"),
						projectRoot = variables.projectRoot
					);
					break;
				case "destroy":
					variables.services.destroy = new services.Destroy(
						helpers = getService("helpers"),
						projectRoot = variables.projectRoot,
						moduleRoot = variables.moduleRoot
					);
					break;
				case "doctor":
					variables.services.doctor = new services.Doctor(
						projectRoot = variables.projectRoot
					);
					break;
				case "stats":
					variables.services.stats = new services.Stats(
						helpers = getService("helpers"),
						projectRoot = variables.projectRoot
					);
					break;
				case "admin":
					variables.services.admin = new services.Admin(
						helpers = getService("helpers"),
						projectRoot = variables.projectRoot,
						moduleRoot = variables.moduleRoot
					);
					break;
				default:
					throw("Unknown service: #name#");
			}
		}
		return variables.services[name];
	}

	/**
	 * Ensure a directory exists, creating it if necessary
	 */
	private void function ensureDirectory(required string path) {
		if (!directoryExists(path)) {
			directoryCreate(path, true);
		}
	}

	/**
	 * Capitalize the first letter of a string
	 */
	private string function capitalize(required string str) {
		return uCase(left(str, 1)) & mid(str, 2, len(str) - 1);
	}

	/**
	 * Print a "create" action line with green formatting
	 */
	private void function printCreated(required string path) {
		out("  create  #path#", "green");
	}

	/**
	 * Extract the value after the first '=' in a --key=value argument.
	 * Unlike listRest(arg, "="), this preserves '=' characters in the value.
	 */
	private string function valueAfterEquals(required string arg) {
		var pos = find("=", arg);
		if (pos == 0) return "";
		return mid(arg, pos + 1, len(arg));
	}

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

	/**
	 * Generate a random alphanumeric password for reload protection.
	 */
	private string function generateRandomPassword(numeric length = 16) {
		var chars = "abcdefghijklmnopqrstuvwxyz0123456789";
		var result = "";
		for (var i = 1; i <= arguments.length; i++) {
			result &= mid(chars, randRange(1, len(chars)), 1);
		}
		return result;
	}

}
