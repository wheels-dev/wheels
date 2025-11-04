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
	 * @noMask.hint Don't mask sensitive values
	 **/
	function run(
		string environment = "",
		string format = "table",
		string output = "",
		boolean noMask = false
	) {

		arguments = reconstructArgs(
			argStruct = arguments,
			allowedValues = {
				format: ["table", "json", "env", "cfml"]
			}
		);

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
		local.outputContent = "";
		switch (arguments.format) {
			case "json":
				local.outputContent = SerializeJSON(local.config, false, false);
				break;
			case "env":
				local.outputContent = formatAsEnv(local.config);
				break;
			case "cfml":
				local.outputContent = formatAsCfml(local.config);
				break;
			default:
				// Table format is handled differently
				formatAsTable(local.config, local.env);
		}

		// Save to file if specified
		if (Len(arguments.output)) {
			if (arguments.format == "table") {
				// For table format, we need to capture the output differently
				local.tableOutput = captureTableOutput(local.config, local.env);
				FileWrite(ResolvePath(arguments.output), local.tableOutput);
				print.greenLine("Configuration saved to: #arguments.output#");
			} else {
				FileWrite(ResolvePath(arguments.output), local.outputContent);
				print.greenLine("Configuration saved to: #arguments.output#");
			}
		} else if (arguments.format != "table") {
			// Output to console if not table format
			if(arguments.format == "json"){
				print.line(deSerializeJSON(local.outputContent));
			}else{
				print.line(local.outputContent);
			}
		}
	}

	private struct function loadConfiguration(required string settingsFile, string envSettingsFile = "") {
		local.settings = {};
		
		// Load base settings
		if (FileExists(arguments.settingsFile)) {
			local.content = FileRead(arguments.settingsFile);
			// Extract set() calls - improved regex pattern
			local.pattern = 'set\s*\([^)]+\)';
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
			local.pattern = 'set\s*\([^)]+\)';
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
		
		// Improved parser for key=value pairs
		// Handle both single and named arguments
		if (!Find("=", local.argsString)) {
			// Single argument format: set(value)
			return {};
		}
		
		// Parse named arguments
		local.inString = false;
		local.currentChar = "";
		local.currentPair = "";
		local.pairs = [];
		local.stringDelimiter = "";
		
		for (local.i = 1; local.i <= Len(local.argsString); local.i++) {
			local.currentChar = Mid(local.argsString, local.i, 1);
			
			if (!local.inString) {
				if (local.currentChar == '"' || local.currentChar == "'") {
					local.inString = true;
					local.stringDelimiter = local.currentChar;
					local.currentPair &= local.currentChar;
				} else if (local.currentChar == ",") {
					ArrayAppend(local.pairs, Trim(local.currentPair));
					local.currentPair = "";
				} else {
					local.currentPair &= local.currentChar;
				}
			} else {
				local.currentPair &= local.currentChar;
				if (local.currentChar == local.stringDelimiter) {
					// Check if it's escaped
					if (local.i < Len(local.argsString) && Mid(local.argsString, local.i + 1, 1) != local.stringDelimiter) {
						local.inString = false;
						local.stringDelimiter = "";
					}
				}
			}
		}
		
		// Add the last pair
		if (Len(Trim(local.currentPair))) {
			ArrayAppend(local.pairs, Trim(local.currentPair));
		}
		
		// Process pairs
		for (local.pair in local.pairs) {
			local.pair = Trim(local.pair);
			if (Find("=", local.pair)) {
				local.eqPos = Find("=", local.pair);
				local.key = Trim(Left(local.pair, local.eqPos - 1));
				local.value = Trim(Mid(local.pair, local.eqPos + 1, Len(local.pair)));
				
				// Remove quotes if present
				if (Len(local.value) >= 2) {
					if ((Left(local.value, 1) == '"' && Right(local.value, 1) == '"') || 
					    (Left(local.value, 1) == "'" && Right(local.value, 1) == "'")) {
						local.value = Mid(local.value, 2, Len(local.value) - 2);
					}
				}
				
				// Try to parse boolean and numeric values
				if (local.value == "true" || local.value == "false") {
					local.value = (local.value == "true");
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
			try {
				if (IsJSON(local.content)) {
					local.envVars = DeserializeJSON(local.content);
					return local.envVars;
				}
			} catch (any e) {
				// Not JSON, continue with properties format
			}
			
			// Parse as properties file
			local.lines = ListToArray(local.content, Chr(10));
			for (local.line in local.lines) {
				local.line = Trim(local.line);
				// Skip empty lines and comments
				if (Len(local.line) && Left(local.line, 1) != "##" && Left(local.line, 1) != ";") {
					if (Find("=", local.line)) {
						local.eqPos = Find("=", local.line);
						local.key = Trim(Left(local.line, local.eqPos - 1));
						local.value = Trim(Mid(local.line, local.eqPos + 1, Len(local.line)));
						// Remove surrounding quotes if present
						if (Len(local.value) >= 2) {
							if ((Left(local.value, 1) == '"' && Right(local.value, 1) == '"') || 
							    (Left(local.value, 1) == "'" && Right(local.value, 1) == "'")) {
								local.value = Mid(local.value, 2, Len(local.value) - 2);
							}
						}
						local.envVars[local.key] = local.value;
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
			"private", "credential", "auth", "passphrase", "salt", "pwd"
		];

		// Recursively mask sensitive values
		for (local.key in local.masked) {
			if (IsStruct(local.masked[local.key])) {
				local.masked[local.key] = maskSensitiveValues(local.masked[local.key]);
			} else if (IsArray(local.masked[local.key])) {
				// Handle arrays
				for (local.i = 1; local.i <= ArrayLen(local.masked[local.key]); local.i++) {
					if (IsStruct(local.masked[local.key][local.i])) {
						local.masked[local.key][local.i] = maskSensitiveValues(local.masked[local.key][local.i]);
					}
				}
			} else if (IsSimpleValue(local.masked[local.key])) {
				// Check if key contains sensitive words (case-insensitive)
				local.lowerKey = LCase(local.key);
				for (local.sensitive in local.sensitiveKeys) {
					if (FindNoCase(local.sensitive, local.lowerKey)) {
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
					// Properly escape values with spaces or special characters
					if (Find(" ", local.value) || Find("##", local.value) || Find("$", local.value)) {
						ArrayAppend(local.lines, '#UCase(local.key)#="#local.value#"');
					} else {
						ArrayAppend(local.lines, "#UCase(local.key)#=#local.value#");
					}
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
					// Convert camelCase to SNAKE_CASE
					local.envKey = "";
					for (local.i = 1; local.i <= Len(local.key); local.i++) {
						local.char = Mid(local.key, local.i, 1);
						if (local.i > 1 && ReFind("[A-Z]", local.char)) {
							local.envKey &= "_";
						}
						local.envKey &= UCase(local.char);
					}
					
					// Properly escape values
					if (IsBoolean(local.value)) {
						ArrayAppend(local.lines, "#local.envKey#=#local.value#");
					} else if (IsNumeric(local.value)) {
						ArrayAppend(local.lines, "#local.envKey#=#local.value#");
					} else if (Find(" ", local.value) || Find("##", local.value) || Find("$", local.value)) {
						ArrayAppend(local.lines, '#local.envKey#="#local.value#"');
					} else {
						ArrayAppend(local.lines, "#local.envKey#=#local.value#");
					}
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
						ArrayAppend(local.lines, "set(#local.key# = #LCase(local.value)#);");
					} else if (IsNumeric(local.value)) {
						ArrayAppend(local.lines, "set(#local.key# = #local.value#);");
					} else {
						// Escape double quotes in string values
						local.escapedValue = Replace(local.value, '"', '""', 'all');
						ArrayAppend(local.lines, 'set(#local.key# = "#local.escapedValue#");');
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
				value: ToString(local.value)
			};

			local.lowerKey = LCase(local.key);
			if (FindNoCase("datasource", local.lowerKey) || FindNoCase("database", local.lowerKey) || FindNoCase("db", local.lowerKey)) {
				ArrayAppend(local.categories.database, local.item);
			} else if (FindNoCase("cache", local.lowerKey)) {
				ArrayAppend(local.categories.caching, local.item);
			} else if (FindNoCase("password", local.lowerKey) || FindNoCase("secret", local.lowerKey) || 
			           FindNoCase("key", local.lowerKey) || FindNoCase("token", local.lowerKey)) {
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
		local.categoryNames = {
			"database": "DATABASE",
			"caching": "CACHING", 
			"security": "SECURITY",
			"environment": "ENVIRONMENT",
			"other": "OTHER"
		};
		
		for (local.category in ["database", "caching", "security", "environment", "other"]) {
			if (ArrayLen(local.categories[local.category])) {
				print.boldLine("#local.categoryNames[local.category]# Settings:");
				print.table(
					data = local.categories[local.category],
					headers = ["Setting", "Value"]
				);
				print.line();
			}
		}
	}

	private string function captureTableOutput(required struct config, required string environment) {
		local.output = [];
		
		ArrayAppend(local.output, "");
		ArrayAppend(local.output, "Configuration for environment: #arguments.environment#");
		ArrayAppend(local.output, "");

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

			local.lowerKey = LCase(local.key);
			local.valueStr = ToString(local.value);
			
			if (FindNoCase("datasource", local.lowerKey) || FindNoCase("database", local.lowerKey) || FindNoCase("db", local.lowerKey)) {
				ArrayAppend(local.categories.database, local.key & " = " & local.valueStr);
			} else if (FindNoCase("cache", local.lowerKey)) {
				ArrayAppend(local.categories.caching, local.key & " = " & local.valueStr);
			} else if (FindNoCase("password", local.lowerKey) || FindNoCase("secret", local.lowerKey) || 
			           FindNoCase("key", local.lowerKey) || FindNoCase("token", local.lowerKey)) {
				ArrayAppend(local.categories.security, local.key & " = " & local.valueStr);
			} else {
				ArrayAppend(local.categories.other, local.key & " = " & local.valueStr);
			}
		}

		// Add environment variables if present
		if (StructKeyExists(arguments.config, "_environment") && StructCount(arguments.config._environment)) {
			ArrayAppend(local.output, "Environment Variables:");
			ArrayAppend(local.output, "---------------------");
			for (local.key in arguments.config._environment) {
				ArrayAppend(local.output, local.key & " = " & arguments.config._environment[local.key]);
			}
			ArrayAppend(local.output, "");
		}

		// Add categorized settings
		local.categoryNames = {
			"database": "DATABASE Settings",
			"caching": "CACHING Settings", 
			"security": "SECURITY Settings",
			"environment": "ENVIRONMENT Settings",
			"other": "OTHER Settings"
		};
		
		for (local.category in ["database", "caching", "security", "environment", "other"]) {
			if (ArrayLen(local.categories[local.category])) {
				ArrayAppend(local.output, local.categoryNames[local.category] & ":");
				ArrayAppend(local.output, RepeatString("-", Len(local.categoryNames[local.category]) + 1));
				for (local.item in local.categories[local.category]) {
					ArrayAppend(local.output, local.item);
				}
				ArrayAppend(local.output, "");
			}
		}

		return ArrayToList(local.output, Chr(10));
	}

	private array function prepareTableData(required struct data) {
		local.result = [];
		for (local.key in arguments.data) {
			ArrayAppend(local.result, {
				key: local.key,
				value: ToString(arguments.data[local.key])
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
			} else if (StructKeyExists(local.envVars, "ENVIRONMENT")) {
				local.env = local.envVars.ENVIRONMENT;
			}
		}

		// Check system environment
		if (!Len(local.env)) {
			try {
				local.sysEnv = CreateObject("java", "java.lang.System").getenv("WHEELS_ENV");
				if (!IsNull(local.sysEnv) && Len(local.sysEnv)) {
					local.env = local.sysEnv;
				}
			} catch (any e) {
				// Java environment variable access failed
			}
		}

		// Check for ENVIRONMENT system variable
		if (!Len(local.env)) {
			try {
				local.sysEnv = CreateObject("java", "java.lang.System").getenv("ENVIRONMENT");
				if (!IsNull(local.sysEnv) && Len(local.sysEnv)) {
					local.env = local.sysEnv;
				}
			} catch (any e) {
				// Java environment variable access failed
			}
		}

		// Default to development
		if (!Len(local.env)) {
			local.env = "development";
		}

		return local.env;
	}

}