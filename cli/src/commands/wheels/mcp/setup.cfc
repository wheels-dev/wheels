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
 * wheels mcp setup --all
 * wheels mcp setup --force
 * {code}
 **/
component extends="../base" {

	/**
	 * @port Port number for Wheels server (auto-detected if not provided)
	 * @ide Specific IDE to configure (claude, cursor, continue, windsurf)
	 * @all Configure all detected IDEs
	 * @force Overwrite existing configuration
	 * @noAutoStart Don't automatically start server if not running
	 **/
	function run(
		numeric port,
		string ide,
		boolean all = false,
		boolean force = false,
		boolean noAutoStart = false
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

			// Try to detect running server
			var serverStatusResult = command("server status").params(getCWD()).run(returnOutput=true);
			var statusOutput = serverStatusResult;

			// Look for port in server status output (format: http://localhost:PORT or 127.0.0.1:PORT)
			var portPattern = "(?:localhost|127\.0\.0\.1):(\d+)";
			var portMatch = reFind(portPattern, statusOutput, 1, true);

			if (isStruct(portMatch) && structKeyExists(portMatch, "pos") && arrayLen(portMatch.pos) > 1 && portMatch.pos[2] > 0) {
				serverPort = mid(statusOutput, portMatch.pos[2], portMatch.len[2]);
				print.greenLine("✅ Detected server on port " & serverPort);
			}

			// If first pattern didn't work, try simpler pattern
			if (serverPort == 0) {
				var simplePattern = "127\.0\.0\.1:(\d+)";
				var simpleMatch = reFind(simplePattern, statusOutput, 1, true);

				if (isStruct(simpleMatch) && structKeyExists(simpleMatch, "pos") && arrayLen(simpleMatch.pos) > 1 && simpleMatch.pos[2] > 0) {
					serverPort = mid(statusOutput, simpleMatch.pos[2], simpleMatch.len[2]);
					print.greenLine("✅ Detected server on port " & serverPort);
				}
			}

			// If still no port, try to find any number after localhost or 127.0.0.1
			if (serverPort == 0) {
				if (findNoCase("localhost:", statusOutput) > 0) {
					var localhostPos = findNoCase("localhost:", statusOutput);
					var afterLocalhost = mid(statusOutput, localhostPos + 10, 10);

					var numberMatch = reFind("(\d+)", afterLocalhost, 1, true);
					if (isStruct(numberMatch) && structKeyExists(numberMatch, "pos") && arrayLen(numberMatch.pos) > 1 && numberMatch.pos[2] > 0) {
						serverPort = mid(afterLocalhost, numberMatch.pos[2], numberMatch.len[2]);
						print.greenLine("✅ Detected server on port " & serverPort);
					}
				} else if (findNoCase("127.0.0.1:", statusOutput) > 0) {
					var ipPos = findNoCase("127.0.0.1:", statusOutput);
					var afterIP = mid(statusOutput, ipPos + 10, 10);

					var numberMatch = reFind("(\d+)", afterIP, 1, true);
					if (isStruct(numberMatch) && structKeyExists(numberMatch, "pos") && arrayLen(numberMatch.pos) > 1 && numberMatch.pos[2] > 0) {
						serverPort = mid(afterIP, numberMatch.pos[2], numberMatch.len[2]);
						print.greenLine("✅ Detected server on port " & serverPort);
					}
				}
			}
		}

		// If no server detected and auto-start enabled, try to start server
		if (serverPort == 0 && !arguments.noAutoStart) {
			print.line("No running server detected. Attempting to start server...");

			try {
				command("server start").params(getCWD()).run();
				sleep(3000); // Wait for server to start

				// Try to detect port again
				var serverStatusResult = command("server status").params(getCWD()).run(returnOutput=true);
				var statusOutput = serverStatusResult;

				var portPattern = "(?:localhost|127\.0\.0\.1):(\d+)";
				var portMatch = reFind(portPattern, statusOutput, 1, true);

				if (isStruct(portMatch) && structKeyExists(portMatch, "pos") && arrayLen(portMatch.pos) > 1 && portMatch.pos[2] > 0) {
					serverPort = mid(statusOutput, portMatch.pos[2], portMatch.len[2]);
					print.greenLine("✅ Started server and detected port " & serverPort);
				}
			} catch (any e) {
				print.yellowLine("⚠️  Could not start server automatically");
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
			// Create .mcp.json for Claude Code project-level configuration
			// This points to the native CFML MCP server endpoint
			var mcpConfigPath = getCWD() & "/.mcp.json";
			if (!fileExists(mcpConfigPath) || arguments.force) {
				var mcpConfig = {
					"mcpServers": {
						"wheels": {
							"type": "http",
							"url": "http://localhost:" & serverPort & "/wheels/mcp"
						}
					}
				};
				fileWrite(mcpConfigPath, serializeJSON(mcpConfig));
				print.greenLine("✅ Created .mcp.json for project-level configuration");
			} else {
				print.yellowLine("⚠️  .mcp.json already exists (use --force to overwrite)");
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
							configured = configureClaudeCode(serverPort, arguments.force);
							break;
						case "cursor":
							configured = configureCursor(serverPort, arguments.force);
							break;
						case "continue":
							configured = configureContinue(serverPort, arguments.force);
							break;
						case "windsurf":
							configured = configureWindsurf(serverPort, arguments.force);
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
		print.indentedLine("MCP Endpoint: http://localhost:" & serverPort & "/wheels/mcp");
		print.indentedLine("Server Type: Native CFML (no Node.js required)");

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

		print.yellowLine("💡 The native MCP server provides AI assistants with:");
		print.indentedLine("• Real-time access to your Wheels project structure");
		print.indentedLine("• Complete API documentation and guides");
		print.indentedLine("• Ability to generate models, controllers, and migrations");
		print.indentedLine("• Direct execution of tests and server commands");
		print.indentedLine("• Project analysis and validation tools");
		print.line();
	}

	private function configureClaudeCode(required numeric port, required boolean force) {
		var homeDir = createObject("java", "java.lang.System").getProperty("user.home");
		var configDir = homeDir & "/.config/claude";
		var configFile = configDir & "/claude_desktop_config.json";

		if (!directoryExists(configDir)) {
			directoryCreate(configDir, true);
		}

		var config = {};
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

		if (!structKeyExists(config.mcpServers, "wheels") || arguments.force) {
			// Use HTTP transport for native CFML MCP server
			config.mcpServers.wheels = {
				"type": "http",
				"url": "http://localhost:" & arguments.port & "/wheels/mcp"
			};

			fileWrite(configFile, serializeJSON(config));
			return true;
		}

		return false;
	}

	private function configureCursor(required numeric port, required boolean force) {
		var homeDir = createObject("java", "java.lang.System").getProperty("user.home");
		var configDir = homeDir & "/.cursor";
		var configFile = configDir & "/mcp_servers.json";

		if (!directoryExists(configDir)) {
			directoryCreate(configDir, true);
		}

		var config = {};
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

		if (!structKeyExists(config.mcpServers, "wheels") || arguments.force) {
			// Use HTTP transport for native CFML MCP server
			config.mcpServers.wheels = {
				"type": "http",
				"url": "http://localhost:" & arguments.port & "/wheels/mcp"
			};

			fileWrite(configFile, serializeJSON(config));
			return true;
		}

		return false;
	}

	private function configureContinue(required numeric port, required boolean force) {
		var homeDir = createObject("java", "java.lang.System").getProperty("user.home");
		var configDir = homeDir & "/.continue";
		var configFile = configDir & "/config.json";

		if (!directoryExists(configDir)) {
			directoryCreate(configDir, true);
		}

		var config = {};
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

		if (!structKeyExists(config.experimental.modelContextProtocol, "wheels") || arguments.force) {
			// Use HTTP transport for native CFML MCP server
			config.experimental.modelContextProtocol.wheels = {
				"type": "http",
				"url": "http://localhost:" & arguments.port & "/wheels/mcp"
			};

			fileWrite(configFile, serializeJSON(config));
			return true;
		}

		return false;
	}

	private function configureWindsurf(required numeric port, required boolean force) {
		var homeDir = createObject("java", "java.lang.System").getProperty("user.home");
		var configDir = homeDir & "/.windsurf";
		var configFile = configDir & "/mcp_servers.json";

		if (!directoryExists(configDir)) {
			directoryCreate(configDir, true);
		}

		var config = {};
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

		if (!structKeyExists(config.mcpServers, "wheels") || arguments.force) {
			// Use HTTP transport for native CFML MCP server
			config.mcpServers.wheels = {
				"type": "http",
				"url": "http://localhost:" & arguments.port & "/wheels/mcp"
			};

			fileWrite(configFile, serializeJSON(config));
			return true;
		}

		return false;
	}


}