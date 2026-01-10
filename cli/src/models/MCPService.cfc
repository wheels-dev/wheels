/**
 * Service for managing MCP (Model Context Protocol) integration
 * Handles MCP server installation, configuration, and management for AI IDE integration
 */
component accessors="true" singleton {

	property name="shell" inject="shell";
	property name="helpers" inject="helpers@wheels-cli";
	property name="serverService" inject="ServerService";
	property name="fileSystemUtil" inject="fileSystem";
	property name="print" inject="print";

	/**
	 * Initialize the service
	 */
	public function init() {
		return this;
	}

	/**
	 * Detect the current Wheels server port
	 * @autoStart boolean Whether to auto-start the server if not running
	 * @return numeric The detected port or 0 if not found
	 */
	public function detectServerPort(boolean autoStart = false) {
		try {
			// Get server info for current directory using serverService
			var cwd = fileSystemUtil.getCWD();
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
					// Try different locations where port might be stored
					if (structKeyExists(serverInfo, "port") && serverInfo.port > 0) {
						return serverInfo.port;
					} else if (structKeyExists(serverInfo, "web") &&
							   structKeyExists(serverInfo.web, "http") &&
							   structKeyExists(serverInfo.web.http, "port")) {
						return serverInfo.web.http.port;
					}
				} else if (serverInfo.status == "stopped") {
					// Server is configured but stopped
					if (arguments.autoStart) {
						// Try to start the server
						try {
							// Determine correct directory for starting
							var startDir = cwd;
							if (directoryExists(cwd & "/public")) {
								// We're in the app root, server should start from here
								startDir = cwd;
							} else if (getFileFromPath(cwd) == "public") {
								// We're in the public directory, go up one level
								startDir = getDirectoryFromPath(cwd.substring(1, cwd.length() - 1));
							}

							serverService.start(
								name = "",
								directory = startDir,
								saveSettings = true
							);
							sleep(3000); // Wait for server to start

							// Get info again after starting
							serverInfo = serverService.getServerInfoByWebroot(cwd);
							if (serverInfo.isEmpty() && directoryExists(cwd & "/public")) {
								serverInfo = serverService.getServerInfoByWebroot(cwd & "/public");
							}
							if (!serverInfo.isEmpty() && structKeyExists(serverInfo, "port")) {
								return serverInfo.port;
							}
						} catch (any e) {
							// Could not start server
						}
					} else {
						// Return configured port even if stopped
						if (structKeyExists(serverInfo, "port") && serverInfo.port > 0) {
							return serverInfo.port;
						}
					}
				}
			}
		} catch (any e) {
			// Server service failed, continue with fallback checks
		}

		// Fallback: Check server.json directly
		var serverJsonPath = fileSystemUtil.resolvePath("server.json");
		if (fileExists(serverJsonPath)) {
			try {
				var serverConfig = deserializeJSON(fileRead(serverJsonPath));
				if (structKeyExists(serverConfig, "web") &&
				    structKeyExists(serverConfig.web, "http") &&
				    structKeyExists(serverConfig.web.http, "port")) {
					return serverConfig.web.http.port;
				}
			} catch (any e) {
				// Invalid JSON, continue
			}
		}

		// Check .env file
		var envPath = fileSystemUtil.resolvePath(".env");
		if (fileExists(envPath)) {
			var envContent = fileRead(envPath);
			var portMatch = reFind("(?i)PORT\s*=\s*(\d+)", envContent, 1, true);
			if (arrayLen(portMatch.pos) > 1) {
				return mid(envContent, portMatch.pos[2], portMatch.len[2]);
			}
		}

		// Try common ports
		var commonPorts = [60000, 8080, 3000, 8500];
		for (var port in commonPorts) {
			if (isPortInUse(port)) {
				return port;
			}
		}

		return 0; // Port not found
	}

	/**
	 * Check if a port is in use
	 * @port The port to check
	 * @return boolean
	 */
	private function isPortInUse(required numeric port) {
		try {
			var result = shell.run(command="!lsof -i :#arguments.port# -P -n | grep LISTEN", returnOutput=true);
			return len(trim(result)) > 0;
		} catch (any e) {
			return false;
		}
	}

	/**
	 * Detect installed AI IDEs
	 * @return struct IDE detection results
	 */
	public function detectIDEs() {
		var ides = {
			"claude": false,
			"cursor": false,
			"continue": false,
			"windsurf": false,
			"vscode": false
		};

		var projectRoot = shell.pwd();

		// Check for Claude Code
		if (directoryExists(fileSystemUtil.resolvePath(".claude"))) {
			ides.claude = true;
		}

		// Check for Cursor
		if (directoryExists(fileSystemUtil.resolvePath(".cursor"))) {
			ides.cursor = true;
		}

		// Check for Continue
		if (directoryExists(fileSystemUtil.resolvePath(".continue"))) {
			ides.continue = true;
		}

		// Check for VSCode (which might indicate Windsurf or Continue)
		if (directoryExists(fileSystemUtil.resolvePath(".vscode"))) {
			ides.vscode = true;
			// Windsurf uses VSCode config
			ides.windsurf = true;
		}

		return ides;
	}

	/**
	 * Check if Node.js is installed
	 * @return struct with installed flag and version
	 */
	public function checkNodeJS() {
		var result = {
			"installed": false,
			"version": "",
			"npmInstalled": false,
			"npmVersion": ""
		};

		try {
			// Check if node command exists
			shell.run(command="!which node", timeout=2);
			result.installed = true;
			result.version = "Installed"; // Can't easily get version in CommandBox shell
		} catch (any e) {
			// Node not installed
		}

		try {
			// Check if npm command exists
			shell.run(command="!which npm", timeout=2);
			result.npmInstalled = true;
			result.npmVersion = "Installed"; // Can't easily get version in CommandBox shell
		} catch (any e) {
			// npm not installed
		}

		return result;
	}

	/**
	 * Install MCP server files
	 * @port The server port to configure
	 * @force Overwrite existing files
	 * @return struct Installation result
	 */
	public function installMCPServer(required numeric port, boolean force = false) {
		var result = {
			"success": false,
			"messages": [],
			"errors": []
		};

		var projectRoot = shell.pwd();

		// Copy mcp-server.js from snippets
		var mcpServerDest = projectRoot & "/mcp-server.js";
		var mcpServerSource = "";

		// Try to find the template in the app's snippets folder
		if (fileExists(fileSystemUtil.resolvePath("app/snippets/mcp-server.js.txt"))) {
			mcpServerSource = fileSystemUtil.resolvePath("app/snippets/mcp-server.js.txt");
		} else if (fileExists(fileSystemUtil.resolvePath("snippets/mcp-server.js.txt"))) {
			// Try alternate path
			mcpServerSource = fileSystemUtil.resolvePath("snippets/mcp-server.js.txt");
		} else if (fileExists(fileSystemUtil.resolvePath("../app/snippets/mcp-server.js.txt"))) {
			// If we're in public directory
			mcpServerSource = fileSystemUtil.resolvePath("../app/snippets/mcp-server.js.txt");
		}

		if (fileExists(mcpServerDest) && !arguments.force) {
			arrayAppend(result.errors, "mcp-server.js already exists. Use --force to overwrite.");
			return result;
		}

		try {
			if (fileExists(mcpServerSource)) {
				// Read template and replace port placeholder
				var template = fileRead(mcpServerSource);
				template = replace(template, "{{PORT}}", arguments.port, "all");
				fileWrite(mcpServerDest, template);
				arrayAppend(result.messages, "✅ Created mcp-server.js");
			} else {
				arrayAppend(result.errors, "MCP server template not found. Make sure you have the latest Wheels base template.");
				return result;
			}
		} catch (any e) {
			arrayAppend(result.errors, "Failed to install mcp-server.js: " & e.message);
			return result;
		}

		// Create package.json if it doesn't exist
		var packageJsonPath = projectRoot & "/package.json";
		if (!fileExists(packageJsonPath) || arguments.force) {
			try {
				var packageJson = {
					"name": "wheels-project-mcp",
					"version": "1.0.0",
					"description": "MCP integration for Wheels project",
					"dependencies": {
						"@modelcontextprotocol/sdk": "^0.5.0"
					},
					"scripts": {
						"mcp": "node mcp-server.js"
					}
				};
				fileWrite(packageJsonPath, serializeJSON(packageJson));
				arrayAppend(result.messages, "✅ Created package.json");
			} catch (any e) {
				arrayAppend(result.errors, "Failed to create package.json: " & e.message);
				return result;
			}
		}

		// Install npm dependencies
		try {
			print.line("Installing npm dependencies...");
			shell.run(command="!npm install", timeout=30);
			arrayAppend(result.messages, "✅ Installed npm dependencies");
		} catch (any e) {
			arrayAppend(result.errors, "Failed to install npm dependencies: " & e.message);
			// Don't return here - the setup was otherwise successful
		}

		result.success = true;
		return result;
	}

	/**
	 * Configure IDE for MCP
	 * @ide The IDE to configure (claude, cursor, continue, windsurf)
	 * @port The server port
	 * @force Overwrite existing configuration
	 * @return boolean Success
	 */
	public function configureIDE(required string ide, required numeric port, boolean force = false) {
		var projectRoot = shell.pwd();

		switch(arguments.ide) {
			case "claude":
				return configureClaudeCode(arguments.port, arguments.force);
			case "cursor":
				return configureCursor(arguments.port, arguments.force);
			case "continue":
				return configureContinue(arguments.port, arguments.force);
			case "windsurf":
				return configureWindsurf(arguments.port, arguments.force);
			default:
				return false;
		}
	}

	/**
	 * Configure Claude Code
	 */
	private function configureClaudeCode(required numeric port, boolean force = false) {
		var configDir = fileSystemUtil.resolvePath(".claude");
		if (!directoryExists(configDir)) {
			directoryCreate(configDir);
		}

		var configPath = configDir & "/claude_project_config.json";

		if (fileExists(configPath) && !arguments.force) {
			return false; // Already configured
		}

		var config = {
			"mcpServers": {
				"wheels": {
					"command": "node",
					"args": ["./mcp-server.js"],
					"env": {
						"WHEELS_PROJECT_PATH": "${workspaceFolder}",
						"WHEELS_DEV_SERVER": "http://localhost:#arguments.port#"
					}
				}
			}
		};

		try {
			fileWrite(configPath, serializeJSON(config));
			return true;
		} catch (any e) {
			return false;
		}
	}

	/**
	 * Configure Cursor
	 */
	private function configureCursor(required numeric port, boolean force = false) {
		var configDir = fileSystemUtil.resolvePath(".cursor");
		if (!directoryExists(configDir)) {
			directoryCreate(configDir);
		}

		var configPath = configDir & "/mcp.json";

		if (fileExists(configPath) && !arguments.force) {
			return false; // Already configured
		}

		var config = {
			"servers": {
				"wheels": {
					"command": "node",
					"args": ["mcp-server.js"],
					"cwd": "${workspaceFolder}",
					"env": {
						"WHEELS_DEV_SERVER": "http://localhost:#arguments.port#"
					}
				}
			}
		};

		try {
			fileWrite(configPath, serializeJSON(config));
			return true;
		} catch (any e) {
			return false;
		}
	}

	/**
	 * Configure Continue
	 */
	private function configureContinue(required numeric port, boolean force = false) {
		var configDir = fileSystemUtil.resolvePath(".continue");
		if (!directoryExists(configDir)) {
			directoryCreate(configDir);
		}

		var configPath = configDir & "/config.json";
		var config = {};

		// Read existing config if present
		if (fileExists(configPath)) {
			try {
				config = deserializeJSON(fileRead(configPath));
			} catch (any e) {
				config = {};
			}
		}

		// Add or update MCP servers
		if (!structKeyExists(config, "mcpServers")) {
			config.mcpServers = [];
		}

		// Check if Wheels server already exists
		var wheelsServerIndex = 0;
		var found = false;
		for (var i = 1; i <= arrayLen(config.mcpServers); i++) {
			if (structKeyExists(config.mcpServers[i], "name") && config.mcpServers[i].name == "wheels") {
				wheelsServerIndex = i;
				found = true;
				break;
			}
		}

		var wheelsServer = {
			"name": "wheels",
			"command": "WHEELS_DEV_SERVER=http://localhost:#arguments.port# node ./mcp-server.js"
		};

		if (found && !arguments.force) {
			return false; // Already configured
		} else if (found) {
			config.mcpServers[wheelsServerIndex] = wheelsServer;
		} else {
			arrayAppend(config.mcpServers, wheelsServer);
		}

		try {
			fileWrite(configPath, serializeJSON(config));
			return true;
		} catch (any e) {
			return false;
		}
	}

	/**
	 * Configure Windsurf (uses VSCode config)
	 */
	private function configureWindsurf(required numeric port, boolean force = false) {
		// Windsurf uses VSCode settings
		var configDir = fileSystemUtil.resolvePath(".vscode");
		if (!directoryExists(configDir)) {
			directoryCreate(configDir);
		}

		var settingsPath = configDir & "/settings.json";
		var settings = {};

		// Read existing settings if present
		if (fileExists(settingsPath)) {
			try {
				settings = deserializeJSON(fileRead(settingsPath));
			} catch (any e) {
				settings = {};
			}
		}

		// Add MCP configuration for Windsurf
		settings["windsurf.mcp.wheels"] = {
			"command": "node",
			"args": ["./mcp-server.js"],
			"env": {
				"WHEELS_PROJECT_PATH": "${workspaceFolder}",
				"WHEELS_DEV_SERVER": "http://localhost:#arguments.port#"
			}
		};

		try {
			fileWrite(settingsPath, serializeJSON(settings));
			return true;
		} catch (any e) {
			return false;
		}
	}

	/**
	 * Get MCP server template
	 * This is the embedded template if the file isn't found
	 */
	private function getMCPServerTemplate() {
		// This would contain the full MCP server code
		// For now, returning a message to copy from the monorepo
		return "// MCP Server for Wheels - Please copy from monorepo/mcp-server.js";
	}

	/**
	 * Test MCP connection
	 * @return struct Test results
	 */
	public function testMCPConnection() {
		var result = {
			"success": false,
			"messages": [],
			"errors": []
		};

		// Check if mcp-server.js exists
		if (!fileExists(fileSystemUtil.resolvePath("mcp-server.js"))) {
			arrayAppend(result.errors, "mcp-server.js not found. Run 'wheels mcp setup' first.");
			return result;
		}

		// Check if node_modules exists
		if (!directoryExists(fileSystemUtil.resolvePath("node_modules"))) {
			arrayAppend(result.errors, "Dependencies not installed. Run 'npm install' first.");
			return result;
		}

		// Try to start the MCP server in test mode
		try {
			var testResult = shell.run(
				command="!node mcp-server.js --test",
				timeout=5,
				returnOutput=true
			);

			if (findNoCase("error", testResult)) {
				arrayAppend(result.errors, "MCP server test failed: " & testResult);
			} else {
				arrayAppend(result.messages, "✅ MCP server is ready");
				result.success = true;
			}
		} catch (any e) {
			arrayAppend(result.errors, "Failed to test MCP server: " & e.message);
		}

		return result;
	}

	/**
	 * Get MCP status
	 * @return struct Current MCP configuration status
	 */
	public function getMCPStatus() {
		var status = {
			"configured": false,
			"port": 0,
			"ides": {},
			"configuredIDEs": []
		};

		// Get port
		status.port = detectServerPort();

		// Check IDEs
		status.ides = detectIDEs();

		// Check if any IDE is configured with native MCP
		var configuredIDEs = [];
		var homeDir = createObject("java", "java.lang.System").getProperty("user.home");

		// Check Claude Code
		var claudeConfigFile = homeDir & "/.config/claude/claude_desktop_config.json";
		if (fileExists(claudeConfigFile)) {
			try {
				var config = deserializeJSON(fileRead(claudeConfigFile));
				if (structKeyExists(config, "mcpServers") && structKeyExists(config.mcpServers, "wheels")) {
					arrayAppend(configuredIDEs, "Claude Code");
				}
			} catch (any e) {
				// Invalid config
			}
		}

		// Check Cursor
		var cursorConfigFile = homeDir & "/.cursor/mcp_servers.json";
		if (fileExists(cursorConfigFile)) {
			try {
				var config = deserializeJSON(fileRead(cursorConfigFile));
				if (structKeyExists(config, "mcpServers") && structKeyExists(config.mcpServers, "wheels")) {
					arrayAppend(configuredIDEs, "Cursor");
				}
			} catch (any e) {
				// Invalid config
			}
		}

		// Check Continue
		var continueConfigFile = homeDir & "/.continue/config.json";
		if (fileExists(continueConfigFile)) {
			try {
				var config = deserializeJSON(fileRead(continueConfigFile));
				if (structKeyExists(config, "experimental") &&
				    structKeyExists(config.experimental, "modelContextProtocol") &&
				    structKeyExists(config.experimental.modelContextProtocol, "wheels")) {
					arrayAppend(configuredIDEs, "Continue");
				}
			} catch (any e) {
				// Invalid config
			}
		}

		// Check Windsurf
		var windsurfConfigFile = homeDir & "/.windsurf/mcp_servers.json";
		if (fileExists(windsurfConfigFile)) {
			try {
				var config = deserializeJSON(fileRead(windsurfConfigFile));
				if (structKeyExists(config, "mcpServers") && structKeyExists(config.mcpServers, "wheels")) {
					arrayAppend(configuredIDEs, "Windsurf");
				}
			} catch (any e) {
				// Invalid config
			}
		}

		status.configured = arrayLen(configuredIDEs) > 0;
		status.configuredIDEs = configuredIDEs;

		return status;
	}

	/**
	 * Remove MCP configuration
	 * @return struct Removal result
	 */
	public function removeMCP() {
		var result = {
			"success": false,
			"messages": [],
			"errors": []
		};

		// Remove .mcp.json project configuration
		var mcpConfigPath = fileSystemUtil.resolvePath(".mcp.json");
		if (fileExists(mcpConfigPath)) {
			try {
				fileDelete(mcpConfigPath);
				arrayAppend(result.messages, "✅ Removed .mcp.json");
			} catch (any e) {
				arrayAppend(result.errors, "Failed to remove .mcp.json: " & e.message);
			}
		}

		// Remove IDE configurations for native MCP
		var homeDir = createObject("java", "java.lang.System").getProperty("user.home");
		var removedCount = 0;

		// Remove from Claude Code config
		var claudeConfigFile = homeDir & "/.config/claude/claude_desktop_config.json";
		if (fileExists(claudeConfigFile)) {
			try {
				var config = deserializeJSON(fileRead(claudeConfigFile));
				if (structKeyExists(config, "mcpServers") && structKeyExists(config.mcpServers, "wheels")) {
					structDelete(config.mcpServers, "wheels");
					fileWrite(claudeConfigFile, serializeJSON(config));
					arrayAppend(result.messages, "✅ Removed from Claude Code configuration");
					removedCount++;
				}
			} catch (any e) {
				arrayAppend(result.errors, "Failed to update Claude Code config: " & e.message);
			}
		}

		// Remove from Cursor config
		var cursorConfigFile = homeDir & "/.cursor/mcp_servers.json";
		if (fileExists(cursorConfigFile)) {
			try {
				var config = deserializeJSON(fileRead(cursorConfigFile));
				if (structKeyExists(config, "mcpServers") && structKeyExists(config.mcpServers, "wheels")) {
					structDelete(config.mcpServers, "wheels");
					fileWrite(cursorConfigFile, serializeJSON(config));
					arrayAppend(result.messages, "✅ Removed from Cursor configuration");
					removedCount++;
				}
			} catch (any e) {
				arrayAppend(result.errors, "Failed to update Cursor config: " & e.message);
			}
		}

		// Remove from Continue config
		var continueConfigFile = homeDir & "/.continue/config.json";
		if (fileExists(continueConfigFile)) {
			try {
				var config = deserializeJSON(fileRead(continueConfigFile));
				if (structKeyExists(config, "experimental") &&
				    structKeyExists(config.experimental, "modelContextProtocol") &&
				    structKeyExists(config.experimental.modelContextProtocol, "wheels")) {
					structDelete(config.experimental.modelContextProtocol, "wheels");
					fileWrite(continueConfigFile, serializeJSON(config));
					arrayAppend(result.messages, "✅ Removed from Continue configuration");
					removedCount++;
				}
			} catch (any e) {
				arrayAppend(result.errors, "Failed to update Continue config: " & e.message);
			}
		}

		// Remove from Windsurf config
		var windsurfConfigFile = homeDir & "/.windsurf/mcp_servers.json";
		if (fileExists(windsurfConfigFile)) {
			try {
				var config = deserializeJSON(fileRead(windsurfConfigFile));
				if (structKeyExists(config, "mcpServers") && structKeyExists(config.mcpServers, "wheels")) {
					structDelete(config.mcpServers, "wheels");
					fileWrite(windsurfConfigFile, serializeJSON(config));
					arrayAppend(result.messages, "✅ Removed from Windsurf configuration");
					removedCount++;
				}
			} catch (any e) {
				arrayAppend(result.errors, "Failed to update Windsurf config: " & e.message);
			}
		}

		// Note about node_modules and package.json
		arrayAppend(result.messages, "ℹ️  package.json and node_modules were preserved. Remove manually if needed.");

		result.success = arrayLen(result.errors) == 0;
		return result;
	}

}