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
	 * @name.hint Name of the file(s) to create, i.e, edit or index,show,edit,new
	 * @template.hint optional template (used in Scaffolding)
	 * @template.options crud/_form,crud/edit,crud/index,crud/new,crud/show
	 * @layout.hint Layout file to use for this view (without .cfm extension)
	 * @force.hint Overwrite existing files without prompting
	 **/
	function run(
		required string objectName,
		required string name,
		string template="",
		string layout="",
		boolean force=false
	){
		requireWheelsApp(getCWD());
		arguments = reconstructArgs(
			argStruct=arguments,
			allowedValues={
				template: ["crud/_form", "crud/edit", "crud/index", "crud/new", "crud/show"]
			}
		);
		var obj = helpers.getNameVariants(listLast( arguments.objectName, '/\' ));
		var viewdirectory     = fileSystemUtil.resolvePath( "app/views" );
		// Build path from resolved viewdirectory to avoid conflicts with existing directories (e.g., tests/)
	var directory 		  = viewdirectory & "/" & obj.objectNamePlural;
		
		// Handle multiple views if comma-separated list is provided
		var viewNames = listToArray(arguments.name);
		if (arrayLen(viewNames) > 1) {
			detailOutput.header("Generating views: #arguments.objectName#/#arguments.name#");
		} else {
			detailOutput.header("Generating view: #arguments.objectName#/#arguments.name#");
		}

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
		
		var generatedViews = [];
		
		// Loop through each view name to create
		for (var viewNameItem in viewNames) {
			viewNameItem = trim(viewNameItem);
			
			// Read in Template
			var viewContent 	= "";
			// Try to use a matching template if available
			var templateToUse = arguments.template;
			if (!len(templateToUse) && fileExists(fileSystemUtil.resolvePath('app/snippets/crud/' & viewNameItem & '.txt'))) {
				templateToUse = "crud/" & viewNameItem;
			}
			
			if(!len(templateToUse)){
				viewContent = fileRead(fileSystemUtil.resolvePath('app/snippets/viewContent.txt'));
			} else {
				viewContent = fileRead(fileSystemUtil.resolvePath('app/snippets/' & templateToUse & '.txt'));
			}
			// Replace Object tokens
			viewContent=$replaceDefaultObjectNames(viewContent, obj);
			
			// Add layout specification if provided
			if (len(arguments.layout)) {
				// Check if the view already has a cfset for layout
				if (!findNoCase("<" & "cfset layout", viewContent)) {
					// Add layout setting at the beginning of the file
					viewContent = '<' & 'cfset layout="##arguments.layout##">' & chr(10) & viewContent;
				} else {
					// Replace existing layout setting
					viewContent = reReplaceNoCase(viewContent, '<' & 'cfset\s+layout\s*=\s*["''][^"'']+["'']\s*>', '<' & 'cfset layout="##arguments.layout##">');
				}
			}
			var viewName = lcase(viewNameItem) & ".cfm";
			var viewPath = directory & "/" & viewName;

			if(fileExists(viewPath)){
				if(arguments.force || confirm( '#viewName# already exists in target directory. Do you want to overwrite? [y/n]' ) ) {
				    detailOutput.update("app/views/" & obj.objectNamePlural & "/" & viewName);
				} else {
				    detailOutput.skip("app/views/" & obj.objectNamePlural & "/" & viewName);
				    continue;
				}
			} else {
				detailOutput.create("app/views/" & obj.objectNamePlural & "/" & viewName);
			}
			file action='write' file='#viewPath#' mode ='777' output='#trim( viewContent )#';
			arrayAppend(generatedViews, viewName);
		}
		
		if (arrayLen(generatedViews) > 0) {
			detailOutput.success("View generation complete!");
			
			var nextSteps = [];
			if (arrayLen(generatedViews) == 1) {
				arrayAppend(nextSteps, "Review the generated view at app/views/" & obj.objectNamePlural & "/" & generatedViews[1]);
			} else {
				arrayAppend(nextSteps, "Review the generated views in app/views/" & obj.objectNamePlural & "/");
			}
			arrayAppend(nextSteps, "Customize the HTML content as needed");
			
			if (len(arguments.template)) {
				arrayAppend(nextSteps, "The views were generated using the '" & arguments.template & "' template");
			}
			
			if (len(arguments.layout)) {
				arrayAppend(nextSteps, "Views are configured to use the '" & arguments.layout & "' layout");
				arrayAppend(nextSteps, "Make sure the layout file exists at app/views/" & arguments.layout & ".cfm");
			}
			
			detailOutput.nextSteps(nextSteps);
		}
	}
}