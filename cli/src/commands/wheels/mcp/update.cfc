/**
 * Update MCP (Model Context Protocol) server to the latest version
 * Updates the MCP server file while preserving your configuration
 *
 * Examples:
 * {code:bash}
 * wheels mcp update
 * wheels mcp update --force
 * wheels mcp update --backup
 * {code}
 **/
component extends="../base" {

	property name="mcpService" inject="MCPService@wheels-cli";

	/**
	 * @force Force update even if already up to date
	 * @backup Create backup of current mcp-server.js before updating
	 **/
	function run(
		boolean force = false,
		boolean backup = true
	) {
		print.line();
		print.boldYellowLine("🔄 Update MCP Integration");
		print.line("=" .repeatString(40));
		print.line();

		// Check current status
		var status = mcpService.getMCPStatus();

		if (!status.serverFile) {
			print.yellowLine("MCP server is not installed.");
			print.line("Run 'wheels mcp setup' to install MCP integration.");
			print.line();
			return;
		}

		print.line("Checking for updates...");
		print.line();

		// Get current port configuration
		var currentPort = status.port;
		if (currentPort == 0) {
			currentPort = mcpService.detectServerPort();
			if (currentPort == 0) {
				print.yellowLine("⚠️  Could not detect server port.");
				var userPort = ask("Enter your Wheels server port (or press Enter to use 60000): ");
				currentPort = len(trim(userPort)) ? userPort : 60000;
			}
		}

		// Check if update is needed
		var serverFilePath = fileSystemUtil.resolvePath("mcp-server.js");
		var currentContent = fileRead(serverFilePath);
		var templatePath = "";

		// Try to find the template in the app's snippets folder
		if (fileExists(fileSystemUtil.resolvePath("app/snippets/mcp-server.js.txt"))) {
			templatePath = fileSystemUtil.resolvePath("app/snippets/mcp-server.js.txt");
		} else if (fileExists(fileSystemUtil.resolvePath("snippets/mcp-server.js.txt"))) {
			// Try alternate path
			templatePath = fileSystemUtil.resolvePath("snippets/mcp-server.js.txt");
		} else if (fileExists(fileSystemUtil.resolvePath("../app/snippets/mcp-server.js.txt"))) {
			// If we're in public directory
			templatePath = fileSystemUtil.resolvePath("../app/snippets/mcp-server.js.txt");
		}

		if (!fileExists(templatePath)) {
			print.redLine("❌ Could not find MCP server template.");
			print.line("Please ensure you have the latest Wheels base template.");
			return;
		}

		var templateContent = fileRead(templatePath);
		// Replace port placeholder
		var newContent = replace(templateContent, "{{PORT}}", currentPort, "all");

		// Check if files are identical (ignoring port differences)
		var currentNormalized = reReplace(currentContent, "port:\s*\d+", "port: PORT", "all");
		var newNormalized = reReplace(newContent, "port:\s*\d+", "port: PORT", "all");

		if (currentNormalized == newNormalized && !arguments.force) {
			print.greenLine("✅ MCP server is already up to date.");
			print.line();
			return;
		}

		// Create backup if requested
		if (arguments.backup) {
			var backupPath = serverFilePath & "." & dateFormat(now(), "yyyymmdd") & timeFormat(now(), "HHmmss") & ".backup";
			fileCopy(serverFilePath, backupPath);
			print.greenLine("✅ Backup created: " & getFileFromPath(backupPath));
		}

		// Update the server file
		print.line("Updating MCP server...");
		try {
			fileWrite(serverFilePath, newContent);
			print.greenLine("✅ MCP server updated successfully!");
			print.line();

			// Check syntax of updated file
			try {
				shell.run(command="!node -c mcp-server.js", timeout=5);
				print.greenLine("✅ Server syntax validation passed");
			} catch (any e) {
				print.yellowLine("⚠️  Warning: Server syntax validation failed");
				print.yellowLine("   Please check the mcp-server.js file");
			}

		} catch (any e) {
			print.redLine("❌ Failed to update MCP server: " & e.message);
			
			if (arguments.backup && fileExists(backupPath)) {
				print.yellowLine("You can restore from backup: " & getFileFromPath(backupPath));
			}
			return;
		}

		// Update npm dependencies if needed
		if (!status.dependencies) {
			print.line();
			print.line("Installing MCP dependencies...");
			try {
				var npmResult = shell.run(command="!npm install", timeout=30, returnOutput=true);
				if (npmResult.error) {
					print.yellowLine("⚠️  npm install encountered issues: " & npmResult.error);
				} else {
					print.greenLine("✅ Dependencies updated");
				}
			} catch (any e) {
				print.yellowLine("⚠️  Could not update dependencies: " & e.message);
				print.yellowLine("   Run 'npm install' manually to update dependencies");
			}
		}

		print.line();
		print.boldLine("Update Summary:");
		print.indentedLine("• MCP server updated to latest version");
		print.indentedLine("• Port configuration preserved: " & currentPort);
		if (arguments.backup && fileExists(backupPath)) {
			print.indentedLine("• Backup created: " & getFileFromPath(backupPath));
		}
		print.line();

		// Check which IDEs are configured and might need restart
		if (status.configured && arrayLen(status.configuredIDEs) > 0) {
			print.boldLine("Next Steps:");
			print.indentedLine("1. Restart your AI IDE to load the updated MCP server");
			print.indentedLine("   Configured IDEs: " & arrayToList(status.configuredIDEs, ", "));
			print.indentedLine("2. Run 'wheels mcp test' to verify the update");
		} else {
			print.boldLine("Next Steps:");
			print.indentedLine("1. Run 'wheels mcp setup' to configure your IDE");
			print.indentedLine("2. Run 'wheels mcp test' to verify the installation");
		}
		print.line();

		// Show what's new (if we can determine it)
		print.boldLine("What's New:");
		print.indentedLine("• Enhanced error handling and logging");
		print.indentedLine("• Improved tool response formatting");
		print.indentedLine("• Better integration with Wheels dev server");
		print.indentedLine("• Support for latest MCP protocol features");
		print.line();
	}

}