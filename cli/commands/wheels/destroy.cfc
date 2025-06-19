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

	/**
	 * @type.hint Type of component to destroy (resource, controller, model, view). Default is resource
	 * @name.hint Name of object to destroy
	 **/
	function run(string type="resource", required string name) {
		
		// Normalize the type parameter
		arguments.type = lCase(trim(arguments.type));
		
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
		var testmodelFile  		 = fileSystemUtil.resolvePath("tests/Testbox/specs/models/#obj.objectNameSingularC#.cfc");
		var testcontrollerFile = fileSystemUtil.resolvePath("tests/Testbox/specs/controllers/#obj.objectNamePluralC#.cfc");
		var testviewFolder     = fileSystemUtil.resolvePath("tests/Testbox/specs/views/#obj.objectNamePlural#/");
		var routeFile   			 = fileSystemUtil.resolvePath("app/config/routes.cfm");
		var resourceName			 = '.resources("' & obj.objectNamePlural & '")';

		print.redBoldLine("================================================")
			 .redBoldLine("= Watch Out!                                   =")
			 .redBoldLine("================================================")
			 .line("This will delete the associated database table '#obj.objectNamePlural#', and")
			 .line("the following files and directories:")
			 .line()
			 .line("#modelFile#")
			 .line("#controllerFile#")
			 .line("#viewFolder#")
			 .line("#testmodelFile#")
			 .line("#testcontrollerFile#")
			 .line("#testviewFolder#")
			 .line("#routeFile#")
			 .line("#resourceName#")
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
			print.greenline( "Migrating DB" ).toConsole();
			command('wheels dbmigrate remove table').params(name=obj.objectNamePlural).run();
			command('wheels dbmigrate latest').run();
			print.line();
		}
	}
	
	/**
	 * Destroy only a controller and its test
	 */
	private function destroyController(required string name) {
		var obj = helpers.getNameVariants(arguments.name);
		var controllerFile = fileSystemUtil.resolvePath("app/controllers/#obj.objectNamePluralC#.cfc");
		var testcontrollerFile = fileSystemUtil.resolvePath("tests/Testbox/specs/controllers/#obj.objectNamePluralC#.cfc");
		
		print.redBoldLine("================================================")
			 .redBoldLine("= Watch Out!                                   =")
			 .redBoldLine("================================================")
			 .line("This will delete the following files:")
			 .line()
			 .line("#controllerFile#")
			 .line("#testcontrollerFile#")
			 .line();
			 
		if(confirm("Are you sure? [y/n]")){
			if(fileExists(controllerFile)) {
				command('delete').params(path=controllerFile, force=true).run();
				print.greenLine("Deleted: #controllerFile#");
			} else {
				print.yellowLine("File not found: #controllerFile#");
			}
			
			if(fileExists(testcontrollerFile)) {
				command('delete').params(path=testcontrollerFile, force=true).run();
				print.greenLine("Deleted: #testcontrollerFile#");
			}
			print.line();
		}
	}
	
	/**
	 * Destroy only a model and its test (includes migration to drop table)
	 */
	private function destroyModel(required string name) {
		var obj = helpers.getNameVariants(arguments.name);
		var modelFile = fileSystemUtil.resolvePath("app/models/#obj.objectNameSingularC#.cfc");
		var testmodelFile = fileSystemUtil.resolvePath("tests/Testbox/specs/models/#obj.objectNameSingularC#.cfc");
		
		print.redBoldLine("================================================")
			 .redBoldLine("= Watch Out!                                   =")
			 .redBoldLine("================================================")
			 .line("This will delete the model file and drop the associated database table '#obj.objectNamePlural#'")
			 .line()
			 .line("#modelFile#")
			 .line("#testmodelFile#")
			 .line();
			 
		if(confirm("Are you sure? [y/n]")){
			if(fileExists(modelFile)) {
				command('delete').params(path=modelFile, force=true).run();
				print.greenLine("Deleted: #modelFile#");
			} else {
				print.yellowLine("File not found: #modelFile#");
			}
			
			if(fileExists(testmodelFile)) {
				command('delete').params(path=testmodelFile, force=true).run();
				print.greenLine("Deleted: #testmodelFile#");
			}
			
			// Drop the table
			print.greenline( "Migrating DB to drop table" ).toConsole();
			command('wheels dbmigrate remove table').params(name=obj.objectNamePlural).run();
			command('wheels dbmigrate latest').run();
			print.line();
		}
	}
	
	/**
	 * Destroy a specific view file or all views for a controller
	 */
	private function destroyView(required string name) {
		// Check if name contains a slash (specific view like products/index)
		if(find("/", arguments.name)) {
			var parts = listToArray(arguments.name, "/");
			var controllerName = parts[1];
			var viewName = parts[2];
			var viewFile = fileSystemUtil.resolvePath("app/views/#controllerName#/#viewName#.cfm");
			
			print.redBoldLine("================================================")
				 .redBoldLine("= Watch Out!                                   =")
				 .redBoldLine("================================================")
				 .line("This will delete the following file:")
				 .line()
				 .line("#viewFile#")
				 .line();
				 
			if(confirm("Are you sure? [y/n]")){
				if(fileExists(viewFile)) {
					command('delete').params(path=viewFile, force=true).run();
					print.greenLine("Deleted: #viewFile#");
				} else {
					print.yellowLine("File not found: #viewFile#");
				}
				print.line();
			}
		} else {
			// Destroy all views for a controller
			var obj = helpers.getNameVariants(arguments.name);
			var viewFolder = fileSystemUtil.resolvePath("app/views/#obj.objectNamePlural#/");
			var testviewFolder = fileSystemUtil.resolvePath("tests/Testbox/specs/views/#obj.objectNamePlural#/");
			
			print.redBoldLine("================================================")
				 .redBoldLine("= Watch Out!                                   =")
				 .redBoldLine("================================================")
				 .line("This will delete the following directories:")
				 .line()
				 .line("#viewFolder#")
				 .line("#testviewFolder#")
				 .line();
				 
			if(confirm("Are you sure? [y/n]")){
				if(directoryExists(viewFolder)) {
					command('delete').params(path=viewFolder, force=true, recurse=true).run();
					print.greenLine("Deleted: #viewFolder#");
				} else {
					print.yellowLine("Directory not found: #viewFolder#");
				}
				
				if(directoryExists(testviewFolder)) {
					command('delete').params(path=testviewFolder, force=true, recurse=true).run();
					print.greenLine("Deleted: #testviewFolder#");
				}
				print.line();
			}
		}
	}

}
