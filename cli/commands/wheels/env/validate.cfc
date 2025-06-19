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
component extends="commandbox.modules.wheels-cli.commands.wheels.base" {

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

		local.envFile = ResolvePath(arguments.file);
		
		if (!FileExists(local.envFile)) {
			error("File not found: #arguments.file#");
		}

		print.line();
		print.boldLine("Validating: #arguments.file#");
		print.line();

		local.issues = [];
		local.warnings = [];
		local.envVars = {};

		// Read and parse the file
		local.content = FileRead(local.envFile);
		local.lineNumber = 0;

		// Check if it's JSON format
		if (IsJSON(local.content)) {
			try {
				local.envVars = DeserializeJSON(local.content);
				print.greenLine("✓ Valid JSON format");
			} catch (any e) {
				ArrayAppend(local.issues, {
					line: 0,
					message: "Invalid JSON format: #e.message#"
				});
			}
		} else {
			// Parse as properties file
			local.lines = ListToArray(local.content, Chr(10));
			
			for (local.line in local.lines) {
				local.lineNumber++;
				local.trimmedLine = Trim(local.line);
				
				// Skip empty lines and comments
				if (!Len(local.trimmedLine) || Left(local.trimmedLine, 1) == "##") {
					continue;
				}
				
				// Check for valid key=value format
				if (!Find("=", local.trimmedLine)) {
					ArrayAppend(local.issues, {
						line: local.lineNumber,
						message: "Invalid format (missing '='): #local.trimmedLine#"
					});
					continue;
				}
				
				local.key = Trim(ListFirst(local.trimmedLine, "="));
				local.value = Trim(ListRest(local.trimmedLine, "="));
				
				// Validate key format
				if (!Len(local.key)) {
					ArrayAppend(local.issues, {
						line: local.lineNumber,
						message: "Empty key name"
					});
					continue;
				}
				
				// Check for valid key characters (letters, numbers, underscores)
				if (!REFind("^[A-Za-z_][A-Za-z0-9_]*$", local.key)) {
					ArrayAppend(local.warnings, {
						line: local.lineNumber,
						message: "Non-standard key name: '#local.key#' (should contain only letters, numbers, and underscores)"
					});
				}
				
				// Check for duplicate keys
				if (StructKeyExists(local.envVars, local.key)) {
					ArrayAppend(local.warnings, {
						line: local.lineNumber,
						message: "Duplicate key: '#local.key#' (previous value will be overwritten)"
					});
				}
				
				// Check for potentially exposed secrets
				if (Len(local.value) && (
					FindNoCase("password", local.key) || 
					FindNoCase("secret", local.key) || 
					FindNoCase("key", local.key) || 
					FindNoCase("token", local.key)
				)) {
					// Check if value looks like a placeholder
					if (local.value == "your_password" || 
						local.value == "your_secret" || 
						local.value == "change_me" ||
						local.value == "xxx" ||
						local.value == "TODO") {
						ArrayAppend(local.warnings, {
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
		if (Len(arguments.required)) {
			local.requiredKeys = ListToArray(arguments.required);
			for (local.requiredKey in local.requiredKeys) {
				local.requiredKey = Trim(local.requiredKey);
				if (!StructKeyExists(local.envVars, local.requiredKey)) {
					ArrayAppend(local.issues, {
						line: 0,
						message: "Required key missing: '#local.requiredKey#'"
					});
				} else if (!Len(local.envVars[local.requiredKey])) {
					ArrayAppend(local.warnings, {
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
		if (ArrayLen(arguments.issues)) {
			print.boldRedLine("Errors found:");
			for (local.issue in arguments.issues) {
				if (local.issue.line > 0) {
					print.redLine("  Line #local.issue.line#: #local.issue.message#");
				} else {
					print.redLine("  #local.issue.message#");
				}
			}
			print.line();
		}

		// Display warnings
		if (ArrayLen(arguments.warnings)) {
			print.boldYellowLine("Warnings:");
			for (local.warning in arguments.warnings) {
				if (local.warning.line > 0) {
					print.yellowLine("  Line #local.warning.line#: #local.warning.message#");
				} else {
					print.yellowLine("  #local.warning.message#");
				}
			}
			print.line();
		}

		// Display summary
		local.keyCount = StructCount(arguments.envVars);
		print.boldLine("Summary:");
		print.line("  Total variables: #local.keyCount#");
		
		if (arguments.verbose && local.keyCount > 0) {
			print.line();
			print.boldLine("Environment Variables:");
			
			// Group by prefix
			local.grouped = {};
			local.ungrouped = [];
			
			for (local.key in arguments.envVars) {
				if (Find("_", local.key)) {
					local.prefix = ListFirst(local.key, "_");
					if (!StructKeyExists(local.grouped, local.prefix)) {
						local.grouped[local.prefix] = [];
					}
					ArrayAppend(local.grouped[local.prefix], local.key);
				} else {
					ArrayAppend(local.ungrouped, local.key);
				}
			}
			
			// Display grouped variables
			for (local.prefix in local.grouped) {
				print.line();
				print.line("  #local.prefix#:");
				for (local.key in local.grouped[local.prefix]) {
					local.value = arguments.envVars[local.key];
					// Mask sensitive values
					if (FindNoCase("password", local.key) || FindNoCase("secret", local.key) || 
						FindNoCase("key", local.key) || FindNoCase("token", local.key)) {
						local.value = "***MASKED***";
					}
					print.line("    #local.key# = #local.value#");
				}
			}
			
			// Display ungrouped variables
			if (ArrayLen(local.ungrouped)) {
				print.line();
				print.line("  Other:");
				for (local.key in local.ungrouped) {
					local.value = arguments.envVars[local.key];
					// Mask sensitive values
					if (FindNoCase("password", local.key) || FindNoCase("secret", local.key) || 
						FindNoCase("key", local.key) || FindNoCase("token", local.key)) {
						local.value = "***MASKED***";
					}
					print.line("    #local.key# = #local.value#");
				}
			}
		}

		print.line();
		
		// Final status
		if (ArrayLen(arguments.issues) == 0) {
			if (ArrayLen(arguments.warnings) == 0) {
				print.greenLine("✓ Validation passed with no issues!");
			} else {
				print.yellowLine("✓ Validation passed with #ArrayLen(arguments.warnings)# warning#ArrayLen(arguments.warnings) != 1 ? 's' : ''#");
			}
		} else {
			print.redLine("✗ Validation failed with #ArrayLen(arguments.issues)# error#ArrayLen(arguments.issues) != 1 ? 's' : ''#");
			setExitCode(1);
		}
	}

}