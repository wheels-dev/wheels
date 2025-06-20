/**
 * Migration to Latest
 **/
component  aliases='wheels db latest,wheels db migrate'  extends="../base"  {

	/**
	 * @version Optional version to migrate to (0 to initialize, or specific version number)
	 * @help Migrate database to latest version or specified version
	 **/
	function run(string version = "") {
		// Support for wheels db migrate version=0 syntax
		if (Len(arguments.version)) {
			if (arguments.version == "0") {
				print.line("Initializing migration tables...");
				// Run reset to version 0 which initializes the migration table
				command('wheels dbmigrate reset').run();
				print.greenLine("Migration table initialized successfully");
			} else {
				// Migrate to specific version
				print.line("Migrating database to version #arguments.version#...");
				command('wheels dbmigrate exec').params(version=arguments.version).run();
			}
		} else {
			// Default behavior - migrate to latest
			try {
				var DBMigrateInfo = $sendToCliCommand("&command=info");
				
				// Check if we got a valid response
				if (!isStruct(DBMigrateInfo) || !structKeyExists(DBMigrateInfo, "result") || !structKeyExists(DBMigrateInfo.result, "lastVersion")) {
					error("Unable to retrieve migration information from the application. Please ensure your server is running and the application is properly configured.");
				}
				
				print.line("Updating Database Schema to Latest Version")
					.line("Latest Version is #DBMigrateInfo.result.lastVersion#");
				command('wheels dbmigrate exec').params(version=DBMigrateInfo.result.lastVersion).run();
			} catch (any e) {
				error("Failed to get migration information: #e.message#");
			}
		}
		
		command('wheels dbmigrate info').run();
	}

}