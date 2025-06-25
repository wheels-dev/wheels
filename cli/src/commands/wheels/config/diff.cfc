/**
 * Compares configuration between two environments
 * 
 * Examples:
 * {code:bash}
 * wheels config diff development production
 * wheels config diff testing production --changes-only
 * wheels config diff development testing --format=json
 * {code}
 */
component extends="commandbox.modules.wheels-cli.commands.wheels.base" {

	/**
	 * @env1.hint First environment to compare
	 * @env2.hint Second environment to compare
	 * @changes-only.hint Only show differences
	 * @format.hint Output format: table or json
	 * @format.options table,json
	 **/
	function run(
		required string env1,
		required string env2,
		boolean changesOnly = false,
		string format = "table"
	) {

		// Validate format
		if (!ListFindNoCase("table,json", arguments.format)) {
			error("Invalid format: #arguments.format#. Valid formats are: table, json");
		}

		// Validate environments are different
		if (arguments.env1 == arguments.env2) {
			error("Cannot compare an environment to itself");
		}

		// Get configuration paths
		local.configPath = ResolvePath("config");
		local.settingsFile = local.configPath & "/settings.cfm";
		
		if (!FileExists(local.settingsFile)) {
			error("No settings.cfm file found in config directory");
		}

		// Load configurations for both environments
		local.env1SettingsFile = local.configPath & "/" & arguments.env1 & "/settings.cfm";
		local.env2SettingsFile = local.configPath & "/" & arguments.env2 & "/settings.cfm";

		local.config1 = loadConfiguration(local.settingsFile, local.env1SettingsFile);
		local.config2 = loadConfiguration(local.settingsFile, local.env2SettingsFile);

		// Compare configurations
		local.differences = compareConfigurations(local.config1, local.config2);

		// Output results
		if (arguments.format == "json") {
			outputAsJson(local.differences, arguments.env1, arguments.env2);
		} else {
			outputAsTable(local.differences, arguments.env1, arguments.env2, arguments.changesOnly);
		}
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
		required boolean changesOnly
	) {
		print.line();
		print.boldLine("Configuration Comparison: #arguments.env1# vs #arguments.env2#");
		print.line();

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
				headers = ["Setting", arguments.env1, arguments.env2]
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
				headers = ["Setting", "Value"]
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
				headers = ["Setting", "Value"]
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
				headers = ["Setting", "Value"]
			);
			print.line();
		}

		// Summary
		local.totalSettings = ArrayLen(arguments.differences.identical) + 
			ArrayLen(arguments.differences.different) + 
			ArrayLen(arguments.differences.onlyInFirst) + 
			ArrayLen(arguments.differences.onlyInSecond);
		
		local.identicalCount = ArrayLen(arguments.differences.identical);
		local.differentCount = ArrayLen(arguments.differences.different);
		local.uniqueCount = ArrayLen(arguments.differences.onlyInFirst) + ArrayLen(arguments.differences.onlyInSecond);
		
		print.boldLine("Summary:");
		print.line("  Total settings: #local.totalSettings#");
		print.greenLine("  Identical: #local.identicalCount#");
		if (local.differentCount > 0) {
			print.yellowLine("  Different: #local.differentCount#");
		}
		if (local.uniqueCount > 0) {
			print.redLine("  Unique: #local.uniqueCount#");
		}
		
		// Calculate similarity percentage
		if (local.totalSettings > 0) {
			local.similarity = Round((local.identicalCount / local.totalSettings) * 100);
			print.line("  Similarity: #local.similarity#%");
		}

		if (!local.hasChanges) {
			print.line();
			print.greenLine("✓ Configurations are identical!");
		}
	}

	private void function outputAsJson(
		required struct differences,
		required string env1,
		required string env2
	) {
		local.output = {
			env1: arguments.env1,
			env2: arguments.env2,
			differences: arguments.differences,
			summary: {
				totalSettings: ArrayLen(arguments.differences.identical) + 
					ArrayLen(arguments.differences.different) + 
					ArrayLen(arguments.differences.onlyInFirst) + 
					ArrayLen(arguments.differences.onlyInSecond),
				identical: ArrayLen(arguments.differences.identical),
				different: ArrayLen(arguments.differences.different),
				onlyInFirst: ArrayLen(arguments.differences.onlyInFirst),
				onlyInSecond: ArrayLen(arguments.differences.onlyInSecond)
			}
		};

		// Mask sensitive values in JSON output
		for (local.item in local.output.differences.different) {
			local.item.value1 = maskSensitiveValue(local.item.key, local.item.value1);
			local.item.value2 = maskSensitiveValue(local.item.key, local.item.value2);
		}
		for (local.item in local.output.differences.onlyInFirst) {
			local.item.value = maskSensitiveValue(local.item.key, local.item.value);
		}
		for (local.item in local.output.differences.onlyInSecond) {
			local.item.value = maskSensitiveValue(local.item.key, local.item.value);
		}
		for (local.item in local.output.differences.identical) {
			local.item.value = maskSensitiveValue(local.item.key, local.item.value);
		}

		print.line(SerializeJSON(local.output, false, false));
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