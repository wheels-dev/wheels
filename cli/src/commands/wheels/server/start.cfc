/**
 * Start the Wheels development server
 * Wraps CommandBox's server start with Wheels-specific checks
 *
 * Examples:
 * {code:bash}
 * wheels server start
 * wheels server start port=8080
 * wheels server start rewritesEnable=true
 * {code}
 **/
component extends="../base" {

	/**
	 * @port Port number to start server on
	 * @host Host/IP to bind server to
	 * @rewritesEnable Enable URL rewriting
	 * @openbrowser Open browser after starting
	 * @directory Directory to serve (defaults to current)
	 * @name Server name
	 * @force Force start even if server is already running
	 **/
	function run(
		numeric port,
		string host = "127.0.0.1",
		boolean rewritesEnable,
		boolean openbrowser = true,
		string directory = getCWD(),
		string name,
		boolean force = false
	) {
		// Check if we're in a Wheels application
		if (!isWheelsApp(arguments.directory)) {
			print.redLine("This doesn't appear to be a Wheels application directory.");
			print.line("Looking for /vendor/wheels, /config, and /app folders in: #arguments.directory#");
			print.line();
			print.yellowLine("Did you mean to run 'wheels generate app' first?");
			return;
		}

		// Check if server is already running
		if (!arguments.force) {
			var serverInfo = getServerInfo();
			if (structKeyExists(serverInfo, "port") && serverInfo.port > 0) {
				print.yellowLine("Server appears to be already running on port #serverInfo.port#");
				print.line("Use --force to start anyway, or 'wheels server restart' to restart.");
				return;
			}
		}

		// Build the server start command
		var startCommand = "server start";
		
		// Add parameters if provided
		if (!isNull(arguments.port)) {
			startCommand &= " --port=#arguments.port#";
		}
		if (!isNull(arguments.host)) {
			startCommand &= " --host=#arguments.host#";
		}
		if (!isNull(arguments.rewritesEnable)) {
			startCommand &= " --rewritesEnable=#arguments.rewritesEnable#";
		}
		if (!isNull(arguments.openbrowser)) {
			startCommand &= " --openbrowser=#arguments.openbrowser#";
		}
		if (!isNull(arguments.name)) {
			startCommand &= " --name=#arguments.name#";
		}
		if (arguments.directory != getCWD()) {
			startCommand &= " --directory=#arguments.directory#";
		}

		print.greenLine("Starting Wheels development server...");
		print.line();
		
		// Execute the server start command
		command(startCommand).run();
		
		// Show helpful information
		print.line();
		print.greenLine("Server started successfully!");
		print.line();
		print.line("Useful commands:");
		print.indentedLine("wheels server status   - Check server status");
		print.indentedLine("wheels server log      - View server logs");
		print.indentedLine("wheels server stop     - Stop the server");
		print.indentedLine("wheels reload          - Reload your application");
		print.line();
	}

	/**
	 * Get server information with error handling
	 **/
	private struct function getServerInfo() {
		try {
			return $getServerInfo();
		} catch (any e) {
			return {};
		}
	}

}