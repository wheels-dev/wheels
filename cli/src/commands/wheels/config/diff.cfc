/**
 * Compares configuration between two environments
 * 
 * Examples:
 * {code:bash}
 * wheels config diff development production
 * wheels config diff testing production --changes-only
 * wheels config diff development testing --format=json
 * wheels config diff development production --env
 * wheels config diff development production --settings
 * {code}
 */
component extends="commandbox.modules.wheels-cli.commands.wheels.base" {

	/**
	 * @env1.hint First environment to compare
	 * @env2.hint Second environment to compare
	 * @changes-only.hint Only show differences
	 * @format.hint Output format: table or json
	 * @format.options table,json
	 * @env.hint Compare environment variables only
	 * @settings.hint Compare settings only
	 **/
	function run(
		required string env1,
		required string env2,
		boolean changesOnly = false,
		string format = "table",
		boolean env = false,
		boolean settings = false
	) {
		requireWheelsApp(getCWD());
		// Reconstruct and validate arguments
		arguments = reconstructArgs(
			argStruct = arguments,
			allowedValues = {
				format: ["table", "json"]
			}
		);


		// Validate environments are different
		if (arguments.env1 == arguments.env2) {
			error("Cannot compare an environment to itself");
		}

		// Determine what to compare
		local.compareSettings = true;
		local.compareEnv = true;
		
		// If both flags are provided or neither, compare both
		if (arguments.settings && arguments.env) {
			local.compareSettings = true;
			local.compareEnv = true;
		} else if (arguments.settings) {
			local.compareSettings = true;
			local.compareEnv = false;
		} else if (arguments.env) {
			local.compareSettings = false;
			local.compareEnv = true;
		}
		// If neither flag is provided, compare both (default behavior)

		local.allDifferences = {};

		// Check if both environments exist (either settings OR .env file)
		// Get all file paths first
		local.configPath = ResolvePath("config");
		local.settingsFile = local.configPath & "/settings.cfm";
		local.env1SettingsFile = local.configPath & "/" & arguments.env1 & "/settings.cfm";
		local.env2SettingsFile = local.configPath & "/" & arguments.env2 & "/settings.cfm";
		local.env1File = ResolvePath(".env.#arguments.env1#");
		local.env2File = ResolvePath(".env.#arguments.env2#");
		local.baseEnvFile = ResolvePath(".env");

		// Check if environment 1 exists (either settings OR .env)
		local.env1SettingsExists = fileExists(local.env1SettingsFile);
		local.env1EnvExists = fileExists(local.env1File) || (arguments.env1 == "development" && fileExists(local.baseEnvFile));

		if (!local.env1SettingsExists && !local.env1EnvExists) {
			print.yellowLine("Warning: Environment '#arguments.env1#' not found!");
			print.cyanLine("  Settings file: #local.env1SettingsFile# (not found)");
			print.cyanLine("  Env file: #local.env1File# (not found)");
			print.redLine("Environment '#arguments.env1#' does not exist. No settings file or .env file found.");
			return;
		}

		// Check if environment 2 exists (either settings OR .env)
		local.env2SettingsExists = fileExists(local.env2SettingsFile);
		local.env2EnvExists = fileExists(local.env2File) || (arguments.env2 == "development" && fileExists(local.baseEnvFile));

		if (!local.env2SettingsExists && !local.env2EnvExists) {
			print.yellowLine("Warning: Environment '#arguments.env2#' not found!");
			print.cyanLine("  Settings file: #local.env2SettingsFile# (not found)");
			print.cyanLine("  Env file: #local.env2File# (not found)");
			print.redLine("Environment '#arguments.env2#' does not exist. No settings file or .env file found.");
			return;
		}

		// Compare settings if requested
		if (local.compareSettings) {
			if (!FileExists(local.settingsFile)) {
				error("No settings.cfm file found in config directory");
			}

			// Load configurations for both environments (even if files don't exist, will be empty)
			local.config1 = loadConfiguration(local.settingsFile, local.env1SettingsFile);
			local.config2 = loadConfiguration(local.settingsFile, local.env2SettingsFile);

			// Compare configurations
			local.allDifferences.settings = compareConfigurations(local.config1, local.config2);
		}

		// Compare environment variables if requested
		if (local.compareEnv) {
			local.envVars1 = {};
			local.envVars2 = {};

			// Load environment variables for env1
			if (FileExists(local.env1File)) {
				local.envVars1 = loadEnvFile(local.env1File);
			} else if (arguments.env1 == "development" && FileExists(local.baseEnvFile)) {
				// Fall back to .env for development
				local.envVars1 = loadEnvFile(local.baseEnvFile);
			}

			// Load environment variables for env2
			if (FileExists(local.env2File)) {
				local.envVars2 = loadEnvFile(local.env2File);
			} else if (arguments.env2 == "development" && FileExists(local.baseEnvFile)) {
				// Fall back to .env for development
				local.envVars2 = loadEnvFile(local.baseEnvFile);
			}

			// Compare environment variables
			local.allDifferences.env = compareConfigurations(local.envVars1, local.envVars2);
		}

		// Output results
		if (arguments.format == "json") {
			outputAsJson(local.allDifferences, arguments.env1, arguments.env2, local.compareSettings, local.compareEnv);
		} else {
			outputAsTable(local.allDifferences, arguments.env1, arguments.env2, arguments.changesOnly, local.compareSettings, local.compareEnv);
		}
	}

	private struct function loadEnvFile(required string filePath) {
		local.envVars = {};
		
		if (FileExists(arguments.filePath)) {
			local.content = FileRead(arguments.filePath);
			local.lines = ListToArray(local.content, Chr(10));
			
			for (local.line in local.lines) {
				local.line = Trim(local.line);
				// Skip empty lines and comments
				if (Len(local.line) && Left(local.line, 1) != "##") {
					// Parse KEY=value pairs
					if (Find("=", local.line)) {
						local.key = Trim(ListFirst(local.line, "="));
						local.value = Trim(ListRest(local.line, "="));
						
						// Remove quotes if present
						if (Left(local.value, 1) == '"' && Right(local.value, 1) == '"') {
							local.value = Mid(local.value, 2, Len(local.value) - 2);
						} else if (Left(local.value, 1) == "'" && Right(local.value, 1) == "'") {
							local.value = Mid(local.value, 2, Len(local.value) - 2);
						}
						
						// Handle inline comments (remove anything after # that's not in quotes)
						local.commentPos = Find("##", local.value);
						if (local.commentPos > 0) {
							local.value = Trim(Left(local.value, local.commentPos - 1));
						}
						
						local.envVars[local.key] = local.value;
					}
				}
			}
		}
		
		return local.envVars;
	}

	private struct function compareConfigurations(required struct config1, required struct config2) {
		local.result = {
			identical: [],
			different: [],
			onlyInFirst: [],
			onlyInSecond: []
		};

		// Check all keys in config1
		for (local.key in arguments.config1) {
			if (StructKeyExists(arguments.config2, local.key)) {
				local.value1 = arguments.config1[local.key];
				local.value2 = arguments.config2[local.key];
				
				if (IsSimpleValue(local.value1) && IsSimpleValue(local.value2)) {
					if (local.value1 == local.value2) {
						ArrayAppend(local.result.identical, {
							key: local.key,
							value: local.value1
						});
					} else {
						ArrayAppend(local.result.different, {
							key: local.key,
							value1: local.value1,
							value2: local.value2
						});
					}
				}
			} else if (IsSimpleValue(arguments.config1[local.key])) {
				ArrayAppend(local.result.onlyInFirst, {
					key: local.key,
					value: arguments.config1[local.key]
				});
			}
		}

		// Check for keys only in config2
		for (local.key in arguments.config2) {
			if (!StructKeyExists(arguments.config1, local.key) && IsSimpleValue(arguments.config2[local.key])) {
				ArrayAppend(local.result.onlyInSecond, {
					key: local.key,
					value: arguments.config2[local.key]
				});
			}
		}

		return local.result;
	}

	private void function outputAsTable(
		required struct differences,
		required string env1,
		required string env2,
		required boolean changesOnly,
		required boolean compareSettings,
		required boolean compareEnv
	) {
		print.line();
		print.boldBlueLine("========================================");
		print.boldLine("Configuration Comparison: #arguments.env1# vs #arguments.env2#");
		print.boldBlueLine("========================================");
		print.line();

		// Display settings differences
		if (arguments.compareSettings && StructKeyExists(arguments.differences, "settings")) {
			print.boldCyanLine("[SETTINGS CONFIGURATION]");
			print.line();
			displayDifferenceSection(arguments.differences.settings, arguments.env1, arguments.env2, arguments.changesOnly, "settings");
		}

		// Display environment variable differences
		if (arguments.compareEnv && StructKeyExists(arguments.differences, "env")) {
			if (arguments.compareSettings && StructKeyExists(arguments.differences, "settings")) {
				print.line();
			}
			print.boldCyanLine("[ENVIRONMENT VARIABLES]");
			print.line();
			displayDifferenceSection(arguments.differences.env, arguments.env1, arguments.env2, arguments.changesOnly, "env");
		}

		// Display combined summary
		print.boldBlueLine("========================================");
		print.boldLine("SUMMARY");
		print.boldBlueLine("========================================");
		
		local.totalIdentical = 0;
		local.totalDifferent = 0;
		local.totalUnique = 0;
		
		if (arguments.compareSettings && StructKeyExists(arguments.differences, "settings")) {
			local.s = arguments.differences.settings;
			local.settingsTotal = ArrayLen(s.identical) + ArrayLen(s.different) + ArrayLen(s.onlyInFirst) + ArrayLen(s.onlyInSecond);
			local.totalIdentical += ArrayLen(s.identical);
			local.totalDifferent += ArrayLen(s.different);
			local.totalUnique += ArrayLen(s.onlyInFirst) + ArrayLen(s.onlyInSecond);
			
			print.line("Settings:");
			print.line("  Total: #local.settingsTotal#");
			print.greenLine("  Identical: #ArrayLen(s.identical)#");
			if (ArrayLen(s.different) > 0) {
				print.yellowLine("  Different: #ArrayLen(s.different)#");
			}
			if (ArrayLen(s.onlyInFirst) + ArrayLen(s.onlyInSecond) > 0) {
				print.redLine("  Unique: #ArrayLen(s.onlyInFirst) + ArrayLen(s.onlyInSecond)#");
			}
		}
		
		if (arguments.compareEnv && StructKeyExists(arguments.differences, "env")) {
			if (arguments.compareSettings && StructKeyExists(arguments.differences, "settings")) {
				print.line();
			}
			local.e = arguments.differences.env;
			local.envTotal = ArrayLen(e.identical) + ArrayLen(e.different) + ArrayLen(e.onlyInFirst) + ArrayLen(e.onlyInSecond);
			local.totalIdentical += ArrayLen(e.identical);
			local.totalDifferent += ArrayLen(e.different);
			local.totalUnique += ArrayLen(e.onlyInFirst) + ArrayLen(e.onlyInSecond);
			
			print.line("Environment Variables:");
			print.line("  Total: #local.envTotal#");
			print.greenLine("  Identical: #ArrayLen(e.identical)#");
			if (ArrayLen(e.different) > 0) {
				print.yellowLine("  Different: #ArrayLen(e.different)#");
			}
			if (ArrayLen(e.onlyInFirst) + ArrayLen(e.onlyInSecond) > 0) {
				print.redLine("  Unique: #ArrayLen(e.onlyInFirst) + ArrayLen(e.onlyInSecond)#");
			}
		}
		
		// Overall summary
		local.grandTotal = local.totalIdentical + local.totalDifferent + local.totalUnique;
		if (local.grandTotal > 0) {
			print.line();
			print.boldLine("Overall:");
			print.line("  Total configurations: #local.grandTotal#");
			print.greenLine("  Identical: #local.totalIdentical#");
			if (local.totalDifferent > 0) {
				print.yellowLine("  Different: #local.totalDifferent#");
			}
			if (local.totalUnique > 0) {
				print.redLine("  Unique: #local.totalUnique#");
			}
			
			local.similarity = Round((local.totalIdentical / local.grandTotal) * 100);
			print.line("  Similarity: #local.similarity#%");
		}
		
		if (local.totalDifferent == 0 && local.totalUnique == 0) {
			print.line();
			print.greenLine("Configurations are identical!");
		}
	}

	private void function displayDifferenceSection(
		required struct differences,
		required string env1,
		required string env2,
		required boolean changesOnly,
		required string type
	) {
		local.hasChanges = false;

		// Show differences
		if (ArrayLen(arguments.differences.different)) {
			local.hasChanges = true;
			print.boldYellowLine("Different Values:");
			local.data = [];
			for (local.item in arguments.differences.different) {
				ArrayAppend(local.data, {
					setting: local.item.key,
					env1: maskSensitiveValue(local.item.key, local.item.value1),
					env2: maskSensitiveValue(local.item.key, local.item.value2)
				});
			}
			print.table(
				data = local.data,
				headers = [arguments.type == "env" ? "Variable" : "Setting", arguments.env1, arguments.env2]
			);
			print.line();
		}

		// Show only in first environment
		if (ArrayLen(arguments.differences.onlyInFirst)) {
			local.hasChanges = true;
			print.boldRedLine("Only in #arguments.env1#:");
			local.data = [];
			for (local.item in arguments.differences.onlyInFirst) {
				ArrayAppend(local.data, {
					setting: local.item.key,
					value: maskSensitiveValue(local.item.key, local.item.value)
				});
			}
			print.table(
				data = local.data,
				headers = [arguments.type == "env" ? "Variable" : "Setting", "Value"]
			);
			print.line();
		}

		// Show only in second environment
		if (ArrayLen(arguments.differences.onlyInSecond)) {
			local.hasChanges = true;
			print.boldGreenLine("Only in #arguments.env2#:");
			local.data = [];
			for (local.item in arguments.differences.onlyInSecond) {
				ArrayAppend(local.data, {
					setting: local.item.key,
					value: maskSensitiveValue(local.item.key, local.item.value)
				});
			}
			print.table(
				data = local.data,
				headers = [arguments.type == "env" ? "Variable" : "Setting", "Value"]
			);
			print.line();
		}

		// Show identical values if not changes-only
		if (!arguments.changesOnly && ArrayLen(arguments.differences.identical)) {
			print.boldLine("Identical Values:");
			local.data = [];
			for (local.item in arguments.differences.identical) {
				ArrayAppend(local.data, {
					setting: local.item.key,
					value: maskSensitiveValue(local.item.key, local.item.value)
				});
			}
			print.table(
				data = local.data,
				headers = [arguments.type == "env" ? "Variable" : "Setting", "Value"]
			);
			print.line();
		}

		if (!local.hasChanges && !arguments.changesOnly) {
			print.greenLine("No differences found in #arguments.type#.");
		}
	}

	private void function outputAsJson(
		required struct differences,
		required string env1,
		required string env2,
		required boolean compareSettings,
		required boolean compareEnv
	) {
		local.output = {
			env1: arguments.env1,
			env2: arguments.env2,
			comparisons: {}
		};

		// Add settings comparison if available
		if (arguments.compareSettings && StructKeyExists(arguments.differences, "settings")) {
			local.output.comparisons.settings = arguments.differences.settings;
			
			// Mask sensitive values in settings
			for (local.item in local.output.comparisons.settings.different) {
				local.item.value1 = maskSensitiveValue(local.item.key, local.item.value1);
				local.item.value2 = maskSensitiveValue(local.item.key, local.item.value2);
			}
			for (local.item in local.output.comparisons.settings.onlyInFirst) {
				local.item.value = maskSensitiveValue(local.item.key, local.item.value);
			}
			for (local.item in local.output.comparisons.settings.onlyInSecond) {
				local.item.value = maskSensitiveValue(local.item.key, local.item.value);
			}
			for (local.item in local.output.comparisons.settings.identical) {
				local.item.value = maskSensitiveValue(local.item.key, local.item.value);
			}
		}

		// Add env comparison if available
		if (arguments.compareEnv && StructKeyExists(arguments.differences, "env")) {
			local.output.comparisons.env = arguments.differences.env;
			
			// Mask sensitive values in env
			for (local.item in local.output.comparisons.env.different) {
				local.item.value1 = maskSensitiveValue(local.item.key, local.item.value1);
				local.item.value2 = maskSensitiveValue(local.item.key, local.item.value2);
			}
			for (local.item in local.output.comparisons.env.onlyInFirst) {
				local.item.value = maskSensitiveValue(local.item.key, local.item.value);
			}
			for (local.item in local.output.comparisons.env.onlyInSecond) {
				local.item.value = maskSensitiveValue(local.item.key, local.item.value);
			}
			for (local.item in local.output.comparisons.env.identical) {
				local.item.value = maskSensitiveValue(local.item.key, local.item.value);
			}
		}

		// Add summary
		local.output.summary = {
			settings: {},
			env: {},
			overall: {}
		};

		if (arguments.compareSettings && StructKeyExists(arguments.differences, "settings")) {
			local.s = arguments.differences.settings;
			local.output.summary.settings = {
				totalSettings: ArrayLen(s.identical) + ArrayLen(s.different) + ArrayLen(s.onlyInFirst) + ArrayLen(s.onlyInSecond),
				identical: ArrayLen(s.identical),
				different: ArrayLen(s.different),
				onlyInFirst: ArrayLen(s.onlyInFirst),
				onlyInSecond: ArrayLen(s.onlyInSecond)
			};
		}

		if (arguments.compareEnv && StructKeyExists(arguments.differences, "env")) {
			local.e = arguments.differences.env;
			local.output.summary.env = {
				totalVariables: ArrayLen(e.identical) + ArrayLen(e.different) + ArrayLen(e.onlyInFirst) + ArrayLen(e.onlyInSecond),
				identical: ArrayLen(e.identical),
				different: ArrayLen(e.different),
				onlyInFirst: ArrayLen(e.onlyInFirst),
				onlyInSecond: ArrayLen(e.onlyInSecond)
			};
		}

		// Calculate overall summary
		local.totalIdentical = 0;
		local.totalDifferent = 0;
		local.totalUnique = 0;
		local.grandTotal = 0;
		
		if (StructKeyExists(local.output.summary, "settings") && !StructIsEmpty(local.output.summary.settings)) {
			local.totalIdentical += local.output.summary.settings.identical;
			local.totalDifferent += local.output.summary.settings.different;
			local.totalUnique += local.output.summary.settings.onlyInFirst + local.output.summary.settings.onlyInSecond;
			local.grandTotal += local.output.summary.settings.totalSettings;
		}
		
		if (StructKeyExists(local.output.summary, "env") && !StructIsEmpty(local.output.summary.env)) {
			local.totalIdentical += local.output.summary.env.identical;
			local.totalDifferent += local.output.summary.env.different;
			local.totalUnique += local.output.summary.env.onlyInFirst + local.output.summary.env.onlyInSecond;
			local.grandTotal += local.output.summary.env.totalVariables;
		}
		
		local.output.summary.overall = {
			total: local.grandTotal,
			identical: local.totalIdentical,
			different: local.totalDifferent,
			unique: local.totalUnique,
			similarity: local.grandTotal > 0 ? Round((local.totalIdentical / local.grandTotal) * 100) : 0
		};
		local.jsonData = SerializeJSON(local.output, false, false);
		print.line(deserializeJSON(local.jsonData));
	}

	private string function maskSensitiveValue(required string key, required any value) {
		local.sensitiveKeys = [
			"password", "secret", "key", "token", "apikey", "api_key",
			"private", "credential", "auth", "passphrase", "salt"
		];

		for (local.sensitive in local.sensitiveKeys) {
			if (FindNoCase(local.sensitive, arguments.key)) {
				return "***MASKED***";
			}
		}

		return arguments.value;
	}

	private struct function loadConfiguration(required string settingsFile, string envSettingsFile = "") {
		local.settings = {};
		
		// Load base settings
		if (FileExists(arguments.settingsFile)) {
			local.content = FileRead(arguments.settingsFile);
			
			// Remove block comments (/* ... */) and line comments (// ...)
			local.cleaned = REReplace(local.content, "/\*[\s\S]*?\*/", "", "all"); // block comments
			local.cleaned = REReplace(local.cleaned, "//.*", "", "all"); // line comments
			
			// Extract set() calls
			local.pattern = 'set\s*\(\s*([^)]+)\s*\)';
			local.matches = REMatchNoCase(local.pattern, local.cleaned);
			
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
			
			// Remove block comments (/* ... */) and line comments (// ...)
			local.cleaned = REReplace(local.content, "/\*[\s\S]*?\*/", "", "all"); // block comments
			local.cleaned = REReplace(local.cleaned, "//.*", "", "all"); // line comments
			
			local.matches = REMatchNoCase(local.pattern, local.cleaned);
			
			for (local.match in local.matches) {
				try {
					local.args = parseSetArguments(local.match);
					StructAppend(local.settings, local.args, true);
				} catch (any e) {
					// Skip invalid set() calls
				}
			}
		}

		return local.settings;
	}

	private struct function parseSetArguments(required string setCall) {
		local.result = {};
		
		// Extract the arguments inside set()
		local.argsString = ReReplace(arguments.setCall, "^set\s*\(\s*", "");
		local.argsString = ReReplace(local.argsString, "\s*\)$", "");
		
		// Simple parser for key=value pairs
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

}