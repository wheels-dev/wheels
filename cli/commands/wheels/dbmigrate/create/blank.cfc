/**
 * Create a blank migration CFC
 *
 **/ 
component aliases='wheels db create blank' extends="../../base"  {

	/**
	 * Initialize the command
	 */
	function init() {
		return this;
	}

	/**
	 * I create a migration file in /db/migrate
	 *
	 * Usage: wheels dbmigrate create blank [name]
	 * @name.hint The Name of the migration file 
	 **/
	function run(required string name) {
		// Initialize detail service
		var details = application.wirebox.getInstance("DetailOutputService@wheels-cli");
		
		// Output detail header
		details.header("🗛️", "Migration Generation");

		// Get Template
		var content=fileRead(getTemplate("dbmigrate/blank.txt")); 

		// Make File
		var migrationPath = $createMigrationFile(name=lcase(trim(arguments.name)),	action="",	content=content);
		
		details.create(migrationPath);
		details.success("Blank migration created successfully!");
		
		var nextSteps = [];
		arrayAppend(nextSteps, "Edit the migration file: #migrationPath#");
		arrayAppend(nextSteps, "Run the migration: wheels dbmigrate up");
		details.nextSteps(nextSteps);
	}
}
