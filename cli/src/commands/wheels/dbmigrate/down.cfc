/**
 * Migration one version DOWN
 **/
component aliases='wheels db down' extends="../base"  {

	property name="detailOutput" inject="DetailOutputService@wheels-cli";

	/**
	 *
	 **/
	function run(  ) {
		var DBMigrateInfo=$sendToCliCommand();
		if(!DBMigrateInfo.success){
			return;
		}
		var migrations=DBMigrateInfo.migrations;

		//print.line(Formatter.formatJson( $getDBMigrateInfo() ) );

		// Check we're not at 0
		if(DBMigrateInfo.currentVersion == 0){
			detailOutput.statusWarning("No migrations have been run yet. Database is at version 0.");
			detailOutput.statusInfo("Use 'wheels dbmigrate latest' to run migrations.");
			return;
		}

		// Check if migrations array is empty (files deleted after running migrations)
		if(!arrayLen(migrations)){
			detailOutput.statusFailed("No migration files found, but database is at version #DBMigrateInfo.currentVersion#.");
			detailOutput.statusWarning("Migration files may have been deleted after running migrations.");
			detailOutput.nextSteps([
				"Restore the migration files from source control",
				"Reset the schema version table manually",
				"Run 'wheels dbmigrate info' to see current status"
			]);
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
			detailOutput.statusFailed("Current database version (#DBMigrateInfo.currentVersion#) not found in migrations.");
			detailOutput.statusWarning("This may indicate a migration file was deleted or the schema version table is corrupt.");
			detailOutput.metric("Current version in database", DBMigrateInfo.currentVersion);
			detailOutput.metric("Available migrations", arrayLen(migrations));
			return;
		}

		newIndex = --currentIndex;
		if(newIndex > 0){
			migrateTo=migrations[newIndex]["version"];
		}
		
		detailOutput.statusInfo("Migrating to version #migrateTo#");
		command('wheels dbmigrate exec')
			.params(version=migrateTo)
			.run();
		if(migrateTo == 0){
			detailOutput.statusSuccess("Database should now be empty.");
		}
		command('wheels dbmigrate info').run();
	}

}
