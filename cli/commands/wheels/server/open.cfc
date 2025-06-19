/**
 * Open the Wheels application in a web browser
 *
 * Examples:
 * {code:bash}
 * wheels server open
 * wheels server open /admin
 * wheels server open --browser=firefox
 * {code}
 **/
component extends="../base" {

	/**
	 * @path URL path to open (e.g., /admin)
	 * @browser Browser to use (chrome, firefox, safari, etc.)
	 * @name Server name (optional)
	 **/
	function run(
		string path = "",
		string browser,
		string name
	) {
		// First check if server is running
		try {
			var serverInfo = $getServerInfo();
			if (!structKeyExists(serverInfo, "port") || serverInfo.port == 0) {
				print.redLine("Server doesn't appear to be running.");
				print.line("Start it with: wheels server start");
				return;
			}
			
			// Build the URL
			var url = serverInfo.serverURL;
			
			// Add path if provided
			if (len(arguments.path)) {
				if (!left(arguments.path, 1) == "/") {
					url &= "/";
				}
				url &= arguments.path;
			}
			
			// Build the open command
			var openCommand = "server open";
			
			if (!isNull(arguments.name)) {
				openCommand &= " --name=#arguments.name#";
			}
			
			if (!isNull(arguments.browser)) {
				openCommand &= " --browser=#arguments.browser#";
			}
			
			// If path was provided, we need to use browse command instead
			if (len(arguments.path)) {
				openCommand = "browse #url#";
				if (!isNull(arguments.browser)) {
					openCommand &= " --browser=#arguments.browser#";
				}
			}
			
			print.greenLine("Opening Wheels application in browser...");
			print.line("URL: #url#");
			print.line();
			
			// Execute the command
			command(openCommand).run();
			
		} catch (any e) {
			print.redLine("Unable to determine server URL.");
			print.line("Is the server running? Check with: wheels server status");
		}
	}

}