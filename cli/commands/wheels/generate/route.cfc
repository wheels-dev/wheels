/**
 * Adds a route to the routes.cfm file
 * 
 * Examples:
 * wheels generate route products (creates resources route)
 * wheels generate route --get products/sale,products#sale
 * wheels generate route --post api/users,api.users#create
 * wheels generate route --resources products
 **/
component  aliases='wheels g route' extends="../base"  {

	/**
	 * Initialize the command
	 */
	function init() {
		super.init();
		return this;
	}

  /**
   * @objectname     The name of the resource/route to add
   * @get            Create a GET route with pattern,handler format
   * @post           Create a POST route with pattern,handler format
   * @put            Create a PUT route with pattern,handler format
   * @patch          Create a PATCH route with pattern,handler format
   * @delete         Create a DELETE route with pattern,handler format
   * @resources      Create a resources route (default behavior)
   * @root           Create a root route with handler
   **/
	 function run(
		string objectname = "",
		string get = "",
		string post = "",
		string put = "",
		string patch = "",
		string delete = "",
		boolean resources = false,
		string root = ""
	) {
		// Initialize rails service
		var rails = application.wirebox.getInstance("RailsOutputService");
		
		// Validate that at least one route option is provided
		if (!len(arguments.objectname) && !len(arguments.get) && !len(arguments.post) && 
			!len(arguments.put) && !len(arguments.patch) && !len(arguments.delete) && 
			!len(arguments.root) && !arguments.resources) {
			error("Please provide either an objectname for a resources route or specify a route type (--get, --post, etc.)");
		}
		
		var target = fileSystemUtil.resolvePath("app/config/routes.cfm");
		var content = fileRead(target);
		var inject = "";
		var routeType = "";
		
		// Determine route type and format
		if (len(arguments.get)) {
			var parts = listToArray(arguments.get, ",");
			if (arrayLen(parts) == 2) {
				inject = '.get(pattern="' & trim(parts[1]) & '", to="' & trim(parts[2]) & '")';
			} else {
				inject = '.get(pattern="' & arguments.get & '")';
			}
			routeType = "GET";
		} else if (len(arguments.post)) {
			var parts = listToArray(arguments.post, ",");
			if (arrayLen(parts) == 2) {
				inject = '.post(pattern="' & trim(parts[1]) & '", to="' & trim(parts[2]) & '")';
			} else {
				inject = '.post(pattern="' & arguments.post & '")';
			}
			routeType = "POST";
		} else if (len(arguments.put)) {
			var parts = listToArray(arguments.put, ",");
			if (arrayLen(parts) == 2) {
				inject = '.put(pattern="' & trim(parts[1]) & '", to="' & trim(parts[2]) & '")';
			} else {
				inject = '.put(pattern="' & arguments.put & '")';
			}
			routeType = "PUT";
		} else if (len(arguments.patch)) {
			var parts = listToArray(arguments.patch, ",");
			if (arrayLen(parts) == 2) {
				inject = '.patch(pattern="' & trim(parts[1]) & '", to="' & trim(parts[2]) & '")';
			} else {
				inject = '.patch(pattern="' & arguments.patch & '")';
			}
			routeType = "PATCH";
		} else if (len(arguments.delete)) {
			var parts = listToArray(arguments.delete, ",");
			if (arrayLen(parts) == 2) {
				inject = '.delete(pattern="' & trim(parts[1]) & '", to="' & trim(parts[2]) & '")';
			} else {
				inject = '.delete(pattern="' & arguments.delete & '")';
			}
			routeType = "DELETE";
		} else if (len(arguments.root)) {
			inject = '.root(to="' & arguments.root & '", method="get")';
			routeType = "root";
		} else {
			// Default to resources route
			var obj = helpers.getNameVariants(listLast(arguments.objectname, '/\'));
			
			// Check if route already exists
			if (findNoCase('.resources("' & obj.objectNamePlural & '")', content)) {
				rails.skip("config/routes.cfm (resources route for #obj.objectNamePlural# already exists)");
				return;
			}
			
			inject = '.resources("' & obj.objectNamePlural & '")';
			routeType = "resources";
		}
		
		// Find the correct indentation level
		var baseIndent = chr(9) & chr(9) & chr(9);
		var markerPattern = baseIndent & '// CLI-Appends-Here';
		if (!find(markerPattern, content)) {
			baseIndent = chr(9) & chr(9);
			markerPattern = baseIndent & '// CLI-Appends-Here';
		}
		if (!find(markerPattern, content)) {
			baseIndent = chr(9);
			markerPattern = baseIndent & '// CLI-Appends-Here';
		}
		if (!find(markerPattern, content)) {
			baseIndent = '';
			markerPattern = '// CLI-Appends-Here';
		}
		
		// Add proper indentation to inject
		inject = baseIndent & inject;
		
		// Replace the marker with the new route followed by the marker on a new line
		content = replace(content, markerPattern, inject & cr & markerPattern, 'all');
		
		file action='write' file='#target#' mode='777' output='#trim(content)#';
		
		// Output Rails-style message
		rails.header("🛤️", "Route Generation");
		rails.route(inject);
		rails.update("config/routes.cfm");
		rails.success("Route added successfully!");
	}

}
