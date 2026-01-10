/**
 * Info
 **/
component aliases='wheels db info' extends="../base" {

	property name="detailOutput" inject="DetailOutputService@wheels-cli";

	/**
	 *  Display DB Migrate info
	 **/
	function run(  ) {
		local.results = $sendToCliCommand();
		if(!local.results.success){
			return;
		}
		local.migrations = local.results.migrations.reverse();
		// calculate the available migrations by stepping through the migration array
		local.available = 0;
		for (local.migration in local.migrations) {
			if (local.migration.status == "") {
				local.available++;
			} 
		}

		detailOutput.header("Database Migration Status", 50);
		
		detailOutput.subHeader("Database Information", 50);
		detailOutput.metric("Datasource", local.results.datasource);
		detailOutput.metric("Database Type", local.results.databaseType);
		
		detailOutput.subHeader("Migration Status", 50);
		detailOutput.metric("Total Migrations", arrayLen(local.results.migrations));
		detailOutput.metric("Available Migrations", local.available);
		detailOutput.metric("Current Version", local.results.currentVersion);
		detailOutput.metric("Latest Version", local.results.lastVersion);
		
		detailOutput.divider();
		
		if (arrayLen(local.migrations)) {
			detailOutput.subHeader("Migration Files", 50);
			
			var migrationData = [];
			for (local.migration in local.migrations) {
				arrayAppend(migrationData, {
					status: local.migration.status == "" ? "" : local.migration.status,
					file: local.migration.CFCFILE
				});
			}
			
			detailOutput.getPrint().table(
				data = migrationData,
				headers = ["Status", "Migration File"]
			).toConsole();
			
			detailOutput.line();
		}
		
		if (local.results.message != "Returning what I know..") {
			detailOutput.statusInfo(local.results.message);
		}
	}
}