/**
 * Migration one version UP
 **/
component aliases='wheels db up' extends="../base"  {

	/**
	 *
	 **/
	function run(  ) {
		var DBMigrateInfo=$sendToCliCommand();
		var migrations=DBMigrateInfo.migrations;

		//print.line(Formatter.formatJson( $getDBMigrateInfo() ) );

		// Check we're not already at the latest version
		if(DBMigrateInfo.currentVersion == DBMigrateInfo.lastVersion){
			print.greenBoldLine("We're all up to date already!");
			return;
		}

		// Get current version as an index of the migration array
		var currentIndex = 0;
		var newIndex     = 0;
		migrations.each(function(migration,i,array){
		    if(migration.version == DBMigrateInfo.currentVersion){
		    	currentIndex = i;
		    }
		});

		if(currentIndex < arrayLen(migrations)){
			newIndex = ++currentIndex;
			print.line("Migrating to #migrations[newIndex]['cfcfile']#");
			command('wheels dbmigrate exec')
				.params(version=migrations[newIndex]["version"])
				.run();
		} else {
			print.line("No more versions to go to?");
		}
		command('wheels dbmigrate info').run();
	}

}