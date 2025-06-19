/**
 * Set a specific configuration value
 *
 * {code:bash}
 * wheels set settings cacheQueries false
 * wheels set settings dataSourceName myapp
 * wheels set settings errorEmailAddress admin@example.com
 * {code}
 */
component extends="../base" {

	/**
	 * @settingName The name of the setting to set
	 * @value The value to set (use true/false for booleans)
	 * @environment Optional environment to set the setting for (default: current)
	 * @help Set a specific configuration value
	 */
	public void function run(
		required string settingName,
		required string value,
		string environment = ""
	) {
		local.appPath = getCWD();

		if (!isWheelsApp(local.appPath)) {
			error("This command must be run from a Wheels application directory");
			return;
		}

		try {
			// Determine environment
			if (!Len(arguments.environment)) {
				arguments.environment = getEnvironment(local.appPath);
			}

			// Validate environment
			local.validEnvironments = ["development", "testing", "maintenance", "production"];
			if (!ArrayFindNoCase(local.validEnvironments, arguments.environment)) {
				error("Invalid environment: #arguments.environment#");
				return;
			}

			print.line();
			print.boldLine("Setting Configuration Value");
			print.line();
			print.yellowLine("Note: This command provides guidance on setting configuration values.");
			print.yellowLine("You need to manually edit your settings file.");
			print.line();
			
			// Determine settings file path
			local.settingsFile = local.appPath & "/config/" & arguments.environment & "/settings.cfm";
			
			// Convert value to appropriate type
			local.formattedValue = formatValue(arguments.value);
			
			print.line("To set this configuration value, add or update the following in your settings file:");
			print.line();
			print.greenLine("File: " & local.settingsFile);
			print.line();
			print.line("Add this line inside the cfscript tags:");
			print.boldCyanLine("    set(" & arguments.settingName & " = " & local.formattedValue & ");");
			print.line();
			
			// Create directory if it doesn't exist
			local.settingsDir = GetDirectoryFromPath(local.settingsFile);
			if (!DirectoryExists(local.settingsDir)) {
				print.line("The environment directory doesn't exist yet.");
				print.line("Create it with: mkdir " & local.settingsDir);
				print.line();
			}
			
			if (!FileExists(local.settingsFile)) {
				print.line("If the file doesn't exist, create it with this content:");
				print.line();
				print.cyanLine("<" & "cfscript>");
				print.cyanLine("    set(" & arguments.settingName & " = " & local.formattedValue & ");");
				print.cyanLine("</" & "cfscript>");
			}
			
			print.line();
			print.yellowLine("After making the change, reload your application with:");
			print.line("wheels reload " & arguments.environment);

		} catch (any e) {
			error("Error: " & e.message);
			if (StructKeyExists(e, "detail") && Len(e.detail)) {
				error("Details: " & e.detail);
			}
		}
	}

	private string function getEnvironment(required string appPath) {
		// Same logic as get environment command
		local.environment = "";

		// Check .env file
		local.envFile = arguments.appPath & "/.env";
		if (FileExists(local.envFile)) {
			local.envContent = FileRead(local.envFile);
			local.envMatch = REFind("(?m)^WHEELS_ENV\s*=\s*(.+)$", local.envContent, 1, true);
			if (local.envMatch.pos[1] > 0) {
				local.environment = Trim(Mid(local.envContent, local.envMatch.pos[2], local.envMatch.len[2]));
			}
		}

		// Check environment variable
		if (!Len(local.environment)) {
			try {
				local.sysEnv = CreateObject("java", "java.lang.System");
				local.wheelsEnv = local.sysEnv.getenv("WHEELS_ENV");
				if (!IsNull(local.wheelsEnv) && Len(local.wheelsEnv)) {
					local.environment = local.wheelsEnv;
				}
			} catch (any e) {
				// Environment variable not accessible
			}
		}

		// Default to development
		if (!Len(local.environment)) {
			local.environment = "development";
		}

		return local.environment;
	}

	private string function formatValue(required string value) {
		// Handle boolean values
		if (arguments.value == "true" || arguments.value == "false") {
			return arguments.value;
		}

		// Handle numeric values
		if (IsNumeric(arguments.value)) {
			return arguments.value;
		}

		// Handle empty string
		if (!Len(arguments.value)) {
			return '""';
		}

		// String value - escape quotes and wrap in quotes
		local.escaped = Replace(arguments.value, '"', '""', "all");
		return '"' & local.escaped & '"';
	}

}