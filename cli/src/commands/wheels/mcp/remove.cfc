/**
 * Remove MCP (Model Context Protocol) integration
 * Removes MCP configuration files from your project and IDEs
 *
 * Examples:
 * {code:bash}
 * wheels mcp remove
 * wheels mcp remove --confirm
 * {code}
 **/
component extends="../base" {

	property name="mcpService" inject="MCPService@wheels-cli";

	/**
	 * @confirm Skip confirmation prompt
	 **/
	function run(
		boolean confirm = false
	) {
		print.line();
		print.boldYellowLine("🗑️  Remove MCP Integration");
		print.line("=" .repeatString(40));
		print.line();

		// Check current status
		var status = mcpService.getMCPStatus();

		// Check for .mcp.json project configuration
		var mcpConfigPath = getCWD() & "/.mcp.json";
		var hasMcpJson = fileExists(mcpConfigPath);

		if (!hasMcpJson && !status.configured) {
			print.yellowLine("MCP integration is not configured.");
			print.line();
			return;
		}

		// Show what will be removed
		print.boldLine("This will remove:");
		if (hasMcpJson) {
			print.indentedLine("• .mcp.json (project configuration)");
		}
		if (status.configured && arrayLen(status.configuredIDEs) > 0) {
			print.indentedLine("• IDE configurations for: " & arrayToList(status.configuredIDEs, ", "));
		}
		print.line();

		print.boldLine("This will preserve:");
		print.indentedLine("• Your Wheels application code");
		print.indentedLine("• MCP server endpoint (built into Wheels dev server)");
		print.indentedLine("• All project files and configurations");
		print.line();

		// Confirm removal
		if (!arguments.confirm) {
			var response = ask("Are you sure you want to remove MCP integration? (y/N): ");
			if (lCase(trim(response)) != "y") {
				print.yellowLine("Removal cancelled.");
				print.line();
				return;
			}
		}

		// Perform removal
		print.line("Removing MCP configuration...");
		print.line();

		var removalResult = mcpService.removeMCP();

		// Display results
		if (arrayLen(removalResult.messages) > 0) {
			for (var message in removalResult.messages) {
				print.greenLine(message);
			}
		}

		if (arrayLen(removalResult.errors) > 0) {
			for (var error in removalResult.errors) {
				print.redLine(error);
			}
		}

		print.line();

		if (removalResult.success) {
			print.boldGreenLine("✅ MCP configuration removed successfully!");
			print.line();

			print.boldLine("Note:");
			print.indentedLine("• The MCP server endpoint remains available at /wheels/mcp");
			print.indentedLine("• It's built into the Wheels dev server");
			print.line();

			print.line("To reconfigure MCP integration later, run:");
			print.indentedYellowLine("wheels mcp setup");
		} else {
			print.boldRedLine("❌ Some errors occurred during removal");
			print.line("Please check the errors above and try again.");
		}
		print.line();
	}

}