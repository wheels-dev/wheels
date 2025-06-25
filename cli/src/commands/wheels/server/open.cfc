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
		// Get server info to determine URL
		try {
			var serverInfo = $getServerInfo();
			var serverURL = serverInfo.serverURL;
			
			// Add path if provided
			if (len(arguments.path)) {
				// Ensure path starts with /
				if (left(arguments.path, 1) != "/") {
					arguments.path = "/" & arguments.path;
				}
				serverURL &= arguments.path;
			}
			
			print.greenLine("Opening Wheels application in browser...");
			print.cyanLine("URL: " & serverURL);
			print.line();
			
			// Use CommandBox's browse command which handles cross-platform opening
			if (!isNull(arguments.browser)) {
				command("browse").params(serverURL, "--browser=" & arguments.browser).run();
			} else {
				command("browse").params(serverURL).run();
			}
		} catch (any e) {
			// Fall back to standard server open command if we can't get server info
			print.yellowLine("Unable to determine server URL. Attempting to use server open command...");
			
			var openCommand = "server open";
			
			if (!isNull(arguments.name)) {
				openCommand &= " name=#arguments.name#";
			}
			
			if (len(arguments.path)) {
				openCommand &= " --path=#arguments.path#";
			}
			
			if (!isNull(arguments.browser)) {
				openCommand &= " --browser=#arguments.browser#";
			}
			
			command(openCommand).run();
		}
	}

}