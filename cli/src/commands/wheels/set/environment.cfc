/**
 * Set the application environment
 *
 * {code:bash}
 * wheels set environment development
 * wheels set environment production
 * wheels set environment testing
 * wheels set environment maintenance
 * {code}
 */
component extends="../base" {

	/**
	 * @environment.hint The environment to set (development, testing, maintenance, production)
	 * @environment.optionsUDF environmentOptions
	 * @help Set the application environment
	 */
	public void function run(required string environment) {
		local.appPath = getCWD();
		
		if (!isWheelsApp(local.appPath)) {
			error("This command must be run from a Wheels application directory");
			return;
		}

		// Validate environment
		local.validEnvironments = ["development", "testing", "maintenance", "production"];
		if (!ArrayFindNoCase(local.validEnvironments, arguments.environment)) {
			error("Invalid environment: #arguments.environment#");
			print.line("Valid environments are: " & ArrayToList(local.validEnvironments, ", "));
			return;
		}

		try {
			local.updated = false;
			
			// 1. Update .env file (preferred)
			local.envFile = local.appPath & "/.env";
			if (FileExists(local.envFile)) {
				local.envContent = FileRead(local.envFile);
				
				// Check if WHEELS_ENV exists
				if (REFind("(?m)^WHEELS_ENV\s*=", local.envContent)) {
					// Update existing
					local.envContent = REReplace(local.envContent, "(?m)^WHEELS_ENV\s*=.*$", "WHEELS_ENV=" & arguments.environment, "all");
				} else {
					// Add new
					local.envContent = local.envContent & Chr(10) & "WHEELS_ENV=" & arguments.environment;
				}
				
				FileWrite(local.envFile, local.envContent);
				local.updated = true;
				print.greenLine("Updated .env file");
			}
			
			// 2. Update server.json
			local.serverJsonPath = local.appPath & "/server.json";
			if (FileExists(local.serverJsonPath)) {
				local.serverJson = DeserializeJSON(FileRead(local.serverJsonPath));
				
				if (!StructKeyExists(local.serverJson, "env")) {
					local.serverJson.env = {};
				}
				
				local.serverJson.env.WHEELS_ENV = arguments.environment;
				
				// Write JSON - try pretty format first
				try {
					// Try with pretty parameter (newer CF versions)
					local.jsonString = SerializeJSON(local.serverJson, "struct", false);
					// If we get here, try adding pretty formatting
					try {
						// Some versions support this syntax
						local.jsonString = SerializeJSON(local.serverJson, false, false);
					} catch (any e2) {
						// Ignore and use regular JSON
					}
					FileWrite(local.serverJsonPath, local.jsonString);
				} catch (any e) {
					// Fall back to most basic JSON serialization
					FileWrite(local.serverJsonPath, SerializeJSON(local.serverJson));
				}
				local.updated = true;
				print.greenLine("Updated server.json");
			}
			
			// 3. Create .env file if nothing exists
			if (!local.updated && !FileExists(local.envFile)) {
				FileWrite(local.envFile, "WHEELS_ENV=" & arguments.environment);
				print.greenLine("Created .env file");
			}
			
			print.line();
			print.boldGreenLine("Environment set to: " & arguments.environment);
			print.line();
			print.yellowLine("Note: You may need to restart your server for changes to take effect.");
			
		} catch (any e) {
			error("Error setting environment: " & e.message);
		}
	}

	public array function environmentOptions() {
		return ["development", "testing", "maintenance", "production"];
	}

}