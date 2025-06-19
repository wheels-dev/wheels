/**
 * Display application settings
 *
 * {code:bash}
 * wheels get settings
 * wheels get settings cacheQueries
 * wheels get settings cache
 * {code}
 */
component extends="../base" {

	/**
	 * @settingName Optional specific setting name or pattern to filter
	 * @help Display all settings or a specific setting value
	 */
	public void function run(string settingName = "") {
		local.appPath = getCWD();
		
		if (!isWheelsApp(local.appPath)) {
			error("This command must be run from a Wheels application directory");
			return;
		}

		try {
			// Read settings from the appropriate environment file
			local.environment = getEnvironment(local.appPath);
			local.settingsFile = local.appPath & "/config/settings.cfm";
			local.envSettingsFile = local.appPath & "/config/" & local.environment & "/settings.cfm";
			
			local.settings = {};
			
			// Get default settings (simulate what Wheels would do)
			local.settings = getDefaultWheelsSettings();
			
			// Override with app settings if file exists
			if (FileExists(local.settingsFile)) {
				// Note: In a real scenario, we'd need to execute the CFM file
				// For now, we'll parse common patterns
				local.settingsContent = FileRead(local.settingsFile);
				parseSettings(local.settingsContent, local.settings);
			}
			
			// Override with environment-specific settings
			if (FileExists(local.envSettingsFile)) {
				local.envSettingsContent = FileRead(local.envSettingsFile);
				parseSettings(local.envSettingsContent, local.settings);
			}
			
			// Filter settings if a name/pattern is provided
			if (Len(arguments.settingName)) {
				local.filteredSettings = {};
				for (local.key in local.settings) {
					if (FindNoCase(arguments.settingName, local.key)) {
						local.filteredSettings[local.key] = local.settings[local.key];
					}
				}
				local.settings = local.filteredSettings;
			}
			
			if (StructCount(local.settings) == 0) {
				if (Len(arguments.settingName)) {
					print.yellowLine("No settings found matching '#arguments.settingName#'");
				} else {
					print.yellowLine("No settings found");
				}
				return;
			}
			
			print.line();
			print.boldLine("Wheels Settings (#local.environment# environment):");
			print.line();
			
			// Sort settings by key
			local.sortedKeys = StructKeyArray(local.settings);
			ArraySort(local.sortedKeys, "textnocase");
			
			// Display settings
			for (local.key in local.sortedKeys) {
				local.value = local.settings[local.key];
				local.displayValue = formatSettingValue(local.value);
				
				print.text(PadRight(local.key & ":", 30));
				print.greenLine(local.displayValue);
			}
			
			print.line();
			print.line("Total settings: " & StructCount(local.settings));
			
		} catch (any e) {
			error("Error reading settings: " & e.message);
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
			local.sysEnv = CreateObject("java", "java.lang.System");
			local.wheelsEnv = local.sysEnv.getenv("WHEELS_ENV");
			if (!IsNull(local.wheelsEnv) && Len(local.wheelsEnv)) {
				local.environment = local.wheelsEnv;
			}
		}
		
		// Default to development
		if (!Len(local.environment)) {
			local.environment = "development";
		}
		
		return local.environment;
	}

	private struct function getDefaultWheelsSettings() {
		// Common default Wheels settings
		return {
			"cacheActions": false,
			"cacheCullInterval": 5,
			"cacheCullPercentage": 10,
			"cacheDatabaseSchema": false,
			"cacheFileChecking": false,
			"cacheImages": false,
			"cacheModelConfig": false,
			"cachePages": false,
			"cachePartials": false,
			"cacheQueries": false,
			"cacheRoutes": false,
			"cacheControllerConfig": false,
			"cacheViewConfig": false,
			"dataSourceName": "wheelstestdb",
			"errorEmailAddress": "",
			"errorEmailServer": "",
			"errorEmailSubject": "Error",
			"excludeFromErrorEmail": "",
			"includeErrorInEmailSubject": true,
			"overwritePlugins": true,
			"showDebugInformation": true,
			"showErrorInformation": true,
			"sendEmailOnError": false,
			"URLRewriting": "none",
			"useExpandedColumnAliases": true,
			"useTimestampsOnDeletedColumn": true,
			"deletePluginDirectories": true,
			"loadIncompatiblePlugins": true,
			"migratorTableName": "migratorversions",
			"allowConcurrentRequestScope": false,
			"booleanAttributes": "allowfullscreen,async,autofocus,autoplay,checked,compact,controls,declare,default,defaultchecked,defaultmuted,defaultselected,defer,disabled,draggable,enabled,formnovalidate,hidden,indeterminate,inert,ismap,itemscope,loop,multiple,muted,nohref,noresize,noshade,novalidate,nowrap,open,pauseonexit,readonly,required,reversed,scoped,seamless,selected,sortable,spellcheck,translate,truespeed,typemustmatch,visible"
		};
	}

	private void function parseSettings(required string content, required struct settings) {
		// Parse set() calls in the settings file
		local.pattern = 'set\s*\(\s*([^=]+)\s*=\s*([^)]+)\)';
		local.matches = REMatchNoCase(local.pattern, arguments.content);
		
		for (local.match in local.matches) {
			try {
				// Extract key and value
				local.parts = REFind(local.pattern, local.match, 1, true);
				if (local.parts.pos[1] > 0) {
					local.assignment = Mid(local.match, local.parts.pos[2], local.parts.len[2]);
					local.assignParts = ListToArray(local.assignment, "=");
					if (ArrayLen(local.assignParts) >= 2) {
						local.key = Trim(local.assignParts[1]);
						// Join remaining parts with = in case value contains =
					local.valueParts = [];
					for (local.i = 2; local.i <= ArrayLen(local.assignParts); local.i++) {
						ArrayAppend(local.valueParts, local.assignParts[local.i]);
					}
					local.value = Trim(ArrayToList(local.valueParts, "="));
						
						// Clean up the value
						local.value = REReplace(local.value, "^['""]|['""]$", "", "all");
						
						// Try to parse boolean/numeric values
						if (local.value == "true") {
							local.value = true;
						} else if (local.value == "false") {
							local.value = false;
						} else if (IsNumeric(local.value)) {
							local.value = Val(local.value);
						}
						
						arguments.settings[local.key] = local.value;
					}
				}
			} catch (any e) {
				// Skip malformed settings
			}
		}
	}

	private string function formatSettingValue(required any value) {
		if (IsBoolean(arguments.value)) {
			return arguments.value ? "true" : "false";
		} else if (IsNumeric(arguments.value)) {
			return ToString(arguments.value);
		} else if (IsSimpleValue(arguments.value)) {
			return arguments.value;
		} else if (IsArray(arguments.value)) {
			return "[" & ArrayToList(arguments.value, ", ") & "]";
		} else if (IsStruct(arguments.value)) {
			return "{" & StructCount(arguments.value) & " items}";
		} else {
			return "[complex value]";
		}
	}

	private string function PadRight(required string text, required numeric width) {
		if (Len(arguments.text) >= arguments.width) {
			return arguments.text;
		}
		return arguments.text & RepeatString(" ", arguments.width - Len(arguments.text));
	}

}