/**
 * Migration to Latest
 **/
component aliases='wheels db latest,wheels db migrate' extends="../base" {

	property name="detailOutput" inject="DetailOutputService@wheels-cli";

	/**
	 * @version Optional version to migrate to (0 to initialize, or specific version number)
	 * @help Migrate database to latest version or specified version
	 **/
	function run(
		string version = ""
	) {
		try{
			// Reconstruct arguments for handling --prefixed options
			arguments = reconstructArgs(arguments);

			// Support for wheels db migrate version=0 syntax
			if (Len(arguments.version)) {
				if (arguments.version == "0") {
					print.line("Initializing migration tables...").toConsole();
					// Run reset to version 0 which initializes the migration table
					command('wheels dbmigrate reset').run();
					detailOutput.statusSuccess("Migration table initialized successfully");
				} else {
					// Migrate to specific version
					print.line("Migrating database to version #arguments.version#...").toConsole();
					command('wheels dbmigrate exec').params(version=arguments.version).run();
				}
			} else {
				// Default behavior - migrate to latest
				try {
					var DBMigrateInfo = $sendToCliCommand("&command=info");
					if(!local.DBMigrateInfo.success){
						return;
					}
					
					// Check if we got a valid response
					if (!DBMigrateInfo.success  || !structKeyExists(DBMigrateInfo, "lastVersion")) {
						detailOutput.error("Unable to retrieve migration information from the application. Please ensure your server is running and the application is properly configured.");
						return;
					}
					
					detailOutput.header("Updating Database Schema to Latest Version");
					detailOutput.metric("Latest Version", DBMigrateInfo.lastVersion);
					
					command('wheels dbmigrate exec').params(version=DBMigrateInfo.lastVersion).run();
				} catch (any e) {
					detailOutput.error("Failed to get migration information: #e.message#");
					return;
				}
			}
			
			// Add a separator before the info command output
			detailOutput.line();
			command('wheels dbmigrate info').run();
		} catch (any e) {
			detailOutput.error("#e.message#");
			setExitCode(1);
		}
	}

}