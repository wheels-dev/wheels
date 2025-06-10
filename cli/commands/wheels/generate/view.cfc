/**
 * I generate a view file in /views/VIEWNAME/NAME.cfm
 *
 * Create a default file called show.cfm without a template
 *
 * {code:bash}
 * wheels generate view user show
 * {code}
 *
 * Create a default file called show.cfm using the default CRUD template
 *
 * {code:bash}
 * wheels generate view user show crud/show
 * {code}
 **/
component aliases='wheels g view' extends="../base"  {
	property name="detailOutput" inject="DetailOutputService@wheels-cli";

	/**
	 * @objectName.hint View path folder, i.e user
	 * @name.hint Name of the file to create, i.e, edit
	 * @template.hint optional template (used in Scaffolding)
	 * @template.options crud/_form,crud/edit,crud/index,crud/new,crud/show
	 **/
	function run(
		required string objectName,
		required string name,
		string template=""
	){
		var obj = helpers.getNameVariants(listLast( arguments.objectName, '/\' ));
		var viewdirectory     = fileSystemUtil.resolvePath( "app/views" );
		var directory 		  = fileSystemUtil.resolvePath( "app/views" & "/" & obj.objectNamePlural);
		detailOutput.header("📄", "Generating view: #arguments.objectName#/#arguments.name#");

		// Validate directory
		if( !directoryExists( viewdirectory ) ) {
			error( "[#viewdirectory#] can't be found. Are you running this from your site root?" );
 		}

 		// Validate views subdirectory, create if doesnt' exist
 		if( !directoryExists( directory ) ) {
 			directoryCreate(directory);
 			detailOutput.create("app/views/" & obj.objectNamePlural);
 		}

		//Copy template files to the application folder if they do not exist there
		ensureSnippetTemplatesExist();
 		// Read in Template
		var viewContent 	= "";
 		if(!len(arguments.template)){
			viewContent = fileRead(fileSystemUtil.resolvePath('app/snippets/viewContent.txt'));
		} else {
			viewContent = fileRead(fileSystemUtil.resolvePath('app/snippets/' & arguments.template & '.txt'));
		}
		// Replace Object tokens
		viewContent=$replaceDefaultObjectNames(viewContent, obj);
		var viewName = lcase(arguments.name) & ".cfm";
		var viewPath = directory & "/" & viewName;

		if(fileExists(viewPath)){
			if( confirm( '#viewName# already exists in target directory. Do you want to overwrite? [y/n]' ) ) {
			    detailOutput.update("app/views/" & obj.objectNamePlural & "/" & viewName);
			} else {
			    detailOutput.skip("app/views/" & obj.objectNamePlural & "/" & viewName);
			    return;
			}
		} else {
			detailOutput.create("app/views/" & obj.objectNamePlural & "/" & viewName);
		}
		file action='write' file='#viewPath#' mode ='777' output='#trim( viewContent )#';
		
		detailOutput.success("View generation complete!");
		
		var nextSteps = [
			"Review the generated view at app/views/" & obj.objectNamePlural & "/" & viewName,
			"Customize the HTML content as needed"
		];
		
		if (len(arguments.template)) {
			arrayAppend(nextSteps, "The view was generated using the '" & arguments.template & "' template");
		}
		
		detailOutput.nextSteps(nextSteps);
	}
}