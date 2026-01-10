/**
 * Validates .env file format and content
 * 
 * Examples:
 * {code:bash}
 * wheels env validate
 * wheels env validate --file=.env.production
 * wheels env validate --required=DB_HOST,DB_USER,DB_PASSWORD
 * {code}
 */
component extends="../base" {

    property name="detailOutput" inject="DetailOutputService@wheels-cli";

	/**
	 * @file.hint The .env file to validate (defaults to .env)
	 * @required.hint Comma-separated list of required keys
	 * @verbose.hint Show detailed validation information
	 **/
	function run(
		string file = ".env",
		string required = "",
		boolean verbose = false
	) {
		requireWheelsApp(getCWD());
		arguments = reconstructArgs(arguments);
		
		local.envFile = resolvePath(arguments.file);
		
		if (!fileExists(local.envFile)) {
			detailOutput.error("File not found: #arguments.file#");
			setExitCode(1);
			return;
		}

		detailOutput.header("Validating: #arguments.file#");

		local.issues = [];
		local.warnings = [];
		local.envVars = {};

		// Read and parse the file
		local.content = fileRead(local.envFile);
		local.lineNumber = 0;

		// Check if it's JSON format
		if (isJSON(local.content)) {
			try {
				local.envVars = deserializeJSON(local.content);
				if (arguments.verbose) {
					detailOutput.statusInfo("Valid JSON format detected");
					detailOutput.line();
				}
			} catch (any e) {
				arrayAppend(local.issues, {
					line: 0,
					message: "Invalid JSON format: #e.message#"
				});
			}
		} else {
			// Parse as properties file
			local.lines = listToArray(local.content, chr(10));
			
			for (local.line in local.lines) {
				local.lineNumber++;
				local.trimmedLine = trim(local.line);
				
				// Skip empty lines and comments
				if (!len(local.trimmedLine) || left(local.trimmedLine, 1) == "##") {
					continue;
				}
				
				// Check for valid key=value format
				if (!find("=", local.trimmedLine)) {
					arrayAppend(local.issues, {
						line: local.lineNumber,
						message: "Invalid format (missing '='): #local.trimmedLine#"
					});
					continue;
				}
				
				local.key = trim(listFirst(local.trimmedLine, "="));
				local.value = trim(listRest(local.trimmedLine, "="));
				
				// Validate key format
				if (!len(local.key)) {
					arrayAppend(local.issues, {
						line: local.lineNumber,
						message: "Empty key name"
					});
					continue;
				}
				
				// Check for valid key characters (letters, numbers, underscores)
				if (!reFind("^[A-Za-z_][A-Za-z0-9_]*$", local.key)) {
					arrayAppend(local.warnings, {
						line: local.lineNumber,
						message: "Non-standard key name: '#local.key#' (should contain only letters, numbers, and underscores)"
					});
				}
				
				// Check for duplicate keys
				if (structKeyExists(local.envVars, local.key)) {
					arrayAppend(local.warnings, {
						line: local.lineNumber,
						message: "Duplicate key: '#local.key#' (previous value will be overwritten)"
					});
				}
				
				// Check for potentially exposed secrets with placeholder values
				if (len(local.value) && (
					findNoCase("password", local.key) || 
					findNoCase("secret", local.key) || 
					findNoCase("key", local.key) || 
					findNoCase("token", local.key)
				)) {
					// Check if value looks like a placeholder
					if (local.value == "your_password" || 
						local.value == "your_secret" || 
						local.value == "change_me" ||
						local.value == "xxx" ||
						local.value == "TODO") {
						arrayAppend(local.warnings, {
							line: local.lineNumber,
							message: "Placeholder value detected for '#local.key#'"
						});
					}
				}
				
				// Store the variable
				local.envVars[local.key] = local.value;
			}
		}

		// Check required keys
		if (len(arguments.required)) {
			local.requiredKeys = listToArray(arguments.required);
			for (local.requiredKey in local.requiredKeys) {
				local.requiredKey = trim(local.requiredKey);
				if (!structKeyExists(local.envVars, local.requiredKey)) {
					arrayAppend(local.issues, {
						line: 0,
						message: "Required key missing: '#local.requiredKey#'"
					});
				} else if (!len(local.envVars[local.requiredKey])) {
					arrayAppend(local.warnings, {
						line: 0,
						message: "Required key has empty value: '#local.requiredKey#'"
					});
				}
			}
		}

		// Display results
		displayValidationResults(local.issues, local.warnings, local.envVars, arguments.verbose);
	}

	private void function displayValidationResults(
		required array issues,
		required array warnings,
		required struct envVars,
		required boolean verbose
	) {
		// Display errors
		if (arrayLen(arguments.issues)) {
			detailOutput.statusFailed("Errors found:");
			for (local.issue in arguments.issues) {
				if (local.issue.line > 0) {
					detailOutput.output("- Line #local.issue.line#: #local.issue.message#", true);
				} else {
					detailOutput.output("- #local.issue.message#", true);
				}
			}
			detailOutput.line();
		}

		// Display warnings
		if (arrayLen(arguments.warnings)) {
			detailOutput.statusWarning("Warnings:");
			for (local.warning in arguments.warnings) {
				if (local.warning.line > 0) {
					detailOutput.output("- Line #local.warning.line#: #local.warning.message#", true);
				} else {
					detailOutput.output("- #local.warning.message#", true);
				}
			}
			detailOutput.line();
		}

		// Display summary
		local.keyCount = structCount(arguments.envVars);
		detailOutput.subHeader("Summary");
		detailOutput.metric("Total variables", local.keyCount);
		
		if (arguments.verbose && local.keyCount > 0) {
			detailOutput.line();
			detailOutput.subHeader("Environment Variables:");
			
			// Group by prefix
			local.grouped = {};
			local.ungrouped = [];
			
			for (local.key in arguments.envVars) {
				if (find("_", local.key)) {
					local.prefix = listFirst(local.key, "_");
					if (!structKeyExists(local.grouped, local.prefix)) {
						local.grouped[local.prefix] = [];
					}
					arrayAppend(local.grouped[local.prefix], local.key);
				} else {
					arrayAppend(local.ungrouped, local.key);
				}
			}
			
			// Display grouped variables
			for (local.prefix in local.grouped) {
				detailOutput.line();
				detailOutput.output("#local.prefix#:");
				for (local.key in local.grouped[local.prefix]) {
					local.value = arguments.envVars[local.key];
					// Mask sensitive values
					if (findNoCase("password", local.key) || findNoCase("secret", local.key) || 
						findNoCase("key", local.key) || findNoCase("token", local.key)) {
						local.value = "***MASKED***";
					}
					detailOutput.output("- #local.key# = #local.value#", true);
				}
			}
			
			// Display ungrouped variables
			if (arrayLen(local.ungrouped)) {
				detailOutput.line();
				detailOutput.output("Other:");
				for (local.key in local.ungrouped) {
					local.value = arguments.envVars[local.key];
					// Mask sensitive values
					if (findNoCase("password", local.key) || findNoCase("secret", local.key) || 
						findNoCase("key", local.key) || findNoCase("token", local.key)) {
						local.value = "***MASKED***";
					}
					detailOutput.output("  #local.key# = #local.value#", true);
				}
			}
		}

		detailOutput.line();
		
		// Final status
		if (arrayLen(arguments.issues) == 0) {
			if (arrayLen(arguments.warnings) == 0) {
				detailOutput.statusSuccess("Validation passed with no issues!");
			} else {
				detailOutput.statusWarning("Validation passed with #arrayLen(arguments.warnings)# warning#arrayLen(arguments.warnings) != 1 ? 's' : ''#");
			}
		} else {
			detailOutput.statusFailed("Validation failed with #arrayLen(arguments.issues)# error#arrayLen(arguments.issues) != 1 ? 's' : ''#");
			setExitCode(1);
			return;
		}
	}
}