/**
 * Exports configuration settings for an environment
 * 
 * Examples:
 * {code:bash}
 * wheels config dump
 * wheels config dump testing
 * wheels config dump --format=json
 * wheels config dump --output=config.json
 * wheels config dump --no-mask
 * {code}
 */
component extends="commandbox.modules.wheels-cli.commands.wheels.base" {

	/**
	 * @environment.hint The environment to dump (development, testing, production)
	 * @format.hint Output format: table, json, env, or cfml
	 * @format.options table,json,env,cfml
	 * @output.hint File to save configuration to
	 * @no-mask.hint Don't mask sensitive values
	 **/
	function run(
		string environment = "",
		string format = "table",
		string output = "",
		boolean noMask = false
	) {

		// Validate format
		if (!ListFindNoCase("table,json,env,cfml", arguments.format)) {
			error("Invalid format: #arguments.format#. Valid formats are: table, json, env, cfml");
		}

		// Determine environment
		local.env = Len(arguments.environment) ? arguments.environment : getEnvironment();
		
		// Get configuration path
		local.configPath = ResolvePath("config");
		local.settingsFile = local.configPath & "/settings.cfm";
		local.envSettingsFile = local.configPath & "/" & local.env & "/settings.cfm";

		if (!FileExists(local.settingsFile)) {
			error("No settings.cfm file found in config directory");
		}

		// Load configuration
		local.config = loadConfiguration(local.settingsFile, local.envSettingsFile);

		// Mask sensitive values unless --no-mask is specified
		if (!arguments.noMask) {
			local.config = maskSensitiveValues(local.config);
		}

		// Format output
		local.output = "";
		switch (arguments.format) {
			case "json":
				local.output = SerializeJSON(local.config, false, false);
				break;
			case "env":
				local.output = formatAsEnv(local.config);
				break;
			case "cfml":
				local.output = formatAsCfml(local.config);
				break;
			default:
				formatAsTable(local.config, local.env);
		}

		// Save to file if specified
		if (Len(arguments.output) && arguments.format != "table") {
			try {
				FileWrite(ResolvePath(arguments.output), local.output);
				print.greenLine("Configuration saved to: #arguments.output#");
			} catch (any e) {
				error("Failed to write file: #e.message#");
			}
		} else if (arguments.format != "table") {
			print.line(local.output);
		}
	}

	private struct function loadConfiguration(required string settingsFile, string envSettingsFile = "") {
		local.settings = {};
		
		// Create a temporary component to load settings
		local.tempCfc = CreateObject("component", "WireBox.system.core.util.CFMLEngine").init();
		
		// Load base settings
		if (FileExists(arguments.settingsFile)) {
			local.content = FileRead(arguments.settingsFile);
			// Extract set() calls
			local.pattern = 'set\s*\(\s*([^)]+)\s*\)';
			local.matches = REMatchNoCase(local.pattern, local.content);
			
			for (local.match in local.matches) {
				try {
					// Parse the settings
					local.args = parseSetArguments(local.match);
					StructAppend(local.settings, local.args, true);
				} catch (any e) {
					// Skip invalid set() calls
				}
			}
		}

		// Load environment-specific settings
		if (Len(arguments.envSettingsFile) && FileExists(arguments.envSettingsFile)) {
			local.content = FileRead(arguments.envSettingsFile);
			local.matches = REMatchNoCase(local.pattern, local.content);
			
			for (local.match in local.matches) {
				try {
					local.args = parseSetArguments(local.match);
					StructAppend(local.settings, local.args, true);
				} catch (any e) {
					// Skip invalid set() calls
				}
			}
		}

		// Load .env file if it exists
		local.envFile = ResolvePath(".env");
		if (FileExists(local.envFile)) {
			local.envVars = loadEnvFile(local.envFile);
			local.settings["_environment"] = local.envVars;
		}

		return local.settings;
	}

	private struct function parseSetArguments(required string setCall) {
		local.result = {};
		
		// Extract the arguments inside set()
		local.argsString = ReReplace(arguments.setCall, "^set\s*\(\s*", "");
		local.argsString = ReReplace(local.argsString, "\s*\)$", "");
		
		// Simple parser for key=value pairs
		// This is a basic implementation and may need refinement
		local.pairs = ListToArray(local.argsString, ",");
		
		for (local.pair in local.pairs) {
			local.pair = Trim(local.pair);
			if (Find("=", local.pair)) {
				local.key = Trim(ListFirst(local.pair, "="));
				local.value = Trim(ListRest(local.pair, "="));
				
				// Remove quotes if present
				if (Left(local.value, 1) == '"' && Right(local.value, 1) == '"') {
					local.value = Mid(local.value, 2, Len(local.value) - 2);
				} else if (Left(local.value, 1) == "'" && Right(local.value, 1) == "'") {
					local.value = Mid(local.value, 2, Len(local.value) - 2);
				}
				
				// Try to parse boolean and numeric values
				if (IsBoolean(local.value)) {
					local.value = local.value ? true : false;
				} else if (IsNumeric(local.value)) {
					local.value = Val(local.value);
				}
				
				local.result[local.key] = local.value;
			}
		}
		
		return local.result;
	}

	private struct function loadEnvFile(required string envFile) {
		local.envVars = {};
		
		if (FileExists(arguments.envFile)) {
			local.content = FileRead(arguments.envFile);
			
			// Try JSON format first
			if (IsJSON(local.content)) {
				local.envVars = DeserializeJSON(local.content);
			} else {
				// Parse as properties file
				local.lines = ListToArray(local.content, Chr(10));
				for (local.line in local.lines) {
					local.line = Trim(local.line);
					if (Len(local.line) && Left(local.line, 1) != "##") {
						if (Find("=", local.line)) {
							local.key = Trim(ListFirst(local.line, "="));
							local.value = Trim(ListRest(local.line, "="));
							local.envVars[local.key] = local.value;
						}
					}
				}
			}
		}
		
		return local.envVars;
	}

	private struct function maskSensitiveValues(required struct config) {
		local.masked = Duplicate(arguments.config);
		local.sensitiveKeys = [
			"password", "secret", "key", "token", "apikey", "api_key",
			"private", "credential", "auth", "passphrase", "salt"
		];

		// Recursively mask sensitive values
		for (local.key in local.masked) {
			if (IsStruct(local.masked[local.key])) {
				local.masked[local.key] = maskSensitiveValues(local.masked[local.key]);
			} else if (IsSimpleValue(local.masked[local.key])) {
				// Check if key contains sensitive words
				for (local.sensitive in local.sensitiveKeys) {
					if (FindNoCase(local.sensitive, local.key)) {
						local.masked[local.key] = "***MASKED***";
						break;
					}
				}
			}
		}

		return local.masked;
	}

	private string function formatAsEnv(required struct config) {
		local.lines = [];
		
		// Add header
		ArrayAppend(local.lines, "## Wheels Configuration Export");
		ArrayAppend(local.lines, "## Generated: #DateTimeFormat(Now(), 'yyyy-mm-dd HH:nn:ss')#");
		ArrayAppend(local.lines, "");

		// Handle environment variables separately
		if (StructKeyExists(arguments.config, "_environment")) {
			ArrayAppend(local.lines, "## Environment Variables");
			for (local.key in arguments.config._environment) {
				local.value = arguments.config._environment[local.key];
				if (IsSimpleValue(local.value)) {
					ArrayAppend(local.lines, "#UCase(local.key)#=#local.value#");
				}
			}
			ArrayAppend(local.lines, "");
		}

		// Handle regular config
		ArrayAppend(local.lines, "## Application Settings");
		for (local.key in arguments.config) {
			if (local.key != "_environment") {
				local.value = arguments.config[local.key];
				if (IsSimpleValue(local.value)) {
					local.envKey = UCase(ReReplace(local.key, "([A-Z])", "_\1", "all"));
					if (Left(local.envKey, 1) == "_") {
						local.envKey = Right(local.envKey, Len(local.envKey) - 1);
					}
					ArrayAppend(local.lines, "#local.envKey#=#local.value#");
				}
			}
		}

		return ArrayToList(local.lines, Chr(10));
	}

	private string function formatAsCfml(required struct config) {
		local.lines = [];
		
		ArrayAppend(local.lines, "// Wheels Configuration Export");
		ArrayAppend(local.lines, "// Generated: #DateTimeFormat(Now(), 'yyyy-mm-dd HH:nn:ss')#");
		ArrayAppend(local.lines, "");

		for (local.key in arguments.config) {
			if (local.key != "_environment") {
				local.value = arguments.config[local.key];
				if (IsSimpleValue(local.value)) {
					if (IsBoolean(local.value)) {
						ArrayAppend(local.lines, "set(#local.key# = #local.value#);");
					} else if (IsNumeric(local.value)) {
						ArrayAppend(local.lines, "set(#local.key# = #local.value#);");
					} else {
						ArrayAppend(local.lines, 'set(#local.key# = "#Replace(local.value, '"', '""', 'all')#");');
					}
				}
			}
		}

		return ArrayToList(local.lines, Chr(10));
	}

	private void function formatAsTable(required struct config, required string environment) {
		print.line();
		print.greenLine("Configuration for environment: #arguments.environment#");
		print.line();

		// Group settings by category
		local.categories = {
			"database": [],
			"environment": [],
			"caching": [],
			"security": [],
			"other": []
		};

		// Categorize settings
		for (local.key in arguments.config) {
			if (local.key == "_environment") continue;
			
			local.value = arguments.config[local.key];
			if (!IsSimpleValue(local.value)) continue;

			local.item = {
				key: local.key,
				value: local.value
			};

			if (FindNoCase("datasource", local.key) || FindNoCase("database", local.key) || FindNoCase("db", local.key)) {
				ArrayAppend(local.categories.database, local.item);
			} else if (FindNoCase("cache", local.key)) {
				ArrayAppend(local.categories.caching, local.item);
			} else if (FindNoCase("password", local.key) || FindNoCase("secret", local.key) || FindNoCase("key", local.key)) {
				ArrayAppend(local.categories.security, local.item);
			} else {
				ArrayAppend(local.categories.other, local.item);
			}
		}

		// Display environment variables if present
		if (StructKeyExists(arguments.config, "_environment") && StructCount(arguments.config._environment)) {
			print.boldLine("Environment Variables:");
			print.table(
				data = prepareTableData(arguments.config._environment),
				headers = ["Variable", "Value"]
			);
			print.line();
		}

		// Display categorized settings
		for (local.category in local.categories) {
			if (ArrayLen(local.categories[local.category])) {
				print.boldLine("#UCase(local.category)# Settings:");
				print.table(
					data = local.categories[local.category],
					headers = ["Setting", "Value"]
				);
				print.line();
			}
		}
	}

	private array function prepareTableData(required struct data) {
		local.result = [];
		for (local.key in arguments.data) {
			ArrayAppend(local.result, {
				key: local.key,
				value: arguments.data[local.key]
			});
		}
		return local.result;
	}

	private string function getEnvironment() {
		// Try to detect from various sources
		local.env = "";
		
		// Check .env file
		local.envFile = ResolvePath(".env");
		if (FileExists(local.envFile)) {
			local.envVars = loadEnvFile(local.envFile);
			if (StructKeyExists(local.envVars, "WHEELS_ENV")) {
				local.env = local.envVars.WHEELS_ENV;
			}
		}

		// Check system environment
		if (!Len(local.env)) {
			local.env = CreateObject("java", "java.lang.System").getenv("WHEELS_ENV");
			if (IsNull(local.env)) {
				local.env = "";
			}
		}

		// Default to development
		if (!Len(local.env)) {
			local.env = "development";
		}

		return local.env;
	}

}