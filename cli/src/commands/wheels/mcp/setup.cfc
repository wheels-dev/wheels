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

	property name="mcpService" inject="MCPService@wheels-cli";
	property name="helpers" inject="helpers@wheels-cli";

	/**
	 * @port Port number for Wheels server (auto-detected if not provided)
	 * @ide Specific IDE to configure (claude, cursor, continue, windsurf)
	 * @all Configure all detected IDEs
	 * @force Overwrite existing configuration
	 * @skipNpm Skip npm install step
	 **/
	function run(
		numeric port,
		string ide,
		boolean all = false,
		boolean force = false,
		boolean skipNpm = false
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
		}

		// Check Node.js installation
		print.line("Checking prerequisites...");
		var nodeInfo = mcpService.checkNodeJS();

		if (!nodeInfo.installed) {
			print.redLine("❌ Node.js is not installed.");
			print.line();
			print.yellowLine("   MCP requires Node.js 16 or later.");
			print.line("   Install from: https://nodejs.org/");
			return;
		}

		print.greenLine("✅ Node.js " & nodeInfo.version & " detected");

		if (!nodeInfo.npmInstalled) {
			print.redLine("❌ npm is not installed.");
			print.line("   npm is required to install MCP dependencies.");
			return;
		}

		print.greenLine("✅ npm " & nodeInfo.npmVersion & " detected");
		print.line();

		// Detect or use provided port
		var serverPort = 0;

		if (!isNull(arguments.port)) {
			serverPort = arguments.port;
			print.line("Using specified port: " & serverPort);
		} else {
			print.line("Detecting Wheels server port...");
			serverPort = mcpService.detectServerPort();

			if (serverPort == 0) {
				print.yellowLine("⚠️  Could not detect server port.");
				print.line();
				print.line("Options:");
				print.indentedLine("1. Start your server: wheels server start");
				print.indentedLine("2. Specify port manually: wheels mcp setup --port=60000");
				print.line();

				// Ask for port
				var userPort = ask("Enter your Wheels server port (or press Enter to use 60000): ");
				serverPort = len(trim(userPort)) ? userPort : 60000;
			} else {
				print.greenLine("✅ Detected server on port " & serverPort);
			}
		}
		print.line();

		// Install MCP server files
		print.boldLine("Installing MCP Server...");

		var installResult = mcpService.installMCPServer(
			port = serverPort,
			force = arguments.force
		);

		if (!installResult.success) {
			print.redLine("❌ Installation failed:");
			for (var error in installResult.errors) {
				print.indentedRedLine(error);
			}
			return;
		}

		for (var message in installResult.messages) {
			print.greenLine(message);
		}
		print.line();

		// Detect IDEs
		print.boldLine("Detecting AI IDEs...");
		var detectedIDEs = mcpService.detectIDEs();
		var ideList = [];

		for (var ideName in detectedIDEs) {
			if (detectedIDEs[ideName]) {
				arrayAppend(ideList, ideName);
			}
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
				var configured = mcpService.configureIDE(
					ide = ideToConfig,
					port = serverPort,
					force = arguments.force
				);

				if (configured) {
					print.greenLine("✅ Configured " & uCase(left(ideToConfig, 1)) & mid(ideToConfig, 2, len(ideToConfig)));
				} else {
					if (!arguments.force) {
						print.yellowLine("⚠️  " & uCase(left(ideToConfig, 1)) & mid(ideToConfig, 2, len(ideToConfig)) & " already configured (use --force to overwrite)");
					} else {
						print.redLine("❌ Failed to configure " & ideToConfig);
					}
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

}