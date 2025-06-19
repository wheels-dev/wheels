/**
 * Server Management Commands
 * Wraps CommandBox's native server functionality with Wheels-specific enhancements
 *
 * Examples:
 * {code:bash}
 * wheels server start
 * wheels server stop
 * wheels server restart
 * wheels server status
 * wheels server log
 * wheels server open
 * {code}
 **/
component extends="base" aliases="" excludeFromHelp=false {

	/**
	 * Display help and available server commands
	 **/
	function run() {
		print.line();
		print.yellowLine("Wheels Server Management Commands");
		print.line("=================================");
		print.line();
		print.line("Available commands:");
		print.line();
		print.indentedLine("wheels server start    - Start the development server");
		print.indentedLine("wheels server stop     - Stop the development server");
		print.indentedLine("wheels server restart  - Restart the development server");
		print.indentedLine("wheels server status   - Show server status");
		print.indentedLine("wheels server log      - Tail server logs");
		print.indentedLine("wheels server open     - Open application in browser");
		print.line();
		print.line("These commands wrap CommandBox's native server functionality");
		print.line("with Wheels-specific enhancements and checks.");
		print.line();
	}

}