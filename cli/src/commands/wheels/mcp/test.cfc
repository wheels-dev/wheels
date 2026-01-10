/**
 * Test MCP (Model Context Protocol) connection and configuration
 * Verifies that your native CFML MCP server is working correctly
 *
 * Examples:
 * {code:bash}
 * wheels mcp test
 * wheels mcp test --verbose
 * wheels mcp test --port=8080
 * {code}
 **/
component extends="../base" {

	property name="mcpService" inject="MCPService@wheels-cli";

	/**
	 * @verbose Show detailed test output
	 * @port Port number for Wheels server (auto-detected if not provided)
	 **/
	function run(
		boolean verbose = false,
		numeric port
	) {
		print.line();
		print.boldYellowLine("🧪 Testing MCP Integration");
		print.line("=" .repeatString(40));
		print.line();

		var allTestsPassed = true;
		var serverPort = 0;

		// Detect or use provided port
		if (!isNull(arguments.port)) {
			serverPort = arguments.port;
		} else {
			// Use the improved port detection to get the actual running server info
			serverPort = mcpService.detectServerPort(false); // Don't auto-start during test
		}

		// Test 1: Check if .mcp.json configuration exists
		print.line("1. Checking MCP configuration...");
		var mcpConfigPath = getCWD() & "/.mcp.json";
		if (fileExists(mcpConfigPath)) {
			try {
				var mcpConfig = deserializeJSON(fileRead(mcpConfigPath));
				if (structKeyExists(mcpConfig, "mcpServers") && structKeyExists(mcpConfig.mcpServers, "wheels")) {
					var wheelsConfig = mcpConfig.mcpServers.wheels;
					if (structKeyExists(wheelsConfig, "type") && wheelsConfig.type == "http") {
						print.greenLine("   ✅ .mcp.json configured for native MCP server");
						if (arguments.verbose) {
							print.line("      URL: " & wheelsConfig.url);
						}
					} else {
						print.yellowLine("   ⚠️  .mcp.json exists but not configured for HTTP transport");
						print.yellowLine("      Run 'wheels mcp setup --force' to update");
					}
				} else {
					print.yellowLine("   ⚠️  .mcp.json exists but missing wheels configuration");
				}
			} catch (any e) {
				print.redLine("   ❌ Invalid .mcp.json file");
				allTestsPassed = false;
			}
		} else {
			print.redLine("   ❌ .mcp.json not found");
			print.yellowLine("      Run 'wheels mcp setup' to configure");
			allTestsPassed = false;
		}
		print.line();

		// Test 2: Check Wheels server
		print.line("2. Checking Wheels server...");
		if (serverPort > 0) {
			print.greenLine("   ✅ Server detected on port " & serverPort);
		} else {
			print.yellowLine("   ⚠️  Server port not detected");
			print.yellowLine("      Make sure your Wheels server is running");
			print.yellowLine("      Or specify port: wheels mcp test --port=8080");
			// This is a warning, not a failure for now
			serverPort = 60000; // Use default for testing
		}
		print.line();

		// Test 3: Check IDE configurations
		print.line("3. Checking IDE configurations...");
		var status = mcpService.getMCPStatus();
		if (status.configured && arrayLen(status.configuredIDEs) > 0) {
			print.greenLine("   ✅ Configured for: " & arrayToList(status.configuredIDEs, ", "));
		} else {
			print.yellowLine("   ⚠️  No IDEs configured");
			print.yellowLine("      Run 'wheels mcp setup' to configure your IDE");
			// This is a warning, not a failure
		}
		print.line();

		// Test 4: Test MCP endpoint (SSE)
		print.line("4. Testing MCP SSE endpoint...");
		try {
			var http = new http();
			http.setMethod("GET");
			http.setUrl("http://localhost:#serverPort#/wheels/mcp");
			http.addParam(type="header", name="Accept", value="text/event-stream");
			http.setTimeout(5);
			var result = http.send().getPrefix();

			if (result.statusCode contains "200") {
				print.greenLine("   ✅ MCP SSE endpoint is accessible");
				if (arguments.verbose && structKeyExists(result, "Mcp-Session-Id")) {
					print.line("      Session ID: " & result["Mcp-Session-Id"]);
				}
			} else {
				print.redLine("   ❌ MCP SSE endpoint returned: " & result.statusCode);
				allTestsPassed = false;
			}
		} catch (any e) {
			print.redLine("   ❌ Could not connect to MCP endpoint");
			if (arguments.verbose) {
				print.redLine("      Error: " & e.message);
			}
			allTestsPassed = false;
		}
		print.line();

		// Test 5: Test MCP JSON-RPC
		print.line("5. Testing MCP JSON-RPC endpoint...");
		try {
			var http = new http();
			http.setMethod("POST");
			http.setUrl("http://localhost:#serverPort#/wheels/mcp");
			http.addParam(type="header", name="Content-Type", value="application/json");
			http.addParam(type="body", value='{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"0.1.0","capabilities":{}},"id":1}');
			http.setTimeout(5);
			var result = http.send();
			var responseBody = result.getPrefix().fileContent;

			if (result.getPrefix().statusCode contains "200") {
				try {
					var jsonResponse = deserializeJSON(responseBody);
					if (structKeyExists(jsonResponse, "result") && structKeyExists(jsonResponse.result, "serverInfo")) {
						print.greenLine("   ✅ MCP JSON-RPC working (" & jsonResponse.result.serverInfo.name & ")");
					} else {
						print.yellowLine("   ⚠️  MCP JSON-RPC response missing expected fields");
					}
				} catch (any je) {
					print.yellowLine("   ⚠️  MCP JSON-RPC returned invalid JSON");
				}
			} else {
				print.redLine("   ❌ MCP JSON-RPC endpoint returned: " & result.getPrefix().statusCode);
				allTestsPassed = false;
			}
		} catch (any e) {
			print.redLine("   ❌ Could not connect to MCP JSON-RPC endpoint");
			if (arguments.verbose) {
				print.redLine("      Error: " & e.message);
			}
			allTestsPassed = false;
		}
		print.line();

		// Test 6: Check if Wheels AI endpoint is accessible
		print.line("6. Testing Wheels AI endpoint...");
		try {
			var http = new http();
			http.setMethod("GET");
			http.setUrl("http://localhost:#serverPort#/wheels/ai?mode=info");
			http.setTimeout(5);
			var result = http.send().getPrefix();

			if (result.statusCode contains "200") {
				print.greenLine("   ✅ Wheels AI endpoint is accessible");
			} else {
				print.yellowLine("   ⚠️  Wheels AI endpoint returned: " & result.statusCode);
			}
		} catch (any e) {
			print.yellowLine("   ⚠️  Could not connect to Wheels AI endpoint");
			if (arguments.verbose) {
				print.yellowLine("      Error: " & e.message);
			}
		}
		print.line();

		// Summary
		print.line("=" .repeatString(40));
		if (allTestsPassed) {
			print.boldGreenLine("✅ All tests passed!");
			print.line();
			print.greenLine("Your native CFML MCP server is ready to use.");
			print.line("Restart your AI IDE to connect to the MCP server.");
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
			print.line("MCP Type: Native CFML (no Node.js required)");
			print.line("MCP Endpoint: http://localhost:" & serverPort & "/wheels/mcp");
			print.line("Server Port: " & serverPort);
			print.line();

			print.boldLine("IDE Detection:");
			var ides = mcpService.detectIDEs();
			for (var ide in ides) {
				print.line(uCase(left(ide, 1)) & mid(ide, 2, len(ide)) & ": " & (ides[ide] ? "Detected" : "Not detected"));
			}
			print.line();

			print.boldLine("Available MCP Tools:");
			print.indentedLine("• wheels_generate - Generate models, controllers, migrations");
			print.indentedLine("• wheels_analyze - Analyze project structure");
			print.indentedLine("• wheels_validate - Validate models and schema");
			print.indentedLine("• wheels_migrate - Run database migrations");
			print.indentedLine("• wheels_test - Execute tests");
			print.indentedLine("• wheels_server - Manage development server");
			print.indentedLine("• wheels_reload - Reload application");
			print.line();

			print.boldLine("Available MCP Resources:");
			print.indentedLine("• Documentation chunks (models, controllers, views, etc.)");
			print.indentedLine("• Project context and structure");
			print.indentedLine("• Routes, migrations, and plugins info");
			print.indentedLine("• Complete API reference and guides");
			print.line();
		}
	}

}