/**
 * Adds a default resources Route.
 *
 **/
component  aliases='wheels g route' extends="../base"  {

  /**
   * @objectname     The name of the resource to add to the routes table
   **/
	 function run(required string objectname) {
		var obj = helpers.getNameVariants(listLast( arguments.objectname, '/\' ));
		var target	= fileSystemUtil.resolvePath("app/config/routes.cfm");
		var content = fileRead(target);

		var inject = '.resources("' & obj.objectNamePlural & '")';

		content = replaceNoCase(content, '// CLI-Appends-Here', inject & cr & '    // CLI-Appends-Here', 'all');
    file action='write' file='#target#' mode ='777' output='#trim(content)#';
    print.line( 'Added resources route for "#obj.objectNamePlural#" to routes.cfm' );
	}

}
