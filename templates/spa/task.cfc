/**
 * Wheels SPA Template Development Task Runner
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

}