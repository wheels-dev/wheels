/**
 * Start the Wheels development server
 * Wraps CommandBox's server start with Wheels-specific checks
 *
 * Examples:
 * {code:bash}
 * wheels server start
 * wheels server start port=8080
 * {code}
 **/
component extends="../base" {

	/**
	 * @port Port number to start server on
	 * @host Host/IP to bind server to
	 * @openbrowser Open browser after starting
	 * @directory Directory to serve (defaults to current)
	 * @name Server name
	 * @force Force start even if server is already running
	 **/
	function run(
		numeric port,
		string host = "127.0.0.1",
		boolean openbrowser = true,
		string directory = getCWD(),
		string name,
		boolean force = false
	) {
		requireWheelsApp(getCWD());

		arguments = reconstructArgs(
			argStruct = arguments
		);

		// Header
		detailOutput.header("Wheels Development Server");

		// Check if server is already running
		if (!arguments.force) {
			detailOutput.statusInfo("Checking server status");
			var statusCommand = "server status";
			local.result = runCommand(statusCommand);

			// Check if server is not running
			if (findNoCase("running", local.result)) {
				detailOutput.statusWarning("Server appears to already be running");
				detailOutput.nextSteps([
					"Run 'wheels server restart' to restart the server",
					"Run 'wheels server stop' to stop the server",
					"Run with --force to start anyway"
				]);
				return;
			}
		}

		// Build the server start command
		var startCommand = "server start";
		
		// Add parameters if provided
		if (!isNull(arguments.port)) {
			startCommand &= " port=#arguments.port#";
		}
		if (!isNull(arguments.host)) {
			startCommand &= " host=#arguments.host#";
		}
		if (!isNull(arguments.openbrowser)) {
			startCommand &= " openbrowser=#arguments.openbrowser#";
		}
		if (!isNull(arguments.name)) {
			startCommand &= " name=#arguments.name#";
		}
		if (arguments.directory != getCWD()) {
			startCommand &= " directory=#arguments.directory#";
		}

		detailOutput.statusInfo("Starting Wheels development server...");

		// Show command
		detailOutput.subHeader("Executing Command");
		detailOutput.code(startCommand);
		
		// Execute the server start command
		command(startCommand).run();
		
		// Show helpful information
		detailOutput.success("Server started successfully!");

		detailOutput.nextSteps([
			"wheels server status   - Check server status",
			"wheels server log      - View server logs",
			"wheels server stop     - Stop the server",
			"wheels reload          - Reload your application"
		]);
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