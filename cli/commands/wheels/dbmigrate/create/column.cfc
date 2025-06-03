/**
 * wheels dbmigrate create column [tablename] [data-type] [column-name]
 * 
 * wheels dbmigrate create column [name] [data-type] [column-name]
 * | Parameter   | Required | Default | Description                                         |
 * | ----------- | -------- | ------- | --------------------------------------------------- |
 * | name        | true     |         | The name of the database table to modify            |
 * | data-type   | true     |         | The column type to add                              |
 * | column-name | false    |         | The column name to add                              |
 * | default     | false    |         | The default value to set for the column             |
 * | null        | false    | true    | Should the column allow nulls                       |
 * | limit       | false    |         | The character limit of the column                   |
 * | precision   | false    |         | The precision of the numeric column                 |
 * | scale       | false    |         | The scale of the numeric column                     |
 * 
 **/
 component aliases='wheels db create column' extends="../../base"  {

	/**
	 * Usage: wheels dbmigrate create column [tablename] [force] [id] [primaryKey]
	 * @name.hint The Object Name
	 * @data-type.hint The column type to add
	 * @column-name.hint The column name to add
	 * @default.hint The default value to set for the column
	 * @null.hint Should the column allow nulls
	 * @limit.hint The character limit of the column
	 * @precision.hint The precision of the numeric column
	 * @scale.hint The scale of the numeric column
	 **/
	function run(
		required string name,
		required string "data-type",
		string "column-name"="",
		any default,
		boolean null=true,
		number limit,
		number precision,
		number scale) {

		// Get Template
		var content=fileRead(getTemplate("dbmigrate/create-column.txt"));
		var argumentArr=[];
		var argumentString="";

		// Changes here
		content=replaceNoCase(content, "|tableName|", "#name#", "all");
		content=replaceNoCase(content, "|columnType|", "#arguments["data-type"]#", "all");
		content=replaceNoCase(content, "|columnName|", "#arguments["column-name"]#", "all");
		//content=replaceNoCase(content, "|referenceName|", "#referenceName#", "all");

		// Construct additional arguments(only add/replace if passed through)
		if(structKeyExists(arguments,"default") && len(arguments.default)){
			if(isnumeric(arguments.default)){
			arrayAppend(argumentArr, "default = #arguments.default#");
			} else {
			arrayAppend(argumentArr, "default = '#arguments.default#'");
			}
		}
		if(structKeyExists(arguments,"null") && len(arguments.null) && isBoolean(arguments.null)){
			arrayAppend(argumentArr, "null = #arguments.null#");
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

		// Make File
		$createMigrationFile(name=lcase(trim(arguments.name)) & '_' & lcase(trim(arguments["column-name"])),	action="create_column",	content=content);
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