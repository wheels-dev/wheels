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

	/**
	 * @help Display help for database commands
	 */
	public void function run() {
		print.line();
		print.boldCyanLine("Wheels Database Management Commands");
		print.line();
		print.line("Database management commands provide tools for creating, managing, and maintaining");
		print.line("your application's database. These commands complement the migration commands");
		print.line("(dbmigrate) with higher-level database operations.");
		print.line();

		print.boldLine("Available Commands:");
		print.line();

		// Database lifecycle commands
		print.greenLine("  wheels db create");
		print.line("    Create a new database based on datasource configuration");
		print.line();

		print.redLine("  wheels db drop");
		print.line("    Drop an existing database (requires confirmation)");
		print.line();

		print.cyanLine("  wheels db setup");
		print.line("    Setup database (create + migrate + seed)");
		print.line();

		print.yellowLine("  wheels db reset");
		print.line("    Reset database (drop + create + migrate + seed)");
		print.line();

		// Data management
		print.greenLine("  wheels db seed");
		print.line("    Populate database with test/sample data");
		print.line();

		// Status and information
		print.blueLine("  wheels db status");
		print.line("    Show migration status and pending migrations");
		print.line();

		print.blueLine("  wheels db version");
		print.line("    Show current database schema version");
		print.line();

		// Migration management
		print.yellowLine("  wheels db rollback");
		print.line("    Rollback database migrations");
		print.line();

		// Backup and restore
		print.magentaLine("  wheels db dump");
		print.line("    Export database schema and data");
		print.line();

		print.magentaLine("  wheels db restore");
		print.line("    Restore database from dump file");
		print.line();

		// Interactive shell
		print.cyanLine("  wheels db shell");
		print.line("    Launch interactive database shell");
		print.line();

		// Schema utilities
		print.blueLine("  wheels db schema");
		print.line("    Export database schema information");
		print.line();

		print.boldLine("Common Usage Examples:");
		print.line();

		print.line("  ## Setup new database for development");
		print.yellowLine("  wheels db setup");
		print.line();

		print.line("  ## Reset database with fresh data");
		print.yellowLine("  wheels db reset --force");
		print.line();

		print.line("  ## Check migration status");
		print.yellowLine("  wheels db status");
		print.line();

		print.line("  ## Rollback last 3 migrations");
		print.yellowLine("  wheels db rollback --steps=3");
		print.line();

		print.line("  ## Backup production database");
		print.yellowLine("  wheels db dump --output=backup.sql --compress");
		print.line();

		print.line("  ## Restore from backup");
		print.yellowLine("  wheels db restore backup.sql.gz --compressed");
		print.line();

		print.line("  ## Launch database shell");
		print.yellowLine("  wheels db shell");
		print.line();

		print.line("  ## Launch H2 web console");
		print.yellowLine("  wheels db shell --web");
		print.line();

		print.boldLine("Database Configuration:");
		print.line();
		print.line("Database commands use the datasource configured in your Wheels application.");
		print.line("You can override this with the --datasource parameter:");
		print.line();
		print.yellowLine("  wheels db create --datasource=myapp_dev");
		print.line();

		print.line("For environment-specific operations, use --environment:");
		print.line();
		print.yellowLine("  wheels db setup --environment=testing");
		print.line();

		print.boldLine("Safety Features:");
		print.line();
		print.line("- Destructive commands (drop, reset) require confirmation");
		print.line("- Use --force to skip confirmation prompts");
		print.line("- Production environment requires explicit confirmation");
		print.line("- Backup recommended before major operations");
		print.line();

		print.line("For detailed help on any command, use:");
		print.yellowLine("  wheels help db [command]");
		print.line();
		print.line("For migration-specific commands, see:");
		print.yellowLine("  wheels help dbmigrate");
		print.line();
	}

}
