/**
 * Create a blank migration CFC
 *
 **/ 
component aliases='wheels db create blank' extends="../../base"  {

	property name="detailOutput" inject="DetailOutputService@wheels-cli";

	/**
	 * Initialize the command
	 */
	function init() {
		super.init();
		return this;
	}

	/**
	 * I create a migration file in /db/migrate
	 *
	 * Usage: wheels dbmigrate create blank --name=<name> [--description=<description>]
	 * @name.hint The name of the migration file (required)
	 * @description.hint Description comment to add to the migration file (optional)
	 **/
	function run(
		required string name,
		string description = ""
	) {
		// Reconstruct arguments for handling --prefixed options
		arguments = reconstructArgs(arguments);
		
		// Output detail header
		detailOutput.header("Migration Generation");

		// Get Template
		var content = fileRead(getTemplate("dbmigrate/blank.txt")); 

		// Replace template variables
		if (len(trim(arguments.description))) {
			content = replaceNoCase(content, "|DBMigrateDescription|", arguments.description, "all");
		}

		// Make File  
		var migrationPath = $createMigrationFile(name=lcase(trim(arguments.name)), action="blank", content=content);
		
		detailOutput.create(migrationPath);
		detailOutput.line();
		detailOutput.statusSuccess("Blank migration created successfully!");
		
		var nextSteps = [];
		arrayAppend(nextSteps, "1. Edit the migration file: #migrationPath#");
		arrayAppend(nextSteps, "2. Start your server: server start");
		arrayAppend(nextSteps, "3. Check migration status: wheels dbmigrate info");
		arrayAppend(nextSteps, "4. Run the migration: wheels dbmigrate latest");
		detailOutput.nextSteps(nextSteps);
	}
}