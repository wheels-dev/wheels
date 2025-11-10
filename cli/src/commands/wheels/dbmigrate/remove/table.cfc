/**
 * Remove a table from the database
 *
 **/
component aliases='wheels db remove table' extends="../../base"  {

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

		// Make File
		 $createMigrationFile(name=lcase(trim(arguments.name)),	action="remove_table",	content=content);
	}
}