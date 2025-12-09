/**
 * Adds a route to the routes.cfm file
 *
 * Examples:
 * wheels generate route products
 * wheels generate route --get products/sale,products#sale
 * wheels generate route --post api/users,api.users#create
 * wheels generate route --resources products
 **/
component  aliases='wheels g route, wheels g routes, wheels generate routes' extends="../base"  {

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
		requireWheelsApp(getCWD());
		arguments = reconstructArgs(argStruct=arguments);

		// Initialize detail service
		var details = application.wirebox.getInstance("DetailOutputService@wheels-cli");

		// Validate that at least one route option is provided
		if (!len(arguments.objectname) && !len(arguments.get) && !len(arguments.post) &&
			!len(arguments.put) && !len(arguments.patch) && !len(arguments.delete) &&
			!len(arguments.root) && !arguments.resources) {
			error("Please provide either an objectname for a resources route or specify a route type (--get, --post, etc.)");
		}

		var target = fileSystemUtil.resolvePath("config/routes.cfm");
		var content = fileRead(target);
		var inject = "";
		var routeType = "";

		// Determine route type and format
		if (len(arguments.get)) {
			var routeData = parseRouteArgument(arguments.get);
			inject = '.get(' & routeData.inject & ')';
			routeType = "GET";
		} else if (len(arguments.post)) {
			var routeData = parseRouteArgument(arguments.post);
			inject = '.post(' & routeData.inject & ')';
			routeType = "POST";
		} else if (len(arguments.put)) {
			var routeData = parseRouteArgument(arguments.put);
			inject = '.put(' & routeData.inject & ')';
			routeType = "PUT";
		} else if (len(arguments.patch)) {
			var routeData = parseRouteArgument(arguments.patch);
			inject = '.patch(' & routeData.inject & ')';
			routeType = "PATCH";
		} else if (len(arguments.delete)) {
			var routeData = parseRouteArgument(arguments.delete);
			inject = '.delete(' & routeData.inject & ')';
			routeType = "DELETE";
		} else if (len(arguments.root)) {
			// Validate root handler format
			validateHandler(arguments.root);
			inject = '.root(to="' & arguments.root & '", method="get")';
			routeType = "root";
		} else {
			// Default to resources route
			var obj = helpers.getNameVariants(listLast(arguments.objectname, '/\'));

			// Check if route already exists
			if (findNoCase('.resources("' & obj.objectNamePlural & '")', content)) {
				details.skip("config/routes.cfm (resources route for #obj.objectNamePlural# already exists)");
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

		// Check for duplicate route before injecting
		if (findNoCase(inject, content)) {
			details.skip("config/routes.cfm (route already exists)");
			return;
		}

		// Replace the marker with the new route followed by the marker on a new line
		content = replace(content, markerPattern, inject & cr & markerPattern, 'all');

		file action='write' file='#target#' mode='777' output='#trim(content)#';

		// Output detail message
		details.header("Route Generation");
		details.route(inject);
		details.update("config/routes.cfm");
		details.success("Route added successfully!");
	}

	/**
	 * Parse route argument (pattern,handler format)
	 */
	private struct function parseRouteArgument(required string argument) {
		// Handle edge case of just a comma
		if (trim(arguments.argument) == ",") {
			error("Invalid route format. Pattern cannot be empty. Expected: pattern or pattern,handler");
		}

		// Use includeEmptyFields=true to catch empty patterns/handlers
		var parts = listToArray(arguments.argument, ",", true);
		var result = {};

		// Validate we have at least one part with content
		if (arrayLen(parts) == 0) {
			error("Invalid route format. Expected: pattern or pattern,handler");
		}

		// Trim all parts
		for (var i = 1; i <= arrayLen(parts); i++) {
			parts[i] = trim(parts[i]);
		}

		// Check if first part (pattern) is empty
		if (!len(parts[1])) {
			error("Invalid route format. Pattern cannot be empty. Expected: pattern or pattern,handler");
		}

		if (arrayLen(parts) == 1) {
			// Only pattern provided
			result.inject = 'pattern="' & parts[1] & '"';
		} else if (arrayLen(parts) == 2) {
			// Both pattern and handler provided
			if (!len(parts[2])) {
				error("Invalid route format. Handler cannot be empty. Expected: pattern,controller##action");
			}

			// Validate handler format
			validateHandler(parts[2]);

			result.inject = 'pattern="' & parts[1] & '", to="' & parts[2] & '"';
		} else {
			error("Invalid route format. Expected: pattern,handler (got too many comma-separated values)");
		}

		return result;
	}

	/**
	 * Validate handler format (controller##action)
	 */
	private void function validateHandler(required string handler) {
		var hashChar = chr(35);
		var doubleHash = hashChar & hashChar;

		// Count actual # characters in the handler
		var hashCount = len(arguments.handler) - len(replace(arguments.handler, hashChar, "", "all"));

		// If there's an odd number of # characters, user provided single hash
		if (hashCount % 2 != 0) {
			error("Invalid handler format. Use double hash (#doubleHash#) to separate controller and action, not single hash (#hashChar#). Example: controller#doubleHash#action");
		}

		// Must contain ## separator
		if (!find(doubleHash, arguments.handler)) {
			error("Invalid handler format. Handler must contain #doubleHash# separator. Expected: controller#doubleHash#action");
		}

		// Check if handler starts with ## (missing controller)
		if (left(arguments.handler, 2) == doubleHash) {
			error("Invalid handler format - missing controller. Expected: controller#doubleHash#action");
		}

		// Check if handler ends with ## (missing action)
		if (right(arguments.handler, 2) == doubleHash) {
			error("Invalid handler format - missing action. Expected: controller#doubleHash#action");
		}

		// Split by ## and validate
		var parts = listToArray(arguments.handler, doubleHash);

		if (arrayLen(parts) != 2) {
			error("Invalid handler format. Handler must have exactly one #doubleHash# separator. Expected: controller#doubleHash#action");
		}

		// Double-check that both parts have content (in case of edge cases)
		if (!len(trim(parts[1]))) {
			error("Invalid handler format - missing controller. Expected: controller#doubleHash#action");
		}

		if (!len(trim(parts[2]))) {
			error("Invalid handler format - missing action. Expected: controller#doubleHash#action");
		}
	}

}
