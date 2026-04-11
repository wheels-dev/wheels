/**
 * MCP (Model Context Protocol) tool implementations for LuCLI stdio transport.
 *
 * LuCLI's McpCommand auto-discovers public functions from the Wheels module
 * (Module.cfc) and exposes them as MCP tools over stdio. This service provides
 * additional structured tool implementations with rich schemas.
 *
 * Configuration for Claude Code (.mcp.json):
 *   {
 *     "mcpServers": {
 *       "wheels": {
 *         "command": "wheels",
 *         "args": ["mcp"]
 *       }
 *     }
 *   }
 *
 * Tools auto-discovered from Module.cfc:
 *   wheels_generate, wheels_migrate, wheels_test, wheels_seed,
 *   wheels_reload, wheels_analyze, wheels_validate, wheels_routes, wheels_info,
 *   wheels_destroy, wheels_doctor, wheels_stats, wheels_notes, wheels_db, wheels_upgrade
 */
component {

	function init(required string projectRoot) {
		variables.projectRoot = arguments.projectRoot;
		return this;
	}

	/**
	 * Return the tool schema definitions for structured MCP tool registration.
	 * These schemas describe the input parameters for each tool, enabling
	 * Claude to generate well-formed tool calls.
	 */
	public array function getToolSchemas() {
		return [
			{
				name: "wheels_generate",
				description: "Generate Wheels components (model, controller, view, migration, scaffold, api-resource, route, test, property, helper, snippets)",
				inputSchema: {
					type: "object",
					properties: {
						type: { type: "string", enum: ["model","controller","view","migration","scaffold","api-resource","route","test","property","helper","snippets"] },
						name: { type: "string", description: "Component name (PascalCase for models/controllers)" },
						attributes: { type: "string", description: "Space-separated attributes (e.g., 'name email:string active:boolean')" }
					},
					required: ["type", "name"]
				}
			},
			{
				name: "wheels_migrate",
				description: "Run database migrations (latest, up, down, info)",
				inputSchema: {
					type: "object",
					properties: {
						action: { type: "string", enum: ["latest","up","down","info"], default: "latest" }
					}
				}
			},
			{
				name: "wheels_test",
				description: "Run the Wheels test suite with optional filtering",
				inputSchema: {
					type: "object",
					properties: {
						filter: { type: "string", description: "Test directory or spec file path" },
						db: { type: "string", default: "sqlite", description: "Database to test against" },
						core: { type: "boolean", default: true, description: "Run core (framework) tests vs app tests" }
					}
				}
			},
			{
				name: "wheels_seed",
				description: "Run database seeds (convention-based or generated)",
				inputSchema: {
					type: "object",
					properties: {
						mode: { type: "string", enum: ["auto","convention","generate"], default: "auto" },
						environment: { type: "string", description: "Target environment (default: current)" }
					}
				}
			},
			{
				name: "wheels_reload",
				description: "Reload the Wheels application (picks up code changes)",
				inputSchema: { type: "object", properties: {} }
			},
			{
				name: "wheels_analyze",
				description: "Analyze the Wheels application for issues, conventions, and optimization opportunities",
				inputSchema: {
					type: "object",
					properties: {
						target: { type: "string", default: "all", description: "What to analyze (all, models, controllers, routes, config)" }
					}
				}
			},
			{
				name: "wheels_routes",
				description: "List all configured routes with their patterns and targets",
				inputSchema: { type: "object", properties: {} }
			},
			{
				name: "wheels_destroy",
				description: "Remove generated Wheels components (model, controller, view, resource) with cleanup",
				inputSchema: {
					type: "object",
					properties: {
						name: { type: "string", description: "Component name to destroy (e.g., User, Products)" },
						type: { type: "string", description: "Type to destroy: resource (default), model, controller, view", enum: ["resource","model","controller","view"] }
					},
					required: ["name"]
				}
			},
			{
				name: "wheels_doctor",
				description: "Run health checks on Wheels application (directories, files, config, permissions, database)",
				inputSchema: {
					type: "object",
					properties: {
						verbose: { type: "boolean", description: "Show all passed checks (default: false)" }
					}
				}
			},
			{
				name: "wheels_stats",
				description: "Show code statistics (files, LOC, comments, blanks) across project directories",
				inputSchema: {
					type: "object",
					properties: {
						verbose: { type: "boolean", description: "Show top 10 largest files (default: false)" }
					}
				}
			},
			{
				name: "wheels_notes",
				description: "Extract TODO, FIXME, OPTIMIZE and other annotations from codebase",
				inputSchema: {
					type: "object",
					properties: {
						annotations: { type: "string", description: "Comma-separated annotation types (default: TODO,FIXME,OPTIMIZE)" },
						custom: { type: "string", description: "Additional custom annotation types to search" }
					}
				}
			},
			{
				name: "wheels_db",
				description: "Database management: reset (migrate + seed), status (migration status), version (schema version)",
				inputSchema: {
					type: "object",
					properties: {
						action: { type: "string", description: "Subcommand: reset, status, version", enum: ["reset","status","version"] },
						skipSeed: { type: "boolean", description: "Skip seeding on reset (default: false)" },
						pending: { type: "boolean", description: "Show only pending migrations for status" },
						detailed: { type: "boolean", description: "Show detailed version info" }
					},
					required: ["action"]
				}
			},
			{
				name: "wheels_upgrade_check",
				description: "Check for breaking changes before upgrading Wheels to a new version",
				inputSchema: {
					type: "object",
					properties: {
						to: { type: "string", description: "Target version (defaults to latest release)" }
					}
				}
			}
		];
	}

}
