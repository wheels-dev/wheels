/**
 * Create a blank migration CFC
 *
 **/ 
component aliases='wheels db create blank' extends="../../base"  {

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
	 * Usage: wheels dbmigrate create blank [name]
	 * @name.hint The Name of the migration file 
	 **/
	function run(required string name) {
		// Initialize rails service
		var rails = application.wirebox.getInstance("RailsOutputService");
		
		// Output Rails-style header
		rails.header("🗛️", "Migration Generation");

		// Get Template
		var content=fileRead(getTemplate("dbmigrate/blank.txt")); 

		// Make File
		var migrationPath = $createMigrationFile(name=lcase(trim(arguments.name)),	action="",	content=content);
		
		rails.create(migrationPath);
		rails.success("Blank migration created successfully!");
		
		var nextSteps = [];
		arrayAppend(nextSteps, "Edit the migration file: #migrationPath#");
		arrayAppend(nextSteps, "Run the migration: wheels dbmigrate up");
		rails.nextSteps(nextSteps);
	}
}
