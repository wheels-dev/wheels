<cfscript>
// AI Documentation System - Optimized for LLM consumption
param name="request.wheels.params.context" default="all";
param name="request.wheels.params.format" default="json";
param name="request.wheels.params.version" default="current";
param name="request.wheels.params.mode" default="docs";
param name="request.wheels.params.id" default="";

try {
	// Always return JSON for AI endpoints
	cfcontent(type="application/json", reset=true);
	// Route to appropriate handler based on mode
	switch(request.wheels.params.mode) {
		case "manifest":
			handleManifest();
			abort;
			break;
		case "project":
			handleProjectContext();
			abort;
			break;
		case "chunk":
			handleChunk();
			abort;
			break;
		case "info":
			handleInfo();
			abort;
			break;
		case "routes":
			handleRoutes();
			abort;
			break;
		case "migrations":
			handleMigrations();
			abort;
			break;
		case "plugins":
			handlePlugins();
			abort;
			break;
		default:
			// Continue with main documentation
			break;
	}
} catch (any e) {
	writeOutput(serializeJSON({
		"error": true,
		"message": e.message,
		"detail": e.detail
	}));
	abort;
}

// Initialize response structure for main docs
local.aiDocs = {
	"version": application.wheels.version,
	"timestamp": now(),
	"context": request.wheels.params.context,
	"documentation": {}
};

// Helper function to get condensed API documentation
function getCondensedAPIDocs(context) {
	local.result = {};

	// Get full API docs (reuse existing logic)
	if (StructKeyExists(application.wheels, "docs")) {
		local.fullDocs = application.wheels.docs;
	} else {
		// Include the core documentation logic
		include "/wheels/public/docs/core.cfm";
		local.fullDocs = docs;
	}

	// Filter based on context
	switch(arguments.context) {
		case "model":
			local.result = filterDocsForContext(local.fullDocs, ["Model Class", "Model Configuration", "Model Object"]);
			break;
		case "controller":
			local.result = filterDocsForContext(local.fullDocs, ["Controller"]);
			break;
		case "view":
			local.result = filterDocsForContext(local.fullDocs, ["View Helpers"]);
			break;
		case "migration":
			local.result = filterDocsForContext(local.fullDocs, ["Migrator", "Migration Functions"]);
			break;
		case "routing":
			local.result = filterDocsForContext(local.fullDocs, ["Configuration", "Routing"]);
			break;
		case "testing":
			local.result = filterDocsForContext(local.fullDocs, ["Test Model", "Testing Functions"]);
			break;
		default:
			// Return essential functions for all contexts
			local.result = getEssentialFunctions(local.fullDocs);
	}

	return local.result;
}

// Filter documentation by section
function filterDocsForContext(docs, sections) {
	local.filtered = {
		"sections": [],
		"functions": []
	};

	// Filter sections
	for (local.section in docs.sections) {
		for (local.targetSection in arguments.sections) {
			if (local.section.name == local.targetSection) {
				arrayAppend(local.filtered.sections, local.section);
				break;
			}
		}
	}

	// Filter functions
	for (local.func in docs.functions) {
		if (structKeyExists(local.func, "tags") && structKeyExists(local.func.tags, "section")) {
			for (local.targetSection in arguments.sections) {
				if (local.func.tags.section == local.targetSection) {
					arrayAppend(local.filtered.functions, simplifyFunction(local.func));
					break;
				}
			}
		}
	}

	return local.filtered;
}

// Get essential functions across all contexts
function getEssentialFunctions(docs) {
	local.essentials = {
		"sections": docs.sections,
		"functions": [],
		"commonPatterns": getCommonPatterns(),
		"quickReference": getQuickReference()
	};

	// List of essential function names
	local.essentialNames = [
		// Model essentials
		"findAll", "findOne", "findByKey", "new", "create", "update", "updateAll", "delete", "deleteAll", "save",
		"valid", "errors", "hasMany", "belongsTo", "hasOne", "validatesPresenceOf", "validatesUniquenessOf",
		"validatesFormatOf", "nestedProperties", "findFirst", "reload",

		// Controller essentials
		"renderView", "renderWith", "redirectTo", "params", "filters", "provides", "protectsFromForgery",
		"sendEmail", "sendFile", "isSecure", "authenticityToken",

		// View essentials
		"linkTo", "buttonTo", "startFormTag", "endFormTag", "textField", "submitTag", "selectTag",
		"styleSheetLinkTag", "javaScriptIncludeTag", "imageTag",

		// Migration essentials
		"createTable", "changeTable", "addColumn", "removeColumn", "addIndex", "removeIndex",
		"createView", "renameTable",

		// Routing essentials
		"mapper", "resources", "resource", "get", "post", "put", "patch", "delete", "root", "wildcard"
	];

	for (local.func in docs.functions) {
		if (arrayFind(local.essentialNames, local.func.name)) {
			arrayAppend(local.essentials.functions, simplifyFunction(local.func));
		}
	}

	return local.essentials;
}

// Simplify function documentation for AI consumption
function simplifyFunction(func) {
	local.simplified = {
		"name": func.name,
		"hint": func.hint,
		"returntype": func.returntype,
		"category": structKeyExists(func.tags, "category") ? func.tags.category : "",
		"section": structKeyExists(func.tags, "section") ? func.tags.section : "",
		"params": []
	};

	// Simplify parameters
	if (structKeyExists(func, "parameters")) {
		for (local.param in func.parameters) {
			arrayAppend(local.simplified.params, {
				"name": param.name,
				"type": param.type,
				"required": param.required,
				"hint": structKeyExists(param, "hint") ? param.hint : "",
				"default": structKeyExists(param, "default") ? param.default : ""
			});
		}
	}

	return local.simplified;
}

// Get common Wheels patterns
function getCommonPatterns() {
	return {
		"modelPatterns": [
			{
				"name": "Basic Model with Validations",
				"code": "component extends='Model' {\n  function config() {\n    validatesPresenceOf('name,email');\n    validatesUniquenessOf('email');\n    validatesFormatOf(property='email', regEx='^[\\w\\.-]+@[\\w\\.-]+\\.\\w+$');\n  }\n}"
			},
			{
				"name": "Model with Associations",
				"code": "component extends='Model' {\n  function config() {\n    hasMany('orders');\n    belongsTo('role');\n  }\n}"
			},
			{
				"name": "Model with Nested Properties",
				"code": "component extends='Model' {\n  function config() {\n    hasMany('addresses');\n    nestedProperties(association='addresses', allowDelete=true, autoSave=true);\n  }\n}"
			}
		],
		"controllerPatterns": [
			{
				"name": "RESTful Controller",
				"code": "component extends='Controller' {\n  function config() {\n    filters(through='authenticate', except='index,show');\n    provides('html,json');\n  }\n  \n  function index() {\n    users = model('User').findAll();\n  }\n  \n  function create() {\n    user = model('User').create(params.user);\n    if (user.hasErrors()) {\n      renderView(action='new');\n    } else {\n      redirectTo(route='user', key=user.id);\n    }\n  }\n}"
			},
			{
				"name": "Controller with Email",
				"code": "component extends='Controller' {\n  function sendWelcomeEmail() {\n    sendEmail(\n      template='users/welcome',\n      from='noreply@myapp.com',\n      to=user.email,\n      subject='Welcome!',\n      user=user\n    );\n  }\n}"
			},
			{
				"name": "Controller with File Download",
				"code": "component extends='Controller' {\n  function downloadReport() {\n    sendFile(\n      file='report.pdf',\n      name='Monthly Report.pdf',\n      type='application/pdf',\n      disposition='attachment',\n      directory='/reports/'\n    );\n  }\n}"
			},
			{
				"name": "Controller with HTTPS Check",
				"code": "component extends='Controller' {\n  function config() {\n    filters(through='requireSSL');\n  }\n  \n  function requireSSL() {\n    if (!isSecure()) {\n      redirectTo(protocol='https');\n    }\n  }\n}"
			}
		],
		"viewPatterns": [
			{
				"name": "Form with CSRF Protection",
				"code": "##startFormTag(route='user', method='post')##\n  ##hiddenFieldTag('authenticityToken', authenticityToken())##\n  ##textField(objectName='user', property='name')##\n  ##textField(objectName='user', property='email')##\n  ##submitTag('Save')##\n##endFormTag()##"
			}
		],
		"migrationPatterns": [
			{
				"name": "Create Table Migration",
				"code": "component extends='wheels.migrator.Migration' {\n  function up() {\n    t = createTable('users');\n    t.string('firstName,lastName', allowNull=false);\n    t.string('email', limit=100, allowNull=false);\n    t.boolean('active', default=true);\n    t.timestamps();\n    t.create();\n    \n    addIndex(table='users', columnNames='email', unique=true);\n  }\n  \n  function down() {\n    dropTable('users');\n  }\n}"
			}
		]
	};
}

// Get quick reference guide
function getQuickReference() {
	return {
		"cli": {
			"generate": [
				"wheels g model User name:string,email:string",
				"wheels g controller Users index,show,new,create,edit,update,delete",
				"wheels g scaffold Product name:string,price:decimal",
				"wheels g migration CreateUsersTable"
			],
			"migrate": [
				"wheels dbmigrate latest",
				"wheels dbmigrate up",
				"wheels dbmigrate down",
				"wheels dbmigrate reset"
			],
			"server": [
				"wheels server start",
				"wheels server stop",
				"wheels server restart",
				"wheels server status"
			]
		},
		"routing": {
			"patterns": [
				"[controller]/[action]/[key]",
				"mapper().resources('users').root(to='home##index').wildcard().end()"
			]
		},
		"conventions": {
			"naming": {
				"models": "Singular (User, Product)",
				"controllers": "Plural (Users, Products)",
				"tables": "Plural lowercase (users, products)",
				"primaryKey": "id (auto-incrementing integer)"
			},
			"directories": {
				"models": "/app/models/",
				"controllers": "/app/controllers/",
				"views": "/app/views/[controller]/",
				"migrations": "/app/migrator/migrations/"
			}
		}
	};
}

// Get guides summary
function getGuidesSummary() {
	local.summaryPath = "/wheels/docs/src/SUMMARY.md";
	local.guides = [];

	if (fileExists(expandPath(summaryPath))) {
		local.summaryContent = fileRead(expandPath(summaryPath));
		local.lines = listToArray(local.summaryContent, chr(10));

		for (local.line in local.lines) {
			if (reFind("\[([^\]]+)\]\(([^\)]+)\)", local.line)) {
				local.title = reReplace(local.line, ".*\[([^\]]+)\].*", "\1");
				local.path = reReplace(local.line, ".*\(([^\)]+)\).*", "\1");

				arrayAppend(local.guides, {
					"title": local.title,
					"path": local.path,
					"endpoint": "/wheels/guides?path=" & reReplace(local.path, "\.md$", "") & "&format=json"
				});
			}
		}
	}

	return local.guides;
}

// Build the AI documentation response
local.aiDocs.documentation = {
	"api": getCondensedAPIDocs(request.wheels.params.context),
	"guides": getGuidesSummary(),
	"endpoints": {
		"fullAPI": "/wheels/api?format=json",
		"guides": "/wheels/guides?format=json",
		"project": "/wheels/ai/project",
		"manifest": "/wheels/ai/manifest"
	},
	"instructions": {
		"usage": "This endpoint provides optimized documentation for AI/LLM consumption",
		"contexts": ["all", "model", "controller", "view", "migration", "routing", "testing"],
		"format": "Always returns JSON",
		"note": "Use context parameter to get focused documentation for specific tasks"
	}
};

// Output the JSON response
writeOutput(serializeJSON(local.aiDocs));

// Handler function for manifest endpoint
function handleManifest() {
	local.manifest = {
		"version": application.wheels.version,
		"timestamp": now(),
		"chunks": [
			{
				"id": "models",
				"name": "Model Documentation",
				"description": "Complete documentation for Wheels models including CRUD, validations, associations",
				"endpoint": "/wheels/ai?mode=chunk&id=models",
				"size": "large",
				"contexts": ["model", "database", "validation"]
			},
			{
				"id": "controllers",
				"name": "Controller Documentation",
				"description": "Controller actions, filters, rendering, and request handling",
				"endpoint": "/wheels/ai?mode=chunk&id=controllers",
				"size": "medium",
				"contexts": ["controller", "routing", "rendering"]
			},
			{
				"id": "views",
				"name": "View Helpers Documentation",
				"description": "View helpers, form builders, asset tags, and templating",
				"endpoint": "/wheels/ai?mode=chunk&id=views",
				"size": "large",
				"contexts": ["view", "forms", "assets"]
			},
			{
				"id": "migrations",
				"name": "Database Migrations",
				"description": "Database schema management and migration functions",
				"endpoint": "/wheels/ai?mode=chunk&id=migrations",
				"size": "small",
				"contexts": ["migration", "database", "schema"]
			},
			{
				"id": "routing",
				"name": "Routing Configuration",
				"description": "URL routing, RESTful resources, and route helpers",
				"endpoint": "/wheels/ai?mode=chunk&id=routing",
				"size": "small",
				"contexts": ["routing", "urls", "rest"]
			},
			{
				"id": "testing",
				"name": "Testing Framework",
				"description": "TestBox integration and testing utilities",
				"endpoint": "/wheels/ai?mode=chunk&id=testing",
				"size": "small",
				"contexts": ["testing", "testbox", "assertions"]
			},
			{
				"id": "cli",
				"name": "CLI Commands",
				"description": "Wheels command-line interface and generators",
				"endpoint": "/wheels/ai?mode=chunk&id=cli",
				"size": "small",
				"contexts": ["cli", "generators", "scaffolding"]
			},
			{
				"id": "patterns",
				"name": "Common Patterns",
				"description": "Best practices and common implementation patterns",
				"endpoint": "/wheels/ai?mode=chunk&id=patterns",
				"size": "medium",
				"contexts": ["patterns", "bestpractices", "examples"]
			},
			{
				"id": "security",
				"name": "Security Features",
				"description": "CSRF protection, HTTPS detection, and security best practices",
				"endpoint": "/wheels/ai?mode=chunk&id=security",
				"size": "small",
				"contexts": ["security", "csrf", "authentication"]
			},
			{
				"id": "email",
				"name": "Email Functionality",
				"description": "Email sending, mailer components, and email templates",
				"endpoint": "/wheels/ai?mode=chunk&id=email",
				"size": "small",
				"contexts": ["email", "mailers", "notifications"]
			},
			{
				"id": "files",
				"name": "File Handling",
				"description": "File uploads, downloads, and file management",
				"endpoint": "/wheels/ai?mode=chunk&id=files",
				"size": "small",
				"contexts": ["files", "uploads", "downloads"]
			}
		],
		"endpoints": {
			"main": "/wheels/ai",
			"manifest": "/wheels/ai?mode=manifest",
			"project": "/wheels/ai?mode=project",
			"chunk": "/wheels/ai?mode=chunk&id={chunkId}",
			"info": "/wheels/ai?mode=info",
			"routes": "/wheels/ai?mode=routes",
			"migrations": "/wheels/ai?mode=migrations",
			"plugins": "/wheels/ai?mode=plugins",
			"fullAPI": "/wheels/api?format=json",
			"guides": "/wheels/guides?format=json"
		},
		"usage": {
			"description": "Use the manifest to discover available documentation chunks",
			"recommendation": "Fetch only the chunks relevant to your current task to optimize context usage",
			"example": "For model work, fetch: /wheels/ai?mode=chunk&id=models"
		}
	};

	writeOutput(serializeJSON(local.manifest));
}

// Handler function for project context endpoint
function handleProjectContext() {
	local.projectContext = {
		"version": application.wheels.version,
		"timestamp": now(),
		"project": {}
	};

	// Analyze current project structure
	try {
		// Get models
		local.modelsPath = expandPath("/app/models/");
		local.models = [];
		if (directoryExists(local.modelsPath)) {
			local.modelFiles = directoryList(local.modelsPath, false, "name", "*.cfc");
			for (local.file in local.modelFiles) {
				if (local.file != "Model.cfc") {
					arrayAppend(local.models, replace(local.file, ".cfc", ""));
				}
			}
		}
		local.projectContext.project.models = local.models;

		// Get controllers
		local.controllersPath = expandPath("/app/controllers/");
		local.controllers = [];
		if (directoryExists(local.controllersPath)) {
			local.controllerFiles = directoryList(local.controllersPath, false, "name", "*.cfc");
			for (local.file in local.controllerFiles) {
				if (local.file != "Controller.cfc") {
					arrayAppend(local.controllers, replace(local.file, ".cfc", ""));
				}
			}
		}
		local.projectContext.project.controllers = local.controllers;

		// Get database configuration
		local.projectContext.project.database = {
			"dataSourceName": application.wheels.dataSourceName,
			"environment": application.wheels.environment
		};

		// Get migrations
		local.migrationsPath = expandPath("/app/migrator/migrations/");
		local.migrations = [];
		if (directoryExists(local.migrationsPath)) {
			local.migrationFiles = directoryList(local.migrationsPath, false, "name", "*.cfc");
			local.migrations = local.migrationFiles;
		}
		local.projectContext.project.migrations = {
			"count": arrayLen(local.migrations),
			"files": local.migrations
		};

		// Get detailed routes from routes endpoint
		try {
			local.http = new http();
			local.http.setMethod("GET");
			local.http.setUrl("http://localhost:#cgi.server_port#/wheels/routes?format=json");
			local.result = local.http.send().getPrefix();

			if (local.result.statusCode == "200 OK") {
				local.routesData = deserializeJSON(local.result.fileContent);
				local.projectContext.project.routes = local.routesData.routes;
			} else {
				// Fallback to basic routes info
				if (structKeyExists(application.wheels, "routes")) {
					local.projectContext.project.routes = {
						"count": arrayLen(application.wheels.routes),
						"namedRoutes": []
					};

					// Extract named routes
					for (local.route in application.wheels.routes) {
						if (structKeyExists(local.route, "name") && len(local.route.name)) {
							arrayAppend(local.projectContext.project.routes.namedRoutes, {
								"name": local.route.name,
								"pattern": structKeyExists(local.route, "pattern") ? local.route.pattern : "",
								"method": structKeyExists(local.route, "methods") ? local.route.methods : "GET"
							});
						}
					}
				}
			}
		} catch (any e) {
			// Fallback on error
			local.projectContext.project.routes = {"error": e.message};
		}

		// Get detailed plugins from plugins endpoint
		try {
			local.http = new http();
			local.http.setMethod("GET");
			local.http.setUrl("http://localhost:#cgi.server_port#/wheels/plugins?format=json");
			local.result = local.http.send().getPrefix();

			if (local.result.statusCode == "200 OK") {
				local.pluginsData = deserializeJSON(local.result.fileContent);
				local.projectContext.project.plugins = local.pluginsData.plugins;
			} else {
				// Fallback to basic plugin list
				local.projectContext.project.plugins = [];
				if (structKeyExists(application.wheels, "plugins")) {
					for (local.plugin in application.wheels.plugins) {
						arrayAppend(local.projectContext.project.plugins, local.plugin);
					}
				}
			}
		} catch (any e) {
			local.projectContext.project.plugins = {"error": e.message};
		}

		// Get detailed migration status from migrator endpoint
		try {
			local.http = new http();
			local.http.setMethod("GET");
			local.http.setUrl("http://localhost:#cgi.server_port#/wheels/migrator?format=json");
			local.result = local.http.send().getPrefix();

			if (local.result.statusCode == "200 OK") {
				local.migratorData = deserializeJSON(local.result.fileContent);
				local.projectContext.project.migrations = local.migratorData.migrator;
			} else {
				// Keep the basic migrations info
				local.projectContext.project.migrations = {
					"count": arrayLen(local.migrations),
					"files": local.migrations
				};
			}
		} catch (any e) {
			// Keep basic info on error
			local.projectContext.project.migrations.error = e.message;
		}

		// Project conventions detected
		local.projectContext.project.conventions = analyzeProjectConventions(local.models, local.controllers);

	} catch (any e) {
		local.projectContext.error = "Error analyzing project: " & e.message;
	}

	writeOutput(serializeJSON(local.projectContext));
}

// Handler function for chunk endpoint
function handleChunk() {
	local.chunk = {
		"id": request.wheels.params.id,
		"timestamp": now(),
		"content": {}
	};

	switch(request.wheels.params.id) {
		case "models":
			local.chunk.content = getCondensedAPIDocs("model");
			local.chunk.content.patterns = getCommonPatterns().modelPatterns;
			break;
		case "controllers":
			local.chunk.content = getCondensedAPIDocs("controller");
			local.chunk.content.patterns = getCommonPatterns().controllerPatterns;
			break;
		case "views":
			local.chunk.content = getCondensedAPIDocs("view");
			local.chunk.content.patterns = getCommonPatterns().viewPatterns;
			break;
		case "migrations":
			local.chunk.content = getCondensedAPIDocs("migration");
			local.chunk.content.patterns = getCommonPatterns().migrationPatterns;
			break;
		case "routing":
			local.chunk.content = getCondensedAPIDocs("routing");
			local.chunk.content.quickReference = getQuickReference().routing;
			break;
		case "testing":
			local.chunk.content = getCondensedAPIDocs("testing");
			break;
		case "cli":
			local.chunk.content = getQuickReference().cli;
			break;
		case "patterns":
			local.chunk.content = getCommonPatterns();
			break;
		case "security":
			local.chunk.content = getSecurityDocumentation();
			break;
		case "email":
			local.chunk.content = getEmailDocumentation();
			break;
		case "files":
			local.chunk.content = getFileHandlingDocumentation();
			break;
		default:
			local.chunk.error = "Unknown chunk ID: " & request.wheels.params.id;
	}

	writeOutput(serializeJSON(local.chunk));
}

// Analyze project conventions
function analyzeProjectConventions(models, controllers) {
	local.conventions = {
		"naming": {
			"modelsAreSingular": true,
			"controllersArePlural": true
		},
		"structure": {
			"usesRESTful": false,
			"hasAuthentication": false,
			"hasAPIEndpoints": false
		}
	};

	// Check for authentication patterns
	for (local.controller in arguments.controllers) {
		if (findNoCase("session", local.controller) || findNoCase("auth", local.controller)) {
			local.conventions.structure.hasAuthentication = true;
		}
		if (findNoCase("api", local.controller)) {
			local.conventions.structure.hasAPIEndpoints = true;
		}
	}

	// Check naming conventions
	for (local.model in arguments.models) {
		if (right(local.model, 1) == "s") {
			local.conventions.naming.modelsAreSingular = false;
		}
	}

	return local.conventions;
}

// Handler function for info mode
function handleInfo() {
	// Fetch system info from the info endpoint
	local.http = new http();
	local.http.setMethod("GET");
	local.http.setUrl("http://localhost:#cgi.server_port#/wheels/info?format=json");
	local.result = local.http.send().getPrefix();

	if (local.result.statusCode == "200 OK") {
		writeOutput(local.result.fileContent);
	} else {
		writeOutput(serializeJSON({
			"error": true,
			"message": "Failed to fetch system info",
			"statusCode": local.result.statusCode
		}));
	}
}

// Handler function for routes mode
function handleRoutes() {
	// Fetch routes from the routes endpoint
	local.http = new http();
	local.http.setMethod("GET");
	local.http.setUrl("http://localhost:#cgi.server_port#/wheels/routes?format=json");
	local.result = local.http.send().getPrefix();

	if (local.result.statusCode == "200 OK") {
		writeOutput(local.result.fileContent);
	} else {
		writeOutput(serializeJSON({
			"error": true,
			"message": "Failed to fetch routes",
			"statusCode": local.result.statusCode
		}));
	}
}

// Handler function for migrations mode
function handleMigrations() {
	// Fetch migrations from the migrator endpoint
	local.http = new http();
	local.http.setMethod("GET");
	local.http.setUrl("http://localhost:#cgi.server_port#/wheels/migrator?format=json");
	local.result = local.http.send().getPrefix();

	if (local.result.statusCode == "200 OK") {
		writeOutput(local.result.fileContent);
	} else {
		writeOutput(serializeJSON({
			"error": true,
			"message": "Failed to fetch migrations",
			"statusCode": local.result.statusCode
		}));
	}
}

// Handler function for plugins mode
function handlePlugins() {
	// Fetch plugins from the plugins endpoint
	local.http = new http();
	local.http.setMethod("GET");
	local.http.setUrl("http://localhost:#cgi.server_port#/wheels/plugins?format=json");
	local.result = local.http.send().getPrefix();

	if (local.result.statusCode == "200 OK") {
		writeOutput(local.result.fileContent);
	} else {
		writeOutput(serializeJSON({
			"error": true,
			"message": "Failed to fetch plugins",
			"statusCode": local.result.statusCode
		}));
	}
}

// Security-focused documentation
function getSecurityDocumentation() {
	return {
		"title": "Wheels Security Documentation",
		"description": "Security features and best practices for Wheels applications",
		"sections": {
			"csrf_protection": {
				"title": "CSRF Protection",
				"description": "Cross-site request forgery protection",
				"methods": [
					{
						"name": "protectsFromForgery",
						"description": "Enable CSRF protection for the controller",
						"usage": "protectsFromForgery()",
						"location": "controllers"
					},
					{
						"name": "authenticityToken",
						"description": "Generate CSRF token for forms",
						"usage": "authenticityToken()",
						"location": "controllers"
					},
					{
						"name": "csrfMetaTags",
						"description": "Generate CSRF meta tags for layout head",
						"usage": "csrfMetaTags()",
						"location": "views"
					}
				],
				"patterns": [
					{
						"title": "Controller CSRF Setup",
						"code": "component extends='Controller' {\n  function config() {\n    protectsFromForgery();\n  }\n}"
					},
					{
						"title": "Form CSRF Token",
						"code": "##startFormTag(route='user', method='put')##\n  ##hiddenFieldTag('authenticityToken', authenticityToken())##\n  <!-- form fields -->\n##endFormTag()##"
					}
				]
			},
			"https_detection": {
				"title": "HTTPS Detection",
				"description": "Check if request is secure",
				"methods": [
					{
						"name": "isSecure",
						"description": "Check if current request uses HTTPS",
						"usage": "isSecure()",
						"location": "controllers"
					}
				],
				"patterns": [
					{
						"title": "Force HTTPS",
						"code": "function config() {\n  filters(through='requireHTTPS');\n}\n\nfunction requireHTTPS() {\n  if (!isSecure()) {\n    redirectTo(protocol='https');\n  }\n}"
					}
				]
			}
		}
	};
}

// Email-focused documentation
function getEmailDocumentation() {
	return {
		"title": "Wheels Email Documentation",
		"description": "Email functionality and mailer components",
		"sections": {
			"sending_email": {
				"title": "Sending Email",
				"description": "Send emails from controllers and models",
				"methods": [
					{
						"name": "sendEmail",
						"description": "Send email using configured mailer",
						"usage": "sendEmail(to='user@example.com', subject='Welcome', template='welcome')",
						"location": "controllers"
					}
				],
				"patterns": [
					{
						"title": "Basic Email Sending",
						"code": "function create() {\n  user = model('User').create(params.user);\n  if (user.valid()) {\n    sendEmail(\n      to=user.email,\n      subject='Welcome to our site!',\n      template='users/welcome',\n      user=user\n    );\n    redirectTo(route='user', key=user.id);\n  }\n}"
					},
					{
						"title": "Email with Attachments",
						"code": "sendEmail(\n  to='user@example.com',\n  subject='Your Report',\n  template='reports/monthly',\n  attachment='##expandPath('./reports/monthly.pdf')##'\n);"
					}
				]
			},
			"mailer_components": {
				"title": "Mailer Components",
				"description": "Dedicated mailer components for email logic",
				"patterns": [
					{
						"title": "User Mailer Component",
						"code": "// /app/mailers/UserMailer.cfc\ncomponent extends='Mailer' {\n  function welcome(user) {\n    set(\n      to=arguments.user.email,\n      subject='Welcome!',\n      template='users/welcome'\n    );\n  }\n}"
					}
				]
			}
		}
	};
}

// File handling documentation
function getFileHandlingDocumentation() {
	return {
		"title": "Wheels File Handling Documentation",
		"description": "File upload, download, and management functionality",
		"sections": {
			"file_downloads": {
				"title": "File Downloads",
				"description": "Serve files for download",
				"methods": [
					{
						"name": "sendFile",
						"description": "Send file to browser for download",
						"usage": "sendFile(file='path/to/file.pdf', name='report.pdf')",
						"location": "controllers"
					}
				],
				"patterns": [
					{
						"title": "Secure File Download",
						"code": "function download() {\n  // Verify user has access\n  if (!session.authenticated) {\n    redirectTo(route='login');\n    return;\n  }\n  \n  local.filePath = expandPath('./files/secure/##params.filename##');\n  if (fileExists(local.filePath)) {\n    sendFile(\n      file=local.filePath,\n      name=params.filename,\n      type='application/pdf'\n    );\n  } else {\n    renderView(template='errors/404');\n  }\n}"
					},
					{
						"title": "File Download with Custom Headers",
						"code": "sendFile(\n  file=expandPath('./reports/monthly.pdf'),\n  name='Monthly_Report.pdf',\n  type='application/pdf',\n  disposition='attachment'\n);"
					}
				]
			},
			"file_uploads": {
				"title": "File Uploads",
				"description": "Handle file uploads in forms",
				"patterns": [
					{
						"title": "Basic File Upload",
						"code": "// Controller\nfunction create() {\n  if (structKeyExists(params, 'avatar') && len(params.avatar)) {\n    local.uploadResult = fileUpload(\n      expandPath('./public/uploads/'),\n      'avatar',\n      'image/*',\n      'MakeUnique'\n    );\n    params.user.avatarPath = '/uploads/' & local.uploadResult.serverFile;\n  }\n  user = model('User').create(params.user);\n}"
					},
					{
						"title": "File Upload Form",
						"code": "##startFormTag(enctype='multipart/form-data')##\n  ##fileField('avatar', label='Profile Picture')##\n  ##submitTag('Upload')##\n##endFormTag()##"
					}
				]
			}
		}
	};
}
</cfscript>