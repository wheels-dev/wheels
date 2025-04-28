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
			print.greenBoldLine("We're already on zero! No migrations to go to");
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

			newIndex = --currentIndex;
			if(newIndex != 0 ){
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