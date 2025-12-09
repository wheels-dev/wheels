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
	property name="detailOutput" inject="DetailOutputService@wheels-cli";

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
		requireWheelsApp(getCWD());
		arguments = reconstructArgs(argStruct=arguments);
		// Determine environment
		local.env = Len(arguments.environment) ? arguments.environment : getEnvironment();
		
		detailOutput.line();
		detailOutput.header("Configuration Validation - #local.env# Environment");
		detailOutput.line();

		local.issues = [];
		local.warnings = [];
		local.fixed = [];

		// Check settings files exist
		if(arguments.verbose) {
			print.line("Checking configuration files... ").toConsole();
		}
		local.configPath = ResolvePath("config");
		local.settingsFile = local.configPath & "/settings.cfm";
		local.envSettingsFile = local.configPath & "/" & local.env & "/settings.cfm";

		if (!FileExists(local.settingsFile)) {
			detailOutput.statusFailed("Files Configuration");
			ArrayAppend(local.issues, {
				type: "error",
				message: "Missing config/settings.cfm file",
				fix: "Create a settings.cfm file in the config directory"
			});
		} else {
			detailOutput.statusSuccess("Files Configuration");
		}

		// Load configuration
		local.config = {};
		if (FileExists(local.settingsFile)) {
			local.config = loadConfiguration(local.settingsFile, local.envSettingsFile);
		}

		// Check for required settings
		if(arguments.verbose) {
			print.line("Checking required settings... ").toConsole();
		}
		local.startCount = ArrayLen(local.issues);
		checkRequiredSettings(local.config, local.issues, local.warnings);
		if (ArrayLen(local.issues) > local.startCount) {
			detailOutput.statusFailed("Required Settings");
		} else {
			detailOutput.statusSuccess("Required Settings");
		}

		// Check for security issues
		if(arguments.verbose) {
			print.line("Checking security configuration... ").toConsole();
		}
		local.startCount = ArrayLen(local.issues);
		local.startWarnings = ArrayLen(local.warnings);
		checkSecuritySettings(local.config, local.issues, local.warnings, local.env);
		if (ArrayLen(local.issues) > local.startCount) {
			detailOutput.statusFailed("Security Configuration");
		} else if (ArrayLen(local.warnings) > local.startWarnings) {
			detailOutput.statusWarning();
		} else {
			detailOutput.statusSuccess("Security Configuration");
		}

		// Check database configuration
		if(arguments.verbose) {
			print.line("Checking database configuration... ").toConsole();
		}
		local.startCount = ArrayLen(local.issues);
		local.startWarnings = ArrayLen(local.warnings);
		checkDatabaseSettings(local.config, local.issues, local.warnings);
		if (ArrayLen(local.issues) > local.startCount) {
			detailOutput.statusFailed("Database Configuration");
		} else if (ArrayLen(local.warnings) > local.startWarnings) {
			detailOutput.statusWarning();
		} else {
			detailOutput.statusSuccess("Database Configuration");
		}

		// Check environment configuration
		if(arguments.verbose) {
			print.line("Checking environment-specific settings... ").toConsole();
		}
		local.startWarnings = ArrayLen(local.warnings);
		checkEnvironmentSettings(local.config, local.issues, local.warnings, local.env);
		if (ArrayLen(local.warnings) > local.startWarnings) {
			detailOutput.statusWarning();
		} else {
			detailOutput.statusSuccess("Environment-Specific Settings");
		}

		// Check .env file
		if(arguments.verbose) {
			print.line("Checking .env file configuration... ").toConsole();
		}
		local.startCount = ArrayLen(local.issues);
		local.startWarnings = ArrayLen(local.warnings);
		local.startFixed = ArrayLen(local.fixed);
		checkEnvFile(local.issues, local.warnings, arguments.fix, local.fixed);
		if (ArrayLen(local.fixed) > local.startFixed) {
			detailOutput.statusFixed();
		} else if (ArrayLen(local.issues) > local.startCount) {
			detailOutput.statusFailed(".env File Configuration");
		} else if (ArrayLen(local.warnings) > local.startWarnings) {
			detailOutput.statusWarning();
		} else {
			detailOutput.statusSuccess(".env File Configuration");
		}

		// Additional checks for production environment
		if (local.env == "production") {
			if(arguments.verbose) {
				print.line("Checking production-specific requirements... ").toConsole();
			}
			local.startCount = ArrayLen(local.issues);
			local.startWarnings = ArrayLen(local.warnings);
			checkProductionSettings(local.config, local.issues, local.warnings);
			if (ArrayLen(local.issues) > local.startCount) {
				detailOutput.statusFailed("Production-Specific Requirements");
			} else if (ArrayLen(local.warnings) > local.startWarnings) {
				detailOutput.statusWarning();
			} else {
				detailOutput.statusSuccess("Production-Specific Requirements");
			}
		}

		detailOutput.line();
		detailOutput.divider();

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
				local.datasources = getDatasourceInfo(arguments.config.dataSourceName, local.env);
				if (!len(local.datasources.datasource)) {
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

	private void function checkProductionSettings(
		required struct config,
		required array issues,
		required array warnings
	) {
		// Check SSL/HTTPS settings
		if (!StructKeyExists(arguments.config, "forceSSL") || !arguments.config.forceSSL) {
			ArrayAppend(arguments.warnings, {
				type: "warning",
				message: "SSL not enforced in production",
				fix: "Set forceSSL = true in config/production/settings.cfm"
			});
		}

		// Check session timeout
		if (StructKeyExists(arguments.config, "sessionTimeout") && arguments.config.sessionTimeout > 30) {
			ArrayAppend(arguments.warnings, {
				type: "warning", 
				message: "Long session timeout in production (#arguments.config.sessionTimeout# minutes)",
				fix: "Consider reducing sessionTimeout for security"
			});
		}

		// Check error handling
		if (!StructKeyExists(arguments.config, "showErrorInformation") || arguments.config.showErrorInformation) {
			ArrayAppend(arguments.issues, {
				type: "error",
				message: "Detailed error information exposed in production",
				fix: "Set showErrorInformation = false in config/production/settings.cfm"
			});
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
		detailOutput.line();

		// Display fixed items
		if (ArrayLen(arguments.fixed)) {
			print.greenBoldLine("[FIXED] Issues:").toConsole();
			for (local.fix in arguments.fixed) {
				print.greenLine("   - #local.fix#").toConsole();
			}
			detailOutput.line();
		}

		// Display errors
		if (ArrayLen(arguments.issues)) {
			print.redBoldLine("[ERRORS] (#ArrayLen(arguments.issues)#):").toConsole();
			for (local.issue in arguments.issues) {
				print.redLine("   - #local.issue.message#").toConsole();
				if (arguments.verbose) {
					print.yellowLine("     --> Fix: #local.issue.fix#").toConsole();
				}
			}
			detailOutput.line();
		}

		// Display warnings
		if (ArrayLen(arguments.warnings)) {
			detailOutput.yellowBold("[WARNINGS] (#ArrayLen(arguments.warnings)#):");
			for (local.warning in arguments.warnings) {
				print.yellowLine("   - #local.warning.message#").toConsole();
				if (arguments.verbose) {
					detailOutput.output("     --> Fix: #local.warning.fix#");
				}
			}
			detailOutput.line();
		}

		// Summary
		detailOutput.divider();
		local.errorCount = ArrayLen(arguments.issues);
		local.warningCount = ArrayLen(arguments.warnings);

		if (local.errorCount == 0 && local.warningCount == 0) {
			print.greenBoldLine("[PASSED] Configuration validation successful!").toConsole();
			print.greenLine("  All checks completed successfully.").toConsole();
		} else {
			local.summary = [];
			if (local.errorCount > 0) {
				ArrayAppend(local.summary, "#local.errorCount# error#local.errorCount != 1 ? 's' : ''#");
			}
			if (local.warningCount > 0) {
				ArrayAppend(local.summary, "#local.warningCount# warning#local.warningCount != 1 ? 's' : ''#");
			}

			if (local.errorCount > 0) {
				print.redBoldLine("[FAILED] Configuration check failed").toConsole();
			} else {
				detailOutput.yellowBold("[WARNING] Configuration check completed with warnings");
			}
			detailOutput.output("  Found: #ArrayToList(local.summary, ', ')#");

			if (!arguments.verbose && (local.errorCount > 0 || local.warningCount > 0)) {
				detailOutput.line();
				detailOutput.output("  Tip: Run with --verbose flag for detailed fix suggestions");
			}
		}
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

	private string function getEnvironment() {
		// Same logic as get environment command
		local.environment = "";
		
		// Check .env file for WHEELS_ENV first, then Environment
		local.envFile = ResolvePath(".env");
		if (FileExists(local.envFile)) {
			local.envContent = FileRead(local.envFile);
			
			// First check for WHEELS_ENV
			local.envMatch = REFind("(?m)^WHEELS_ENV\s*=\s*([^\s##]+)", local.envContent, 1, true);
			if (local.envMatch.pos[1] > 0) {
				local.environment = Trim(Mid(local.envContent, local.envMatch.pos[2], local.envMatch.len[2]));
			}
			
			// If not found, check for Environment
			if (!Len(local.environment)) {
				local.envMatch = REFind("(?m)^Environment\s*=\s*([^\s##]+)", local.envContent, 1, true);
				if (local.envMatch.pos[1] > 0) {
					local.environment = Trim(Mid(local.envContent, local.envMatch.pos[2], local.envMatch.len[2]));
				}
			}
		}
		
		// Check system environment variables for WHEELS_ENV first, then Environment
		if (!Len(local.environment)) {
			local.sysEnv = CreateObject("java", "java.lang.System");
			
			// First check for WHEELS_ENV
			local.wheelsEnv = local.sysEnv.getenv("WHEELS_ENV");
			if (!IsNull(local.wheelsEnv) && Len(local.wheelsEnv)) {
				local.environment = local.wheelsEnv;
			}
			
			// If not found, check for Environment
			if (!Len(local.environment)) {
				local.env = local.sysEnv.getenv("Environment");
				if (!IsNull(local.env) && Len(local.env)) {
					local.environment = local.env;
				}
			}
		}
		
		// Default to development
		if (!Len(local.environment)) {
			local.environment = "development";
		}
		
		return local.environment;
	}

}