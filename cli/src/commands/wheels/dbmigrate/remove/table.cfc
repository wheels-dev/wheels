/**
 * Remove a table from the database
 *
 **/
component aliases='wheels db remove table' extends="../../base"  {

	property name="detailOutput" inject="DetailOutputService@wheels-cli";

	/**
	 * I create a migration file to remove a table
	 *
	 * Usage: wheels dbmigrate remove table [name]
	 * @name The name of the table to remove
	 * 
	 **/
	function run(
		required string name ) {
		arguments = reconstructArgs(arguments);
		// Get Template
		var content=fileRead(getTemplate("dbmigrate/remove-table.txt"));

		// Changes here
		content=replaceNoCase(content, "|tableName|", "#name#", "all");

		// Output detail header
		detailOutput.header("Migration Generation");
		
		// Make File
		var migrationPath = $createMigrationFile(name=lcase(trim(arguments.name)),	action="remove_table",	content=content);
		
		detailOutput.remove(migrationPath);
		detailOutput.line();
		detailOutput.statusSuccess("Table removal migration created successfully!");
		
		var nextSteps = [];
		arrayAppend(nextSteps, "Review the migration file: #migrationPath#");
		arrayAppend(nextSteps, "Run the migration: wheels dbmigrate up");
		arrayAppend(nextSteps, "Run all pending migrations: wheels dbmigrate latest");
		detailOutput.nextSteps(nextSteps);
	}
}