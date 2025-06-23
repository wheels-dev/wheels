/**
 * Wheels Blog Example Development Task Runner
 * Run 'box task run' to see available commands
 */
component extends="../../tools/docker/SimpleTaskRunner" {

	/**
	 * Default task - delegate to parent or show help
	 */
	function run() {
		// Show help if no command specified
		if (arrayLen(arguments) == 0) {
			help();
		} else {
			// Pass through to parent with blog defaults
			// Blog app needs a real database by default
			if (!structKeyExists(arguments, "database")) {
				arguments.database = "mysql";
			}
			super.run(argumentCollection = arguments);
		}
	}

	/**
	 * Show available commands
	 */
	function help() {
		print.line();
		print.boldBlueLine("Wheels Blog Example Task Runner");
		print.line("================================");
		print.line();
		print.yellowLine("This example demonstrates a blog application with:");
		print.line("- User authentication");
		print.line("- Post management (CRUD)");
		print.line("- Database migrations");
		print.line();
		// Show parent help for standard commands
		super.help();
		print.line();
		print.yellowLine("Blog-Specific Notes:");
		print.line();
		print.line("  This example requires a real database (defaults to MySQL)");
		print.line("  After starting the server:");
		print.line("  - Navigate to /wheels/migrator to run migrations");
		print.line("  - Create sample data through the application");
		print.line();
		print.yellowLine("Quick Start:");
		print.line();
		print.cyanLine("  box task run start --database=mysql");
		print.cyanLine("  # Then visit http://localhost:8080/wheels/migrator");
		print.line();
	}

}