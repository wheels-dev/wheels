/**
 * I generate a dbmigration to add a property to an object and scaffold into _form.cfm and show.cfm
 * i.e, wheels generate property table column-name data-type
 *
 * Create the a string/textField property called firstname on the User model:
 *
 * {code:bash}
 * wheels generate property user --column-name=firstname
 * {code}
 *
 * Create a boolean/Checkbox property called isActive on the User model with a default of 0:
 *
 * {code:bash}
 * wheels generate property user --column-name=isActive --data-type=boolean
 * {code}
 *
 * Create a boolean/Checkbox property called hasActivated on the User model with a default of 1 (i.e, true):
 *
 * {code:bash}
 * wheels generate property user --column-name=isActive --data-type=boolean --default=1
 * {code}
 *
 * Create a datetime/datetimepicker property called lastloggedin on the User model:
 *
 * {code:bash}
 * wheels generate property user --column-name=lastloggedin --data-type=datetime
 * {code}
 *
 * All data-type options:
 * biginteger,binary,boolean,date,datetime,decimal,float,integer,string,limit,text,time,timestamp,uuid
 *
 **/
component aliases='wheels g property'  extends="../base"  {

	/**
	 * @name.hint Table Name
	 * @columnName.hint Name of Column
	 * @dataType.hint Type of Column
	 * @dataType.options biginteger,binary,boolean,date,datetime,decimal,float,integer,string,limit,text,time,timestamp,uuid
	 * @default.hint Default Value for column
	 * @null.hint Whether to allow null values
	 * @limit.hint character or integer size limit for column
	 * @precision.hint precision value for decimal columns, i.e. number of digits the column can hold
	 * @scale.hint scale value for decimal columns, i.e. number of digits that can be placed to the right of the decimal point (must be less than or equal to precision)
	 **/
	function run(
		required string name,
		required string columnName,
		string dataType="string",
		any default="",
		boolean null=true,
		number limit=0,
		number precision=0,
		number scale=0
	){

    	var obj = helpers.getNameVariants(arguments.name);

    	// Quick Sanity Checks: are we actually adding a property to an existing model?
    	// Check for existence of model file: NB, DB columns can of course exist without a model file,
    	// But we should confirm they've got it correct.
    	if(!fileExists(fileSystemUtil.resolvePath("app/models/#obj.objectNameSingularC#.cfc"))){
    		if(!confirm("Hold On! We couldn't find a corresponding Model at /app/models/#obj.objectNameSingularC#.cfc: are you sure you wish to add the property '#arguments.columnName#' to #obj.objectNamePlural#? [y/n]")){
    			print.line("Fair enough. Aborting!");
    			return;
    		}
    	}

    	// Set booleans to have a default value of 0 if not specified
    	if(arguments.dataType == "boolean" && len(arguments.default) == 0 ){
    		arguments.default=0;
    	}
    	// NB wheels default is lowercase column names
		command('wheels dbmigrate create column')
			.params(
				name=obj.objectNamePlural,
				columnName=lcase(arguments.columnName),
				dataType=arguments.dataType,
				default=arguments.default,
				null=arguments.null,
				limit=arguments.limit,
				precision=arguments.precision,
				scale=arguments.scale
				)
			.run();
		print.line("Attempting to migrate to latest DB schema");

		// Insert form field
		var formPath = fileSystemUtil.resolvePath("app/views/#obj.objectNamePlural#/_form.cfm");
		if (fileExists(formPath)) {
			print.line("Inserting field into view form");
			$injectIntoView(objectnames=obj, property=arguments.columnName, type=arguments.dataType, action="input");
		} else {
			print.yellowLine("Warning: _form.cfm not found at #formPath#, skipping form field injection");
		}

		// Insert field into index listing
		var indexPath = fileSystemUtil.resolvePath("app/views/#obj.objectNamePlural#/index.cfm");
		if (fileExists(indexPath)) {
			print.line("Inserting field into into index listing");
			$injectIntoIndex(objectnames=obj, property=arguments.columnName, type=arguments.dataType);
		} else {
			print.yellowLine("Warning: index.cfm not found at #indexPath#, skipping index field injection");
		}

		// Insert default output
		var showPath = fileSystemUtil.resolvePath("app/views/#obj.objectNamePlural#/show.cfm");
		if (fileExists(showPath)) {
			print.line("Inserting output into views");
			$injectIntoView(objectnames=obj, property=arguments.columnName, type=arguments.dataType, action="output");
		} else {
			print.yellowLine("Warning: show.cfm not found at #showPath#, skipping show field injection");
		}

		print.yellowline( "Migrating DB" ).toConsole();
		if(confirm("Would you like to migrate the database now? [y/n]")){
			command('wheels dbmigrate latest').run();
	    }
		print.line();
	}

}