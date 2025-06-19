/**
 * Tail the Wheels development server logs
 *
 * Examples:
 * {code:bash}
 * wheels server log
 * wheels server log --follow
 * wheels server log --lines=50
 * {code}
 **/
component extends="../base" {

	/**
	 * @name Server name (optional)
	 * @follow Follow log output (tail -f)
	 * @lines Number of lines to show
	 * @debug Show debug-level logging
	 **/
	function run(
		string name,
		boolean follow = true,
		numeric lines = 50,
		boolean debug = false
	) {
		// Build the log command
		var logCommand = "server log";
		
		if (!isNull(arguments.name)) {
			logCommand &= " --name=#arguments.name#";
		}
		
		if (arguments.follow) {
			logCommand &= " --follow";
		}
		
		if (!isNull(arguments.lines)) {
			logCommand &= " --lines=#arguments.lines#";
		}
		
		if (arguments.debug) {
			logCommand &= " --debug";
		}

		print.yellowLine("Tailing Wheels server logs...");
		print.grayLine("Press Ctrl+C to stop following logs");
		print.line();
		
		// Execute the server log command
		command(logCommand).run();
	}

}