/**
 * Show MCP (Model Context Protocol) configuration status
 * Displays current MCP setup and configuration details
 *
 * Examples:
 * {code:bash}
 * wheels mcp status
 * wheels mcp status --json
 * {code}
 **/
component extends="../base" {

	property name="mcpService" inject="MCPService@wheels-cli";

	/**
	 * @json Output status in JSON format
	 **/
	function run(
		boolean json = false
	) {
		var status = mcpService.getMCPStatus();

		if (arguments.json) {
			// Output JSON format
			print.line(serializeJSON(status));
			return;
		}

		// Human-readable output
		print.line();
		print.boldYellowLine("🤖 MCP Integration Status");
		print.line("=" .repeatString(50));
		print.line();

		// Installation Status
		print.boldLine("Installation:");
		if (status.installed) {
			print.greenLine("✅ MCP is installed and ready");
		} else {
			print.yellowLine("⚠️  MCP is not fully installed");
		}

		print.indentedLine("Server file: " & (status.serverFile ? "✅ Installed" : "❌ Not found"));
		print.indentedLine("Dependencies: " & (status.dependencies ? "✅ Installed" : "❌ Not installed"));
		print.line();

		// Node.js Information
		print.boldLine("Environment:");
		if (len(status.nodeVersion)) {
			print.indentedLine("Node.js: " & status.nodeVersion);
			print.indentedLine("npm: " & status.npmVersion);
		} else {
			print.indentedRedLine("Node.js: Not installed");
		}
		print.line();

		// Server Configuration
		print.boldLine("Server Configuration:");
		if (status.port > 0) {
			print.indentedLine("Port: " & status.port);
			print.indentedLine("URL: http://localhost:" & status.port);
		} else {
			print.indentedYellowLine("Port: Not detected");
			print.indentedLine("(Start your server or run 'wheels mcp setup --port=YOUR_PORT')");
		}
		print.line();

		// IDE Configuration
		print.boldLine("IDE Configuration:");
		if (status.configured && arrayLen(status.configuredIDEs) > 0) {
			print.greenLine("✅ Configured for " & arrayLen(status.configuredIDEs) & " IDE(s)");
			for (var ide in status.configuredIDEs) {
				print.indentedGreenLine("• " & ide);
			}
		} else {
			print.yellowLine("⚠️  No IDEs configured");
		}
		print.line();

		// IDE Detection
		print.boldLine("Detected IDE Folders:");
		var detectedCount = 0;
		for (var ide in status.ides) {
			if (status.ides[ide]) {
				detectedCount++;
				var ideName = uCase(left(ide, 1)) & mid(ide, 2, len(ide));

				// Check if this IDE is configured
				var isConfigured = false;
				if (arrayFindNoCase(status.configuredIDEs, ideName) ||
				    arrayFindNoCase(status.configuredIDEs, ideName & " Code")) {
					isConfigured = true;
				}

				if (isConfigured) {
					print.indentedGreenLine("• " & ideName & " (configured)");
				} else {
					print.indentedLine("• " & ideName & " (not configured)");
				}
			}
		}
		if (detectedCount == 0) {
			print.indentedLine("None detected");
		}
		print.line();

		// Project Information
		print.boldLine("Project:");
		print.indentedLine("Root: " & getCWD());
		print.indentedLine("Wheels App: " & (isWheelsApp() ? "✅ Yes" : "❌ No"));
		if (isWheelsApp()) {
			try {
				print.indentedLine("Wheels Version: " & $getWheelsVersion());
			} catch (any e) {
				// Version not available
			}
		}
		print.line();

		// Quick Actions
		if (!status.installed) {
			print.boldLine("Quick Actions:");
			print.indentedYellowLine("Run 'wheels mcp setup' to install MCP integration");
		} else if (!status.configured) {
			print.boldLine("Quick Actions:");
			print.indentedYellowLine("Run 'wheels mcp setup' to configure your IDE");
		} else {
			print.boldLine("Quick Actions:");
			print.indentedLine("wheels mcp test   - Test MCP connection");
			print.indentedLine("wheels mcp update - Update MCP server");
			print.indentedLine("wheels mcp remove - Remove MCP integration");
		}
		print.line();

		// MCP Tools Available
		if (status.installed && status.configured) {
			print.boldLine("Available MCP Tools (in your AI IDE):");
			print.indentedLine("• wheels_generate - Generate code");
			print.indentedLine("• wheels_migrate - Run migrations");
			print.indentedLine("• wheels_test - Execute tests");
			print.indentedLine("• wheels_server - Manage server");
			print.indentedLine("• wheels_info - Get system info");
			print.indentedLine("• wheels_routes - View routes");
			print.indentedLine("• wheels_plugins - List plugins");
		}
		print.line();
	}

}