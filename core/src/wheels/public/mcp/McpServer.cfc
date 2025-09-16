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
				default:
					return createErrorResponse({"id": arguments.id}, -32602, "Invalid params", "Unknown resource URI: #local.uri#");
			}

			return createSuccessResponse(arguments.id, {
				"contents": [
					{
						"uri": local.uri,
						"mimeType": "application/json",
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
				"name": "wheels_generate",
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
				"name": "wheels_analyze",
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
				"name": "wheels_validate",
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
				"name": "wheels_migrate",
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
				"name": "wheels_test",
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
				"name": "wheels_server",
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
				"name": "wheels_reload",
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
				case "wheels_generate":
					local.result = executeWheelsGenerate(local.args);
					break;
				case "wheels_migrate":
					local.result = executeWheelsMigrate(local.args);
					break;
				case "wheels_test":
					local.result = executeWheelsTest(local.args);
					break;
				case "wheels_server":
					local.result = executeWheelsServer(local.args);
					break;
				case "wheels_reload":
					local.result = executeWheelsReload(local.args);
					break;
				case "wheels_analyze":
					local.result = executeWheelsAnalyze(local.args);
					break;
				case "wheels_validate":
					local.result = executeWheelsValidate(local.args);
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
				"name": "wheels_model_help",
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
				"name": "wheels_controller_help",
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
				"name": "wheels_migration_help",
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

		local.prompts = {
			"wheels_model_help": "You are helping with Wheels model development. The user needs assistance with: #local.args.task#.

Key Wheels model concepts:
- Models extend the Model component
- Use config() function for setup
- Validations: validatesPresenceOf(), validatesUniquenessOf(), validatesFormatOf()
- Associations: hasMany(), belongsTo(), hasOne()
- Callbacks: beforeSave(), afterCreate(), etc.
- CRUD: findAll(), findOne(), create(), update(), delete()

Provide specific code examples using Wheels conventions.",

			"wheels_controller_help": "You are helping with Wheels controller development. The user needs assistance with: #local.args.task#.

Key Wheels controller concepts:
- Controllers extend the Controller component
- Use config() function for filters and settings
- Filters: filters(through='authenticate', except='index')
- Rendering: renderView(), renderWith(), redirectTo()
- Content types: provides('html,json')
- CSRF: protectsFromForgery()

Focus on RESTful patterns and Wheels conventions.",

			"wheels_migration_help": "You are helping with Wheels database migrations. The user needs to: #local.args.task#.

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

		local.command = "wheels g " & arguments.args.type & " " & arguments.args.name;

		if (structKeyExists(arguments.args, "attributes") && len(arguments.args.attributes)) {
			local.command &= " " & arguments.args.attributes;
		}

		if (structKeyExists(arguments.args, "actions") && len(arguments.args.actions) && arguments.args.type == "controller") {
			local.command &= " " & arguments.args.actions;
		}

		return executeCommand(local.command);
	}

	private string function executeWheelsMigrate(required struct args) {
		if (!structKeyExists(arguments.args, "action")) {
			return "Error: Missing required parameter 'action'";
		}

		local.command = "wheels dbmigrate " & arguments.args.action;
		return executeCommand(local.command);
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
			// Get the current working directory (should be the app root)
			local.appPath = expandPath("/");

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
					directory = expandPath("/")
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
		// Implement application reload using the Wheels internal reload endpoint
		try {
			local.currentPort = cgi.server_port;
			if (local.currentPort == 0 || !len(local.currentPort)) {
				local.currentPort = StructKeyExists(server, "lucee") ? "60000" : "8500";
			}

			// Use the Wheels internal reload endpoint
			local.reloadUrl = "http://localhost:" & local.currentPort & "/wheels/info?reload";

			// Add password if provided
			if (structKeyExists(arguments.args, "password")) {
				local.reloadUrl &= "&password=" & arguments.args.password;
			}

			cfhttp(url=local.reloadUrl, method="GET", timeout="30", redirect="false", result="local.httpResult");

			// Accept 200 (OK), 302 (Redirect), or 408 (which sometimes happens during reload)
			if (local.httpResult.status_code == 200 || local.httpResult.status_code == 302 || local.httpResult.status_code == 408) {
				// Even with a 408, the reload usually completes
				return "Application reload initiated successfully via Wheels internal endpoint";
			} else {
				return "Failed to reload application: HTTP " & local.httpResult.status_code;
			}
		} catch (any e) {
			return "Failed to reload application: " & e.message;
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
}