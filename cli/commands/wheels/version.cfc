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
		// Get server information
		local.serverInfo = getServerInfo();
		
		print.boldGreenLine("CFWheels CLI Module " & getWheelsCliVersion());
		print.line("");
		print.greenLine("CFWheels Version: " & $getWheelsVersion());
		print.greenLine("CFML Engine: " & local.serverInfo.name & " " & local.serverInfo.version);
		print.greenLine("CommandBox Version: " & shell.getVersion());
	}

	private struct function getServerInfo() {
		local.result = {
			name = "Unknown",
			version = "Unknown"
		};
		
		try {
			// Try to get server info
			local.serverDetails = serverService.resolveServerDetails(serverProps = {webroot = getCWD()});
			if (StructKeyExists(local.serverDetails, "serverInfo")) {
				local.result.name = local.serverDetails.serverInfo.name ?: "Unknown";
				local.result.version = local.serverDetails.serverInfo.version ?: "Unknown";
			}
		} catch (any e) {
			// Fall back to basic detection
			if (StructKeyExists(server, "lucee")) {
				local.result.name = "Lucee";
				local.result.version = server.lucee.version;
			} else if (StructKeyExists(server, "coldfusion")) {
				local.result.name = server.coldfusion.productname;
				local.result.version = server.coldfusion.productversion;
			}
		}
		
		return local.result;
	}

	private string function getWheelsCliVersion() {
		// Read from CLI module's box.json
		local.boxJsonPath = getDirectoryFromPath(getCurrentTemplatePath()) & "../../../box.json";
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