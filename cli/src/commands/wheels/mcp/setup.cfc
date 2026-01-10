/**
 * Set up MCP (Model Context Protocol) integration for AI IDE support
 * Creates .mcp.json and .opencode.json configuration files in your project root
 * Uses the native CFML MCP server built into Wheels (no Node.js required)
 *
 * Examples:
 * {code:bash}
 * wheels mcp setup
 * wheels mcp setup --port=8080
 * wheels mcp setup --force
 * {code}
 **/
component extends="../base" {

	/**
	 * @port Port number for Wheels server (auto-detected if not provided)
	 * @force Overwrite existing configuration files
	 * @noAutoStart Don't automatically start server if not running
	 **/
	function run(
		numeric port = 0,
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

		print.greenLine("✅ Using native CFML MCP server (no Node.js required)");

		// Detect or use provided port
		var serverPort = detectServerPort(arguments.port, arguments.noAutoStart);
		print.line();

		// Create configuration files
		print.boldLine("Creating MCP configuration files...");

		try {
			var projectRoot = getCWD();

			// Create .mcp.json
			var mcpConfigPath = projectRoot & "/.mcp.json";
			if (!fileExists(mcpConfigPath) || arguments.force) {
				var mcpTemplate = fileRead(expandPath("/wheels-cli/templates/McpConfig.json"));
				var mcpContent = replace(mcpTemplate, "{PORT}", serverPort, "ALL");
				fileWrite(mcpConfigPath, mcpContent);
				print.greenLine("✅ Created .mcp.json");
			} else {
				print.yellowLine("⚠️  .mcp.json already exists (use --force to overwrite)");
			}

			// Create .opencode.json
			var opencodeConfigPath = projectRoot & "/.opencode.json";
			if (!fileExists(opencodeConfigPath) || arguments.force) {
				var opencodeTemplate = fileRead(expandPath("/wheels-cli/templates/OpenCodeConfig.json"));
				var opencodeContent = replace(opencodeTemplate, "{PORT}", serverPort, "ALL");
				fileWrite(opencodeConfigPath, opencodeContent);
				print.greenLine("✅ Created .opencode.json");
			} else {
				print.yellowLine("⚠️  .opencode.json already exists (use --force to overwrite)");
			}

			print.greenLine("✅ MCP configuration files created");
		} catch (any e) {
			print.redLine("❌ Configuration failed: " & e.message);
			return;
		}
		print.line();

		// Summary
		print.boldGreenLine("✨ MCP Integration Setup Complete!");
		print.line();
		print.boldLine("Configuration Summary:");
		print.indentedLine("Wheels MCP Endpoint: http://localhost:" & serverPort & "/wheels/mcp");
		print.indentedLine("Server Type: Native CFML (no Node.js required)");
		print.indentedLine("Files Created: .mcp.json, .opencode.json");
		print.line();

		print.boldLine("Next Steps:");
		print.indentedLine("1. Ensure your Wheels server is running on port " & serverPort);
		print.indentedLine("2. Configure your AI IDE to use the generated configuration files");
		print.indentedLine("3. Test the connection: wheels mcp test");
		print.line();

		print.boldLine("Available MCP Commands:");
		print.indentedLine("wheels mcp status  - Check MCP configuration");
		print.indentedLine("wheels mcp test    - Test MCP connection");
		print.indentedLine("wheels mcp remove  - Remove MCP integration");
		print.line();

		print.yellowLine("💡 The generated files provide AI assistants with:");
		print.indentedLine("• Real-time access to your Wheels project structure");
		print.indentedLine("• Complete API documentation and guides");
		print.indentedLine("• Ability to generate models, controllers, and migrations");
		print.indentedLine("• Direct execution of tests and server commands");
		print.indentedLine("• Browser automation capabilities (via Browser MCP)");
		print.line();
	}

	private function detectServerPort(port, noAutoStart) {
		var serverPort = 0;

		if (!isNull(port) && port > 0) {
			serverPort = port;
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
		if (serverPort == 0 && !noAutoStart) {
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

		return serverPort;
	}

}