/**
 * Remove MCP (Model Context Protocol) integration
 * Removes MCP server and configuration files from your project
 *
 * Examples:
 * {code:bash}
 * wheels mcp remove
 * wheels mcp remove --confirm
 * wheels mcp remove --keep-dependencies
 * {code}
 **/
component extends="../base" {

	property name="mcpService" inject="MCPService@wheels-cli";

	/**
	 * @confirm Skip confirmation prompt
	 * @keepDependencies Keep package.json and node_modules
	 **/
	function run(
		boolean confirm = false,
		boolean keepDependencies = false
	) {
		print.line();
		print.boldYellowLine("🗑️  Remove MCP Integration");
		print.line("=" .repeatString(40));
		print.line();

		// Check current status
		var status = mcpService.getMCPStatus();

		if (!status.serverFile && !status.configured) {
			print.yellowLine("MCP integration is not installed.");
			print.line();
			return;
		}

		// Show what will be removed
		print.boldLine("This will remove:");
		if (status.serverFile) {
			print.indentedLine("• mcp-server.js");
		}
		if (status.configured && arrayLen(status.configuredIDEs) > 0) {
			print.indentedLine("• IDE configurations for: " & arrayToList(status.configuredIDEs, ", "));
		}
		if (!arguments.keepDependencies) {
			print.indentedLine("• package.json (if it only contains MCP dependencies)");
		}
		print.line();

		print.boldLine("This will preserve:");
		print.indentedLine("• Your Wheels application code");
		print.indentedLine("• Your project configuration");
		if (arguments.keepDependencies) {
			print.indentedLine("• package.json and node_modules");
		} else {
			print.indentedLine("• node_modules (remove manually if needed)");
		}
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
		print.line("Removing MCP integration...");
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
			print.boldGreenLine("✅ MCP integration removed successfully!");
			print.line();

			// Provide next steps
			print.boldLine("Optional cleanup:");
			print.indentedLine("• Remove node_modules: rm -rf node_modules");
			print.indentedLine("• Remove package-lock.json: rm package-lock.json");

			if (fileExists(fileSystemUtil.resolvePath("package.json"))) {
				print.indentedLine("• Review package.json for other dependencies");
			}
			print.line();

			print.line("To reinstall MCP integration later, run:");
			print.indentedYellowLine("wheels mcp setup");
		} else {
			print.boldRedLine("❌ Some errors occurred during removal");
			print.line("Please check the errors above and try again.");
		}
		print.line();
	}

}