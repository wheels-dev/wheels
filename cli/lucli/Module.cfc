/**
 * Wheels CLI Module for LuCLI
 *
 * Provides code generation, migrations, testing, and server management
 * for CFWheels applications. Each public function is a subcommand:
 *
 *   wheels generate model User name email
 *   wheels migrate latest
 *   wheels test --filter=models
 *   wheels start
 *
 * hint: CFWheels framework CLI - generate, migrate, test, and manage your app
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
	 * hint: Generate Wheels components (model, controller, view, migration, scaffold, route, test, property)
	 */
	public string function generate() {
		var args = __arguments ?: [];

		if (!arrayLen(args)) {
			out("Usage: wheels generate <type> <name> [attributes...]", "yellow");
			out("");
			out("Types:", "bold");
			out("  model       Generate a model CFC");
			out("  controller  Generate a controller CFC");
			out("  view        Generate a view template");
			out("  migration   Generate a database migration");
			out("  scaffold    Generate model + controller + views + migration + tests + routes");
			out("  route       Add a resource route to config/routes.cfm");
			out("  test        Generate a test spec file");
			out("  property    Generate an add-column migration for a model property");
			out("");
			out("Examples:", "bold");
			out("  wheels generate model User name email:string active:boolean");
			out("  wheels generate controller Users index show create");
			out("  wheels generate migration CreateUsers");
			out("  wheels generate scaffold Post title body:text publishedAt:datetime");
			out("  wheels generate route posts");
			out("  wheels generate test model User");
			out("  wheels generate property User email:string");
			return "";
		}

		var type = args[1];
		var remaining = args.len() > 1 ? args.slice(2) : [];

		switch (lCase(type)) {
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
			case "route":
			case "r":
				return generateRoute(remaining);
			case "test":
				return generateTest(remaining);
			case "property":
			case "prop":
				return generateProperty(remaining);
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
			} else if (arg == "--verbose" || arg == "-v") {
				verboseOutput = true;
			} else if (!arg.startsWith("--")) {
				// Positional arg is the filter directory
				filter = arg;
			}
		}

		return runTests(filter, reporter, format, verboseOutput);
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
			out("Usage: wheels new <appname>", "yellow");
			out("");
			out("Creates a new Wheels application in the specified directory.");
			out("");
			out("Example:", "bold");
			out("  wheels new myapp");
			return "";
		}

		var appName = args[1];
		return scaffoldNewApp(appName);
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

	// ── Migration Execution ──────────────────────────

	private string function runMigration(required string action) {
		var serverPort = detectServerPort();
		if (!serverPort) {
			out("No running Wheels server detected.", "red");
			out("Migrations require a running server. Start with: wheels start");
			return "";
		}

		out("Running migration: #action#...", "cyan");

		try {
			var migrateUrl = "http://localhost:#serverPort#/wheels/app/tests?type=app&reload=true";

			switch (action) {
				case "latest":
					migrateUrl = "http://localhost:#serverPort#/?controller=wheels&action=wheels&view=migrate&type=migrateToLatest&reload=true&password=";
					break;
				case "up":
					migrateUrl = "http://localhost:#serverPort#/?controller=wheels&action=wheels&view=migrate&type=migrateUp&reload=true&password=";
					break;
				case "down":
					migrateUrl = "http://localhost:#serverPort#/?controller=wheels&action=wheels&view=migrate&type=migrateDown&reload=true&password=";
					break;
				case "info":
					migrateUrl = "http://localhost:#serverPort#/?controller=wheels&action=wheels&view=migrate&type=info&reload=true&password=";
					break;
			}

			var httpResult = makeHttpRequest(migrateUrl);
			out("Migration #action# completed.", "green");
			verbose(httpResult);
		} catch (any e) {
			out("Migration failed: #e.message#", "red");
		}

		return "";
	}

	// ── Test Execution ───────────────────────────────

	private string function runTests(
		string filter = "",
		string reporter = "simple",
		string format = "json",
		boolean verboseOutput = false
	) {
		var serverPort = detectServerPort();
		if (!serverPort) {
			out("No running Wheels server detected.", "red");
			out("Tests require a running server. Start with: wheels start");
			return "";
		}

		out("Running tests...", "cyan");

		try {
			var testUrl = "http://localhost:#serverPort#/wheels/app/tests?format=#format#";
			if (len(filter)) {
				testUrl &= "&directory=#filter#";
			}
			testUrl &= "&reload=true";

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

	private string function scaffoldNewApp(required string appName) {
		var targetDir = variables.cwd & "/" & appName;

		if (directoryExists(targetDir)) {
			out("Directory already exists: #appName#", "red");
			return "";
		}

		out("Creating new Wheels application: #appName#...", "cyan");
		out("");

		// Create directory structure
		var dirs = [
			"app/controllers",
			"app/models",
			"app/views/layout",
			"app/views/main",
			"app/migrator/migrations",
			"app/events",
			"app/global",
			"app/lib",
			"config",
			"public",
			"tests/specs/models",
			"tests/specs/controllers",
			"tests/specs/functional",
			"vendor"
		];

		for (var dir in dirs) {
			ensureDirectory(targetDir & "/" & dir);
			printCreated(appName & "/" & dir & "/");
		}

		// Create index.cfm (front controller)
		fileWrite(
			targetDir & "/public/index.cfm",
			'<cfinclude template="../vendor/wheels/public/root.cfm">'
		);
		printCreated(appName & "/public/index.cfm");

		// Create Application.cfc
		fileWrite(
			targetDir & "/config/app.cfm",
			'<cfset set(dataSourceName="#lCase(appName)#")>#chr(10)#<cfset set(reloadPassword="")>'
		);
		printCreated(appName & "/config/app.cfm");

		// Create routes.cfm
		fileWrite(
			targetDir & "/config/routes.cfm",
			'<cfscript>#chr(10)#mapper()#chr(10)##chr(9)#.root(to="main##index")#chr(10)##chr(9)#.wildcard()#chr(10)#.end();#chr(10)#</cfscript>'
		);
		printCreated(appName & "/config/routes.cfm");

		// Create lucee.json
		var luceeConfig = {
			"name": appName,
			"version": "7.0.2.101",
			"port": 8080,
			"shutdownPort": 8081,
			"webroot": "./public",
			"openBrowser": true,
			"jvm": {"maxMemory": "512m", "minMemory": "128m"},
			"urlRewrite": {"enabled": true, "routerFile": "index.cfm"},
			"admin": {"enabled": true},
			"enableLucee": true,
			"monitoring": {"enabled": false},
			"configuration": {
				"datasources": {},
				"mappings": {
					"/wheels": "../vendor/wheels",
					"/app": "../app",
					"/config": "../config",
					"/tests": "../tests"
				}
			}
		};
		fileWrite(targetDir & "/lucee.json", serializeJSON(var = luceeConfig, compact = false));
		printCreated(appName & "/lucee.json");

		// Create main controller
		fileWrite(
			targetDir & "/app/controllers/Main.cfc",
			'component extends="Controller" {#chr(10)##chr(10)##chr(9)#function index() {#chr(10)##chr(9)##chr(9)#// Default action#chr(10)##chr(9)#}#chr(10)##chr(10)#}'
		);
		printCreated(appName & "/app/controllers/Main.cfc");

		// Create main index view
		fileWrite(
			targetDir & "/app/views/main/index.cfm",
			'<h1>Welcome to #appName#</h1>#chr(10)#<p>Your Wheels application is running. Edit this file at app/views/main/index.cfm</p>'
		);
		printCreated(appName & "/app/views/main/index.cfm");

		out("");
		out("Application created!", "green");
		out("");
		out("Next steps:", "bold");
		out("  cd #appName#");
		out("  wheels start");
		return "";
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
	private string function makeHttpRequest(required string url) {
		var URL = createObject("java", "java.net.URL").init(url);
		var conn = URL.openConnection();
		conn.setRequestMethod("GET");
		conn.setConnectTimeout(5000);
		conn.setReadTimeout(10000);

		var scanner = createObject("java", "java.util.Scanner").init(conn.getInputStream(), "UTF-8");
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

}
