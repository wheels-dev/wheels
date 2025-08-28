/**
 * Display the current environment setting
 *
 * {code:bash}
 * wheels get environment
 * {code}
 */
component aliases="wheels get env" extends="../base" {

	/**
	 * @help Show the current environment setting
	 */
	public void function run() {
		local.appPath = getCWD();
		
		if (!isWheelsApp(local.appPath)) {
			error("This command must be run from a Wheels application directory");
			return;
		}

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
			
			print.line();
			print.boldLine("Current Environment:");
			print.greenLine(local.environment);
			print.line();
			
			// Show where it's configured
			print.line("Configured in: " & local.configSource);
			
		} catch (any e) {
			error("Error reading environment: " & e.message);
		}
	}
}