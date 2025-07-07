/**
 * Display comprehensive information about the Wheels application and environment
 *
 * {code:bash}
 * wheels about
 * {code}
 */
component extends="base" {

	property name="fileSystem" inject="fileSystem";
	property name="serverService" inject="ServerService";

	/**
	 * @help Show detailed information about the Wheels application and environment
	 */
	public void function run() {
		local.appPath = getCWD();
		
		// Header - Updated to just "Wheels"
		print.line();
		print.boldRedLine(" __          ___               _     ");
		print.boldRedLine(" \ \        / / |             | |    ");
		print.boldRedLine("  \ \  /\  / /| |__   ___  ___| |___ ");
		print.boldRedLine("   \ \/  \/ / | '_ \ / _ \/ _ \ / __|");
		print.boldRedLine("    \  /\  /  | | | |  __/  __/ \__ \");
		print.boldRedLine("     \/  \/   |_| |_|\___|\___|_|___/");
		print.line();
		
		// Wheels Version
		print.boldGreenLine("Wheels Framework");
		print.greenLine("  Version: " & $getWheelsVersion());
		print.line();
		
		// CLI Version
		print.boldGreenLine("Wheels CLI");
		print.greenLine("  Version: " & getWheelsCliVersion());
		print.greenLine("  Location: " & expandPath("/wheels-cli/"));
		print.line();
		
		// Application Info
		if (isWheelsApp(local.appPath)) {
			print.boldGreenLine("Application");
			print.greenLine("  Path: " & local.appPath);
			
			// Try to get app name from config
			local.appName = getApplicationName(local.appPath);
			if (Len(local.appName)) {
				print.greenLine("  Name: " & local.appName);
			}
			
			// Get environment
			local.environment = getApplicationEnvironment(local.appPath);
			print.greenLine("  Environment: " & local.environment);
			
			// Check for database configuration
			if (hasDatabaseConfig(local.appPath)) {
				print.greenLine("  Database: Configured");
			} else {
				print.yellowLine("  Database: Not configured");
			}
			
			print.line();
		}
		
		// Server Info
		print.boldGreenLine("Server Environment");
		local.serverInfo = getServerInfo();
		print.greenLine("  CFML Engine: " & local.serverInfo.name & " " & local.serverInfo.version);
		print.greenLine("  Java Version: " & getJavaVersion());
		print.greenLine("  OS: " & server.os.name & " " & server.os.version);
		print.greenLine("  Architecture: " & server.os.arch);
		print.line();
		
		// CommandBox Info
		print.boldGreenLine("CommandBox");
		print.greenLine("  Version: " & shell.getVersion());
		print.line();
		
		// File Statistics (if in Wheels app)
		if (isWheelsApp(local.appPath)) {
			local.stats = getApplicationStats(local.appPath);
			print.boldGreenLine("Application Statistics");
			print.greenLine("  Controllers: " & local.stats.controllers);
			print.greenLine("  Models: " & local.stats.models);
			print.greenLine("  Views: " & local.stats.views);
			print.greenLine("  Tests: " & local.stats.tests);
			print.greenLine("  Migrations: " & local.stats.migrations);
			print.line();
		}
		
		// Helpful Links
		print.boldGreenLine("Resources");
		print.cyanLine("  Documentation: https://wheels.dev/docs");
		print.cyanLine("  API Reference: https://wheels.dev/api");
		print.cyanLine("  GitHub: https://github.com/wheels-dev/wheels");
		print.cyanLine("  Community: https://wheels.dev/community");
		print.line();
	}

	private string function getWheelsCliVersion() {
		// Read from CLI module's box.json
		local.boxJsonPath = getDirectoryFromPath(getCurrentTemplatePath()) & "../../../box.json";
		if (FileExists(local.boxJsonPath)) {
			try {
				local.boxJson = DeserializeJSON(FileRead(local.boxJsonPath));
				if (StructKeyExists(local.boxJson, "version")) {
					return local.boxJson.version;
				}
			} catch (any e) {
				// Continue to default
			}
		}
		
		return "1.0.0"; // Default version
	}

	private struct function getServerInfo() {
		local.result = {
			name = "Unknown",
			version = "Unknown"
		};
		
		try {
			// Try to get server info
			local.serverDetails = serverService.resolveServerDetails(serverProps = {webroot = getCWD()});
			if (StructKeyExists(local.serverDetails, "serverInfo")) {
				local.result.name = local.serverDetails.serverInfo.name ?: "Unknown";
				local.result.version = local.serverDetails.serverInfo.version ?: "Unknown";
			}
		} catch (any e) {
			// Fall back to basic detection
			if (StructKeyExists(server, "lucee")) {
				local.result.name = "Lucee";
				local.result.version = server.lucee.version;
			} else if (StructKeyExists(server, "coldfusion")) {
				local.result.name = server.coldfusion.productname;
				local.result.version = server.coldfusion.productversion;
			}
		}
		
		return local.result;
	}

	private string function getJavaVersion() {
		try {
			local.javaSystem = CreateObject("java", "java.lang.System");
			return local.javaSystem.getProperty("java.version");
		} catch (any e) {
			return "Unknown";
		}
	}

	private string function getApplicationName(required string appPath) {
		// Try to read from Application.cfc
		local.appFile = arguments.appPath & "/Application.cfc";
		if (FileExists(local.appFile)) {
			try {
				local.appContent = FileRead(local.appFile);
				local.nameMatch = REMatchNoCase('this\.name\s*=\s*["'']([^"'']+)["'']', local.appContent);
				if (ArrayLen(local.nameMatch)) {
					return REReplace(local.nameMatch[1], 'this\.name\s*=\s*["'']([^"'']+)["'']', "\1");
				}
			} catch (any e) {
				// Continue
			}
		}
		return "";
	}

	private string function getApplicationEnvironment(required string appPath) {
		// Check for environment setting
		try {
			// First check server.json
			local.serverJsonPath = arguments.appPath & "/server.json";
			if (FileExists(local.serverJsonPath)) {
				local.serverJson = DeserializeJSON(FileRead(local.serverJsonPath));
				if (StructKeyExists(local.serverJson, "env") && StructKeyExists(local.serverJson.env, "WHEELS_ENV")) {
					return local.serverJson.env.WHEELS_ENV;
				}
			}
			
			// Check system environment
			local.javaSystem = CreateObject("java", "java.lang.System");
			local.wheelsEnv = local.javaSystem.getenv("WHEELS_ENV");
			if (Len(local.wheelsEnv)) {
				return local.wheelsEnv;
			}
		} catch (any e) {
			// Continue
		}
		
		return "development"; // Default
	}

	private boolean function hasDatabaseConfig(required string appPath) {
		// Check for database configuration files
		local.configPaths = [
			arguments.appPath & "/config/app.cfm",
			arguments.appPath & "/config/settings.cfm",
			arguments.appPath & "/.env"
		];
		
		for (local.configPath in local.configPaths) {
			if (FileExists(local.configPath)) {
				try {
					local.content = FileRead(local.configPath);
					if (FindNoCase("datasource", local.content) || FindNoCase("database", local.content)) {
						return true;
					}
				} catch (any e) {
					// Continue
				}
			}
		}
		
		return false;
	}

	private struct function getApplicationStats(required string appPath) {
		local.stats = {
			controllers = 0,
			models = 0,
			views = 0,
			tests = 0,
			migrations = 0
		};
		
		try {
			// Count controllers
			local.controllersPath = arguments.appPath & "/app/controllers";
			if (DirectoryExists(local.controllersPath)) {
				local.controllers = DirectoryList(local.controllersPath, false, "name", "*.cfc");
				local.stats.controllers = ArrayLen(local.controllers);
			}
			
			// Count models
			local.modelsPath = arguments.appPath & "/app/models";
			if (DirectoryExists(local.modelsPath)) {
				local.models = DirectoryList(local.modelsPath, false, "name", "*.cfc");
				local.stats.models = ArrayLen(local.models);
			}
			
			// Count views
			local.viewsPath = arguments.appPath & "/app/views";
			if (DirectoryExists(local.viewsPath)) {
				local.views = DirectoryList(local.viewsPath, true, "name", "*.cfm");
				local.stats.views = ArrayLen(local.views);
			}
			
			// Count tests
			local.testsPath = arguments.appPath & "/tests";
			if (DirectoryExists(local.testsPath)) {
				local.tests = DirectoryList(local.testsPath, true, "name", "*.cfc");
				local.stats.tests = ArrayLen(local.tests);
			}
			
			// Count migrations
			local.migrationsPath = arguments.appPath & "/db/migrate";
			if (DirectoryExists(local.migrationsPath)) {
				local.migrations = DirectoryList(local.migrationsPath, false, "name", "*.cfc");
				local.stats.migrations = ArrayLen(local.migrations);
			}
			
		} catch (any e) {
			// Continue with defaults
		}
		
		return local.stats;
	}

}