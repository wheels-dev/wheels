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
			stopCommand &= " --name=#arguments.name#";
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