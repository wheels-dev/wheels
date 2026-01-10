/**
 * Display the current environment setting
 *
 * {code:bash}
 * wheels get environment
 * {code}
 */
component aliases="wheels get env" extends="../base" {

    property name="detailOutput" inject="DetailOutputService@wheels-cli";

	/**
	 * @help Show the current environment setting
	 */
	public void function run() {
		local.appPath = getCWD();
		requireWheelsApp(local.appPath);

		try {
			// Check for environment in multiple places
			local.environment = "";
			local.configSource = "";
			
			// 1. Check .env file for WHEELS_ENV first, then Environment
			local.envFile = local.appPath & "/.env";
			if (FileExists(local.envFile)) {
				local.envContent = FileRead(local.envFile);
				
				// First check for WHEELS_ENV
				local.envMatch = REFind("(?m)^WHEELS_ENV\s*=\s*([^\s##]+)", local.envContent, 1, true);
				if (local.envMatch.pos[1] > 0) {
					local.environment = Trim(Mid(local.envContent, local.envMatch.pos[2], local.envMatch.len[2]));
					local.configSource = ".env file (WHEELS_ENV)";
				}
				
				// If not found, check for Environment
				if (!Len(local.environment)) {
					local.envMatch = REFind("(?m)^Environment\s*=\s*([^\s##]+)", local.envContent, 1, true);
					if (local.envMatch.pos[1] > 0) {
						local.environment = Trim(Mid(local.envContent, local.envMatch.pos[2], local.envMatch.len[2]));
						local.configSource = ".env file (Environment)";
					}
				}
			}
			
			// 2. Check system environment variables for WHEELS_ENV first, then Environment
			if (!Len(local.environment)) {
				local.sysEnv = CreateObject("java", "java.lang.System");
				
				// First check for WHEELS_ENV
				local.wheelsEnv = local.sysEnv.getenv("WHEELS_ENV");
				if (!IsNull(local.wheelsEnv) && Len(local.wheelsEnv)) {
					local.environment = local.wheelsEnv;
					local.configSource = "System environment variable (WHEELS_ENV)";
				}
				
				// If not found, check for Environment
				if (!Len(local.environment)) {
					local.env = local.sysEnv.getenv("Environment");
					if (!IsNull(local.env) && Len(local.env)) {
						local.environment = local.env;
						local.configSource = "System environment variable (Environment)";
					}
				}
			}
			
			// 3. Default to development
			if (!Len(local.environment)) {
				local.environment = "development";
				local.configSource = "Using default";
			}
			
			detailOutput.header("Current Environment: #local.environment#");
			detailOutput.metric("Configured in", local.configSource);
			
			
			// Add usage information
			detailOutput.line();
			if (local.configSource == "Using default") {
				detailOutput.output("To set an environment:");
				detailOutput.output("- wheels env set environment_name", true);
				detailOutput.output("- wheels env switch environment_name", true);
				detailOutput.output("- Set WHEELS_ENV in .env file",true);
			}
			
		} catch (any e) {
			detailOutput.error("Error reading environment: #e.message#");
			return;
		}
	}
}