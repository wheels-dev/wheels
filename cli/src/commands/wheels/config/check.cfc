/**
 * Validates configuration settings
 * 
 * Examples:
 * {code:bash}
 * wheels config check
 * wheels config check testing
 * wheels config check --verbose
 * wheels config check --fix
 * {code}
 */
component extends="commandbox.modules.wheels-cli.commands.wheels.base" {

	/**
	 * @environment.hint The environment to check (development, testing, production)
	 * @verbose.hint Show detailed validation information
	 * @fix.hint Attempt to fix issues automatically
	 **/
	function run(
		string environment = "",
		boolean verbose = false,
		boolean fix = false
	) {

		// Determine environment
		local.env = Len(arguments.environment) ? arguments.environment : getEnvironment();
		
		print.line();
		print.boldLine("Checking configuration for environment: #local.env#");
		print.line();

		local.issues = [];
		local.warnings = [];
		local.fixed = [];

		// Check settings files exist
		local.configPath = ResolvePath("config");
		local.settingsFile = local.configPath & "/settings.cfm";
		local.envSettingsFile = local.configPath & "/" & local.env & "/settings.cfm";

		if (!FileExists(local.settingsFile)) {
			ArrayAppend(local.issues, {
				type: "error",
				message: "Missing config/settings.cfm file",
				fix: "Create a settings.cfm file in the config directory"
			});
		}

		// Load configuration
		local.config = {};
		if (FileExists(local.settingsFile)) {
			local.config = loadConfiguration(local.settingsFile, local.envSettingsFile);
		}

		// Check for required settings
		checkRequiredSettings(local.config, local.issues, local.warnings);

		// Check for security issues
		checkSecuritySettings(local.config, local.issues, local.warnings, local.env);

		// Check database configuration
		checkDatabaseSettings(local.config, local.issues, local.warnings);

		// Check environment configuration
		checkEnvironmentSettings(local.config, local.issues, local.warnings, local.env);

		// Check .env file
		checkEnvFile(local.issues, local.warnings, arguments.fix, local.fixed);

		// Display results
		displayResults(local.issues, local.warnings, local.fixed, arguments.verbose);

		// Return appropriate exit code
		if (ArrayLen(local.issues)) {
			setExitCode(1);
		}
	}

	private void function checkRequiredSettings(
		required struct config,
		required array issues,
		required array warnings
	) {
		// Check for datasource
		if (!StructKeyExists(arguments.config, "dataSourceName") || !Len(arguments.config.dataSourceName)) {
			ArrayAppend(arguments.issues, {
				type: "error",
				message: "No datasource configured",
				fix: "Add set(dataSourceName = 'your_datasource') to config/settings.cfm"
			});
		}
	}

	private void function checkSecuritySettings(
		required struct config,
		required array issues,
		required array warnings,
		required string environment
	) {
		// Check for exposed sensitive values
		local.sensitiveKeys = ["password", "secret", "key", "token", "apikey"];
		
		for (local.key in arguments.config) {
			local.value = arguments.config[local.key];
			if (IsSimpleValue(local.value) && Len(local.value)) {
				for (local.sensitive in local.sensitiveKeys) {
					if (FindNoCase(local.sensitive, local.key)) {
						// Check if value looks hardcoded
						if (!Find("application.env", local.value) && !Find("${", local.value)) {
							ArrayAppend(arguments.warnings, {
								type: "warning",
								message: "Possible hardcoded sensitive value in '#local.key#'",
								fix: "Move sensitive values to .env file and reference with application.env['KEY_NAME']"
							});
						}
						break;
					}
				}
			}
		}

		// Production-specific checks
		if (arguments.environment == "production") {
			// Check if debug mode is enabled
			if (StructKeyExists(arguments.config, "showDebugInformation") && arguments.config.showDebugInformation) {
				ArrayAppend(arguments.issues, {
					type: "error",
					message: "Debug mode is enabled in production",
					fix: "Set showDebugInformation = false in config/production/settings.cfm"
				});
			}

			// Check if error emails are configured
			if (!StructKeyExists(arguments.config, "sendEmailOnError") || !arguments.config.sendEmailOnError) {
				ArrayAppend(arguments.warnings, {
					type: "warning",
					message: "Error emails not configured for production",
					fix: "Enable sendEmailOnError and configure errorEmailAddress"
				});
			}

			// Check reload password
			if (StructKeyExists(arguments.config, "reloadPassword") && 
				(arguments.config.reloadPassword == "reload" || arguments.config.reloadPassword == "")) {
				ArrayAppend(arguments.issues, {
					type: "error",
					message: "Weak or default reload password in production",
					fix: "Set a strong reloadPassword in config/production/settings.cfm"
				});
			}
		}
	}

	private void function checkDatabaseSettings(
		required struct config,
		required array issues,
		required array warnings
	) {
		// Check datasource exists
		if (StructKeyExists(arguments.config, "dataSourceName") && Len(arguments.config.dataSourceName)) {
			try {
				// Try to get datasource info
				local.datasources = getApplicationSettings().datasources;
				if (!StructKeyExists(local.datasources, arguments.config.dataSourceName)) {
					ArrayAppend(arguments.issues, {
						type: "error",
						message: "Datasource '#arguments.config.dataSourceName#' not found",
						fix: "Configure the datasource in your CFML administrator or Application.cfc"
					});
				}
			} catch (any e) {
				// Can't check datasources
			}
		}

		// Check migration settings
		if (StructKeyExists(arguments.config, "autoMigrateDatabase") && arguments.config.autoMigrateDatabase) {
			ArrayAppend(arguments.warnings, {
				type: "warning",
				message: "Automatic database migration is enabled",
				fix: "Consider disabling autoMigrateDatabase in production"
			});
		}
	}

	private void function checkEnvironmentSettings(
		required struct config,
		required array issues,
		required array warnings,
		required string environment
	) {
		// Check if environment-specific directory exists
		local.envDir = ResolvePath("config/#arguments.environment#");
		if (!DirectoryExists(local.envDir)) {
			ArrayAppend(arguments.warnings, {
				type: "warning",
				message: "No environment-specific config directory for '#arguments.environment#'",
				fix: "Create directory: config/#arguments.environment#/"
			});
		}

		// Check caching settings
		if (arguments.environment == "production") {
			local.cacheSettings = [
				"cacheControllerConfig", "cacheDatabaseSchema", "cacheFileChecking",
				"cacheImages", "cacheModelConfig", "cachePartials", "cacheQueries", "cacheRoutes"
			];
			
			for (local.setting in local.cacheSettings) {
				if (StructKeyExists(arguments.config, local.setting) && !arguments.config[local.setting]) {
					ArrayAppend(arguments.warnings, {
						type: "warning",
						message: "Caching disabled for #local.setting# in production",
						fix: "Enable #local.setting# for better performance"
					});
				}
			}
		}
	}

	private void function checkEnvFile(
		required array issues,
		required array warnings,
		required boolean fix,
		required array fixed
	) {
		local.envFile = ResolvePath(".env");
		
		if (!FileExists(local.envFile)) {
			ArrayAppend(arguments.warnings, {
				type: "warning",
				message: "No .env file found",
				fix: "Create a .env file for environment-specific configuration"
			});

			if (arguments.fix) {
				// Create a sample .env file
				local.sampleEnv = [
					"## Wheels Environment Configuration",
					"WHEELS_ENV=development",
					"",
					"## Database Configuration",
					"DB_HOST=localhost",
					"DB_PORT=3306",
					"DB_NAME=your_database",
					"DB_USER=your_username",
					"DB_PASSWORD=your_password",
					"",
					"## Application Settings",
					"RELOAD_PASSWORD=your_reload_password",
					"SECRET_KEY=your_secret_key"
				];
				
				try {
					FileWrite(local.envFile, ArrayToList(local.sampleEnv, Chr(10)));
					ArrayAppend(arguments.fixed, "Created sample .env file");
				} catch (any e) {
					// Could not create file
				}
			}
		} else {
			// Check .env file permissions
			local.fileInfo = GetFileInfo(local.envFile);
			// Check file permissions - note that canExecute may not exist on all platforms
			local.hasPermissionIssue = false;
			if (structKeyExists(fileInfo, "canRead") && structKeyExists(fileInfo, "canWrite")) {
				// On systems that support execute permission
				if (structKeyExists(fileInfo, "canExecute") && fileInfo.canExecute) {
					local.hasPermissionIssue = true;
				}
			}
			
			if (local.hasPermissionIssue) {
				ArrayAppend(arguments.warnings, {
					type: "warning",
					message: ".env file has overly permissive permissions",
					fix: "Restrict .env file permissions (chmod 600 .env)"
				});
			}

			// Check if .env is in .gitignore
			local.gitignore = ResolvePath(".gitignore");
			if (FileExists(local.gitignore)) {
				local.gitignoreContent = FileRead(local.gitignore);
				if (!FindNoCase(".env", local.gitignoreContent)) {
					ArrayAppend(arguments.issues, {
						type: "error",
						message: ".env file not in .gitignore",
						fix: "Add .env to .gitignore to prevent committing secrets"
					});

					if (arguments.fix) {
						try {
							FileWrite(local.gitignore, local.gitignoreContent & Chr(10) & ".env" & Chr(10));
							ArrayAppend(arguments.fixed, "Added .env to .gitignore");
						} catch (any e) {
							// Could not update file
						}
					}
				}
			}
		}
	}

	private void function displayResults(
		required array issues,
		required array warnings,
		required array fixed,
		required boolean verbose
	) {
		// Display fixed items
		if (ArrayLen(arguments.fixed)) {
			print.boldGreenLine("Fixed:");
			for (local.fix in arguments.fixed) {
				print.greenLine("  ✓ #local.fix#");
			}
			print.line();
		}

		// Display errors
		if (ArrayLen(arguments.issues)) {
			print.boldRedLine("Errors:");
			for (local.issue in arguments.issues) {
				print.redLine("  ✗ #local.issue.message#");
				if (arguments.verbose) {
					print.yellowLine("    Fix: #local.issue.fix#");
				}
			}
			print.line();
		}

		// Display warnings
		if (ArrayLen(arguments.warnings)) {
			print.boldYellowLine("Warnings:");
			for (local.warning in arguments.warnings) {
				print.yellowLine("  ⚠ #local.warning.message#");
				if (arguments.verbose) {
					print.line("    Fix: #local.warning.fix#");
				}
			}
			print.line();
		}

		// Summary
		local.errorCount = ArrayLen(arguments.issues);
		local.warningCount = ArrayLen(arguments.warnings);
		
		if (local.errorCount == 0 && local.warningCount == 0) {
			print.greenLine("✓ Configuration validation passed!");
		} else {
			local.summary = [];
			if (local.errorCount > 0) {
				ArrayAppend(local.summary, "#local.errorCount# error#local.errorCount != 1 ? 's' : ''#");
			}
			if (local.warningCount > 0) {
				ArrayAppend(local.summary, "#local.warningCount# warning#local.warningCount != 1 ? 's' : ''#");
			}
			print.line("Configuration check complete: #ArrayToList(local.summary, ', ')#");
			
			if (!arguments.verbose && (local.errorCount > 0 || local.warningCount > 0)) {
				print.line();
				print.line("Run with --verbose flag for detailed fix suggestions");
			}
		}
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

	private string function getEnvironment() {
		// Try to detect from various sources
		local.env = "";
		
		// Check .env file
		local.envFile = ResolvePath(".env");
		if (FileExists(local.envFile)) {
			local.content = FileRead(local.envFile);
			if (IsJSON(local.content)) {
				local.envVars = DeserializeJSON(local.content);
				if (StructKeyExists(local.envVars, "WHEELS_ENV")) {
					local.env = local.envVars.WHEELS_ENV;
				}
			} else {
				// Parse as properties file
				local.lines = ListToArray(local.content, Chr(10));
				for (local.line in local.lines) {
					local.line = Trim(local.line);
					if (Len(local.line) && Left(local.line, 1) != "##") {
						if (Find("=", local.line) && FindNoCase("WHEELS_ENV", local.line)) {
							local.env = Trim(ListRest(local.line, "="));
							break;
						}
					}
				}
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