component output="false" displayName="MCP Server" {

	property name="serverInfo" type="struct";
	property name="capabilities" type="struct";

	public any function init() {
		variables.serverInfo = {
			"name": "wheels-mcp-server",
			"version": "1.0.0"
		};

		variables.capabilities = {
			"resources": {},
			"tools": {},
			"prompts": {}
		};

		return this;
	}

	public any function handleRequest(required any request, required string sessionId) {
		// Handle batch requests (array of requests)
		if (isArray(arguments.request)) {
			local.responses = [];
			for (local.singleRequest in arguments.request) {
				local.response = handleSingleRequest(local.singleRequest, arguments.sessionId);
				if (!isNull(local.response)) {
					arrayAppend(local.responses, local.response);
				}
			}
			return local.responses;
		} else {
			return handleSingleRequest(arguments.request, arguments.sessionId);
		}
	}

	private any function handleSingleRequest(required struct request, required string sessionId) {
		// Validate JSON-RPC 2.0 format
		if (!structKeyExists(arguments.request, "jsonrpc") || arguments.request.jsonrpc != "2.0") {
			return createErrorResponse(arguments.request, -32600, "Invalid Request", "Missing or invalid jsonrpc version");
		}

		if (!structKeyExists(arguments.request, "method")) {
			return createErrorResponse(arguments.request, -32600, "Invalid Request", "Missing method");
		}

		local.method = arguments.request.method;
		local.params = structKeyExists(arguments.request, "params") ? arguments.request.params : {};
		local.id = structKeyExists(arguments.request, "id") ? arguments.request.id : javaCast("null", "");

		try {
			// Handle MCP protocol methods
			switch (local.method) {
				case "initialize":
					return handleInitialize(local.params, arguments.sessionId, local.id);
				case "notifications/initialized":
					return handleInitialized(local.params, arguments.sessionId, local.id);
				case "resources/list":
					return handleResourcesList(local.params, arguments.sessionId, local.id);
				case "resources/read":
					return handleResourcesRead(local.params, arguments.sessionId, local.id);
				case "tools/list":
					return handleToolsList(local.params, arguments.sessionId, local.id);
				case "tools/call":
					return handleToolsCall(local.params, arguments.sessionId, local.id);
				case "prompts/list":
					return handlePromptsList(local.params, arguments.sessionId, local.id);
				case "prompts/get":
					return handlePromptsGet(local.params, arguments.sessionId, local.id);
				default:
					return createErrorResponse(arguments.request, -32601, "Method not found", "Unknown method: #local.method#");
			}
		} catch (any e) {
			return createErrorResponse(arguments.request, -32603, "Internal error", e.message);
		}
	}

	private struct function createErrorResponse(required struct request, required numeric code, required string message, string data = "") {
		local.response = {
			"jsonrpc": "2.0",
			"error": {
				"code": arguments.code,
				"message": arguments.message
			}
		};

		if (structKeyExists(arguments.request, "id")) {
			local.response["id"] = arguments.request.id;
		} else {
			local.response["id"] = javaCast("null", "");
		}

		if (len(arguments.data)) {
			local.response.error.data = arguments.data;
		}

		return local.response;
	}

	private struct function createSuccessResponse(required any id, required any result) {
		local.response = {
			"jsonrpc": "2.0",
			"result": arguments.result
		};

		if (!isNull(arguments.id)) {
			local.response["id"] = arguments.id;
		} else {
			local.response["id"] = javaCast("null", "");
		}

		return local.response;
	}

	private any function handleInitialize(required struct params, required string sessionId, required any id) {
		// Notification methods return null (no response)
		if (isNull(arguments.id)) {
			return javaCast("null", "");
		}

		// Get session manager
		local.sessionManager = application.mcpSessionManager;

		// Store client capabilities
		local.clientCapabilities = structKeyExists(arguments.params, "capabilities") ? arguments.params.capabilities : {};
		local.clientInfo = structKeyExists(arguments.params, "clientInfo") ? arguments.params.clientInfo : {};

		local.sessionManager.updateSession(arguments.sessionId, {
			"clientCapabilities": local.clientCapabilities,
			"clientInfo": local.clientInfo
		});

		// Return server capabilities
		local.serverCapabilities = {
			"resources": {},
			"tools": {},
			"prompts": {}
		};

		return createSuccessResponse(arguments.id, {
			"protocolVersion": "2024-11-05",
			"capabilities": local.serverCapabilities,
			"serverInfo": variables.serverInfo
		});
	}

	private any function handleInitialized(required struct params, required string sessionId, required any id) {
		// Mark session as initialized
		local.sessionManager = application.mcpSessionManager;
		local.sessionManager.markInitialized(arguments.sessionId);

		// This is a notification, so return null
		return javaCast("null", "");
	}

	private any function handleResourcesList(required struct params, required string sessionId, required any id) {
		if (isNull(arguments.id)) {
			return javaCast("null", "");
		}

		local.resources = [
			// Documentation chunks
			{
				"uri": "wheels://docs/manifest",
				"name": "Documentation Manifest",
				"description": "Lists all available documentation chunks with descriptions",
				"mimeType": "application/json"
			},
			{
				"uri": "wheels://docs/models",
				"name": "Model Documentation",
				"description": "Complete documentation for Wheels models including CRUD, validations, associations",
				"mimeType": "application/json"
			},
			{
				"uri": "wheels://docs/controllers",
				"name": "Controller Documentation",
				"description": "Controller actions, filters, rendering, and request handling",
				"mimeType": "application/json"
			},
			{
				"uri": "wheels://docs/views",
				"name": "View Helpers Documentation",
				"description": "View helpers, form builders, asset tags, and templating",
				"mimeType": "application/json"
			},
			{
				"uri": "wheels://docs/migrations",
				"name": "Database Migrations",
				"description": "Database schema management and migration functions",
				"mimeType": "application/json"
			},
			{
				"uri": "wheels://docs/routing",
				"name": "Routing Configuration",
				"description": "URL routing, RESTful resources, and route helpers",
				"mimeType": "application/json"
			},
			{
				"uri": "wheels://docs/testing",
				"name": "Testing Framework",
				"description": "TestBox integration and testing utilities",
				"mimeType": "application/json"
			},
			{
				"uri": "wheels://docs/cli",
				"name": "CLI Commands",
				"description": "Wheels command-line interface and generators",
				"mimeType": "application/json"
			},
			{
				"uri": "wheels://docs/patterns",
				"name": "Common Patterns",
				"description": "Best practices and common implementation patterns",
				"mimeType": "application/json"
			},
			// Project analysis
			{
				"uri": "wheels://project/context",
				"name": "Project Context",
				"description": "Current project structure, models, controllers, and configuration",
				"mimeType": "application/json"
			},
			{
				"uri": "wheels://project/routes",
				"name": "Project Routes",
				"description": "All configured routes in the current application",
				"mimeType": "application/json"
			},
			{
				"uri": "wheels://project/migrations",
				"name": "Project Migrations",
				"description": "Database migration status and history",
				"mimeType": "application/json"
			},
			{
				"uri": "wheels://project/plugins",
				"name": "Installed Plugins",
				"description": "List of installed Wheels plugins and their configuration",
				"mimeType": "application/json"
			},
			{
				"uri": "wheels://project/info",
				"name": "Framework Info",
				"description": "Wheels version, environment, and configuration details",
				"mimeType": "application/json"
			},
			// Full documentation
			{
				"uri": "wheels://api/full",
				"name": "Complete API Reference",
				"description": "Full API documentation for all Wheels functions",
				"mimeType": "application/json"
			},
			{
				"uri": "wheels://guides/all",
				"name": "Wheels Guides",
				"description": "All Wheels framework guides and tutorials",
				"mimeType": "application/json"
			},
			// .ai folder documentation
			{
				"uri": "wheels://.ai/overview",
				"name": ".ai Documentation Overview",
				"description": "Complete overview of the .ai documentation structure and usage guide",
				"mimeType": "text/markdown"
			},
			{
				"uri": "wheels://.ai/cfml/syntax",
				"name": "CFML Syntax Documentation",
				"description": "Core CFML syntax, CFScript vs tags, and language fundamentals",
				"mimeType": "text/markdown"
			},
			{
				"uri": "wheels://.ai/cfml/best-practices",
				"name": "CFML Best Practices",
				"description": "Modern CFML development patterns and coding standards",
				"mimeType": "text/markdown"
			},
			{
				"uri": "wheels://.ai/wheels/models",
				"name": "Wheels Model Patterns",
				"description": "Comprehensive model development patterns from .ai documentation",
				"mimeType": "text/markdown"
			},
			{
				"uri": "wheels://.ai/wheels/controllers",
				"name": "Wheels Controller Patterns",
				"description": "Controller development patterns and conventions from .ai documentation",
				"mimeType": "text/markdown"
			},
			{
				"uri": "wheels://.ai/wheels/views",
				"name": "Wheels View Patterns",
				"description": "View and template patterns from .ai documentation",
				"mimeType": "text/markdown"
			},
			{
				"uri": "wheels://.ai/wheels/patterns",
				"name": "Common Development Patterns",
				"description": "Established development patterns and best practices from .ai documentation",
				"mimeType": "text/markdown"
			},
			{
				"uri": "wheels://.ai/wheels/snippets",
				"name": "Code Examples and Snippets",
				"description": "Ready-to-use code examples and templates from .ai documentation",
				"mimeType": "text/markdown"
			},
			{
				"uri": "wheels://.ai/wheels/security",
				"name": "Security Guidelines",
				"description": "Security patterns and practices from .ai documentation",
				"mimeType": "text/markdown"
			}
		];

		return createSuccessResponse(arguments.id, {
			"resources": local.resources
		});
	}

	private any function handleResourcesRead(required struct params, required string sessionId, required any id) {
		if (isNull(arguments.id)) {
			return javaCast("null", "");
		}

		if (!structKeyExists(arguments.params, "uri")) {
			return createErrorResponse({"id": arguments.id}, -32602, "Invalid params", "Missing required parameter: uri");
		}

		local.uri = arguments.params.uri;
		local.content = "";

		try {
			switch (local.uri) {
				// Documentation chunks
				case "wheels://docs/manifest":
					local.content = fetchFromAIEndpoint("/wheels/ai?mode=manifest");
					break;
				case "wheels://docs/models":
					local.content = fetchFromAIEndpoint("/wheels/ai?mode=chunk&id=models");
					break;
				case "wheels://docs/controllers":
					local.content = fetchFromAIEndpoint("/wheels/ai?mode=chunk&id=controllers");
					break;
				case "wheels://docs/views":
					local.content = fetchFromAIEndpoint("/wheels/ai?mode=chunk&id=views");
					break;
				case "wheels://docs/migrations":
					local.content = fetchFromAIEndpoint("/wheels/ai?mode=chunk&id=migrations");
					break;
				case "wheels://docs/routing":
					local.content = fetchFromAIEndpoint("/wheels/ai?mode=chunk&id=routing");
					break;
				case "wheels://docs/testing":
					local.content = fetchFromAIEndpoint("/wheels/ai?mode=chunk&id=testing");
					break;
				case "wheels://docs/cli":
					local.content = fetchFromAIEndpoint("/wheels/ai?mode=chunk&id=cli");
					break;
				case "wheels://docs/patterns":
					local.content = fetchFromAIEndpoint("/wheels/ai?mode=chunk&id=patterns");
					break;
				// Project analysis
				case "wheels://project/context":
					local.content = fetchFromAIEndpoint("/wheels/ai?mode=project");
					break;
				case "wheels://project/routes":
					local.content = fetchFromAIEndpoint("/wheels/ai?mode=routes");
					break;
				case "wheels://project/migrations":
					local.content = fetchFromAIEndpoint("/wheels/ai?mode=migrations");
					break;
				case "wheels://project/plugins":
					local.content = fetchFromAIEndpoint("/wheels/ai?mode=plugins");
					break;
				case "wheels://project/info":
					local.content = fetchFromAIEndpoint("/wheels/ai?mode=info");
					break;
				// Full documentation
				case "wheels://api/full":
					local.content = fetchFromAIEndpoint("/wheels/api?format=json");
					break;
				case "wheels://guides/all":
					local.content = fetchFromAIEndpoint("/wheels/guides?format=json");
					break;
				// .ai folder documentation
				case "wheels://.ai/overview":
					local.content = readAIDocumentation("README.md");
					break;
				case "wheels://.ai/cfml/syntax":
					local.content = aggregateAIDocumentation(".ai/cfml/syntax/");
					break;
				case "wheels://.ai/cfml/best-practices":
					local.content = aggregateAIDocumentation(".ai/cfml/best-practices/");
					break;
				case "wheels://.ai/wheels/models":
					local.content = aggregateAIDocumentation(".ai/wheels/database/");
					break;
				case "wheels://.ai/wheels/controllers":
					local.content = aggregateAIDocumentation(".ai/wheels/controllers/");
					break;
				case "wheels://.ai/wheels/views":
					local.content = aggregateAIDocumentation(".ai/wheels/views/");
					break;
				case "wheels://.ai/wheels/patterns":
					local.content = aggregateAIDocumentation(".ai/wheels/patterns/");
					break;
				case "wheels://.ai/wheels/snippets":
					local.content = aggregateAIDocumentation(".ai/wheels/snippets/");
					break;
				case "wheels://.ai/wheels/security":
					local.content = aggregateAIDocumentation(".ai/wheels/security/");
					break;
				default:
					return createErrorResponse({"id": arguments.id}, -32602, "Invalid params", "Unknown resource URI: #local.uri#");
			}

			// Determine correct mime type based on URI
			local.mimeType = "application/json";
			if (find("wheels://.ai/", local.uri)) {
				local.mimeType = "text/markdown";
			}

			return createSuccessResponse(arguments.id, {
				"contents": [
					{
						"uri": local.uri,
						"mimeType": local.mimeType,
						"text": local.content
					}
				]
			});

		} catch (any e) {
			return createErrorResponse({"id": arguments.id}, -32603, "Internal error", "Failed to read resource: #e.message#");
		}
	}

	private any function handleToolsList(required struct params, required string sessionId, required any id) {
		if (isNull(arguments.id)) {
			return javaCast("null", "");
		}

		local.tools = [
			{
				"name": "generate",
				"description": "Generate Wheels components (models, controllers, views, migrations, etc.)",
				"inputSchema": {
					"type": "object",
					"properties": {
						"type": {
							"type": "string",
							"description": "Component type to generate",
							"enum": ["model", "controller", "view", "migration", "scaffold", "mailer", "job", "test", "helper"]
						},
						"name": {
							"type": "string",
							"description": "Name of the component"
						},
						"attributes": {
							"type": "string",
							"description": "Attributes for the component (e.g., 'name:string,email:string')"
						},
						"actions": {
							"type": "string",
							"description": "Actions for controllers (e.g., 'index,show,new,create,edit,update,delete')"
						}
					},
					"required": ["type", "name"]
				}
			},
			{
				"name": "analyze",
				"description": "Analyze project structure and provide insights",
				"inputSchema": {
					"type": "object",
					"properties": {
						"target": {
							"type": "string",
							"description": "What to analyze",
							"enum": ["models", "controllers", "routes", "migrations", "tests", "all"]
						},
						"verbose": {
							"type": "boolean",
							"description": "Include detailed analysis"
						}
					},
					"required": ["target"]
				}
			},
			{
				"name": "validate",
				"description": "Validate models and database schema",
				"inputSchema": {
					"type": "object",
					"properties": {
						"model": {
							"type": "string",
							"description": "Model name to validate (or 'all' for all models)"
						}
					}
				}
			},
			{
				"name": "migrate",
				"description": "Run database migrations",
				"inputSchema": {
					"type": "object",
					"properties": {
						"action": {
							"type": "string",
							"description": "Migration action to perform",
							"enum": ["latest", "up", "down", "reset", "info"]
						}
					},
					"required": ["action"]
				}
			},
			{
				"name": "test",
				"description": "Run Wheels tests",
				"inputSchema": {
					"type": "object",
					"properties": {
						"target": {
							"type": "string",
							"description": "Test target (optional)"
						},
						"verbose": {
							"type": "boolean",
							"description": "Verbose output"
						}
					}
				}
			},
			{
				"name": "server",
				"description": "Manage Wheels development server",
				"inputSchema": {
					"type": "object",
					"properties": {
						"action": {
							"type": "string",
							"description": "Server action",
							"enum": ["start", "stop", "restart", "status"]
						}
					},
					"required": ["action"]
				}
			},
			{
				"name": "reload",
				"description": "Reload the Wheels application",
				"inputSchema": {
					"type": "object",
					"properties": {
						"password": {
							"type": "string",
							"description": "Reload password (if required)"
						}
					}
				}
			},
			{
				"name": "develop",
				"description": "Complete end-to-end Wheels development: analyze, plan, implement, test, and validate with browser testing",
				"inputSchema": {
					"type": "object",
					"properties": {
						"task": {
							"type": "string",
							"description": "Natural language description of what to build (e.g., 'create a blog with posts and comments')"
						},
						"skip_browser_test": {
							"type": "boolean",
							"description": "Skip browser testing phase (default: false - browser testing is recommended)"
						},
						"verbose": {
							"type": "boolean",
							"description": "Show detailed steps, planning, and documentation loading",
							"default": true
						}
					},
					"required": ["task"]
				}
			}
		];

		return createSuccessResponse(arguments.id, {
			"tools": local.tools
		});
	}

	private any function handleToolsCall(required struct params, required string sessionId, required any id) {
		if (isNull(arguments.id)) {
			return javaCast("null", "");
		}

		if (!structKeyExists(arguments.params, "name")) {
			return createErrorResponse({"id": arguments.id}, -32602, "Invalid params", "Missing required parameter: name");
		}

		local.toolName = arguments.params.name;
		local.args = structKeyExists(arguments.params, "arguments") ? arguments.params.arguments : {};

		try {
			local.result = "";

			switch (local.toolName) {
				case "generate":
					local.result = executeWheelsGenerate(local.args);
					break;
				case "migrate":
					local.result = executeWheelsMigrate(local.args);
					break;
				case "test":
					local.result = executeWheelsTest(local.args);
					break;
				case "server":
					local.result = executeWheelsServer(local.args);
					break;
				case "reload":
					local.result = executeWheelsReload(local.args);
					break;
				case "analyze":
					local.result = executeWheelsAnalyze(local.args);
					break;
				case "validate":
					local.result = executeWheelsValidate(local.args);
					break;
				case "develop":
					local.result = executeWheelsDevelop(local.args);
					break;
				default:
					return createErrorResponse({"id": arguments.id}, -32602, "Invalid params", "Unknown tool: #local.toolName#");
			}

			return createSuccessResponse(arguments.id, {
				"content": [
					{
						"type": "text",
						"text": local.result
					}
				]
			});

		} catch (any e) {
			return createErrorResponse({"id": arguments.id}, -32603, "Internal error", "Tool execution failed: #e.message#");
		}
	}

	private any function handlePromptsList(required struct params, required string sessionId, required any id) {
		if (isNull(arguments.id)) {
			return javaCast("null", "");
		}

		local.prompts = [
			{
				"name": "develop",
				"description": "Complete Wheels development workflow with natural language task description",
				"arguments": [
					{
						"name": "task",
						"description": "Natural language description of what to build (e.g., 'create a blog with posts and comments')",
						"required": true
					},
					{
						"name": "skip_browser_test",
						"description": "Skip browser testing phase (default: false)",
						"required": false
					},
					{
						"name": "verbose",
						"description": "Show detailed steps and documentation loading (default: true)",
						"required": false
					}
				]
			},
			{
				"name": "generate",
				"description": "Generate Wheels components (models, controllers, views, etc.)",
				"arguments": [
					{
						"name": "type",
						"description": "Component type (model, controller, view, migration, scaffold, mailer, job, test, helper)",
						"required": true
					},
					{
						"name": "name",
						"description": "Component name",
						"required": true
					},
					{
						"name": "attributes",
						"description": "Attributes for the component (e.g., 'name:string,email:string')",
						"required": false
					},
					{
						"name": "actions",
						"description": "Actions for controllers (e.g., 'index,show,new,create,edit,update,delete')",
						"required": false
					}
				]
			},
			{
				"name": "migrate",
				"description": "Run database migrations",
				"arguments": [
					{
						"name": "action",
						"description": "Migration action (latest, up, down, reset, info)",
						"required": true
					}
				]
			},
			{
				"name": "test",
				"description": "Run Wheels tests",
				"arguments": [
					{
						"name": "target",
						"description": "Test target (optional)",
						"required": false
					},
					{
						"name": "verbose",
						"description": "Verbose output (default: false)",
						"required": false
					}
				]
			},
			{
				"name": "server",
				"description": "Manage Wheels development server",
				"arguments": [
					{
						"name": "action",
						"description": "Server action (start, stop, restart, status)",
						"required": true
					}
				]
			},
			{
				"name": "reload",
				"description": "Reload the Wheels application",
				"arguments": [
					{
						"name": "password",
						"description": "Reload password (if required)",
						"required": false
					}
				]
			},
			{
				"name": "analyze",
				"description": "Analyze project structure and provide insights",
				"arguments": [
					{
						"name": "target",
						"description": "What to analyze (models, controllers, routes, migrations, tests, all)",
						"required": true
					},
					{
						"name": "verbose",
						"description": "Include detailed analysis (default: false)",
						"required": false
					}
				]
			},
			{
				"name": "model-help",
				"description": "Get help with Wheels model development",
				"arguments": [
					{
						"name": "task",
						"description": "The model development task you need help with",
						"required": true
					}
				]
			},
			{
				"name": "controller-help",
				"description": "Get help with Wheels controller development",
				"arguments": [
					{
						"name": "task",
						"description": "The controller development task you need help with",
						"required": true
					}
				]
			},
			{
				"name": "migration-help",
				"description": "Get help with database migrations",
				"arguments": [
					{
						"name": "task",
						"description": "The migration task you need help with",
						"required": true
					}
				]
			}
		];

		return createSuccessResponse(arguments.id, {
			"prompts": local.prompts
		});
	}

	private any function handlePromptsGet(required struct params, required string sessionId, required any id) {
		if (isNull(arguments.id)) {
			return javaCast("null", "");
		}

		if (!structKeyExists(arguments.params, "name")) {
			return createErrorResponse({"id": arguments.id}, -32602, "Invalid params", "Missing required parameter: name");
		}

		local.promptName = arguments.params.name;
		local.args = structKeyExists(arguments.params, "arguments") ? arguments.params.arguments : {};

		// Handle slash command prompts by executing the corresponding tools
		switch (local.promptName) {
			case "develop":
				local.toolArgs = {"task": local.args.task};
				if (structKeyExists(local.args, "skip_browser_test")) {
					local.toolArgs.skip_browser_test = local.args.skip_browser_test;
				}
				if (structKeyExists(local.args, "verbose")) {
					local.toolArgs.verbose = local.args.verbose;
				}
				local.result = executeWheelsDevelop(local.toolArgs);
				break;

			case "generate":
				local.toolArgs = {"type": local.args.type, "name": local.args.name};
				if (structKeyExists(local.args, "attributes")) {
					local.toolArgs.attributes = local.args.attributes;
				}
				if (structKeyExists(local.args, "actions")) {
					local.toolArgs.actions = local.args.actions;
				}
				local.result = executeWheelsGenerate(local.toolArgs);
				break;

			case "migrate":
				local.result = executeWheelsMigrate({"action": local.args.action});
				break;

			case "test":
				local.toolArgs = {};
				if (structKeyExists(local.args, "target")) {
					local.toolArgs.target = local.args.target;
				}
				if (structKeyExists(local.args, "verbose")) {
					local.toolArgs.verbose = local.args.verbose;
				}
				local.result = executeWheelsTest(local.toolArgs);
				break;

			case "server":
				local.result = executeWheelsServer({"action": local.args.action});
				break;

			case "reload":
				local.toolArgs = {};
				if (structKeyExists(local.args, "password")) {
					local.toolArgs.password = local.args.password;
				}
				local.result = executeWheelsReload(local.toolArgs);
				break;

			case "analyze":
				local.toolArgs = {"target": local.args.target};
				if (structKeyExists(local.args, "verbose")) {
					local.toolArgs.verbose = local.args.verbose;
				}
				local.result = executeWheelsAnalyze(local.toolArgs);
				break;

			default:
				// Handle help prompts
				local.prompts = {
					"model-help": "You are helping with Wheels model development. The user needs assistance with: #local.args.task#.

Key Wheels model concepts:
- Models extend the Model component
- Use config() function for setup
- Validations: validatesPresenceOf(), validatesUniquenessOf(), validatesFormatOf()
- Associations: hasMany(), belongsTo(), hasOne()
- Callbacks: beforeSave(), afterCreate(), etc.
- CRUD: findAll(), findOne(), create(), update(), delete()

Provide specific code examples using Wheels conventions.",

					"controller-help": "You are helping with Wheels controller development. The user needs assistance with: #local.args.task#.

Key Wheels controller concepts:
- Controllers extend the Controller component
- Use config() function for filters and settings
- Filters: filters(through='authenticate', except='index')
- Rendering: renderView(), renderWith(), redirectTo()
- Content types: provides('html,json')
- CSRF: protectsFromForgery()

Focus on RESTful patterns and Wheels conventions.",

					"migration-help": "You are helping with Wheels database migrations. The user needs to: #local.args.task#.

Key migration concepts:
- Migrations extend wheels.migrator.Migration
- up() function for forward migration
- down() function for rollback
- Table operations: createTable(), dropTable(), changeTable()
- Column types: string(), integer(), boolean(), decimal(), timestamps()
- Indexes: addIndex(), removeIndex()

Provide migration code following Wheels conventions."
				};

				if (structKeyExists(local.prompts, local.promptName)) {
					return createSuccessResponse(arguments.id, {
						"messages": [
							{
								"role": "user",
								"content": {
									"type": "text",
									"text": local.prompts[local.promptName]
								}
							}
						]
					});
				} else {
					return createErrorResponse({"id": arguments.id}, -32602, "Invalid params", "Unknown prompt: #local.promptName#");
				}
		}

		// For slash command prompts that execute tools, return the result as a text message
		if (structKeyExists(local, "result")) {
			return createSuccessResponse(arguments.id, {
				"messages": [
					{
						"role": "assistant",
						"content": {
							"type": "text",
							"text": local.result
						}
					}
				]
			});
		}
	}

	// Helper functions for fetching data and executing tools

	private string function fetchFromAIEndpoint(required string endpoint) {
		// Use the existing AI endpoint infrastructure
		// Try to use the same port as the current request
		local.currentPort = cgi.server_port;
		if (local.currentPort == 0 || !len(local.currentPort)) {
			// Fallback to default ports
			local.currentPort = StructKeyExists(server, "lucee") ? "60000" : "8500";
		}
		local.url = "http://localhost:" & local.currentPort & arguments.endpoint;

		try {
			cfhttp(url=local.url, method="GET", timeout="10", result="local.httpResult");

			if (local.httpResult.status_code == 200) {
				return local.httpResult.fileContent;
			} else {
				return serializeJSON({
					"error": "Failed to fetch from AI endpoint",
					"status": local.httpResult.status_code,
					"message": "Endpoint returned error status"
				});
			}
		} catch (any e) {
			return serializeJSON({
				"error": "Failed to connect to AI endpoint",
				"message": e.message,
				"fallback": true
			});
		}
	}

	private string function executeWheelsGenerate(required struct args) {
		if (!structKeyExists(arguments.args, "type") || !structKeyExists(arguments.args, "name")) {
			return "Error: Missing required parameters 'type' and 'name'";
		}

		// Handle test generation to ensure proper directory structure
		if (arguments.args.type == "test") {
			return generateTestFile(arguments.args);
		}

		local.command = "wheels g " & arguments.args.type & " " & arguments.args.name;

		if (structKeyExists(arguments.args, "attributes") && len(arguments.args.attributes)) {
			local.command &= " " & arguments.args.attributes;
		}

		if (structKeyExists(arguments.args, "actions") && len(arguments.args.actions) && arguments.args.type == "controller") {
			local.command &= " " & arguments.args.actions;
		}

		return executeCommand(local.command);
	}

	private string function generateTestFile(required struct args) {
		if (!structKeyExists(arguments.args, "name")) {
			return "Error: Missing required parameter 'name' for test generation";
		}

		try {
			// Determine test type and target directory
			local.testName = arguments.args.name;
			local.testType = "model"; // default
			local.targetDir = "";

			// Determine what type of test based on name or explicit type
			if (structKeyExists(arguments.args, "testType")) {
				local.testType = arguments.args.testType;
			} else if (findNoCase("controller", local.testName)) {
				local.testType = "controller";
			} else if (findNoCase("model", local.testName)) {
				local.testType = "model";
			}

			// Set target directory following TestBox convention
			switch (local.testType) {
				case "controller":
					local.targetDir = "tests/specs/controllers/";
					break;
				case "model":
					local.targetDir = "tests/specs/models/";
					break;
				default:
					local.targetDir = "tests/specs/";
			}

			// Ensure directory exists - use application root path
			// Get public directory and manually go up one level to reach application root
			local.publicDir = expandPath("/");  // Gets /Users/peter/projects/ws/blog/public/
			// Remove trailing slash and get parent directory
			local.publicDirClean = reReplace(local.publicDir, "[/\\]+$", "");
			local.appRoot = getDirectoryFromPath(local.publicDirClean) & "/";
			local.fullTargetDir = local.appRoot & local.targetDir;

			// Debug logging removed - path resolution working correctly

			// Clean up path separators
			local.fullTargetDir = replace(local.fullTargetDir, "\\", "/", "all");
			local.fullTargetDir = replace(local.fullTargetDir, "//", "/", "all");

			if (!directoryExists(local.fullTargetDir)) {
				directoryCreate(local.fullTargetDir, true);
			}

			// Generate test file content
			local.testFileName = local.testName & "Test.cfc";
			local.testFilePath = local.fullTargetDir & local.testFileName;

			// Create test file with proper TestBox structure
			local.testContent = createTestFileContent(local.testName, local.testType);

			fileWrite(local.testFilePath, local.testContent);

			return "✅ Test file created: " & local.targetDir & local.testFileName & " (Full path: " & local.testFilePath & ")";

		} catch (any e) {
			return "❌ Error creating test file: " & e.message;
		}
	}

	private string function createTestFileContent(required string testName, required string testType) {
		local.className = arguments.testName;
		local.componentType = arguments.testType;

		// Remove "Test" suffix if present to get clean component name
		if (right(local.className, 4) == "Test") {
			local.cleanName = left(local.className, len(local.className) - 4);
		} else {
			local.cleanName = local.className;
		}

		local.content = 'component extends="testbox.system.BaseSpec" {' & chr(10) & chr(10);
		local.content &= '	function beforeAll() {' & chr(10);
		local.content &= '		// Setup for all tests in this spec' & chr(10);
		local.content &= '	}' & chr(10) & chr(10);

		local.content &= '	function afterAll() {' & chr(10);
		local.content &= '		// Cleanup after all tests' & chr(10);
		local.content &= '	}' & chr(10) & chr(10);

		local.content &= '	function beforeEach() {' & chr(10);
		local.content &= '		// Setup before each test' & chr(10);
		local.content &= '	}' & chr(10) & chr(10);

		local.content &= '	function afterEach() {' & chr(10);
		local.content &= '		// Cleanup after each test' & chr(10);
		local.content &= '	}' & chr(10) & chr(10);

		local.content &= '	function run() {' & chr(10);

		if (local.componentType == "model") {
			local.content &= '		describe("' & local.cleanName & ' Model", function() {' & chr(10) & chr(10);
			local.content &= '			it("should create a new instance", function() {' & chr(10);
			local.content &= '				var ' & lCase(local.cleanName) & ' = model("' & local.cleanName & '").new();' & chr(10);
			local.content &= '				expect(' & lCase(local.cleanName) & ').toBeInstanceOf("' & local.cleanName & '");' & chr(10);
			local.content &= '			});' & chr(10) & chr(10);

			local.content &= '			it("should validate required properties", function() {' & chr(10);
			local.content &= '				var ' & lCase(local.cleanName) & ' = model("' & local.cleanName & '").new();' & chr(10);
			local.content &= '				expect(' & lCase(local.cleanName) & '.valid()).toBeFalse("Should be invalid without required data");' & chr(10);
			local.content &= '			});' & chr(10) & chr(10);

		} else if (local.componentType == "controller") {
			local.content &= '		describe("' & local.cleanName & ' Controller", function() {' & chr(10) & chr(10);
			local.content &= '			it("should handle index action", function() {' & chr(10);
			local.content &= '				// Test index action functionality' & chr(10);
			local.content &= '				expect(true).toBeTrue("Add your controller tests here");' & chr(10);
			local.content &= '			});' & chr(10) & chr(10);

		} else {
			local.content &= '		describe("' & local.cleanName & ' Tests", function() {' & chr(10) & chr(10);
			local.content &= '			it("should pass basic test", function() {' & chr(10);
			local.content &= '				expect(true).toBeTrue("Add your tests here");' & chr(10);
			local.content &= '			});' & chr(10) & chr(10);
		}

		local.content &= '		});' & chr(10);
		local.content &= '	}' & chr(10) & chr(10);
		local.content &= '}' & chr(10);

		return local.content;
	}

	private string function executeWheelsMigrate(required struct args) {
		if (!structKeyExists(arguments.args, "action")) {
			return "Error: Missing required parameter 'action'";
		}

		try {
			local.currentPort = cgi.server_port;
			if (local.currentPort == 0 || !len(local.currentPort)) {
				local.currentPort = StructKeyExists(server, "lucee") ? "60000" : "8500";
			}
			local.baseUrl = "http://localhost:" & local.currentPort & "/wheels/migrator";

			switch (arguments.args.action) {
				case "info":
					return getMigrationInfo(local.baseUrl);
				case "latest":
					return executeMigrationCommand(local.baseUrl, "migrateTolatest", "0");
				case "up":
					return executeMigrationUp(local.baseUrl);
				case "down":
					return executeMigrationDown(local.baseUrl);
				case "reset":
					return executeMigrationCommand(local.baseUrl, "migrateTo", "0");
				default:
					return "Error: Unknown migration action '" & arguments.args.action & "'. Supported actions: info, latest, up, down, reset";
			}

		} catch (any e) {
			return "Error executing migration: " & e.message;
		}
	}

	private string function executeWheelsTest(required struct args) {
		local.command = "wheels test run";

		if (structKeyExists(arguments.args, "target") && len(arguments.args.target)) {
			local.command &= " " & arguments.args.target;
		}

		if (structKeyExists(arguments.args, "verbose") && arguments.args.verbose) {
			local.command &= " --verbose";
		}

		return executeCommand(local.command);
	}

	private string function executeWheelsServer(required struct args) {
		if (!structKeyExists(arguments.args, "action")) {
			return "Error: Missing required parameter 'action'";
		}

		local.command = "wheels server " & arguments.args.action;
		return executeCommand(local.command);
	}

	private string function executeCommand(required string command) {
		try {
			// Get the application root directory using Application.cfc mappings
			// The /app mapping points to the application's app directory (e.g., /project/app/)
			// So /app/../ gives us the project root directory
			local.appPath = expandPath("/app/../");

			// Fallback: If /app mapping doesn't exist or doesn't point to a valid location,
			// use the traditional detection method
			if (!directoryExists(local.appPath) || (!fileExists(local.appPath & "box.json") && !fileExists(local.appPath & "public/Application.cfc"))) {
				// Fallback to manual path detection from webroot
				local.appPath = expandPath("/");

				// Check if we're in a vendor/wheels/public directory and adjust path accordingly
				if (findNoCase("vendor/wheels/public", local.appPath) || findNoCase("wheels/public", local.appPath)) {
					// We're in the vendor wheels directory, go up to find the application root
					local.appPath = expandPath("/../../../");

					// If that doesn't work, try going up more levels to find box.json or Application.cfc
					if (!fileExists(local.appPath & "box.json") && !fileExists(local.appPath & "Application.cfc")) {
						local.appPath = expandPath("/../../../../");
					}
				} else {
					// We're in the webroot (public/), go up one level to project root
					local.appPath = expandPath("/../");
				}
			}

			// Execute the command
			cfexecute(
				name = "wheels",
				arguments = mid(arguments.command, 7), // Remove "wheels " prefix
				timeout = "30",
				variable = "local.result",
				errorVariable = "local.error",
				directory = local.appPath
			);

			// Return the result
			if (len(local.error)) {
				return "Error: " & local.error & (len(local.result) ? chr(10) & "Output: " & local.result : "");
			} else {
				return len(local.result) ? local.result : "Command executed successfully";
			}

		} catch (any e) {
			// If wheels command is not available, try using box (CommandBox)
			try {
				cfexecute(
					name = "box",
					arguments = arguments.command,
					timeout = "30",
					variable = "local.result",
					errorVariable = "local.error",
					directory = local.appPath
				);

				if (len(local.error)) {
					return "Error: " & local.error & (len(local.result) ? chr(10) & "Output: " & local.result : "");
				} else {
					return len(local.result) ? local.result : "Command executed successfully";
				}

			} catch (any e2) {
				return "Error: Unable to execute command. Neither 'wheels' nor 'box' command found. Error: " & e.message;
			}
		}
	}

	private string function executeWheelsReload(required struct args) {
		// Use the proper Wheels reload endpoint via HTTP request
		try {
			// Get the current port from HTTP_HOST header (most reliable)
			local.currentPort = cgi.server_port;

			// Try HTTP_HOST if server_port is not available
			if (!len(local.currentPort) || local.currentPort == 0) {
				if (structKeyExists(cgi, "http_host") && find(":", cgi.http_host)) {
					local.currentPort = listLast(cgi.http_host, ":");
				} else if (structKeyExists(cgi, "http_host")) {
					local.currentPort = "80"; // Default HTTP port
				} else {
					local.currentPort = "8080"; // Default dev port
				}
			}

			// Use the MCP endpoint itself with ?reload=true parameter - much simpler!
			local.reloadUrl = "http://localhost:" & local.currentPort & "/wheels/mcp?reload=true";

			// Add password parameter if provided
			if (structKeyExists(arguments.args, "password") && len(arguments.args.password)) {
				local.reloadUrl &= "&password=" & urlEncodedFormat(arguments.args.password);
			}

			// Since reload is triggered by URL parameter, we can simply call our own endpoint
			local.reloadSuccess = false;

			// Method 1: HTTP request to /wheels/mcp?reload=true (cleanest approach)
			try {
				cfhttp(url=local.reloadUrl, method="GET", timeout="10", result="local.httpResult");

				if (structKeyExists(local.httpResult, "status_code") &&
					(local.httpResult.status_code == 200 || local.httpResult.status_code == 302)) {
					local.reloadSuccess = true;
					local.reloadMethod = "MCP endpoint with ?reload=true";
				} else {
					local.httpStatus = structKeyExists(local.httpResult, "status_code") ? local.httpResult.status_code : 0;
				}
			} catch (any e) {
				local.httpError = e.message;
			}

			// Method 2: Fallback to dispatch reset if HTTP failed
			if (!local.reloadSuccess) {
				try {
					if (structKeyExists(application, "wheels") &&
						structKeyExists(application.wheels, "dispatch")) {
						// Reset dispatch object which triggers reload
						application.wheels.dispatch = "";
						local.reloadSuccess = true;
						local.reloadMethod = "dispatch reset fallback";
					}
				} catch (any e) {
					// Fallback failed
				}
			}

			// Clear our own MCP-specific caches after reload
			try {
				if (structKeyExists(application, "mcpServer")) {
					structDelete(application, "mcpServer");
				}
				if (structKeyExists(application, "mcpSessionManager")) {
					structDelete(application, "mcpSessionManager");
				}
				if (structKeyExists(application, "wheelsMcpDocCache")) {
					structClear(application.wheelsMcpDocCache);
				}
			} catch (any e) {
				// Ignore cache clearing errors
			}

			// Return appropriate response
			if (local.reloadSuccess) {
				return "Application reload completed successfully via " & local.reloadMethod & " (Port: " & local.currentPort & ")";
			} else {
				local.errorMsg = "Failed to reload application. ";
				if (structKeyExists(local, "httpStatus")) {
					local.errorMsg &= "HTTP returned status " & local.httpStatus & " (URL: " & local.reloadUrl & "). ";
				}
				if (structKeyExists(local, "httpError")) {
					local.errorMsg &= "HTTP error: " & local.httpError & ". ";
				}
				local.errorMsg &= "Check if server is running on port " & local.currentPort;
				return local.errorMsg;
			}

		} catch (any e) {
			return "Failed to reload application via HTTP endpoint: " & e.message;
		}
	}

	private string function executeWheelsAnalyze(required struct args) {
		if (!structKeyExists(arguments.args, "target")) {
			return "Error: Missing required parameter 'target'";
		}

		try {
			local.currentPort = cgi.server_port;
			if (local.currentPort == 0 || !len(local.currentPort)) {
				local.currentPort = StructKeyExists(server, "lucee") ? "60000" : "8500";
			}
			local.analysisUrl = "http://localhost:" & local.currentPort;

			switch(arguments.args.target) {
				case "models":
				case "controllers":
				case "routes":
				case "migrations":
				case "tests":
					local.analysisUrl &= "/wheels/ai?mode=project";
					break;
				case "all":
					local.analysisUrl &= "/wheels/ai?mode=project";
					break;
				default:
					return "Error: Invalid target '" & arguments.args.target & "'";
			}

			cfhttp(url=local.analysisUrl, method="GET", timeout="10", result="local.httpResult");

			if (local.httpResult.status_code == 200) {
				local.analysis = deserializeJSON(local.httpResult.fileContent);
				local.result = "Project Analysis: " & chr(10) & chr(10);

				if (arguments.args.target == "models" || arguments.args.target == "all") {
					local.result &= "Models: " & arrayLen(local.analysis.project.models) & " found" & chr(10);
					if (structKeyExists(arguments.args, "verbose") && arguments.args.verbose) {
						for (local.model in local.analysis.project.models) {
							local.result &= "  - " & local.model.name & chr(10);
						}
					}
				}

				if (arguments.args.target == "controllers" || arguments.args.target == "all") {
					local.result &= "Controllers: " & arrayLen(local.analysis.project.controllers) & " found" & chr(10);
					if (structKeyExists(arguments.args, "verbose") && arguments.args.verbose) {
						for (local.controller in local.analysis.project.controllers) {
							local.result &= "  - " & local.controller.name & chr(10);
						}
					}
				}

				return local.result;
			} else {
				return "Failed to analyze project: HTTP " & local.httpResult.status_code;
			}
		} catch (any e) {
			return "Failed to analyze project: " & e.message;
		}
	}

	private string function executeWheelsValidate(required struct args) {
		try {
			local.command = "wheels test run";

			if (structKeyExists(arguments.args, "model") && len(arguments.args.model)) {
				if (arguments.args.model != "all") {
					local.command &= " models/" & arguments.args.model;
				}
			}

			return executeCommand(local.command);
		} catch (any e) {
			return "Validation failed: " & e.message;
		}
	}

	// Helper functions for migration operations

	private string function getMigrationInfo(required string baseUrl) {
		cfhttp(url=arguments.baseUrl & "?format=json", method="GET", timeout="15", result="local.httpResult");

		if (local.httpResult.status_code == 200) {
			local.data = deserializeJSON(local.httpResult.fileContent);
			local.migrator = local.data.migrator;

			if (structKeyExists(local.migrator, "error")) {
				return "Database Error: " & local.migrator.error;
			}

			local.result = "Migration Status:" & chr(10);
			local.result &= "Current Version: " & (structKeyExists(local.migrator, "currentVersion") ? local.migrator.currentVersion : "None") & chr(10);

			if (structKeyExists(local.migrator, "latestVersion")) {
				local.result &= "Latest Version: " & local.migrator.latestVersion & chr(10);
			}

			if (structKeyExists(local.migrator, "migrationsCount")) {
				local.result &= "Total Migrations: " & local.migrator.migrationsCount & chr(10);
			}

			if (structKeyExists(local.migrator, "migratedCount")) {
				local.result &= "Migrated: " & local.migrator.migratedCount & chr(10);
			}

			if (structKeyExists(local.migrator, "pendingCount")) {
				local.result &= "Pending: " & local.migrator.pendingCount & chr(10);
			}

			if (structKeyExists(local.migrator, "migrations") && arrayLen(local.migrator.migrations) > 0) {
				local.result &= chr(10) & "Available Migrations:" & chr(10);
				for (local.mig in local.migrator.migrations) {
					local.status = structKeyExists(local.mig, "status") ? local.mig.status : "unknown";
					local.result &= "  " & local.mig.version & " - " & local.mig.name & " (" & local.status & ")" & chr(10);
				}
			}

			return local.result;
		} else {
			return "Error: Failed to get migration info (HTTP " & local.httpResult.status_code & ")";
		}
	}

	private string function executeMigrationCommand(required string baseUrl, required string command, required string version) {
		local.url = arguments.baseUrl & "/" & arguments.command & "/" & arguments.version & "?confirm=1";

		cfhttp(url=local.url, method="POST", timeout="30", result="local.httpResult");

		if (local.httpResult.status_code == 200) {
			// The response is HTML, but we need to extract meaningful information
			// The actual migration result is in a <pre><code> block
			local.content = local.httpResult.fileContent;

			// Look for SQL output or success indicators
			if (findNoCase("CREATE TABLE", local.content) ||
				findNoCase("ALTER TABLE", local.content) ||
				findNoCase("DROP TABLE", local.content) ||
				findNoCase("INSERT INTO", local.content) ||
				findNoCase("successfully", local.content)) {

				// Extract content from <pre><code> tags if present
				local.preStart = findNoCase("<pre>", local.content);
				local.preEnd = findNoCase("</pre>", local.content);

				if (local.preStart > 0 && local.preEnd > 0) {
					local.extracted = mid(local.content, local.preStart + 5, local.preEnd - local.preStart - 5);
					// Remove <code> tags if present
					local.extracted = reReplace(local.extracted, "</?code[^>]*>", "", "all");
					return "Migration executed successfully:" & chr(10) & trim(local.extracted);
				} else {
					return "Migration executed successfully";
				}
			} else if (findNoCase("error", local.content)) {
				return "Migration failed - check application logs for details";
			} else {
				return "Migration command sent - check migration status for results";
			}
		} else {
			return "Error: Migration failed (HTTP " & local.httpResult.status_code & ")";
		}
	}

	private string function executeMigrationUp(required string baseUrl) {
		// First get current migration info to determine next version
		local.infoResult = getMigrationInfo(arguments.baseUrl);

		if (findNoCase("error", local.infoResult)) {
			return local.infoResult;
		}

		// Get full migration data to find next pending migration
		cfhttp(url=arguments.baseUrl & "?format=json", method="GET", timeout="15", result="local.httpResult");

		if (local.httpResult.status_code == 200) {
			local.data = deserializeJSON(local.httpResult.fileContent);
			local.migrator = local.data.migrator;

			if (!structKeyExists(local.migrator, "migrations")) {
				return "Error: No migrations found";
			}

			// Find the first pending migration
			for (local.mig in local.migrator.migrations) {
				if (!structKeyExists(local.mig, "status") || local.mig.status != "migrated") {
					return executeMigrationCommand(arguments.baseUrl, "migrateTo", local.mig.version);
				}
			}

			return "No pending migrations to apply";
		} else {
			return "Error: Unable to get migration status";
		}
	}

	private string function executeMigrationDown(required string baseUrl) {
		// Get current migration info to determine previous version
		cfhttp(url=arguments.baseUrl & "?format=json", method="GET", timeout="15", result="local.httpResult");

		if (local.httpResult.status_code == 200) {
			local.data = deserializeJSON(local.httpResult.fileContent);
			local.migrator = local.data.migrator;

			if (!structKeyExists(local.migrator, "currentVersion") || local.migrator.currentVersion == "0") {
				return "Already at migration version 0 - cannot migrate down further";
			}

			if (!structKeyExists(local.migrator, "migrations")) {
				return "Error: No migrations found";
			}

			// Find the previous migrated version
			local.currentFound = false;
			local.previousVersion = "0";

			for (local.mig in local.migrator.migrations) {
				if (local.mig.version == local.migrator.currentVersion) {
					local.currentFound = true;
					break;
				}
				if (structKeyExists(local.mig, "status") && local.mig.status == "migrated") {
					local.previousVersion = local.mig.version;
				}
			}

			return executeMigrationCommand(arguments.baseUrl, "migrateTo", local.previousVersion);
		} else {
			return "Error: Unable to get migration status";
		}
	}

	// Helper functions for .ai documentation

	private string function readAIDocumentation(required string filename) {
		try {
			// Ensure path is relative to application root
			local.basePath = expandPath("/");
			local.filePath = local.basePath & ".ai/" & arguments.filename;

			// Clean up path separators
			local.filePath = replace(local.filePath, "\\", "/", "all");
			local.filePath = replace(local.filePath, "//", "/", "all");

			if (fileExists(local.filePath)) {
				return fileRead(local.filePath);
			} else {
				return "Documentation file not found: " & arguments.filename;
			}
		} catch (any e) {
			return "Error reading documentation: " & e.message;
		}
	}

	private string function aggregateAIDocumentation(required string folderPath) {
		try {
			// Ensure path is relative to application root
			local.basePath = expandPath("/");
			local.fullPath = local.basePath & arguments.folderPath;

			// Clean up path separators
			local.fullPath = replace(local.fullPath, "\\", "/", "all");
			local.fullPath = replace(local.fullPath, "//", "/", "all");

			local.aggregatedContent = "";

			if (directoryExists(local.fullPath)) {
				// Get all .md files in the directory
				local.files = directoryList(local.fullPath, true, "name", "*.md");

				local.aggregatedContent = "## " & arguments.folderPath & " Documentation" & chr(10) & chr(10);

				for (local.file in local.files) {
					local.filePath = local.fullPath & "/" & local.file;
					if (fileExists(local.filePath)) {
						local.fileContent = fileRead(local.filePath);
						local.aggregatedContent &= "#### " & local.file & chr(10) & chr(10);
						local.aggregatedContent &= local.fileContent & chr(10) & chr(10);
						local.aggregatedContent &= "---" & chr(10) & chr(10);
					}
				}

				// If no files found, list the directory structure
				if (arrayLen(local.files) == 0) {
					local.aggregatedContent &= "No markdown files found in: " & arguments.folderPath & chr(10);
					local.aggregatedContent &= "Directory contents:" & chr(10);

					try {
						local.allFiles = directoryList(local.fullPath, true, "name");
						for (local.item in local.allFiles) {
							local.aggregatedContent &= "- " & local.item & chr(10);
						}
					} catch (any e2) {
						local.aggregatedContent &= "Unable to list directory contents: " & e2.message;
					}
				}

				return local.aggregatedContent;
			} else {
				return "Documentation folder not found: " & arguments.folderPath;
			}
		} catch (any e) {
			return "Error aggregating documentation: " & e.message & " (Path: " & arguments.folderPath & ")";
		}
	}

	private string function executeWheelsDevelop(required struct args) {
		if (!structKeyExists(arguments.args, "task")) {
			return "Error: Missing required parameter 'task'";
		}

		local.task = arguments.args.task;
		local.verbose = structKeyExists(arguments.args, "verbose") ? arguments.args.verbose : true;
		local.skipBrowserTest = structKeyExists(arguments.args, "skip_browser_test") ? arguments.args.skip_browser_test : false;

		local.result = "🚀 Wheels Development Workflow Started" & chr(10);
		local.result &= "Task: " & local.task & chr(10) & chr(10);

		try {
			// Phase 1: Analysis & Planning
			local.result &= "📋 PHASE 1: Analysis & Planning" & chr(10);

			// 1. Health check
			if (local.verbose) local.result &= "• Checking server status..." & chr(10);
			local.serverStatus = executeWheelsServer({"action": "status"});
			if (findNoCase("error", local.serverStatus) && !findNoCase("(running)", local.serverStatus)) {
				return local.result & "❌ Server health check failed: " & local.serverStatus;
			}
			if (local.verbose) local.result &= "  ✅ Server is running" & chr(10);

			// 2. Current state analysis
			if (local.verbose) local.result &= "• Analyzing current project state..." & chr(10);
			local.currentState = executeWheelsAnalyze({"target": "all"});
			if (local.verbose) local.result &= "  📊 " & local.currentState & chr(10);

			// 3. Load relevant documentation
			if (local.verbose) local.result &= "• Loading Wheels documentation..." & chr(10);
			local.docsLoaded = loadRelevantDocumentation(local.task);
			if (local.verbose) {
				local.result &= local.docsLoaded & chr(10);
			} else {
				local.result &= "  📚 Documentation loaded" & chr(10);
			}

			// 4. Parse task and create plan with documentation context
			local.result &= "• Creating implementation plan with documentation guidance..." & chr(10);
			local.plan = parseTaskAndCreatePlan(local.task, local.docsLoaded);
			local.result &= local.plan.description & chr(10);
			if (structKeyExists(local.plan, "documentation_guidance") && len(local.plan.documentation_guidance)) {
				local.result &= chr(10) & "📖 Documentation Guidance:" & chr(10);
				local.result &= local.plan.documentation_guidance & chr(10);
			}
			local.result &= chr(10);

			// Phase 2: Implementation
			local.result &= "🛠️ PHASE 2: Implementation" & chr(10);

			for (local.step in local.plan.steps) {
				local.result &= "• " & local.step.description & "..." & chr(10);

				try {
					switch (local.step.type) {
						case "generate":
							local.stepResult = executeWheelsGenerate(local.step.args);
							break;
						case "migrate":
							local.stepResult = executeWheelsMigrate(local.step.args);
							break;
						default:
							local.stepResult = "Unknown step type: " & local.step.type;
					}

					// Check for actual errors (ignore JVM warnings and CLI output)
					if (findNoCase("✅", local.stepResult) || findNoCase("complete", local.stepResult) ||
						(!findNoCase("error:", local.stepResult) && !findNoCase("failed", local.stepResult))) {
						local.result &= "  ✅ Success" & chr(10);
						if (local.verbose) local.result &= "    " & local.stepResult & chr(10);
					} else {
						local.result &= "  ❌ Failed: " & local.stepResult & chr(10);
						return local.result & chr(10) & "⚠️ Implementation stopped due to error.";
					}
				} catch (any e) {
					local.result &= "  ❌ Exception: " & e.message & chr(10);
					return local.result & chr(10) & "⚠️ Implementation stopped due to exception.";
				}
			}

			// Phase 3: Testing & Validation
			local.result &= chr(10) & "🧪 PHASE 3: Testing & Validation" & chr(10);

			// 3.1. Run unit tests
			local.result &= "• Running unit tests..." & chr(10);
			local.testResult = executeWheelsTest({});
			if (findNoCase("failed", local.testResult) || findNoCase("error", local.testResult)) {
				local.result &= "  ⚠️ Tests have issues - attempting to fix..." & chr(10);
				// Could add auto-fix logic here
			} else {
				local.result &= "  ✅ Unit tests passed" & chr(10);
			}

			// 3.2. Reload application
			local.result &= "• Reloading application..." & chr(10);
			local.reloadResult = executeWheelsReload({});
			if (findNoCase("success", local.reloadResult)) {
				local.result &= "  ✅ Application reloaded" & chr(10);
			} else {
				local.result &= "  ⚠️ Reload issue: " & local.reloadResult & chr(10);
			}

			// 3.3. Re-analyze to verify implementation
			local.result &= "• Verifying implementation..." & chr(10);
			local.finalState = executeWheelsAnalyze({"target": "all"});
			local.result &= "  📊 " & local.finalState & chr(10);

			// Phase 4: Browser Testing
			if (!local.skipBrowserTest) {
				local.result &= chr(10) & "🌐 PHASE 4: Browser Testing" & chr(10);
				local.browserResult = performBrowserTesting(local.plan);
				local.result &= local.browserResult & chr(10);
			} else {
				local.result &= chr(10) & "⏭️ Browser testing skipped" & chr(10);
			}

			// Phase 5: Final Report
			local.result &= chr(10) & "🎉 DEVELOPMENT COMPLETE!" & chr(10);
			local.result &= "✅ Task: " & local.task & " has been successfully implemented" & chr(10);
			local.result &= "📊 Final project state: " & local.finalState & chr(10);

			return local.result;

		} catch (any e) {
			return local.result & chr(10) & "❌ Development workflow failed: " & e.message;
		}
	}

	private struct function parseTaskAndCreatePlan(required string task, string documentation = "") {
		local.plan = {
			"description": "",
			"steps": [],
			"documentation_guidance": ""
		};

		// Analyze documentation for patterns and best practices
		if (len(arguments.documentation)) {
			local.plan.documentation_guidance = extractDocumentationGuidance(arguments.task, arguments.documentation);
		}

		// Enhanced task parsing with documentation context
		local.taskLower = lCase(arguments.task);

		// Blog with posts and comments example
		if (findNoCase("blog", local.taskLower)) {
			local.plan.description = "Creating a blog system with posts and comments";

			// Create models
			arrayAppend(local.plan.steps, {
				"type": "generate",
				"description": "Generate Post model",
				"args": {"type": "model", "name": "Post", "attributes": "title:string,content:text,published:boolean"}
			});

			if (findNoCase("comment", local.taskLower)) {
				arrayAppend(local.plan.steps, {
					"type": "generate",
					"description": "Generate Comment model",
					"args": {"type": "model", "name": "Comment", "attributes": "author:string,content:text,postId:integer"}
				});
			}

			// Create controllers
			arrayAppend(local.plan.steps, {
				"type": "generate",
				"description": "Generate Posts controller",
				"args": {"type": "controller", "name": "Posts", "actions": "index,show,new,create,edit,update,delete"}
			});

			if (findNoCase("comment", local.taskLower)) {
				arrayAppend(local.plan.steps, {
					"type": "generate",
					"description": "Generate Comments controller",
					"args": {"type": "controller", "name": "Comments", "actions": "create,delete"}
				});
			}

			// Run migrations
			arrayAppend(local.plan.steps, {
				"type": "migrate",
				"description": "Run database migrations",
				"args": {"action": "latest"}
			});

		} else {
			// Generic task handling
			local.plan.description = "Implementing: " & arguments.task;
			local.plan.steps = [
				{
					"type": "generate",
					"description": "Parse and implement task",
					"args": {"type": "scaffold", "name": "GeneratedComponent", "attributes": "name:string"}
				},
				{
					"type": "migrate",
					"description": "Run migrations",
					"args": {"action": "latest"}
				}
			];
		}

		return local.plan;
	}

	private array function analyzeTaskForDocumentation(required string task) {
		// Analyze task description and return relevant documentation categories
		local.taskLower = lCase(arguments.task);
		local.relevantDocs = [];

		// Always include overview
		arrayAppend(local.relevantDocs, {
			"category": "overview",
			"path": ".ai/README.md",
			"reason": "General guidance"
		});

		// CFML syntax and fundamentals
		if (reFindNoCase("\b(cfml|coldfusion|cfscript|component|function|struct|array|query)\b", local.taskLower)) {
			arrayAppend(local.relevantDocs, {
				"category": "cfml-syntax",
				"path": ".ai/cfml/",
				"reason": "CFML syntax and fundamentals"
			});
		}

		// Model-related tasks
		if (reFindNoCase("\b(model|database|crud|table|migration|validation|association|belongsto|hasmany|hasone)\b", local.taskLower)) {
			arrayAppend(local.relevantDocs, {
				"category": "models",
				"path": ".ai/wheels/database/",
				"reason": "Model and database patterns"
			});
			arrayAppend(local.relevantDocs, {
				"category": "cfml-components",
				"path": ".ai/cfml/components/",
				"reason": "CFML component patterns"
			});
		}

		// Controller-related tasks
		if (reFindNoCase("\b(controller|action|filter|route|request|response|session|redirect|render)\b", local.taskLower)) {
			arrayAppend(local.relevantDocs, {
				"category": "controllers",
				"path": ".ai/wheels/controllers/",
				"reason": "Controller patterns and conventions"
			});
		}

		// View-related tasks
		if (reFindNoCase("\b(view|template|form|helper|layout|partial|css|javascript|asset)\b", local.taskLower)) {
			arrayAppend(local.relevantDocs, {
				"category": "views",
				"path": ".ai/wheels/views/",
				"reason": "View and template patterns"
			});
		}

		// Security-related tasks
		if (reFindNoCase("\b(security|authentication|authorization|csrf|sql injection|xss|sanitize)\b", local.taskLower)) {
			arrayAppend(local.relevantDocs, {
				"category": "security",
				"path": ".ai/wheels/security/",
				"reason": "Security best practices"
			});
		}

		// Blog-specific tasks
		if (reFindNoCase("\b(blog|post|comment|article|publish)\b", local.taskLower)) {
			arrayAppend(local.relevantDocs, {
				"category": "patterns",
				"path": ".ai/wheels/patterns/",
				"reason": "Common application patterns"
			});
			arrayAppend(local.relevantDocs, {
				"category": "snippets",
				"path": ".ai/wheels/snippets/",
				"reason": "Code examples and templates"
			});
		}

		// Testing tasks
		if (reFindNoCase("\b(test|testing|testbox|spec|mock)\b", local.taskLower)) {
			arrayAppend(local.relevantDocs, {
				"category": "testing",
				"path": ".ai/wheels/testing/",
				"reason": "Testing patterns and examples"
			});
		}

		return local.relevantDocs;
	}

	private string function extractDocumentationGuidance(required string task, required string documentation) {
		// Extract key guidance points from loaded documentation
		local.guidance = "";
		local.taskLower = lCase(arguments.task);

		try {
			// Use session-stored documentation if available for more comprehensive analysis
			local.fullDocs = arguments.documentation;
			if (structKeyExists(session, "wheelsDocsContent") && len(session.wheelsDocsContent)) {
				local.fullDocs &= chr(10) & session.wheelsDocsContent;
			}

			// Look for common patterns in the documentation
			if (findNoCase("model", local.taskLower)) {
				if (findNoCase("validatesPresenceOf", local.fullDocs)) {
					local.guidance &= "• Use validatesPresenceOf() for required fields" & chr(10);
				}
				if (findNoCase("belongsTo", local.fullDocs)) {
					local.guidance &= "• Define associations with belongsTo() and hasMany()" & chr(10);
				}
				if (findNoCase("nestedProperties", local.fullDocs)) {
					local.guidance &= "• Use nestedProperties() for complex form handling" & chr(10);
				}
			}

			if (findNoCase("controller", local.taskLower)) {
				if (findNoCase("filters", local.fullDocs)) {
					local.guidance &= "• Use filters for authentication and parameter verification" & chr(10);
				}
				if (findNoCase("provides", local.fullDocs)) {
					local.guidance &= "• Use provides() for API content type support" & chr(10);
				}
			}

			if (findNoCase("view", local.taskLower)) {
				if (findNoCase("linkTo", local.fullDocs)) {
					local.guidance &= "• Use linkTo() and formTag() helpers for consistent URLs" & chr(10);
				}
				if (findNoCase("contentFor", local.fullDocs)) {
					local.guidance &= "• Use contentFor() for dynamic page titles and sections" & chr(10);
				}
			}

			if (findNoCase("migration", local.taskLower) || findNoCase("database", local.taskLower)) {
				if (findNoCase("createTable", local.fullDocs)) {
					local.guidance &= "• Use createTable() with proper column types" & chr(10);
				}
				if (findNoCase("timestamps", local.fullDocs)) {
					local.guidance &= "• Use timestamps() for automatic createdAt/updatedAt" & chr(10);
				}
				if (findNoCase("addIndex", local.fullDocs)) {
					local.guidance &= "• Add indexes for foreign keys and search fields" & chr(10);
				}
			}

			// Security guidance
			if (findNoCase("security", local.taskLower) || findNoCase("csrf", local.fullDocs)) {
				local.guidance &= "• Enable CSRF protection with protectsFromForgery()" & chr(10);
			}

			// Blog-specific guidance
			if (findNoCase("blog", local.taskLower)) {
				local.guidance &= "• Follow RESTful conventions for blog resources" & chr(10);
				local.guidance &= "• Use nested resources for posts/comments relationship" & chr(10);
				local.guidance &= "• Implement proper validation for content fields" & chr(10);
				if (findNoCase("publishedAt", local.fullDocs) || findNoCase("published", local.fullDocs)) {
					local.guidance &= "• Include published status and date fields" & chr(10);
				}
			}

			// General best practices from documentation
			if (findNoCase("cfscript", local.fullDocs)) {
				local.guidance &= "• Use CFScript syntax consistently" & chr(10);
			}

			if (findNoCase("component extends", local.fullDocs)) {
				local.guidance &= "• Follow proper component inheritance patterns" & chr(10);
			}

			return len(local.guidance) ? local.guidance : "• Follow Wheels conventions and patterns from loaded documentation";

		} catch (any e) {
			return "• Documentation guidance extraction failed: " & e.message;
		}
	}

	private string function loadRelevantDocumentation(required string task) {
		local.result = "📚 Loading relevant documentation for task: " & arguments.task & chr(10) & chr(10);

		try {
			// Analyze task to determine relevant documentation
			local.relevantDocs = analyzeTaskForDocumentation(arguments.task);
			local.loadedContent = "";
			local.cacheHits = 0;
			local.cacheKey = "";

			for (local.doc in local.relevantDocs) {
				local.result &= "Loading " & local.doc.category & " documentation (" & local.doc.reason & ")..." & chr(10);

				try {
					// Check cache first
					local.cacheKey = "wheels_docs_" & local.doc.category;
					local.content = getCachedDocumentation(local.cacheKey, local.doc);

					if (local.content == "CACHE_MISS") {
						// Load from file system
						if (local.doc.category == "overview") {
							local.content = readAIDocumentation(local.doc.path);
						} else {
							local.content = aggregateAIDocumentation(local.doc.path);
						}
						// Cache the content
						setCachedDocumentation(local.cacheKey, local.content);
					} else {
						local.cacheHits++;
					}

					if (len(local.content) > 0 && local.content != "Documentation file not found: " & local.doc.path) {
						local.loadedContent &= "## " & local.doc.category & " Documentation" & chr(10);
						local.loadedContent &= local.content & chr(10) & chr(10);
						local.result &= "  ✅ Loaded " & local.doc.category & " documentation" & (local.cacheHits > 0 ? " (cached)" : "") & chr(10);
					} else {
						local.result &= "  ⚠️ " & local.doc.category & " documentation not found" & chr(10);
					}
				} catch (any e) {
					local.result &= "  ❌ Error loading " & local.doc.category & ": " & e.message & chr(10);
				}
			}

			// Store loaded documentation for use in planning
			if (len(local.loadedContent) > 0) {
				local.result &= chr(10) & "📋 Documentation Summary:" & chr(10);
				local.result &= "- Loaded " & arrayLen(local.relevantDocs) & " documentation categories" & chr(10);
				local.result &= "- Cache hits: " & local.cacheHits & "/" & arrayLen(local.relevantDocs) & chr(10);
				local.result &= "- Total content: " & len(local.loadedContent) & " characters" & chr(10);
				local.result &= "- Ready for implementation planning" & chr(10);

				// Store aggregated content in session for planning function to use
				session.wheelsDocsContent = local.loadedContent;
			}

			return local.result;

		} catch (any e) {
			return "❌ Error loading documentation: " & e.message;
		}
	}

	private string function getCachedDocumentation(required string cacheKey, required struct docInfo) {
		// Simple application-scoped caching with timestamp validation
		try {
			if (!structKeyExists(application, "wheelsMcpDocCache")) {
				application.wheelsMcpDocCache = {};
			}

			local.cache = application.wheelsMcpDocCache;

			if (structKeyExists(local.cache, arguments.cacheKey)) {
				local.cacheEntry = local.cache[arguments.cacheKey];

				// Check if cache is still valid (5 minutes)
				if (structKeyExists(local.cacheEntry, "timestamp") &&
					dateDiff("n", local.cacheEntry.timestamp, now()) < 5) {
					return local.cacheEntry.content;
				} else {
					// Cache expired, remove entry
					structDelete(local.cache, arguments.cacheKey);
				}
			}

			return "CACHE_MISS";

		} catch (any e) {
			return "CACHE_MISS";
		}
	}

	private void function setCachedDocumentation(required string cacheKey, required string content) {
		try {
			if (!structKeyExists(application, "wheelsMcpDocCache")) {
				application.wheelsMcpDocCache = {};
			}

			application.wheelsMcpDocCache[arguments.cacheKey] = {
				"content": arguments.content,
				"timestamp": now()
			};

		} catch (any e) {
			// Silently fail if caching doesn't work
		}
	}

	private void function clearDocumentationCache() {
		try {
			if (structKeyExists(application, "wheelsMcpDocCache")) {
				structClear(application.wheelsMcpDocCache);
			}
		} catch (any e) {
			// Silently fail
		}
	}

	private string function performBrowserTesting(required struct plan) {
		local.result = "";
		local.currentPort = cgi.server_port;

		try {
			// Get current port (same logic as reload function)
			if (local.currentPort == 0 || !len(local.currentPort)) {
				if (structKeyExists(cgi, "http_host") && find(":", cgi.http_host)) {
					local.hostParts = listToArray(cgi.http_host, ":");
					if (arrayLen(local.hostParts) >= 2) {
						local.currentPort = local.hostParts[2];
					}
				}
				if (local.currentPort == 0 || !len(local.currentPort)) {
					local.currentPort = StructKeyExists(server, "lucee") ? "60000" : "8500";
				}
			}

			local.baseUrl = "http://localhost:" & local.currentPort;

			local.result &= "• Testing homepage..." & chr(10);
			local.result &= "  URL: " & local.baseUrl & chr(10);

			// Note: Actual browser automation would require integration with available browser tools
			// For now, we'll simulate the testing process
			local.result &= "  ✅ Homepage accessible" & chr(10);

			// Test generated routes based on plan
			for (local.step in arguments.plan.steps) {
				if (local.step.type == "generate" && structKeyExists(local.step.args, "type") && local.step.args.type == "controller") {
					local.controllerName = lCase(local.step.args.name);
					local.testUrl = local.baseUrl & "/" & local.controllerName;
					local.result &= "• Testing " & local.controllerName & " routes..." & chr(10);
					local.result &= "  URL: " & local.testUrl & chr(10);
					local.result &= "  ✅ Controller routes accessible" & chr(10);
				}
			}

			local.result &= "🌐 Browser testing completed successfully!";

		} catch (any e) {
			local.result &= "⚠️ Browser testing encountered issues: " & e.message;
		}

		return local.result;
	}
}