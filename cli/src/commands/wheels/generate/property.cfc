/**
 * I generate a dbmigration to add a property to an object and scaffold into _form.cfm and show.cfm
 * i.e, wheels generate property table column-name data-type
 *
 * Create the a string/textField property called firstname on the User model:
 *
 * {code:bash}
 * wheels generate property user columnname=firstname
 * {code}
 *
 * Create a boolean/Checkbox property called isActive on the User model with a default of 0:
 *
 * {code:bash}
 * wheels generate property user columname=isActive datatype=boolean
 * {code}
 *
 * Create a boolean/Checkbox property called hasActivated on the User model with a default of 1 (i.e, true):
 *
 * {code:bash}
 * wheels generate property user columnname=isActive datatype=boolean default=1
 * {code}
 *
 * Create a datetime/datetimepicker property called lastloggedin on the User model:
 *
 * {code:bash}
 * wheels generate property user columnname=lastloggedin datatype=datetime
 * {code}
 *
 * All data-type options:
 * biginteger,binary,boolean,date,datetime,decimal,float,integer,string,limit,text,time,timestamp,uuid
 *
 **/
component aliases='wheels g property'  extends="../base"  {
	property name="detailOutput" inject="DetailOutputService@wheels-cli";

	/**
	 * @name.hint Table Name
	 * @columnName.hint Name of Column
	 * @dataType.hint Type of Column
	 * @dataType.options biginteger,binary,boolean,date,datetime,decimal,float,integer,string,limit,text,time,timestamp,uuid
	 * @default.hint Default Value for column
	 * @allowNull.hint Whether to allow null values
	 * @limit.hint character or integer size limit for column
	 * @precision.hint precision value for decimal columns, i.e. number of digits the column can hold
	 * @scale.hint scale value for decimal columns, i.e. number of digits that can be placed to the right of the decimal point (must be less than or equal to precision)
	 **/
	function run(
		required string name,
		required string columnName,
		string dataType="string",
		any default="",
		boolean allowNull=true,
		number limit=0,
		number precision=0,
		number scale=0
	){
		requireWheelsApp(getCWD());
		arguments = reconstructArgs(
			argStruct=arguments,
			allowedValues={
				dataType: ["biginteger", "binary", "boolean", "date", "datetime", "decimal", "float", "integer", "string", "limit", "text", "time", "timestamp", "uuid"]
			}
		);

    	var obj = helpers.getNameVariants(arguments.name);

    	detailOutput.header("Generating property: #arguments.columnName# for #arguments.name#");

    	// Quick Sanity Checks: are we actually adding a property to an existing model?
    	// Check for existence of model file: NB, DB columns can of course exist without a model file,
    	// But we should confirm they've got it correct.
    	if(!fileExists(fileSystemUtil.resolvePath("app/models/#obj.objectNameSingularC#.cfc"))){
    		if(!confirm("Hold On! We couldn't find a corresponding Model at /app/models/#obj.objectNameSingularC#.cfc: are you sure you wish to add the property '#arguments.columnName#' to #obj.objectNamePlural#? [y/n]")){
    			detailOutput.error("Aborting property generation.");
    			return;
    		}
    	}

    	// Set booleans to have a default value of 0 if not specified
    	if(arguments.dataType == "boolean" && len(arguments.default) == 0 ){
    		arguments.default=0;
    	}
    	// NB wheels default is lowercase column names
    	detailOutput.invoke("dbmigrate");
		command('wheels dbmigrate create column')
			.params(
				name=obj.objectNamePlural,
				columnName=lcase(arguments.columnName),
				dataType=arguments.dataType,
				default=arguments.default,
				allowNull=arguments.allowNull,
				limit=arguments.limit,
				precision=arguments.precision,
				scale=arguments.scale
				)
			.run();

		// Insert form field
		var formPath = fileSystemUtil.resolvePath("app/views/#obj.objectNamePlural#/_form.cfm");
		if (fileExists(formPath)) {
			$injectIntoView(objectnames=obj, property=arguments.columnName, type=arguments.dataType, action="input");
			detailOutput.update("app/views/#obj.objectNamePlural#/_form.cfm");
		} else {
			detailOutput.skip("app/views/#obj.objectNamePlural#/_form.cfm");
		}

		// Insert field into index listing
		var indexPath = fileSystemUtil.resolvePath("app/views/#obj.objectNamePlural#/index.cfm");
		if (fileExists(indexPath)) {
			$injectIntoIndex(objectnames=obj, property=arguments.columnName, type=arguments.dataType);
			detailOutput.update("app/views/#obj.objectNamePlural#/index.cfm");
		} else {
			detailOutput.skip("app/views/#obj.objectNamePlural#/index.cfm");
		}

		// Insert default output
		var showPath = fileSystemUtil.resolvePath("app/views/#obj.objectNamePlural#/show.cfm");
		if (fileExists(showPath)) {
			$injectIntoView(objectnames=obj, property=arguments.columnName, type=arguments.dataType, action="output");
			detailOutput.update("app/views/#obj.objectNamePlural#/show.cfm");
		} else {
			detailOutput.skip("app/views/#obj.objectNamePlural#/show.cfm");
		}

		detailOutput.success("Property generation complete!");

		var nextSteps = [
			"Review the generated migration",
			"Run migrations: wheels dbmigrate latest"
		];

		if (fileExists(formPath) || fileExists(indexPath) || fileExists(showPath)) {
			arrayAppend(nextSteps, "Review the updated view files");
		}

		detailOutput.nextSteps(nextSteps);

		if(confirm("Would you like to migrate the database now? [y/n]")){
			detailOutput.invoke("dbmigrate");
			command('wheels dbmigrate latest').run();
	    }
	}

}
