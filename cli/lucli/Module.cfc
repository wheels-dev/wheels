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

		// Lazy-init service instances
		variables.services = {};

		return this;
	}

	// ─────────────────────────────────────────────────
	//  generate — Code generation (model, controller, view, migration, scaffold)
	// ─────────────────────────────────────────────────

	/**
	 * Generate code: model, controller, view, migration, or scaffold
	 *
	 * hint: Generate models, controllers, views, migrations, or scaffolds
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
			out("  scaffold    Generate model + controller + views + migration");
			out("");
			out("Examples:", "bold");
			out("  wheels generate model User name email:string active:boolean");
			out("  wheels generate controller Users index show create");
			out("  wheels generate migration CreateUsers");
			out("  wheels generate scaffold Post title body:text publishedAt:datetime");
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
	 * Run database migrations
	 *
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
	 * Run the test suite
	 *
	 * hint: Run tests with optional filter and reporter
	 */
	public string function test() {
		var args = __arguments ?: [];
		var filter = "";
		var reporter = "simple";
		var format = "json";

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
			} else if (!arg.startsWith("--")) {
				// Positional arg is the filter directory
				filter = arg;
			}
		}

		return runTests(filter, reporter, format);
	}

	// ─────────────────────────────────────────────────
	//  reload — Reload application
	// ─────────────────────────────────────────────────

	/**
	 * Reload the Wheels application
	 *
	 * hint: Reload the running Wheels application
	 */
	public string function reload() {
		var serverPort = detectServerPort();
		if (!serverPort) {
			out("No running Wheels server detected. Start one with: wheels start", "red");
			return "";
		}

		try {
			var reloadUrl = "http://localhost:#serverPort#/?reload=true&password=";
			var httpResult = makeHttpRequest(reloadUrl);
			out("Application reloaded successfully.", "green");
		} catch (any e) {
			out("Failed to reload: #e.message#", "red");
			verbose("URL: #reloadUrl#");
		}
		return "";
	}

	// ─────────────────────────────────────────────────
	//  start / stop — Dev server management
	// ─────────────────────────────────────────────────

	/**
	 * Start the development server
	 *
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
	 * Stop the development server
	 *
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
	 * Create a new Wheels application
	 *
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
	 * Display application routes
	 *
	 * hint: List all configured routes
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
	 * Display Wheels environment information
	 *
	 * hint: Show framework version, environment, and configuration
	 */
	public string function info() {
		out("Wheels CLI v#version()#", "bold");

		if (len(variables.projectRoot) && directoryExists(variables.projectRoot & "/vendor/wheels")) {
			out("Project: #variables.projectRoot#");

			// Try to detect environment from config
			var envFile = variables.projectRoot & "/.env";
			if (fileExists(envFile)) {
				out("Environment file: .env found", "green");
			}

			var luceeJson = variables.projectRoot & "/lucee.json";
			if (fileExists(luceeJson)) {
				out("Server config: lucee.json found", "green");
			}

			var serverPort = detectServerPort();
			if (serverPort) {
				out("Server: running on port #serverPort#", "green");
			} else {
				out("Server: not running", "yellow");
			}
		} else {
			out("Not in a Wheels project directory.", "yellow");
		}
		return "";
	}

	// ─────────────────────────────────────────────────
	//  mcp — Start MCP server over stdio
	// ─────────────────────────────────────────────────

	/**
	 * Start MCP server for AI editor integration
	 *
	 * hint: Start Model Context Protocol server over stdio
	 */
	public string function mcp() {
		var args = __arguments ?: [];

		// Placeholder for Phase 2 MCP implementation
		out("MCP server support coming in Wheels 3.1.1", "yellow");
		out("");
		out("For now, use the HTTP MCP endpoint:");
		out("  Start server: wheels start");
		out("  MCP endpoint: http://localhost:<port>/wheels/mcp");
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
		var filePath = variables.projectRoot & "/app/models/#modelName#.cfc";

		if (fileExists(filePath)) {
			out("Model already exists: app/models/#modelName#.cfc", "red");
			out("Use --force to overwrite.");
			return "";
		}

		// Parse properties and associations from args
		var parsed = parseGeneratorArgs(properties);

		// Build model content from template
		var content = buildModelContent(modelName, parsed);

		// Ensure directory exists
		ensureDirectory(getDirectoryFromPath(filePath));
		fileWrite(filePath, content);

		printCreated("app/models/#modelName#.cfc");

		// Also generate migration if properties provided
		if (arrayLen(parsed.properties)) {
			var migrationName = "Create#getService('helpers').pluralize(modelName)#";
			var migrationContent = buildCreateTableMigration(
				getService("helpers").pluralize(lCase(modelName)),
				parsed.properties
			);
			var timestamp = dateFormat(now(), "yyyymmdd") & timeFormat(now(), "HHmmss");
			var migrationFile = variables.projectRoot & "/app/migrator/migrations/#timestamp#_#migrationName#.cfc";
			ensureDirectory(getDirectoryFromPath(migrationFile));
			fileWrite(migrationFile, migrationContent);
			printCreated("app/migrator/migrations/#timestamp#_#migrationName#.cfc");
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
		var filePath = variables.projectRoot & "/app/controllers/#controllerName#.cfc";

		if (fileExists(filePath)) {
			out("Controller already exists: app/controllers/#controllerName#.cfc", "red");
			return "";
		}

		var content = buildControllerContent(controllerName, actions);

		ensureDirectory(getDirectoryFromPath(filePath));
		fileWrite(filePath, content);

		printCreated("app/controllers/#controllerName#.cfc");

		// Create view directory
		var viewDir = variables.projectRoot & "/app/views/#lCase(controllerName)#";
		ensureDirectory(viewDir);

		// Create view files for each action
		for (var action in actions) {
			if (!listFindNoCase("create,update,delete,destroy", action)) {
				var viewPath = viewDir & "/#lCase(action)#.cfm";
				fileWrite(viewPath, '<cfparam name="params" default="">#chr(10)##chr(10)#<h1>#controllerName# - #capitalize(action)#</h1>');
				printCreated("app/views/#lCase(controllerName)#/#lCase(action)#.cfm");
			}
		}

		return "";
	}

	private string function generateView(required array args) {
		if (arrayLen(args) < 2) {
			out("Usage: wheels generate view <controller> <action>", "yellow");
			return "";
		}

		var controllerName = lCase(args[1]);
		var actionName = lCase(args[2]);
		var viewDir = variables.projectRoot & "/app/views/#controllerName#";
		var filePath = viewDir & "/#actionName#.cfm";

		if (fileExists(filePath)) {
			out("View already exists: app/views/#controllerName#/#actionName#.cfm", "red");
			return "";
		}

		ensureDirectory(viewDir);
		fileWrite(filePath, '<cfparam name="params" default="">#chr(10)##chr(10)#<h1>#capitalize(controllerName)# - #capitalize(actionName)#</h1>');
		printCreated("app/views/#controllerName#/#actionName#.cfm");
		return "";
	}

	private string function generateMigration(required array args) {
		if (!arrayLen(args)) {
			out("Usage: wheels generate migration <Name>", "yellow");
			out("  Example: wheels generate migration AddEmailToUsers");
			return "";
		}

		var migrationName = args[1];
		var timestamp = dateFormat(now(), "yyyymmdd") & timeFormat(now(), "HHmmss");
		var fileName = "#timestamp#_#migrationName#.cfc";
		var migrationDir = variables.projectRoot & "/app/migrator/migrations";
		var filePath = migrationDir & "/#fileName#";

		ensureDirectory(migrationDir);

		var content = buildEmptyMigration(migrationName);
		fileWrite(filePath, content);
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

		// Generate model
		generateModel(args);

		// Generate controller with CRUD actions
		generateController([controllerName, "index", "show", "new", "create", "edit", "update", "delete"]);

		out("");
		out("Scaffold complete! Next steps:", "green");
		out("  1. Run migrations: wheels migrate latest");
		out("  2. Add route to config/routes.cfm:");
		out('     .resources("#lCase(controllerName)#")');
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
		string format = "json"
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
				displayTestResults(result);
			} else {
				out(httpResult);
			}
		} catch (any e) {
			out("Test execution failed: #e.message#", "red");
		}

		return "";
	}

	private void function displayTestResults(required any result) {
		if (isStruct(result)) {
			var passed = result.totalPassed ?: 0;
			var failed = result.totalFailed ?: 0;
			var errors = result.totalErrors ?: 0;
			var total = passed + failed + errors;

			if (failed == 0 && errors == 0) {
				out("#total# tests passed", "green");
			} else {
				out("#total# tests: #passed# passed, #failed# failed, #errors# errors", "red");

				// Show failure details
				if (structKeyExists(result, "failures") && isArray(result.failures)) {
					for (var failure in result.failures) {
						out("  FAIL: #failure.name ?: 'unknown'#", "red");
						if (structKeyExists(failure, "message")) {
							out("    #failure.message#", "yellow");
						}
					}
				}
			}
		} else {
			out(serializeJSON(result));
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

	// ── Template Builders ────────────────────────────

	private string function buildModelContent(required string modelName, required struct parsed) {
		var nl = chr(10);
		var tab = chr(9);
		var content = "component extends=""Model"" {" & nl & nl;
		content &= tab & "function config() {" & nl;

		// belongsTo
		for (var rel in parsed.belongsTo) {
			content &= tab & tab & "belongsTo('#rel#');" & nl;
		}

		// hasMany
		for (var rel in parsed.hasMany) {
			content &= tab & tab & "hasMany('#rel#');" & nl;
		}

		// hasOne
		for (var rel in parsed.hasOne) {
			content &= tab & tab & "hasOne('#rel#');" & nl;
		}

		// Validations for required properties
		var requiredProps = [];
		for (var prop in parsed.properties) {
			arrayAppend(requiredProps, prop.name);
		}
		if (arrayLen(requiredProps)) {
			content &= tab & tab & "validatesPresenceOf(""#arrayToList(requiredProps)#"");" & nl;
		}

		content &= tab & "}" & nl & nl;
		content &= "}" & nl;
		return content;
	}

	private string function buildControllerContent(required string controllerName, required array actions) {
		var nl = chr(10);
		var tab = chr(9);
		var content = "component extends=""Controller"" {" & nl & nl;
		content &= tab & "function config() {" & nl;
		content &= tab & tab & "// Controller configuration" & nl;
		content &= tab & "}" & nl;

		for (var action in actions) {
			content &= nl;
			content &= tab & "function #action#() {" & nl;
			content &= tab & tab & "// TODO: Implement #action#" & nl;
			content &= tab & "}" & nl;
		}

		content &= nl & "}" & nl;
		return content;
	}

	private string function buildCreateTableMigration(required string tableName, required array properties) {
		var nl = chr(10);
		var tab = chr(9);
		var content = "component extends=""wheels.migrator.Migration"" {" & nl & nl;
		content &= tab & "function up() {" & nl;
		content &= tab & tab & "transaction {" & nl;
		content &= tab & tab & tab & 't = createTable(name="#tableName#");' & nl;

		for (var prop in properties) {
			var colType = mapPropertyType(prop.type ?: "string");
			content &= tab & tab & tab & 't.#colType#(columnNames="#prop.name#");' & nl;
		}

		content &= tab & tab & tab & "t.timestamps();" & nl;
		content &= tab & tab & tab & "t.create();" & nl;
		content &= tab & tab & "}" & nl;
		content &= tab & "}" & nl & nl;

		content &= tab & "function down() {" & nl;
		content &= tab & tab & "transaction {" & nl;
		content &= tab & tab & tab & 'dropTable(name="#tableName#");' & nl;
		content &= tab & tab & "}" & nl;
		content &= tab & "}" & nl & nl;

		content &= "}" & nl;
		return content;
	}

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
			case "string":
			case "varchar":
				return "string";
			case "text":
			case "longtext":
				return "text";
			case "integer":
			case "int":
				return "integer";
			case "biginteger":
			case "bigint":
				return "bigInteger";
			case "boolean":
			case "bool":
				return "boolean";
			case "date":
				return "date";
			case "datetime":
			case "timestamp":
				return "datetime";
			case "time":
				return "time";
			case "decimal":
			case "float":
			case "numeric":
				return "decimal";
			case "binary":
				return "binary";
			default:
				return "string";
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
	 * Get or create a service instance
	 */
	private any function getService(required string name) {
		if (!structKeyExists(variables.services, name)) {
			switch (name) {
				case "helpers":
					variables.services.helpers = new services.Helpers();
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
