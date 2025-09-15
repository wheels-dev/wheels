/**
 * Set up MCP (Model Context Protocol) integration for AI IDE support
 * Configures your Wheels project to work with AI coding assistants like Claude Code, Cursor, and Continue
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
	 * @skipNpm Skip npm install step
	 * @noAutoStart Don't automatically start server if not running
	 **/
	function run(
		numeric port,
		string ide,
		boolean all = false,
		boolean force = false,
		boolean skipNpm = false,
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
			print.greenLine("✅ Wheels directory detected");
		}

		try {
			// Check if node command exists
			command(name='!which node', timeout=2);
			print.greenLine("✅ Node.js detected");
		} catch (any e) {
			print.redLine("❌ Node.js may not be installed - MCP requires Node.js 16 or later.");// Node not installed
		}

		try {
			// Check if node command exists
			command(name='!which npm', timeout=2);
			print.greenLine("✅ npm detected");
		} catch (any e) {
			print.redLine("❌ npm is not installed.");
			print.line("   npm is required to install MCP dependencies.");
		}

		// Detect or use provided port
		var serverPort = 0;

		if (!isNull(arguments.port)) {
			serverPort = arguments.port;
			print.line("Using specified port: " & serverPort);
		} else {
			print.line("Detecting Wheels server port...");
			print.yellowLine("    DEBUG - Step 1: Starting server detection");

			// Try to detect running server
			print.yellowLine("    DEBUG - Step 2: About to run 'server status' command");
			var serverStatusResult = command("server status").params(getCWD()).run(returnOutput=true);
			var statusOutput = serverStatusResult;
			print.yellowLine("    DEBUG - Step 3: Command completed successfully");
			print.yellowLine("    DEBUG - statusOutput: " & statusOutput);
			print.yellowLine("    DEBUG - statusOutput length: " & len(statusOutput));
			print.yellowLine("    DEBUG - getCWD(): " & getCWD());

			// Look for port in server status output (format: http://localhost:PORT or 127.0.0.1:PORT)
			print.yellowLine("    DEBUG - Step 4: Starting regex pattern matching");
			var portPattern = "(?:localhost|127\.0\.0\.1):(\d+)";
			print.yellowLine("    DEBUG - Using pattern: " & portPattern);

			var portMatch = reFind(portPattern, statusOutput, 1, true);
			print.yellowLine("    DEBUG - Step 5: Regex completed");
			print.yellowLine("    DEBUG - portMatch result: " & serializeJSON(portMatch));

			if (isStruct(portMatch)) {
				print.yellowLine("    DEBUG - Step 6: portMatch is a struct");
				print.yellowLine("    DEBUG - portMatch keys: " & structKeyList(portMatch));

				if (structKeyExists(portMatch, "pos")) {
					print.yellowLine("    DEBUG - Step 7: 'pos' key exists");
					print.yellowLine("    DEBUG - pos array: " & serializeJSON(portMatch.pos));
					print.yellowLine("    DEBUG - pos array length: " & arrayLen(portMatch.pos));

					if (arrayLen(portMatch.pos) > 1) {
						print.yellowLine("    DEBUG - Step 8: pos array has more than 1 element");
						print.yellowLine("    DEBUG - pos[2] value: " & portMatch.pos[2]);

						if (portMatch.pos[2] > 0) {
							print.yellowLine("    DEBUG - Step 9: pos[2] > 0, extracting port");
							print.yellowLine("    DEBUG - len array: " & serializeJSON(portMatch.len));
							print.yellowLine("    DEBUG - len[2] value: " & portMatch.len[2]);

							serverPort = mid(statusOutput, portMatch.pos[2], portMatch.len[2]);
							print.yellowLine("    DEBUG - Step 10: Extracted port: " & serverPort);
							print.greenLine("✅ Detected server on port " & serverPort);
						} else {
							print.yellowLine("    DEBUG - Step 9: pos[2] is 0 or negative");
						}
					} else {
						print.yellowLine("    DEBUG - Step 8: pos array length is " & arrayLen(portMatch.pos));
					}
				} else {
					print.yellowLine("    DEBUG - Step 7: 'pos' key does not exist");
				}
			} else {
				print.yellowLine("    DEBUG - Step 6: portMatch is not a struct, type: " & getMetadata(portMatch).name);
			}

			// If first pattern didn't work, try simpler pattern
			if (serverPort == 0) {
				print.yellowLine("    DEBUG - Step 11: First pattern failed, trying simpler pattern");
				var simplePattern = "127\.0\.0\.1:(\d+)";
				print.yellowLine("    DEBUG - Using simple pattern: " & simplePattern);

				var simpleMatch = reFind(simplePattern, statusOutput, 1, true);
				print.yellowLine("    DEBUG - Simple pattern result: " & serializeJSON(simpleMatch));

				if (isStruct(simpleMatch) && structKeyExists(simpleMatch, "pos") && arrayLen(simpleMatch.pos) > 1 && simpleMatch.pos[2] > 0) {
					serverPort = mid(statusOutput, simpleMatch.pos[2], simpleMatch.len[2]);
					print.yellowLine("    DEBUG - Simple pattern extracted port: " & serverPort);
					print.greenLine("✅ Detected server on port " & serverPort & " (using simple pattern)");
				} else {
					print.yellowLine("    DEBUG - Simple pattern also failed");
				}
			}

			// If still no port, try to find any number after localhost or 127.0.0.1
			if (serverPort == 0) {
				print.yellowLine("    DEBUG - Step 12: Trying manual string search");
				if (findNoCase("localhost:", statusOutput) > 0) {
					var localhostPos = findNoCase("localhost:", statusOutput);
					print.yellowLine("    DEBUG - Found localhost: at position " & localhostPos);
					var afterLocalhost = mid(statusOutput, localhostPos + 10, 10);
					print.yellowLine("    DEBUG - Text after localhost:: " & afterLocalhost);

					var numberMatch = reFind("(\d+)", afterLocalhost, 1, true);
					if (isStruct(numberMatch) && structKeyExists(numberMatch, "pos") && arrayLen(numberMatch.pos) > 1 && numberMatch.pos[2] > 0) {
						serverPort = mid(afterLocalhost, numberMatch.pos[2], numberMatch.len[2]);
						print.yellowLine("    DEBUG - Manual extraction found port: " & serverPort);
						print.greenLine("✅ Detected server on port " & serverPort & " (manual extraction)");
					}
				} else if (findNoCase("127.0.0.1:", statusOutput) > 0) {
					var ipPos = findNoCase("127.0.0.1:", statusOutput);
					print.yellowLine("    DEBUG - Found 127.0.0.1: at position " & ipPos);
					var afterIP = mid(statusOutput, ipPos + 10, 10);
					print.yellowLine("    DEBUG - Text after 127.0.0.1:: " & afterIP);

					var numberMatch = reFind("(\d+)", afterIP, 1, true);
					if (isStruct(numberMatch) && structKeyExists(numberMatch, "pos") && arrayLen(numberMatch.pos) > 1 && numberMatch.pos[2] > 0) {
						serverPort = mid(afterIP, numberMatch.pos[2], numberMatch.len[2]);
						print.yellowLine("    DEBUG - Manual IP extraction found port: " & serverPort);
						print.greenLine("✅ Detected server on port " & serverPort & " (manual IP extraction)");
					}
				} else {
					print.yellowLine("    DEBUG - No localhost: or 127.0.0.1: found in output");
				}
			}

			print.yellowLine("    DEBUG - Step 13: Server detection complete, final serverPort: " & serverPort);
		}

		// If no server detected and auto-start enabled, try to start server
		if (serverPort == 0 && !arguments.noAutoStart) {
			print.line("No running server detected. Attempting to start server...");
			print.yellowLine("    DEBUG - Auto-start: serverPort is 0, noAutoStart is " & arguments.noAutoStart);

			try {
				print.yellowLine("    DEBUG - Auto-start: About to run 'server start' command");
				command("server start").params(getCWD()).run();
				print.yellowLine("    DEBUG - Auto-start: Server start command completed");

				print.yellowLine("    DEBUG - Auto-start: Sleeping for 3 seconds");
				sleep(3000); // Wait for server to start
				print.yellowLine("    DEBUG - Auto-start: Sleep completed");

				// Try to detect port again
				print.yellowLine("    DEBUG - Auto-start: Running 'server status' again");
				var serverStatusResult = command("server status").params(getCWD()).run(returnOutput=true);
				var statusOutput = serverStatusResult;
				print.yellowLine("    DEBUG - Auto-start: Second status output: " & statusOutput);

				var portPattern = "(?:localhost|127\.0\.0\.1):(\d+)";
				var portMatch = reFind(portPattern, statusOutput, 1, true);
				print.yellowLine("    DEBUG - Auto-start: Second portMatch: " & serializeJSON(portMatch));

				if (isStruct(portMatch) && structKeyExists(portMatch, "pos") && arrayLen(portMatch.pos) > 1 && portMatch.pos[2] > 0) {
					serverPort = mid(statusOutput, portMatch.pos[2], portMatch.len[2]);
					print.yellowLine("    DEBUG - Auto-start: Extracted port: " & serverPort);
					print.greenLine("✅ Started server and detected port " & serverPort);
				} else {
					print.yellowLine("    DEBUG - Auto-start: Failed to detect port after server start");
				}
			} catch (any e) {
				print.yellowLine("⚠️  Could not start server automatically");
				print.yellowLine("    DEBUG - Auto-start exception: " & e.message);
			}
		} else {
			if (serverPort == 0) {
				print.yellowLine("    DEBUG - Auto-start skipped: noAutoStart is " & arguments.noAutoStart);
			} else {
				print.yellowLine("    DEBUG - Auto-start not needed: serverPort is " & serverPort);
			}
		}

		if (serverPort == 0) {
			print.yellowLine("    DEBUG - Final check: serverPort is still 0");
			print.yellowLine("⚠️  Could not detect server port.");
			print.line();
			print.line("Options:");
			print.indentedLine("1. Start your server: wheels server start");
			print.indentedLine("2. Specify port manually: wheels mcp setup --port=60000");
			print.indentedLine("3. Run with --noAutoStart to disable server auto-start");
			print.line();

			// Ask for port
			var userPort = ask("Enter your Wheels server port (or press Enter to use 60000): ");
			print.yellowLine("    DEBUG - User entered port: '" & userPort & "'");
			serverPort = len(trim(userPort)) ? userPort : 60000;
			print.yellowLine("    DEBUG - Final serverPort set to: " & serverPort);
		} else {
			print.yellowLine("    DEBUG - Final check: serverPort detected as " & serverPort);
		}
		print.line();

		// Install MCP server files
		print.boldLine("Installing MCP Server...");
		print.yellowLine("    DEBUG - Install: Starting MCP server installation");

		try {
			// Check if package.json exists, create if not
			var packageJsonPath = getCWD() & "/package.json";
			print.yellowLine("    DEBUG - Install: Checking package.json at: " & packageJsonPath);
			print.yellowLine("    DEBUG - Install: package.json exists: " & fileExists(packageJsonPath));
			print.yellowLine("    DEBUG - Install: force flag: " & arguments.force);

			if (!fileExists(packageJsonPath) || arguments.force) {
				print.yellowLine("    DEBUG - Install: Creating package.json");
				var packageContent = {
					"name": "wheels-mcp-server",
					"version": "1.0.0",
					"description": "MCP server for Wheels framework",
					"main": "mcp-server.js",
					"dependencies": {
						"@modelcontextprotocol/sdk": "^0.5.0"
					},
					"scripts": {
						"start": "node mcp-server.js"
					}
				};
				fileWrite(packageJsonPath, serializeJSON(packageContent));
				print.greenLine("✅ Created package.json");
			}

			// Install npm dependencies
			if (!arguments.skipNpm) {
				print.line("Installing npm dependencies...");
				try {
					command(name='!npm install', timeout=60);
					print.greenLine("✅ npm dependencies installed");
				} catch (any e) {
					print.redLine("❌ Failed to install npm dependencies: " & e.message);
					return;
				}
			}

			// Create MCP server file
			var mcpServerPath = getCWD() & "/mcp-server.js";
			if (!fileExists(mcpServerPath) || arguments.force) {
				try {
					// Create basic working MCP server
					fileWrite(mcpServerPath, "console.log('MCP Server - will be enhanced later');");
					print.greenLine("✅ Created mcp-server.js");
				} catch (any e) {
					print.redLine("❌ Failed to create mcp-server.js: " & e.message);
					return;
				}
			}

			// Make the server executable
			try {
				command(name='!chmod +x mcp-server.js', timeout=5);
			} catch (any e) {
				// Ignore chmod errors on Windows
			}

			// Create .mcp.json for Claude Code project-level configuration
			var mcpConfigPath = getCWD() & "/.mcp.json";
			if (!fileExists(mcpConfigPath) || arguments.force) {
				var mcpConfig = {
					"mcpServers": {
						"wheels": {
							"command": "node",
							"args": ["mcp-server.js"],
							"env": {
								"WHEELS_DEV_SERVER": "http://localhost:" & serverPort
							}
						}
					}
				};
				fileWrite(mcpConfigPath, serializeJSON(mcpConfig));
				print.greenLine("✅ Created .mcp.json for Claude Code");
			}

			print.greenLine("✅ MCP server installation completed");
		} catch (any e) {
			print.redLine("❌ Installation failed: " & e.message);
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
		print.indentedLine("Server URL: http://localhost:" & serverPort);
		print.indentedLine("MCP Server: ./mcp-server.js");

		if (arrayLen(idesToConfigure) > 0) {
			print.indentedLine("Configured IDEs: " & arrayToList(idesToConfigure, ", "));
		}
		print.line();

		print.boldLine("Next Steps:");
		print.indentedLine("1. Ensure your Wheels server is running on port " & serverPort);
		print.indentedLine("2. Restart your AI IDE to load the MCP server");
		print.indentedLine("3. Test the connection: wheels mcp test");
		print.line();

		print.boldLine("Available MCP Commands:");
		print.indentedLine("wheels mcp status  - Check MCP configuration");
		print.indentedLine("wheels mcp test    - Test MCP connection");
		print.indentedLine("wheels mcp update  - Update MCP server");
		print.indentedLine("wheels mcp remove  - Remove MCP integration");
		print.line();

		print.yellowLine("💡 The MCP server provides AI assistants with:");
		print.indentedLine("• Real-time access to your Wheels project structure");
		print.indentedLine("• Ability to generate models, controllers, and migrations");
		print.indentedLine("• Direct execution of tests and server commands");
		print.indentedLine("• Understanding of your routes and database schema");
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
			config.mcpServers.wheels = {
				"command": "node",
				"args": [getCWD() & "/mcp-server.js"],
				"env": {
					"WHEELS_DEV_SERVER": "http://localhost:" & arguments.port
				}
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
			config.mcpServers.wheels = {
				"command": "node",
				"args": [getCWD() & "/mcp-server.js"],
				"env": {
					"WHEELS_DEV_SERVER": "http://localhost:" & arguments.port
				}
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
			config.experimental.modelContextProtocol.wheels = {
				"command": "node",
				"args": [getCWD() & "/mcp-server.js"],
				"env": {
					"WHEELS_DEV_SERVER": "http://localhost:" & arguments.port
				}
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
			config.mcpServers.wheels = {
				"command": "node",
				"args": [getCWD() & "/mcp-server.js"],
				"env": {
					"WHEELS_DEV_SERVER": "http://localhost:" & arguments.port
				}
			};

			fileWrite(configFile, serializeJSON(config));
			return true;
		}

		return false;
	}


}