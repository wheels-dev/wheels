/**
 * Wheels Template Development Task Runner
 * Run 'box task run' to see available commands
 */
component extends="../../tools/docker/SimpleTaskRunner" {

	// Just inherit all functionality from base class
	// Override only if specific template behavior is needed

	/**
	 * Default task - delegate to parent or show help
	 */
	function run() {
		// Show help if no command specified
		if (arrayLen(arguments) == 0) {
			super.help();
		} else {
			// Pass through to parent
			super.run(argumentCollection = arguments);
		}
	}

	/**
	 * Start the development server
	 */
	function start(
		string engine = variables.defaultEngine,
		string database = variables.defaultDatabase,
		numeric port = 0
	) {
		super.run(argumentCollection = arguments);
	}
	
	/**
	 * Stop the development server
	 */
	function stop() {
		super.stop();
	}
	
	/**
	 * Restart the development server
	 */
	function restart() {
		super.restart();
	}
	
	/**
	 * Show server status
	 */
	function status() {
		super.status();
	}
	
	/**
	 * Show server logs
	 */
	function logs(boolean follow = false, numeric tail = 100) {
		super.logs(argumentCollection = arguments);
	}
	
	/**
	 * Run application tests
	 */
	function test(string reporter = "text") {
		super.test(argumentCollection = arguments);
	}
	
	/**
	 * Run core framework tests
	 */
	function testCore(string format = "txt") {
		super.testCore(argumentCollection = arguments);
	}
	
	/**
	 * Clean up Docker resources
	 */
	function clean() {
		super.clean();
	}

}