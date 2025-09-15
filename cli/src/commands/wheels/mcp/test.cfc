/**
 * Test MCP (Model Context Protocol) connection and configuration
 * Verifies that your MCP setup is working correctly
 *
 * Examples:
 * {code:bash}
 * wheels mcp test
 * wheels mcp test --verbose
 * {code}
 **/
component extends="../base" {

	property name="mcpService" inject="MCPService@wheels-cli";

	/**
	 * @verbose Show detailed test output
	 **/
	function run(
		boolean verbose = false
	) {
		print.line();
		print.boldYellowLine("🧪 Testing MCP Integration");
		print.line("=" .repeatString(40));
		print.line();

		var status = mcpService.getMCPStatus();
		var allTestsPassed = true;

		// Test 1: Check if MCP server file exists
		print.line("1. Checking MCP server file...");
		if (status.serverFile) {
			print.greenLine("   ✅ mcp-server.js found");
		} else {
			print.redLine("   ❌ mcp-server.js not found");
			print.yellowLine("      Run 'wheels mcp setup' to install");
			allTestsPassed = false;
		}
		print.line();

		// Test 2: Check dependencies
		print.line("2. Checking dependencies...");
		if (status.dependencies) {
			print.greenLine("   ✅ MCP SDK installed");
		} else {
			print.redLine("   ❌ MCP SDK not installed");
			print.yellowLine("      Run 'npm install' to install dependencies");
			allTestsPassed = false;
		}
		print.line();

		// Test 3: Check Node.js
		print.line("3. Checking Node.js...");
		if (len(status.nodeVersion)) {
			print.greenLine("   ✅ Node.js " & status.nodeVersion);
			if (arguments.verbose) {
				print.line("      npm " & status.npmVersion);
			}
		} else {
			print.redLine("   ❌ Node.js not found");
			print.yellowLine("      Install Node.js from https://nodejs.org/");
			allTestsPassed = false;
		}
		print.line();

		// Test 4: Check server port
		print.line("4. Checking Wheels server...");
		if (status.port > 0) {
			print.greenLine("   ✅ Server configured on port " & status.port);
		} else {
			print.yellowLine("   ⚠️  Server port not detected");
			print.yellowLine("      Make sure your Wheels server is running");
			// This is a warning, not a failure
		}
		print.line();

		// Test 5: Check IDE configurations
		print.line("5. Checking IDE configurations...");
		if (status.configured && arrayLen(status.configuredIDEs) > 0) {
			print.greenLine("   ✅ Configured for: " & arrayToList(status.configuredIDEs, ", "));
		} else {
			print.yellowLine("   ⚠️  No IDEs configured");
			print.yellowLine("      Run 'wheels mcp setup' to configure your IDE");
			// This is a warning, not a failure
		}
		print.line();

		// Test 6: Try to validate MCP server can start
		if (status.serverFile && status.dependencies) {
			print.line("6. Testing MCP server startup...");

			// Create a simple test by checking if the server file is valid JavaScript
			try {
				var testCommand = "!node -c mcp-server.js";
				shell.run(command=testCommand, timeout=5);
				print.greenLine("   ✅ MCP server syntax valid");
			} catch (any e) {
				print.redLine("   ❌ MCP server has syntax errors");
				if (arguments.verbose) {
					print.redLine("      " & e.message);
				}
				allTestsPassed = false;
			}
			print.line();
		}

		// Test 7: Check if Wheels dev server is accessible
		print.line("7. Testing Wheels dev server connection...");

		// Use the improved port detection to get the actual running server info
		var actualPort = mcpService.detectServerPort(false); // Don't auto-start during test

		if (actualPort > 0) {
			try {
				var http = new http();
				http.setMethod("GET");
				http.setUrl("http://localhost:#actualPort#/wheels/ai?mode=info");
				http.setTimeout(5);
				var result = http.send().getPrefix();

				if (result.statusCode contains "200") {
					print.greenLine("   ✅ Wheels dev server is accessible on port " & actualPort);
				} else {
					print.yellowLine("   ⚠️  Wheels dev server returned: " & result.statusCode & ". Status code unavailable.");
				}
			} catch (any e) {
				print.yellowLine("   ⚠️  Wheels dev server returned: Connection Failure. Status code unavailable.");
				if (arguments.verbose) {
					print.yellowLine("      Error: " & e.message);
					print.yellowLine("      URL tested: http://localhost:" & actualPort & "/wheels/ai?mode=info");
				}
			}
		} else {
			print.yellowLine("   ⚠️  No running Wheels server detected");
			print.yellowLine("      Start server with: wheels server start");
		}
		print.line();

		// Summary
		print.line("=" .repeatString(40));
		if (allTestsPassed) {
			print.boldGreenLine("✅ All tests passed!");
			print.line();
			print.greenLine("Your MCP integration is ready to use.");
			print.line("Restart your AI IDE to activate the MCP server.");
		} else {
			print.boldYellowLine("⚠️  Some tests failed");
			print.line();
			print.line("Fix the issues above and run 'wheels mcp test' again.");
		}
		print.line();

		// Verbose output
		if (arguments.verbose) {
			print.boldLine("Detailed Configuration:");
			print.line("Project Root: " & getCWD());
			print.line("MCP Server: " & (status.serverFile ? "Installed" : "Not installed"));
			print.line("Dependencies: " & (status.dependencies ? "Installed" : "Not installed"));
			print.line("Server Port: " & (status.port > 0 ? status.port : "Not detected"));
			print.line();

			print.boldLine("IDE Detection:");
			var ides = mcpService.detectIDEs();
			for (var ide in ides) {
				print.line(uCase(left(ide, 1)) & mid(ide, 2, len(ide)) & ": " & (ides[ide] ? "Detected" : "Not detected"));
			}
			print.line();

			print.boldLine("Available MCP Tools:");
			print.indentedLine("• wheels_generate - Generate models, controllers, migrations");
			print.indentedLine("• wheels_migrate - Run database migrations");
			print.indentedLine("• wheels_test - Execute tests");
			print.indentedLine("• wheels_server - Manage development server");
			print.indentedLine("• wheels_reload - Reload application");
			print.indentedLine("• wheels_info - Get system configuration");
			print.indentedLine("• wheels_routes - Inspect application routes");
			print.indentedLine("• wheels_plugins - List installed plugins");
			print.indentedLine("• wheels_test_status - Check test results");
			print.line();
		}
	}

}