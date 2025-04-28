/**
 * Create a blank migration CFC
 *
 **/ 
component aliases='wheels db create blank' extends="../../base"  {

	/**
	 * I create a migration file in /db/migrate
	 *
	 * Usage: wheels dbmigrate create blank [name]
	 * @name.hint The Name of the migration file 
	 **/
	function run(required string name) {

		// Get Template
		var content=fileRead(getTemplate("dbmigrate/blank.txt")); 

		// Make File
		$createMigrationFile(name=lcase(trim(arguments.name)),	action="",	content=content);
	}
}
