/**
 * Stop the Wheels development server
 *
 * Examples:
 * {code:bash}
 * wheels server stop
 * wheels server stop --force
 * {code}
 **/
component extends="../base" {

	/**
	 * @name Server name to stop (optional)
	 * @force Force stop all servers
	 **/
	function run(
		string name,
		boolean force = false
	) {
		// Build the stop command
		var stopCommand = "server stop";
		
		if (!isNull(arguments.name)) {
			stopCommand &= " #arguments.name#";
		} else {
			// Try to get server name from server.json
			var serverJSON = fileSystemUtil.resolvePath("server.json");
			if (fileExists(serverJSON)) {
				try {
					var serverConfig = deserializeJSON(fileRead(serverJSON));
					if (structKeyExists(serverConfig, "name")) {
						stopCommand &= " #serverConfig.name#";
					}
				} catch (any e) {
					// Fall back to directory method
					stopCommand &= " --directory=#getCWD()#";
				}
			} else {
				// Use current directory
				stopCommand &= " --directory=#getCWD()#";
			}
		}
		
		if (arguments.force) {
			stopCommand &= " --all";
		}

		print.yellowLine("Stopping Wheels development server...");
		
		// Execute the server stop command
		command(stopCommand).run();
		
		print.line();
		print.greenLine("Server stopped successfully!");
		print.line();
	}

}