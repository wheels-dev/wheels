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

		print.yellowLine("Restarting Wheels development server...");
		print.line();
		
		// Execute the server restart command
		command(restartCommand).run();
		
		print.line();
		print.greenLine("Server restarted successfully!");
		print.line();
		
		// Also reload the Wheels application
		print.line("Reloading Wheels application...");
		try {
			command("wheels reload").run();
			print.greenLine("Application reloaded successfully!");
		} catch (any e) {
			print.yellowLine("Note: Application reload may require manual refresh in browser.");
		}
		print.line();
	}

}