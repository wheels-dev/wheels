/**
 * Set up MCP (Model Context Protocol) integration for AI IDE support
 * Configures your Wheels project to work with AI coding assistants like Claude Code, Cursor, and Continue
 * Uses the native CFML MCP server built into Wheels (no Node.js required)
 *
 * Examples:
 * {code:bash}
 * wheels mcp setup
 * wheels mcp setup --port=8080
 * wheels mcp setup --ide=claude
 * wheels mcp setup --ide=opencode
 * wheels mcp setup --all
 * wheels mcp setup --force
 * wheels mcp setup --browserMcp
 * wheels mcp setup --browserMcp --all
 * {code}
 **/
component extends="../base" {

	/**
	 * @port Port number for Wheels server (auto-detected if not provided)
	 * @ide Specific IDE to configure (claude, cursor, continue, windsurf, opencode)
	 * @all Configure all detected IDEs
	 * @force Overwrite existing configuration
	 * @noAutoStart Don't automatically start server if not running
	 * @browserMcp Include Browser MCP server in configuration
	 **/
	function run(
		numeric port,
		string ide,
		boolean all = false,
		boolean force = false,
		boolean noAutoStart = false,
		boolean browserMcp = false
	) {
		print.line();
		print.boldYellowLine("🤖 Setting up MCP Integration for Wheels");
		print.line("=" .repeatString(50));
		print.line();

		// Check if we're in a Wheels application
		if (!isWheelsApp()) {
			print.redLine("❌ This doesn't appear to be a Wheels application directory.");
			print.line("   Looking for /vendor/wheels, /config, and /app folders");
			print.line();
			print.yellowLine("   Run this command from your Wheels project root directory.");
			return;
		} else {
			print.greenLine("✅ Wheels application detected");
		}

		// Note: No Node.js required anymore!
		print.greenLine("✅ Using native CFML MCP server (no Node.js required)");

		// Detect or use provided port
		var serverPort = 0;

		if (!isNull(arguments.port)) {
			serverPort = arguments.port;
			print.line("Using specified port: " & serverPort);
		} else {
			print.line("Detecting Wheels server port...");

			// Use CommandBox serverService to get server info
			try {
				var cwd = getCWD();
				var serverInfo = {};

				// Try current directory first
				serverInfo = serverService.getServerInfoByWebroot(cwd);

				// If not found, try with /public subdirectory (common Wheels setup)
				if (serverInfo.isEmpty() && directoryExists(cwd & "/public")) {
					serverInfo = serverService.getServerInfoByWebroot(cwd & "/public");
				}

				// If still not found, try parent directory (in case we're in /public)
				if (serverInfo.isEmpty() && getFileFromPath(cwd) == "public") {
					var parentDir = getDirectoryFromPath(cwd.substring(1, cwd.length() - 1));
					serverInfo = serverService.getServerInfoByWebroot(parentDir);
				}

				if (!serverInfo.isEmpty()) {
					// Check if server is running
					if (serverInfo.status == "running") {
						// Get the port from the running server
						if (structKeyExists(serverInfo, "port")) {
							serverPort = serverInfo.port;
							print.greenLine("✅ Detected running server on port " & serverPort);
						} else if (structKeyExists(serverInfo, "web") &&
								   structKeyExists(serverInfo.web, "http") &&
								   structKeyExists(serverInfo.web.http, "port")) {
							serverPort = serverInfo.web.http.port;
							print.greenLine("✅ Detected running server on port " & serverPort);
						}
					} else if (serverInfo.status == "stopped") {
						// Server exists but is stopped
						print.yellowLine("⚠️  Server is configured but not running");

						// Try to get configured port even if stopped
						if (structKeyExists(serverInfo, "port")) {
							serverPort = serverInfo.port;
							print.line("   Using configured port: " & serverPort);
						}
					}
				}
			} catch (any e) {
				// Fallback if serverService fails
				print.yellowLine("⚠️  Could not detect server via CommandBox service");
			}
		}

		// If no server detected and auto-start enabled, try to start server
		if (serverPort == 0 && !arguments.noAutoStart) {
			print.line("No running server detected. Attempting to start server...");

			try {
				// Start the server using serverService
				var serverInfo = serverService.start(
					name = "",  // Use default name for current directory
					directory = getCWD(),
					saveSettings = true
				);

				sleep(3000); // Wait for server to fully start

				// Get the server info again after starting
				serverInfo = serverService.getServerInfoByWebroot(getCWD());

				if (!serverInfo.isEmpty() && serverInfo.status == "running") {
					if (structKeyExists(serverInfo, "port")) {
						serverPort = serverInfo.port;
						print.greenLine("✅ Started server on port " & serverPort);
					}
				}
			} catch (any e) {
				print.yellowLine("⚠️  Could not start server automatically: " & e.message);
			}
		}

		if (serverPort == 0) {
			print.yellowLine("⚠️  Could not detect server port.");
			print.line();
			print.line("Options:");
			print.indentedLine("1. Start your server: wheels server start");
			print.indentedLine("2. Specify port manually: wheels mcp setup --port=60000");
			print.indentedLine("3. Run with --noAutoStart to disable server auto-start");
			print.line();

			// Ask for port
			var userPort = ask("Enter your Wheels server port (or press Enter to use 60000): ");
			serverPort = len(trim(userPort)) ? userPort : 60000;
		}
		print.line();

		// Configure MCP project file
		print.boldLine("Configuring MCP Integration...");

		try {
			var mcpConfigPath = getCWD() & "/.mcp.json";
			var mcpConfig = {};
			var configUpdated = false;

			// Read existing configuration if it exists
			if (fileExists(mcpConfigPath) && !arguments.force) {
				try {
					mcpConfig = deserializeJSON(fileRead(mcpConfigPath));
					print.line("Found existing .mcp.json, merging configuration...");
				} catch (any e) {
					print.yellowLine("⚠️  Existing .mcp.json has invalid JSON, creating new configuration");
					mcpConfig = {};
				}
			}

			// Ensure mcpServers structure exists
			if (!structKeyExists(mcpConfig, "mcpServers")) {
				mcpConfig.mcpServers = {};
			}

			// Add/update Wheels MCP server if not present or force flag is set
			if (!structKeyExists(mcpConfig.mcpServers, "wheels") || arguments.force) {
				mcpConfig.mcpServers.wheels = {
					"type": "http",
					"url": "http://localhost:" & serverPort & "/wheels/mcp"
				};
				configUpdated = true;
				print.greenLine("✅ Added Wheels MCP server configuration");
			} else {
				print.line("Wheels MCP server already configured");
			}

			// Add Browser MCP server if requested and not present
			if (arguments.browserMcp && (!structKeyExists(mcpConfig.mcpServers, "browsermcp") || arguments.force)) {
				mcpConfig.mcpServers.browsermcp = {
					"command": "npx",
					"args": ["@browsermcp/mcp@latest"]
				};
				configUpdated = true;
				print.greenLine("✅ Added Browser MCP server configuration");
			} else if (arguments.browserMcp) {
				print.line("Browser MCP server already configured");
			}

			// Write configuration file if updated or new
			if (configUpdated || !fileExists(mcpConfigPath)) {
				fileWrite(mcpConfigPath, serializeJSON(mcpConfig));
				if (fileExists(mcpConfigPath) && configUpdated) {
					print.greenLine("✅ Updated .mcp.json with new MCP servers");
				} else {
					print.greenLine("✅ Created .mcp.json for project-level configuration");
				}
			}

			print.greenLine("✅ MCP configuration completed");
		} catch (any e) {
			print.redLine("❌ Configuration failed: " & e.message);
			return;
		}
		print.line();

		// Detect IDEs
		print.boldLine("Detecting AI IDEs...");
		var detectedIDEs = {};
		var ideList = [];

		// Check for IDE configuration directories
		var homeDir = createObject("java", "java.lang.System").getProperty("user.home");

		// Claude Code
		var claudeDir = homeDir & "/.claude";
		if (directoryExists(claudeDir)) {
			detectedIDEs.claude = true;
			arrayAppend(ideList, "claude");
		}

		// Cursor
		var cursorDir = homeDir & "/.cursor";
		if (directoryExists(cursorDir)) {
			detectedIDEs.cursor = true;
			arrayAppend(ideList, "cursor");
		}

		// Continue
		var continueDir = homeDir & "/.continue";
		if (directoryExists(continueDir)) {
			detectedIDEs.continue = true;
			arrayAppend(ideList, "continue");
		}

		// Windsurf
		var windsurfDir = homeDir & "/.windsurf";
		if (directoryExists(windsurfDir)) {
			detectedIDEs.windsurf = true;
			arrayAppend(ideList, "windsurf");
		}

		// OpenCode
		var opencodeDir = homeDir & "/.opencode";
		if (directoryExists(opencodeDir)) {
			detectedIDEs.opencode = true;
			arrayAppend(ideList, "opencode");
		}

		if (arrayLen(ideList) == 0) {
			print.yellowLine("⚠️  No AI IDE configuration folders detected.");
			print.line("   You can still configure an IDE manually.");
		} else {
			print.line("Detected IDE folders:");
			for (var detectedIDE in ideList) {
				print.indentedGreenLine("• " & uCase(left(detectedIDE, 1)) & mid(detectedIDE, 2, len(detectedIDE)));
			}
		}
		print.line();

		// Configure IDEs
		var idesToConfigure = [];

		if (!isNull(arguments.ide)) {
			// Specific IDE requested
			idesToConfigure = [arguments.ide];
		} else if (arguments.all) {
			// Configure all detected IDEs
			idesToConfigure = ideList;
		} else if (arrayLen(ideList) > 0) {
			// Ask which IDEs to configure
			print.line("Which IDEs would you like to configure?");
			print.indentedLine("1. All detected IDEs");

			var i = 2;
			for (var availableIDE in ideList) {
				print.indentedLine(i & ". " & uCase(left(availableIDE, 1)) & mid(availableIDE, 2, len(availableIDE)));
				i++;
			}
			print.indentedLine(i & ". Skip IDE configuration");
			print.line();

			var choice = ask("Enter your choice (1-" & i & "): ");

			if (choice == "1") {
				idesToConfigure = ideList;
			} else if (choice == toString(i)) {
				// Skip
				idesToConfigure = [];
			} else if (isNumeric(choice) && choice > 1 && choice < i) {
				idesToConfigure = [ideList[choice - 1]];
			}
		}

		// Configure selected IDEs
		if (arrayLen(idesToConfigure) > 0) {
			print.boldLine("Configuring IDEs...");

			for (var ideToConfig in idesToConfigure) {
				var configured = false;

				try {
					switch (ideToConfig) {
						case "claude":
							configured = configureClaudeCode(serverPort, arguments.force, arguments.browserMcp);
							break;
						case "cursor":
							configured = configureCursor(serverPort, arguments.force, arguments.browserMcp);
							break;
						case "continue":
							configured = configureContinue(serverPort, arguments.force, arguments.browserMcp);
							break;
						case "windsurf":
							configured = configureWindsurf(serverPort, arguments.force, arguments.browserMcp);
							break;
						case "opencode":
							configured = configureOpenCode(serverPort, arguments.force, arguments.browserMcp);
							break;
					}

					if (configured) {
						print.greenLine("✅ Configured " & uCase(left(ideToConfig, 1)) & mid(ideToConfig, 2, len(ideToConfig)));
					} else {
						print.yellowLine("⚠️  " & uCase(left(ideToConfig, 1)) & mid(ideToConfig, 2, len(ideToConfig)) & " already configured (use --force to overwrite)");
					}
				} catch (any e) {
					print.redLine("❌ Failed to configure " & ideToConfig & ": " & e.message);
				}
			}
			print.line();
		}

		// Summary
		print.boldGreenLine("✨ MCP Integration Setup Complete!");
		print.line();
		print.boldLine("Configuration Summary:");
		print.indentedLine("Wheels MCP Endpoint: http://localhost:" & serverPort & "/wheels/mcp");
		print.indentedLine("Server Type: Native CFML (no Node.js required)");

		if (arguments.browserMcp) {
			print.indentedLine("Browser MCP: @browsermcp/mcp@latest (via npx)");
		}

		if (arrayLen(idesToConfigure) > 0) {
			print.indentedLine("Configured IDEs: " & arrayToList(idesToConfigure, ", "));
		}
		print.line();

		print.boldLine("Next Steps:");
		print.indentedLine("1. Ensure your Wheels server is running on port " & serverPort);
		print.indentedLine("2. Restart your AI IDE to connect to the MCP server");
		print.indentedLine("3. Test the connection: wheels mcp test");
		print.line();

		print.boldLine("Available MCP Commands:");
		print.indentedLine("wheels mcp status  - Check MCP configuration");
		print.indentedLine("wheels mcp test    - Test MCP connection");
		print.indentedLine("wheels mcp remove  - Remove MCP integration");
		print.line();

		print.yellowLine("💡 The MCP integration provides AI assistants with:");
		print.indentedLine("• Real-time access to your Wheels project structure");
		print.indentedLine("• Complete API documentation and guides");
		print.indentedLine("• Ability to generate models, controllers, and migrations");
		print.indentedLine("• Direct execution of tests and server commands");
		print.indentedLine("• Project analysis and validation tools");

		if (arguments.browserMcp) {
			print.indentedLine("• Browser automation capabilities (via Browser MCP)");
		}
		print.line();
	}

	private function configureClaudeCode(required numeric port, required boolean force, boolean browserMcp = false) {
		var homeDir = createObject("java", "java.lang.System").getProperty("user.home");
		var configDir = homeDir & "/.config/claude";
		var configFile = configDir & "/claude_desktop_config.json";

		if (!directoryExists(configDir)) {
			directoryCreate(configDir, true);
		}

		var config = {};
		var configUpdated = false;

		if (fileExists(configFile) && !arguments.force) {
			try {
				config = deserializeJSON(fileRead(configFile));
			} catch (any e) {
				// Invalid JSON, start fresh
				config = {};
			}
		}

		if (!structKeyExists(config, "mcpServers")) {
			config.mcpServers = {};
		}

		// Add/update Wheels MCP server
		if (!structKeyExists(config.mcpServers, "wheels") || arguments.force) {
			config.mcpServers.wheels = {
				"type": "http",
				"url": "http://localhost:" & arguments.port & "/wheels/mcp"
			};
			configUpdated = true;
		}

		// Add Browser MCP server if requested and not already present
		if (arguments.browserMcp && (!structKeyExists(config.mcpServers, "browsermcp") || arguments.force)) {
			config.mcpServers.browsermcp = {
				"command": "npx",
				"args": ["@browsermcp/mcp@latest"]
			};
			configUpdated = true;
		}

		if (configUpdated) {
			fileWrite(configFile, serializeJSON(config));
			return true;
		}

		return false;
	}

	private function configureCursor(required numeric port, required boolean force, boolean browserMcp = false) {
		var homeDir = createObject("java", "java.lang.System").getProperty("user.home");
		var configDir = homeDir & "/.cursor";
		var configFile = configDir & "/mcp_servers.json";

		if (!directoryExists(configDir)) {
			directoryCreate(configDir, true);
		}

		var config = {};
		var configUpdated = false;

		if (fileExists(configFile) && !arguments.force) {
			try {
				config = deserializeJSON(fileRead(configFile));
			} catch (any e) {
				config = {};
			}
		}

		if (!structKeyExists(config, "mcpServers")) {
			config.mcpServers = {};
		}

		// Add/update Wheels MCP server
		if (!structKeyExists(config.mcpServers, "wheels") || arguments.force) {
			config.mcpServers.wheels = {
				"type": "http",
				"url": "http://localhost:" & arguments.port & "/wheels/mcp"
			};
			configUpdated = true;
		}

		// Add Browser MCP server if requested and not already present
		if (arguments.browserMcp && (!structKeyExists(config.mcpServers, "browsermcp") || arguments.force)) {
			config.mcpServers.browsermcp = {
				"command": "npx",
				"args": ["@browsermcp/mcp@latest"]
			};
			configUpdated = true;
		}

		if (configUpdated) {
			fileWrite(configFile, serializeJSON(config));
			return true;
		}

		return false;
	}

	private function configureContinue(required numeric port, required boolean force, boolean browserMcp = false) {
		var homeDir = createObject("java", "java.lang.System").getProperty("user.home");
		var configDir = homeDir & "/.continue";
		var configFile = configDir & "/config.json";

		if (!directoryExists(configDir)) {
			directoryCreate(configDir, true);
		}

		var config = {};
		var configUpdated = false;

		if (fileExists(configFile) && !arguments.force) {
			try {
				config = deserializeJSON(fileRead(configFile));
			} catch (any e) {
				config = {};
			}
		}

		if (!structKeyExists(config, "experimental")) {
			config.experimental = {};
		}

		if (!structKeyExists(config.experimental, "modelContextProtocol")) {
			config.experimental.modelContextProtocol = {};
		}

		// Add/update Wheels MCP server
		if (!structKeyExists(config.experimental.modelContextProtocol, "wheels") || arguments.force) {
			config.experimental.modelContextProtocol.wheels = {
				"type": "http",
				"url": "http://localhost:" & arguments.port & "/wheels/mcp"
			};
			configUpdated = true;
		}

		// Add Browser MCP server if requested and not already present
		if (arguments.browserMcp && (!structKeyExists(config.experimental.modelContextProtocol, "browsermcp") || arguments.force)) {
			config.experimental.modelContextProtocol.browsermcp = {
				"command": "npx",
				"args": ["@browsermcp/mcp@latest"]
			};
			configUpdated = true;
		}

		if (configUpdated) {
			fileWrite(configFile, serializeJSON(config));
			return true;
		}

		return false;
	}

	private function configureWindsurf(required numeric port, required boolean force, boolean browserMcp = false) {
		var homeDir = createObject("java", "java.lang.System").getProperty("user.home");
		var configDir = homeDir & "/.windsurf";
		var configFile = configDir & "/mcp_servers.json";

		if (!directoryExists(configDir)) {
			directoryCreate(configDir, true);
		}

		var config = {};
		var configUpdated = false;

		if (fileExists(configFile) && !arguments.force) {
			try {
				config = deserializeJSON(fileRead(configFile));
			} catch (any e) {
				config = {};
			}
		}

		if (!structKeyExists(config, "mcpServers")) {
			config.mcpServers = {};
		}

		// Add/update Wheels MCP server
		if (!structKeyExists(config.mcpServers, "wheels") || arguments.force) {
			config.mcpServers.wheels = {
				"type": "http",
				"url": "http://localhost:" & arguments.port & "/wheels/mcp"
			};
			configUpdated = true;
		}

		// Add Browser MCP server if requested and not already present
		if (arguments.browserMcp && (!structKeyExists(config.mcpServers, "browsermcp") || arguments.force)) {
			config.mcpServers.browsermcp = {
				"command": "npx",
				"args": ["@browsermcp/mcp@latest"]
			};
			configUpdated = true;
		}

		if (configUpdated) {
			fileWrite(configFile, serializeJSON(config));
			return true;
		}

		return false;
	}

	private function configureOpenCode(required numeric port, required boolean force, boolean browserMcp = false) {
		var homeDir = createObject("java", "java.lang.System").getProperty("user.home");
		var configDir = homeDir & "/.opencode";
		var configFile = configDir & "/opencode.json";

		if (!directoryExists(configDir)) {
			directoryCreate(configDir, true);
		}

		var config = {};
		var configUpdated = false;

		if (fileExists(configFile) && !arguments.force) {
			try {
				config = deserializeJSON(fileRead(configFile));
			} catch (any e) {
				config = {};
			}
		}

		if (!structKeyExists(config, "mcp")) {
			config.mcp = {};
		}

		// Add/update Wheels MCP server
		if (!structKeyExists(config.mcp, "wheels") || arguments.force) {
			config.mcp.wheels = {
				"type": "remote",
				"url": "http://localhost:" & arguments.port & "/wheels/mcp",
				"enabled": true
			};
			configUpdated = true;
		}

		// Add Browser MCP server if requested and not already present
		if (arguments.browserMcp && (!structKeyExists(config.mcp, "browsermcp") || arguments.force)) {
			config.mcp.browsermcp = {
				"type": "local",
				"command": ["npx", "@browsermcp/mcp@latest"],
				"enabled": true
			};
			configUpdated = true;
		}

		if (configUpdated) {
			fileWrite(configFile, serializeJSON(config));
			return true;
		}

		return false;
	}


}