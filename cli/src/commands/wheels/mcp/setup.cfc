/**
 * Set up MCP (Model Context Protocol) integration for AI IDE support.
 *
 * Writes .mcp.json and .opencode.json configuration files in the project
 * root. Both point your AI IDE at the LuCLI stdio MCP server (`wheels mcp
 * wheels`) — the canonical Wheels MCP surface as of 4.0. No port or running
 * dev server required; the IDE launches the stdio subprocess on demand.
 *
 * Examples:
 * {code:bash}
 * wheels mcp setup
 * wheels mcp setup --force
 * {code}
 **/
component extends="../base" {

	/**
	 * @force Overwrite existing configuration files
	 **/
	function run(boolean force = false) {
		print.line();
		print.boldYellowLine("🤖 Setting up MCP Integration for Wheels");
		print.line("=" .repeatString(50));
		print.line();

		if (!isWheelsApp()) {
			print.redLine("❌ This doesn't appear to be a Wheels application directory.");
			print.line("   Looking for /vendor/wheels, /config, and /app folders");
			print.line();
			print.yellowLine("   Run this command from your Wheels project root directory.");
			return;
		}
		print.greenLine("✅ Wheels application detected");
		print.greenLine("✅ Using LuCLI stdio MCP (transport: stdio, no port needed)");

		print.line();
		print.boldLine("Creating MCP configuration files...");

		try {
			var projectRoot = getCWD();

			var mcpConfigPath = projectRoot & "/.mcp.json";
			if (!fileExists(mcpConfigPath) || arguments.force) {
				var mcpTemplate = fileRead(expandPath("/wheels-cli/templates/McpConfig.json"));
				fileWrite(mcpConfigPath, mcpTemplate);
				print.greenLine("✅ Created .mcp.json");
			} else {
				print.yellowLine("⚠️  .mcp.json already exists (use --force to overwrite)");
			}

			var opencodeConfigPath = projectRoot & "/.opencode.json";
			if (!fileExists(opencodeConfigPath) || arguments.force) {
				var opencodeTemplate = fileRead(expandPath("/wheels-cli/templates/OpenCodeConfig.json"));
				fileWrite(opencodeConfigPath, opencodeTemplate);
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
		print.boldGreenLine("✨ MCP Integration Setup Complete!");
		print.line();
		print.boldLine("Configuration Summary:");
		print.indentedLine("MCP transport: stdio (launched on demand by your AI IDE)");
		print.indentedLine('Command: wheels mcp wheels');
		print.indentedLine("Files created: .mcp.json, .opencode.json");
		print.line();

		print.boldLine("Next Steps:");
		print.indentedLine("1. Ensure the 'wheels' CLI binary is on PATH (brew install wheels)");
		print.indentedLine("2. Restart your AI IDE so it re-reads .mcp.json / .opencode.json");
		print.indentedLine("3. Verify tool discovery in the IDE's MCP panel — 16 tools should appear");
		print.line();

		print.boldLine("Available MCP Commands:");
		print.indentedLine("wheels mcp status  - Check MCP configuration");
		print.indentedLine("wheels mcp test    - Test MCP connection");
		print.indentedLine("wheels mcp remove  - Remove MCP integration");
		print.line();

		print.yellowLine("💡 The generated files give AI assistants:");
		print.indentedLine("• Code generation (generate, destroy, seed, ...)");
		print.indentedLine("• Migration + database operations (migrate, db, ...)");
		print.indentedLine("• Project introspection (routes, info, analyze, doctor, stats, notes)");
		print.indentedLine("• Test runner (test)");
		print.indentedLine("• Browser automation (via Browser MCP)");
		print.line();
		print.indentedLine("Full guide: docs/command-line-tools/commands/mcp/mcp-configuration-guide.md");
		print.line();
	}

}
