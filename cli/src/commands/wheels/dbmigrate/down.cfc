/**
 * Migration one version DOWN
 **/
component aliases='wheels db down' extends="../base"  {

	/**
	 *
	 **/
	function run(  ) {
		var DBMigrateInfo=$sendToCliCommand();
		var migrations=DBMigrateInfo.migrations;

		//print.line(Formatter.formatJson( $getDBMigrateInfo() ) );

		// Check we're not at 0
		if(DBMigrateInfo.currentVersion == 0){
			print.yellowLine("No migrations have been run yet. Database is at version 0.");
			print.line("Use 'wheels dbmigrate latest' to run migrations.");
			return;
		}

		// Check if migrations array is empty (files deleted after running migrations)
		if(!arrayLen(migrations)){
			print.redLine("Error: No migration files found, but database is at version #DBMigrateInfo.currentVersion#.");
			print.yellowLine("Migration files may have been deleted after running migrations.");
			print.yellowLine("Options:");
			print.line("  1. Restore the migration files from source control");
			print.line("  2. Reset the schema version table manually");
			print.line("  3. Run 'wheels dbmigrate info' to see current status");
			return;
		}

		// Get current version as an index of the migration array
		var currentIndex = 0;
		var newIndex     = 0;
		var migrateTo    = 0;
		migrations.each(function(migration,i,array){
		    if(migration.version == DBMigrateInfo.currentVersion){
		    	currentIndex = i;
		    }
		});

		// Check if current version was found in migrations array
		if(currentIndex == 0){
			print.redLine("Error: Current database version (#DBMigrateInfo.currentVersion#) not found in migrations.");
			print.yellowLine("This may indicate a migration file was deleted or the schema version table is corrupt.");
			print.line("Current version in database: #DBMigrateInfo.currentVersion#");
			print.line("Available migrations: #arrayLen(migrations)#");
			return;
		}

		newIndex = --currentIndex;
		if(newIndex > 0){
			migrateTo=migrations[newIndex]["version"];
		}
		print.line("Migrating to #migrateTo#");
		command('wheels dbmigrate exec')
			.params(version=migrateTo)
			.run();
		if(migrateTo == 0){
			print.line("Database should now be empty.");
		}
		command('wheels dbmigrate info').run();
	}

}
