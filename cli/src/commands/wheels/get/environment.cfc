/**
 * Display the current environment setting
 *
 * {code:bash}
 * wheels get environment
 * {code}
 */
component extends="../base" {

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
			
			// 1. Check .env file
			local.envFile = local.appPath & "/.env";
			if (FileExists(local.envFile)) {
				local.envContent = FileRead(local.envFile);
				// local.envMatch = REFind("(?m)^WHEELS_ENV\s*=\s*(.+)$", local.envContent, 1, true);
				local.envMatch = REFind("(?m)^WHEELS_ENV\s*=\s*([^\s##]+)", local.envContent, 1, true);
				if (local.envMatch.pos[1] > 0) {
					local.environment = Trim(Mid(local.envContent, local.envMatch.pos[2], local.envMatch.len[2]));
				}
			}
			
			// 2. Check environment variable
			if (!Len(local.environment)) {
				local.sysEnv = CreateObject("java", "java.lang.System");
				local.wheelsEnv = local.sysEnv.getenv("WHEELS_ENV");
				if (!IsNull(local.wheelsEnv) && Len(local.wheelsEnv)) {
					local.environment = local.wheelsEnv;
				}
			}
			
			// 3. Check server.json
			if (!Len(local.environment)) {
				local.serverJsonPath = local.appPath & "/server.json";
				if (FileExists(local.serverJsonPath)) {
					local.serverJson = DeserializeJSON(FileRead(local.serverJsonPath));
					if (StructKeyExists(local.serverJson, "env") && 
					    StructKeyExists(local.serverJson.env, "WHEELS_ENV")) {
						local.environment = local.serverJson.env.WHEELS_ENV;
					}
				}
			}
			
			// 4. Default to development
			if (!Len(local.environment)) {
				local.environment = "development";
			}
			
			print.line();
			print.boldLine("Current Environment:");
			print.greenLine(local.environment);
			print.line();
			
			// Show where it's configured
			if (FileExists(local.envFile) && REFind("(?m)^WHEELS_ENV\s*=", FileRead(local.envFile))) {
				print.line("Configured in: .env file");
			} else if (!IsNull(local.sysEnv.getenv("WHEELS_ENV"))) {
				print.line("Configured in: System environment variable");
			} else if (FileExists(local.serverJsonPath)) {
				print.line("Configured in: server.json");
			} else {
				print.line("Using default: development");
			}
			
		} catch (any e) {
			error("Error reading environment: " & e.message);
		}
	}

}