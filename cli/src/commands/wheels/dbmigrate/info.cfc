/**
 * Info
 **/
component aliases='wheels db info' extends="../base" {

	property name="detailOutput" inject="DetailOutputService@wheels-cli";

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

		detailOutput.header("Database Migration Status", 50);
		
		detailOutput.subHeader("Database Information", 50);
		detailOutput.metric("Datasource", results.datasource);
		detailOutput.metric("Database Type", results.databaseType);
		
		detailOutput.subHeader("Migration Status", 50);
		detailOutput.metric("Total Migrations", arrayLen(results.migrations));
		detailOutput.metric("Available Migrations", available);
		detailOutput.metric("Current Version", results.currentVersion);
		detailOutput.metric("Latest Version", results.lastVersion);
		
		detailOutput.divider();
		
		if (arrayLen(migrations)) {
			detailOutput.subHeader("Migration Files", 50);
			
			var migrationData = [];
			for (migration in migrations) {
				arrayAppend(migrationData, {
					status: migration.status == "" ? "" : migration.status,
					file: migration.CFCFILE
				});
			}
			
			detailOutput.getPrint().table(
				data = migrationData,
				headers = ["Status", "Migration File"]
			).toConsole();
			
			detailOutput.line();
		}
		
		if (results.message != "Returning what I know..") {
			detailOutput.statusInfo(results.message);
		}
	}
}