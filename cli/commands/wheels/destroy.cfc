/**
 * Kills an object and it's associated DB transactions and view/controller/model/test files
 *
 * {code:bash}
 * wheels destroy user
 * {code}
 *
 **/
component aliases='wheels d'  extends="base"  {

	/**
	 * @name.hint Name of object to destroy
	 **/
	function run(required string name) {

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

}
