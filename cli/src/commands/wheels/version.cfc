/**
 * Display version information for the Wheels CLI
 *
 * {code:bash}
 * wheels version
 * wheels -v
 * wheels --version
 * {code}
 */
component aliases="-v,--version" extends="base" {

	/**
	 * @help Show version information
	 */
	public void function run() {
		try {
			requireWheelsApp(getCWD());
			// Get server information
			local.serverInfo = getServerInfo();
			
			print.boldGreenLine("Wheels CLI Module " & getWheelsCliVersion());
			print.line("");
			print.greenLine("Wheels Version: " & $getWheelsVersion());
			print.greenLine("CFML Engine: " & local.serverInfo.name & " " & local.serverInfo.version);
			print.greenLine("CommandBox Version: " & shell.getVersion());
		} catch (any e) {
			detailOutput.error("#e.message#");
			setExitCode(1);
		}
	}

	private struct function getServerInfo() {
		local.result = {
			name = "Unknown",
			version = "Unknown"
		};

		try {
			local.serverDetails = serverService.resolveServerDetails({});

			// Check if SERVERINFO exists (it contains engineName and engineVersion)
			if (StructKeyExists(local.serverDetails, "SERVERINFO")) {
				local.serverInfo = local.serverDetails.SERVERINFO;

				if (StructKeyExists(local.serverInfo, "engineName") && StructKeyExists(local.serverInfo, "engineVersion")) {
					// Get engine name
					if (local.serverInfo.engineName == "lucee") {
						local.result.name = "Lucee";
					} else if (local.serverInfo.engineName == "adobe") {
						local.result.name = "Adobe ColdFusion";
					} else if (local.serverInfo.engineName == "boxlang") {
						local.result.name = "BoxLang";
					} else {
						local.result.name = local.serverInfo.engineName;
					}

					// Get version
					if (Len(local.serverInfo.engineVersion) && local.serverInfo.engineVersion != "Unknown") {
						local.result.version = local.serverInfo.engineVersion;
					}

					return local.result;
				}
			}
		} catch (any e) {
			// Continue to direct server detection
		}

		// Fallback to direct server scope detection
		try {
			if (StructKeyExists(server, "lucee")) {
				local.result.name = "Lucee";
				if (StructKeyExists(server.lucee, "version")) {
					local.result.version = server.lucee.version;
				}
			} else if (StructKeyExists(server, "coldfusion")) {
				local.result.name = server.coldfusion.productname ?: "Adobe ColdFusion";
				if (StructKeyExists(server.coldfusion, "productversion")) {
					local.result.version = server.coldfusion.productversion;
				}
			}
		} catch (any e) {
			// Use defaults
		}

		return local.result;
	}

	private string function getWheelsCliVersion() {
		// Read from CLI module's box.json
		local.boxJsonPath = expandPath("/wheels-cli/box.json");
		if (FileExists(local.boxJsonPath)) {
			try {
				local.boxJson = DeserializeJSON(FileRead(local.boxJsonPath));
				if (StructKeyExists(local.boxJson, "version")) {
					return local.boxJson.version;
				}
			} catch (any e) {
				// Continue to default
			}
		}
		
		return "1.0.0"; // Default version
	}

}