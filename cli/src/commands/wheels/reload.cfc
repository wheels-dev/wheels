/**
 * Reloads a wheels app: will ask for your reload password (and optional mode, we assume development)
 * Will only work on a running server
 *
 * {code:bash}
 * wheels reload
 * {code}
 *
 * {code:bash}
 * wheels reload mode="production"
 * {code}
 **/
component aliases='wheels r'  extends="base"  {

	/**
	 * @mode.hint Mode to switch to
	 * @mode.options development,testing,maintenance,production
	 * @password The reload password
	 **/

	property name="detailOutput" inject="DetailOutputService@wheels-cli";
	
	function run(string mode="development", string password="") {
		requireWheelsApp(getCWD());
		arguments=reconstructArgs(arguments);
  		var serverDetails = $getServerInfo();
		var appSettings = $getAppSettings(mode);

		var reloadPassword = StructKeyExists(appSettings, "reloadPassword") ? appSettings.reloadPassword : "";
		getURL = serverDetails.serverURL & "/index.cfm?reload=#mode#";

		// Handle password logic
		if (len(reloadPassword)) {
			// Password is configured
			if (len(password)) {
				// User provided a password, validate it against configured one
				if (password != reloadPassword) {
					detailOutput.error("Invalid password. The configured reload password does not match the provided password.");
					return;
				}
				getURL &= "&password=#password#";
			} else {
				detailOutput.error("Reload password is configured but not provided!");
				return;
			}
		} else {
			// No password configured - check if user provided one unnecessarily
			if (len(password)) {
				detailOutput.statusWarning("No reload password is configured in settings, but you provided one. Proceeding without password.");
			}
		}
  		getURL = serverDetails.serverURL &
  			"/index.cfm?reload=#mode#&password=#password#";
  		var loc = new Http( url=getURL ).send().getPrefix();
  		detailOutput.statusSuccess("Reload Request sent");
	}

	private struct function $getAppSettings(required string mode="development") {
		try {
			local.appPath = getCWD();
			local.settingsFile = local.appPath & "/config/settings.cfm";
			local.envSettingsFile = local.appPath & "/config/" & arguments.mode & "/settings.cfm";
			local.settings = {};

			// Override with app settings if file exists
			if (FileExists(local.settingsFile)) {
				local.settingsContent = FileRead(local.settingsFile);
				parseSettings(local.settingsContent, local.settings);
			}
			
			// Override with environment-specific settings
			if (FileExists(local.envSettingsFile)) {
				local.envSettingsContent = FileRead(local.envSettingsFile);
				parseSettings(local.envSettingsContent, local.settings);
			}

			return local.settings;
		} catch (any e) {
			detailOutput.error("Error reading settings: #e.message#");
			if (StructKeyExists(e, "detail") && Len(e.detail)) {
				detailOutput.output("Details: #e.detail#");
			}
		}
	}

	private void function parseSettings(required string content, required struct settings) {
		local.pattern = '(?i)set\s*\(\s*([^)]+)\)';
		local.matches = REMatch(local.pattern, arguments.content);

		for (local.match in local.matches) {
			try {
				// extract the inside of set(...)
				local.inner = REReplace(local.match, '(?i)^set\s*\(|\);?$', '', 'all');

				// split only on FIRST =
				local.eqPos = Find("=", local.inner);
				if (!local.eqPos) continue;

				local.key   = Trim(Left(local.inner, local.eqPos - 1));
				local.value = Trim(Mid(local.inner, local.eqPos + 1));

				// strip quotes
				local.value = REReplace(local.value, "^['""]|['""]$", "", "all");

				// coerce types
				if (local.value == "true") {
					local.value = true;
				} else if (local.value == "false") {
					local.value = false;
				} else if (IsNumeric(local.value)) {
					local.value = Val(local.value);
				}

				arguments.settings[local.key] = local.value;
			} catch (any e) {
				detailOutput.error("Error reading settings: #e.message#");
				if (StructKeyExists(e, "detail") && Len(e.detail)) {
					detailOutput.output("Details: #e.detail#");
				}
			}
		}
	}
}
