/**
 * Update MCP (Model Context Protocol) configuration
 * Updates IDE configurations to use the latest MCP server endpoint
 *
 * Examples:
 * {code:bash}
 * wheels mcp update
 * wheels mcp update --port=8080
 * wheels mcp update --force
 * {code}
 **/
component extends="../base" {

	property name="mcpService" inject="MCPService@wheels-cli";

	/**
	 * @port Port number for Wheels server (auto-detected if not provided)
	 * @force Force update even if configuration exists
	 **/
	function run(
		numeric port,
		boolean force = false
	) {
		print.line();
		print.boldYellowLine("🔄 Update MCP Configuration");
		print.line("=" .repeatString(40));
		print.line();

		// Check current status
		var status = mcpService.getMCPStatus();

		print.boldLine("MCP Server Status:");
		print.indentedLine("Native CFML MCP server is built into Wheels");
		print.indentedLine("No separate server updates required");
		print.line();

		// Get current port configuration
		var serverPort = 0;
		if (!isNull(arguments.port)) {
			serverPort = arguments.port;
		} else {
			serverPort = mcpService.detectServerPort();
			if (serverPort == 0) {
				print.yellowLine("⚠️  Could not detect server port.");
				var userPort = ask("Enter your Wheels server port (or press Enter to use 60000): ");
				serverPort = len(trim(userPort)) ? userPort : 60000;
			}
		}

		// Update .mcp.json project configuration
		print.line("Updating project configuration...");
		var mcpConfigPath = getCWD() & "/.mcp.json";
		var configUpdated = false;

		if (fileExists(mcpConfigPath) || arguments.force) {
			try {
				var mcpConfig = {
					"mcpServers": {
						"wheels": {
							"type": "http",
							"url": "http://localhost:" & serverPort & "/wheels/mcp"
						}
					}
				};
				fileWrite(mcpConfigPath, serializeJSON(mcpConfig));
				print.greenLine("✅ Updated .mcp.json with port " & serverPort);
				configUpdated = true;
			} catch (any e) {
				print.redLine("❌ Failed to update .mcp.json: " & e.message);
			}
		} else {
			print.yellowLine("⚠️  No .mcp.json found. Run 'wheels mcp setup' first.");
		}

		// Update IDE configurations if they exist
		var ideUpdates = 0;
		if (status.configured && arrayLen(status.configuredIDEs) > 0) {
			print.line();
			print.line("Updating IDE configurations...");

			for (var ide in status.configuredIDEs) {
				var updated = false;
				try {
					switch (lCase(ide)) {
						case "claude":
						case "claude code":
							updated = updateClaudeConfig(serverPort, arguments.force);
							break;
						case "cursor":
							updated = updateCursorConfig(serverPort, arguments.force);
							break;
						case "continue":
							updated = updateContinueConfig(serverPort, arguments.force);
							break;
						case "windsurf":
							updated = updateWindsurfConfig(serverPort, arguments.force);
							break;
					}

					if (updated) {
						print.greenLine("✅ Updated " & ide & " configuration");
						ideUpdates++;
					}
				} catch (any e) {
					print.yellowLine("⚠️  Could not update " & ide & ": " & e.message);
				}
			}
		}

		print.line();
		if (configUpdated || ideUpdates > 0) {
			print.boldLine("Update Summary:");
			if (configUpdated) {
				print.indentedLine("• Project configuration updated");
			}
			if (ideUpdates > 0) {
				print.indentedLine("• " & ideUpdates & " IDE configuration(s) updated");
			}
			print.indentedLine("• Server port: " & serverPort);
			print.line();

			print.boldLine("Next Steps:");
			print.indentedLine("1. Restart your AI IDE to use the updated configuration");
			print.indentedLine("2. Run 'wheels mcp test' to verify the connection");
		} else {
			print.yellowLine("No configurations were updated.");
			print.line();
			if (!status.configured) {
				print.line("Run 'wheels mcp setup' to configure MCP integration.");
			}
		}
		print.line();
	}

	private function updateClaudeConfig(required numeric port, required boolean force) {
		var homeDir = createObject("java", "java.lang.System").getProperty("user.home");
		var configFile = homeDir & "/.config/claude/claude_desktop_config.json";

		if (!fileExists(configFile)) {
			return false;
		}

		try {
			var config = deserializeJSON(fileRead(configFile));
			if (structKeyExists(config, "mcpServers") && structKeyExists(config.mcpServers, "wheels")) {
				config.mcpServers.wheels = {
					"type": "http",
					"url": "http://localhost:" & arguments.port & "/wheels/mcp"
				};
				fileWrite(configFile, serializeJSON(config));
				return true;
			}
		} catch (any e) {
			// Config parse error
		}
		return false;
	}

	private function updateCursorConfig(required numeric port, required boolean force) {
		var homeDir = createObject("java", "java.lang.System").getProperty("user.home");
		var configFile = homeDir & "/.cursor/mcp_servers.json";

		if (!fileExists(configFile)) {
			return false;
		}

		try {
			var config = deserializeJSON(fileRead(configFile));
			if (structKeyExists(config, "mcpServers") && structKeyExists(config.mcpServers, "wheels")) {
				config.mcpServers.wheels = {
					"type": "http",
					"url": "http://localhost:" & arguments.port & "/wheels/mcp"
				};
				fileWrite(configFile, serializeJSON(config));
				return true;
			}
		} catch (any e) {
			// Config parse error
		}
		return false;
	}

	private function updateContinueConfig(required numeric port, required boolean force) {
		var homeDir = createObject("java", "java.lang.System").getProperty("user.home");
		var configFile = homeDir & "/.continue/config.json";

		if (!fileExists(configFile)) {
			return false;
		}

		try {
			var config = deserializeJSON(fileRead(configFile));
			if (structKeyExists(config, "experimental") &&
				structKeyExists(config.experimental, "modelContextProtocol") &&
				structKeyExists(config.experimental.modelContextProtocol, "wheels")) {
				config.experimental.modelContextProtocol.wheels = {
					"type": "http",
					"url": "http://localhost:" & arguments.port & "/wheels/mcp"
				};
				fileWrite(configFile, serializeJSON(config));
				return true;
			}
		} catch (any e) {
			// Config parse error
		}
		return false;
	}

	private function updateWindsurfConfig(required numeric port, required boolean force) {
		var homeDir = createObject("java", "java.lang.System").getProperty("user.home");
		var configFile = homeDir & "/.windsurf/mcp_servers.json";

		if (!fileExists(configFile)) {
			return false;
		}

		try {
			var config = deserializeJSON(fileRead(configFile));
			if (structKeyExists(config, "mcpServers") && structKeyExists(config.mcpServers, "wheels")) {
				config.mcpServers.wheels = {
					"type": "http",
					"url": "http://localhost:" & arguments.port & "/wheels/mcp"
				};
				fileWrite(configFile, serializeJSON(config));
				return true;
			}
		} catch (any e) {
			// Config parse error
		}
		return false;
	}

}