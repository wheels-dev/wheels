/**
 * Info
 **/
component aliases='wheels db info' extends="../base" {

	/**
	 *  Display DB Migrate info
	 **/
	function run(  ) {
		results = $sendToCliCommand();
		migrations = results.migrations.reverse();

		// calculate the available migrations by stepping through the migration array
		available = 0;
		for (migration in migrations) {
			if (migration.status == "") {
				available++;
			} 
		}

		print.yellowline( "+-----------------------------------------+-----------------------------------------+" );
		print.yellow( "| Datasource: " & rJustify(results.datasource,27) & " | " );
		print.yellowLine( "Total Migrations: " & rJustify(arrayLen(results.migrations),21) & " |" );
		//print.yellowline( "+-----------------------------------------+-----------------------------------------+" );
		print.yellow( "| Database Type: " & rJustify(results.databaseType,24) & " | " );
		print.yellowLine( "Available Migrations: " & rJustify(available,17) & " |" );
		print.yellow( "| " & rJustify("",39) & " | " );
		print.yellowLine( "Current Version: " & rJustify(results.currentVersion,22) & " |" );
		print.yellow( "| " & rJustify("",39) & " | " );
		print.yellowLine( "Latest Version: " & rJustify(results.lastVersion,23) & " |" );
		print.yellowline( "+-----------------------------------------+-----------------------------------------+" );

		if (arrayLen(migrations)) {
			print.yellowline( "+----------+------------------------------------------------------------------------+" );
			for (migration in migrations) {
				print.yellow("| ");
				if (migration.status == "") {
					available++;
					print.yellow( lJustify("",8) );
				} else {
					print.yellow( lJustify(migration.status,8) );
				}
				print.yellowLine( ' | ' & lJustify(migration.CFCFILE,70) & ' |');
			}
			print.yellowline( "+----------+------------------------------------------------------------------------+" );
		}
		
		if (results.message != "Returning what I know..") {
			print.yellowline(results.message);
		}

	}
}