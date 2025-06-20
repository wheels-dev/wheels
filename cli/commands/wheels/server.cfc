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
	// This is a namespace command - subcommands are in the server/ directory
	// CommandBox will automatically handle subcommand routing
}