/**
 * Database management commands
 *
 * {code:bash}
 * wheels db
 * wheels db create
 * wheels db drop
 * wheels db setup
 * wheels db reset
 * wheels db seed
 * wheels db status
 * wheels db version
 * wheels db rollback
 * wheels db dump
 * wheels db restore
 * {code}
 */
component extends="base" {
	// This is a namespace command - subcommands are in the db/ directory
	// CommandBox will automatically handle subcommand routing
}
