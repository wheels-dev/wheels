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

		// Check if route already exists
		if (findNoCase('.resources("' & obj.objectNamePlural & '")', content)) {
			print.yellowLine('Route for "#obj.objectNamePlural#" already exists in routes.cfm');
			return;
		}

		// Inject the route with proper indentation and chaining
		var inject = chr(9) & chr(9) & chr(9) & '.resources("' & obj.objectNamePlural & '")';

		// Find the CLI-Appends-Here marker and replace it
		var markerPattern = chr(9) & chr(9) & chr(9) & '// CLI-Appends-Here';
		if (!find(markerPattern, content)) {
			// Try with different indentation levels
			markerPattern = chr(9) & chr(9) & '// CLI-Appends-Here';
			inject = chr(9) & chr(9) & '.resources("' & obj.objectNamePlural & '")';
		}
		if (!find(markerPattern, content)) {
			markerPattern = chr(9) & '// CLI-Appends-Here';
			inject = chr(9) & '.resources("' & obj.objectNamePlural & '")';
		}
		if (!find(markerPattern, content)) {
			markerPattern = '// CLI-Appends-Here';
			inject = '.resources("' & obj.objectNamePlural & '")';
		}

		// Replace the marker with the new route followed by the marker on a new line
		content = replace(content, markerPattern, inject & cr & markerPattern, 'all');
		
		file action='write' file='#target#' mode ='777' output='#trim(content)#';
		print.line( 'Added resources route for "#obj.objectNamePlural#" to routes.cfm' );
	}

}
