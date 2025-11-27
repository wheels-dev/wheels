/**
 * wheels dbmigrate create column [tableName] [dataType] [name]
 *
 * | Parameter   | Required | Default | Description                                         |
 * | ----------- | -------- | ------- | --------------------------------------------------- |
 * | name        | true     |         | The column name to add                              |
 * | tableName   | true     |         | The name of the database table to modify            |
 * | dataType    | true     |         | The column type to add                              |
 * | default     | false    |         | The default value to set for the column             |
 * | allowNull   | false    | true    | Should the column allow nulls                       |
 * | limit       | false    |         | The character limit of the column                   |
 * | precision   | false    |         | The precision of the numeric column                 |
 * | scale       | false    |         | The scale of the numeric column                     |
 *
 **/
 component aliases='wheels db create column' extends="../../base"  {

	/**
	 * Initialize the command
	 */
	function init() {
		super.init();
		return this;
	}

	/**
	 * Usage: wheels dbmigrate create column [name] [dataType] [dataType]
	 * @name.hint The column name to add
	 * @tableName.hint The name of the database table to modify
	 * @dataType.hint The column type to add
	 * @default.hint The default value to set for the column
	 * @allowNull.hint Should the column allow nulls
	 * @limit.hint The character limit of the column
	 * @precision.hint The precision of the numeric column
	 * @scale.hint The scale of the numeric column
	 **/
	function run(
		required string name,
		required string tableName,
		required string dataType,
		any default,
		boolean allowNull=true,
		number limit,
		number precision,
		number scale) {
	
		// Reconstruct arguments for handling -- prefixed options
		arguments = reconstructArgs(
			argStruct = arguments,
            allowedValues = {
                dataType= ["string", "text", "integer", "biginteger", "float", "boolean", "date", "time", "datetime", "timestamp", "binary"]
            }
		);

		// Initialize detail service
		var details = application.wirebox.getInstance("DetailOutputService@wheels-cli");
		
		// Get Template
		var content=fileRead(getTemplate("dbmigrate/create-column.txt"));
		var argumentArr=[];
		var argumentString="";

		// Changes here
		content=replaceNoCase(content, "|tableName|", "#arguments.tableName#", "all");
		content=replaceNoCase(content, "|columnType|", "#arguments.dataType#", "all");
		content=replaceNoCase(content, "|columnName|", "#arguments.name#", "all");
		//content=replaceNoCase(content, "|referenceName|", "#referenceName#", "all");

		// Construct additional arguments(only add/replace if passed through)
		if(structKeyExists(arguments,"default") && len(arguments.default)){
			if(isnumeric(arguments.default)){
			arrayAppend(argumentArr, "default = #arguments.default#");
			} else {
			arrayAppend(argumentArr, "default = '#arguments.default#'");
			}
		}
		if(structKeyExists(arguments,"allowNull") && len(arguments.allowNull) && isBoolean(arguments.allowNull)){
			arrayAppend(argumentArr, "allowNull = #arguments.allowNull#");
		}
		if(structKeyExists(arguments,"limit") && len(arguments.limit) && isnumeric(arguments.limit) && arguments.limit != 0){
			arrayAppend(argumentArr, "limit = #arguments.limit#");
		}
		if(structKeyExists(arguments,"precision") && len(arguments.precision) && isnumeric(arguments.precision) && arguments.precision != 0){
			arrayAppend(argumentArr, "precision = #arguments.precision#");
		}
		if(structKeyExists(arguments,"scale") && len(arguments.scale) && isnumeric(arguments.scale) && arguments.scale != 0){
			arrayAppend(argumentArr, "scale = #arguments.scale#");
		}
		if(arrayLen(argumentArr)){
			argumentString&=", ";
			argumentString&=$constructArguments(argumentArr);
		}

		// Finally, replace |arguments| with appropriate string
		content=replaceNoCase(content, "|arguments|", "#argumentString#", "all");
		//content=replaceNoCase(content, "|null|", "#null#", "all");
		//content=replaceNoCase(content, "|limit|", "#limit#", "all");
		//content=replaceNoCase(content, "|precision|", "#precision#", "all");
		//content=replaceNoCase(content, "|scale|", "#scale#", "all");

		// Output detail header
		details.header("Migration Generation");
		
		// Make File
		var migrationPath = $createMigrationFile(name=lcase(trim(arguments.tableName)) & '_' & lcase(trim(arguments.name)),	action="create_column",	content=content);
		
		details.create(migrationPath);
		details.success("Column migration created successfully!");
		
		var nextSteps = [];
		arrayAppend(nextSteps, "Review the migration file: #migrationPath#");
		arrayAppend(nextSteps, "Run the migration: wheels dbmigrate up");
		arrayAppend(nextSteps, "Or run all pending migrations: wheels dbmigrate latest");
		details.nextSteps(nextSteps);
	}

	function $constructArguments(args, string operator=","){
		var loc = {};
	    loc.array = [];
	    for (loc.i=1; loc.i <= ArrayLen(arguments.args); loc.i++) {
	        loc.array[loc.i] = "#arguments.args[loc.i]#";
	    }
	    return ArrayToList(loc.array, " #arguments.operator# ");
	}

}