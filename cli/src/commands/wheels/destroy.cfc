/**
 * Kills an object and it's associated DB transactions and view/controller/model/test files
 *
 * {code:bash}
 * wheels destroy user
 * wheels destroy controller Products
 * wheels destroy model Product
 * wheels destroy view products/index
 * {code}
 *
 **/
component aliases='wheels d'  extends="base"  {

	property name="detailOutput" inject="DetailOutputService@wheels-cli";

	/**
	 * @type.hint Type of component to destroy (resource, controller, model, view). Default is resource
	 * @name.hint Name of object to destroy
	 **/
	function run(required string name, string type="resource") {

		requireWheelsApp(getCWD());
		arguments=reconstructArgs(arguments);
		// Validate that name is not empty
		arguments.name = trim(arguments.name);
		if (len(arguments.name) == 0) {
			detailOutput.error("Name argument cannot be empty.")
				 .output("Please provide a name for the component to destroy.")
				 .line()
				 .output("Examples:")
				 .output("wheels destroy User", true)
				 .output("wheels destroy controller Products", true)
				 .output("wheels destroy model Product", true)
				 .output("wheels destroy view products/index", true)
				 .line();
			return;
		}

		// Normalize the type parameter
		arguments.type = lCase(trim(arguments.type));

		// Validate that type is not empty (though it has a default)
		if (len(arguments.type) == 0) {
			detailOutput.error("Type argument cannot be empty.")
				 .output("Valid types: resource, controller, model, view", true)
				 .line();
			return;
		}

		// Handle different destroy types
		switch(arguments.type) {
			case "controller":
				destroyController(arguments.name);
				break;
			case "model":
				destroyModel(arguments.name);
				break;
			case "view":
				destroyView(arguments.name);
				break;
			case "resource":
			default:
				destroyResource(arguments.name);
				break;
		}
	}
	
	/**
	 * Destroy a complete resource (model, controller, views, tests, route, table)
	 */
	private function destroyResource(required string name) {
		var obj            		 = helpers.getNameVariants(arguments.name);
		var modelFile      		 = fileSystemUtil.resolvePath("app/models/#obj.objectNameSingularC#.cfc");
		var controllerFile 		 = fileSystemUtil.resolvePath("app/controllers/#obj.objectNamePluralC#.cfc");
		var viewFolder     		 = fileSystemUtil.resolvePath("app/views/#obj.objectNamePlural#/");
		var testmodelFile  		 = fileSystemUtil.resolvePath("tests/specs/models/#obj.objectNameSingularC#Spec.cfc");
		var testcontrollerFile = fileSystemUtil.resolvePath("tests/specs/controllers/#obj.objectNamePluralC#ControllerSpec.cfc");
		var testviewFolder     = fileSystemUtil.resolvePath("tests/specs/views/#obj.objectNamePlural#/");
		var routeFile   			 = fileSystemUtil.resolvePath("config/routes.cfm");
		var resourceName			 = '.resources("' & obj.objectNamePlural & '")';

		detailOutput.header("Watch Out!")
		.output("This will delete the associated database table '#obj.objectNamePlural#', and")
			 .output("the following files and directories:")
			 .line()
			 .output(modelFile, true)
			 .output(controllerFile, true)
			 .output(viewFolder, true)
			 .output(testmodelFile, true)
			 .output(testcontrollerFile, true)
			 .output(testviewFolder, true)
			 .output(routeFile, true)
			 .output(resourceName, true)
			 .line();

		if(confirm("Are you sure? [y/n]")){
			command('delete').params(path=modelFile, force=true).run();
			command('delete').params(path=controllerFile, force=true).run();
			command('delete').params(path=viewFolder, force=true, recurse=true).run();
			command('delete').params(path=testmodelFile, force=true).run();
			command('delete').params(path=testcontrollerFile, force=true).run();
			command('delete').params(path=testviewFolder, force=true, recurse=true).run();

			//remove the resource from the route config
			var routeContent = fileRead(routeFile);
			routeContent = replaceNoCase(routeContent, resourceName & cr, '', 'all');
			routeContent = replaceNoCase(routeContent, '    ', '  ', 'all');
			file action='write' file='#routeFile#' mode ='777' output='#trim(routeContent)#';
	
			//drop the table
			detailOutput.statusInfo("Migrating DB");
			command('wheels dbmigrate remove table').params(name=obj.objectNamePlural).run();
			command('wheels dbmigrate latest').run();
			detailOutput.line();
		}else{
			detailOutput.getPrint().redLine("Resource destruction cancelled.").toConsole();
			return;
		}
	}
	
	/**
	 * Destroy only a controller and its test
	 */
	private function destroyController(required string name) {
		var obj = helpers.getNameVariants(arguments.name);
		var controllerFile = fileSystemUtil.resolvePath("app/controllers/#obj.objectNamePluralC#.cfc");
		var testcontrollerFile = fileSystemUtil.resolvePath("tests/specs/controllers/#obj.objectNamePluralC#ControllerSpec.cfc");
		
		detailOutput.header("Watch Out!")
		.output("This will delete the following files:")
			 .line()
			 .output(controllerFile, true)
			 .output(testcontrollerFile, true)
			 .line();
			 
		if(confirm("Are you sure? [y/n]")){
			if(fileExists(controllerFile)) {
				command('delete').params(path=controllerFile, force=true).run();
				detailOutput.statusSuccess("Deleted: #controllerFile#");
			} else {
				detailOutput.statusWarning("File not found: #controllerFile#");
			}
			
			if(fileExists(testcontrollerFile)) {
				command('delete').params(path=testcontrollerFile, force=true).run();
				detailOutput.statusSuccess("Deleted: #testcontrollerFile#");
			}
			detailOutput.line();
		}else{
			detailOutput.getPrint().redLine("Resource destruction cancelled.").toConsole();
			return;
		}
	}
	
	/**
	 * Destroy only a model and its test (includes migration to drop table)
	 */
	private function destroyModel(required string name) {
		var obj = helpers.getNameVariants(arguments.name);
		var modelFile = fileSystemUtil.resolvePath("app/models/#obj.objectNameSingularC#.cfc");
		var testmodelFile = fileSystemUtil.resolvePath("tests/specs/models/#obj.objectNameSingularC#Spec.cfc");
		
		detailOutput.header("Watch Out!")
		.output("This will delete the model file and drop the associated database table '#obj.objectNamePlural#'")
			 .line()
			 .output(modelFile, true)
			 .output(testmodelFile, true)
			 .line();
			 
		if(confirm("Are you sure? [y/n]")){
			if(fileExists(modelFile)) {
				command('delete').params(path=modelFile, force=true).run();
				detailOutput.statusSuccess("Deleted: #modelFile#");
			} else {
				detailOutput.statusWarning("File not found: #modelFile#");
			}
			
			if(fileExists(testmodelFile)) {
				command('delete').params(path=testmodelFile, force=true).run();
				detailOutput.statusSuccess("Deleted: #testmodelFile#");
			}
			
			// Drop the table
			detailOutput.statusInfo("Migrating DB to drop table");
			command('wheels dbmigrate remove table').params(name=obj.objectNamePlural).run();
			command('wheels dbmigrate latest').run();
			detailOutput.line();
		}else{
			detailOutput.getPrint().redLine("Resource destruction cancelled.").toConsole();
			return;
		}
	}
	
	/**
	 * Destroy a specific view file or all views for a controller
	 */
	private function destroyView(required string name) {
		// Check if name contains a slash (specific view like products/index)
		if(find("/", arguments.name)) {
			var parts = listToArray(arguments.name, "/");

			// Validate that we have both controller and view parts
			if(arrayLen(parts) != 2 || len(trim(parts[1])) == 0 || len(trim(parts[2])) == 0) {
				detailOutput.error("Invalid view path format.")
					 .output("When destroying a specific view, use format: controller/view", true)
					 .output("Example: wheels destroy view products/index", true)
					 .line();
				return;
			}

			var controllerName = trim(parts[1]);
			var viewName = trim(parts[2]);
			var viewFile = fileSystemUtil.resolvePath("app/views/#controllerName#/#viewName#.cfm");
			
			detailOutput.header("Watch Out!")
			.output("This will delete the following file:")
				 .line()
				 .output(viewFile, true)
				 .line();
				 
			if(confirm("Are you sure? [y/n]")){
				if(fileExists(viewFile)) {
					command('delete').params(path=viewFile, force=true).run();
					detailOutput.statusSuccess("Deleted: #viewFile#");
				} else {
					detailOutput.statusWarning("File not found: #viewFile#");
				}
				detailOutput.line();
			}else{
				detailOutput.getPrint().redLine("Resource destruction cancelled.").toConsole();
				return;
			}
		} else {
			// Destroy all views for a controller
			var obj = helpers.getNameVariants(arguments.name);
			var viewFolder = fileSystemUtil.resolvePath("app/views/#obj.objectNamePlural#/");
			var testviewFolder = fileSystemUtil.resolvePath("tests/specs/views/#obj.objectNamePlural#/");
			
			detailOutput.header("Watch Out!")
			.output("This will delete the following directories:")
				 .line()
				 .output(viewFolder, true)
				 .output(testviewFolder, true)
				 .line();
				 
			if(confirm("Are you sure? [y/n]")){
				if(directoryExists(viewFolder)) {
					command('delete').params(path=viewFolder, force=true, recurse=true).run();
					detailOutput.statusSuccess("Deleted: #viewFolder#");
				} else {
					detailOutput.statusWarning("Directory not found: #viewFolder#");
				}
				
				if(directoryExists(testviewFolder)) {
					command('delete').params(path=testviewFolder, force=true, recurse=true).run();
					detailOutput.statusSuccess("Deleted: #testviewFolder#");
				}
				detailOutput.line();
			}else{
				detailOutput.getPrint().redLine("Resource destruction cancelled.").toConsole();
				return;
			}
		}
	}

}
