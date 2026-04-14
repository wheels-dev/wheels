/**
 * Show status of the Wheels development server
 *
 * Examples:
 * {code:bash}
 * wheels server status
 * wheels server status --json
 * wheels server status --verbose
 * {code}
 **/
component extends="../base" {

	/**
	 * @name Server name to check (optional)
	 * @json Output in JSON format
	 * @verbose Show detailed information
	 **/
	function run(
		string name,
		boolean json = false,
		boolean verbose = false
	) {
		// Build the status command
		var statusCommand = "server status";
		
		if (!isNull(arguments.name)) {
			statusCommand &= " --name=#arguments.name#";
		}
		
		if (arguments.json) {
			statusCommand &= " --json";
		}
		
		if (arguments.verbose) {
			statusCommand &= " --verbose";
		}

		if (!arguments.json) {
			detailOutput.header("Wheels Server Status");
		}
		
		// Execute the server status command
		command(statusCommand).run();
		
		// If not JSON output and server is running, show additional Wheels info
		if (!arguments.json) {
			try {
				var serverInfo = $getServerInfo();
				if (structKeyExists(serverInfo, "port") && serverInfo.port > 0) {
					detailOutput.subHeader("Wheels Application Info");
					detailOutput.metric("URL", serverInfo.serverURL);
					
					// Check if it's a Wheels app
					if (isWheelsApp()) {
						detailOutput.metric("Wheels Version", $getWheelsVersion());
						detailOutput.metric("Application Root", getCWD());
					}
					
					detailOutput.nextSteps([
						"wheels server open     - Open in browser",
						"wheels server log      - View logs",
						"wheels reload          - Reload application"
					]);
				}
			} catch (any e) {
				// Silently continue if we can't get additional info
			}
		}
	}
}