/**
 * Restart the Wheels development server
 *
 * Examples:
 * {code:bash}
 * wheels server restart
 * wheels server restart --force
 * {code}
 **/
component extends="../base" {

	/**
	 * @name Server name to restart (optional)
	 * @force Force restart
	 **/
	function run(
		string name,
		boolean force = false
	) {
		detailOutput.header("Restart Wheels Development Server");
		// Build the restart command
		var restartCommand = "server restart";
		
		if (!isNull(arguments.name)) {
			restartCommand &= " #arguments.name#";
		} else {
			// Try to get server name from server.json
			var serverJSON = fileSystemUtil.resolvePath("server.json");
			if (fileExists(serverJSON)) {
				try {
					var serverConfig = deserializeJSON(fileRead(serverJSON));
					if (structKeyExists(serverConfig, "name")) {
						restartCommand &= " #serverConfig.name#";
					}
				} catch (any e) {
					// Fall back to directory method
					restartCommand &= " --directory=#getCWD()#";
				}
			} else {
				// Use current directory
				restartCommand &= " --directory=#getCWD()#";
			}
		}
		
		if (arguments.force) {
			restartCommand &= " --force";
		}

		// Show command
		detailOutput.subHeader("Executing Restart Command");
		detailOutput.code(restartCommand);
		
		// Execute the server restart command
		command(restartCommand).run();
		
		detailOutput.statusSuccess("Server restarted successfully");

		// Reload Wheels
		detailOutput.subHeader("Reload Wheels Application");
		try {
			command("wheels reload").run();
			detailOutput.statusSuccess("Application reloaded successfully");
		} catch (any e) {
			detailOutput.statusWarning("Application reload may require manual browser refresh");
		}
	}

}