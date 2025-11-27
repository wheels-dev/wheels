/**
 * wheels db create table
 * 
 * wheels dbmigrate create table [name] [force] [id] [primary-key]
 * | Parameter   | Required | Default | Description                                         |
 * | ----------- | -------- | ------- | --------------------------------------------------- |
 * | name        | true     |         | The name of the database table to create            |
 * | force       | false    | false   | Force the creation of the table                     |
 * | id          | false    | true    | Auto create ID column as autoincrement ID           |
 * | primary-key | false    | ID      | Overrides the default primary key column name       |
 * 
 **/
 component aliases='wheels db create table' extends="../../base"  {

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
	 * Usage: wheels dbmigrate create table [name] [force] [id] [primary-key]
	 * @name.hint The Object Name
	 * @force.hint Force Creation
	 * @id.hint Auto create ID column as autoincrement ID
	 * @primaryKey.hint overrides default primary key name
	 **/
	function run(
		required string name,
		boolean force    = false,
		boolean id 		 = true,
		string primaryKey="id") {
		
		// Reconstruct arguments for handling --prefixed options
		arguments = reconstructArgs(arguments);
		
		// Initialize detail service
		var details = application.wirebox.getInstance("DetailOutputService@wheels-cli");

		// Get Template
		var content=fileRead(getTemplate("dbmigrate/create-table.txt"));

		// Changes here
		content=replaceNoCase(content, "|tableName|", "#name#", "all");
		content=replaceNoCase(content, "|force|", "#force#", "all");
		content=replaceNoCase(content, "|id|", "#id#", "all");
		content=replaceNoCase(content, "|primaryKey|", "#arguments.primaryKey#", "all");

		// Output detail header
		details.header("Migration Generation");
		
		// Make File
		var migrationPath = $createMigrationFile(name=lcase(trim(arguments.name)),	action="create_table",	content=content);
		
		details.create(migrationPath);
		details.success("Table migration created successfully!");
		
		var nextSteps = [];
		arrayAppend(nextSteps, "Edit the migration to add columns: #migrationPath#");
		arrayAppend(nextSteps, "Run the migration: wheels dbmigrate up");
		arrayAppend(nextSteps, "Generate a model for this table: wheels generate model #arguments.name#");
		details.nextSteps(nextSteps);
	}
}