component output="false" {

	/**
	 * Initializes the component and integrates methods from Wheels.Global
	 */
	function init() {
		local.globalComponent = createObject("wheels.Global");
		$integrateFunctions(local.globalComponent);
		$integrateComponents("wheels.mapper");
		return this;
	}

	/**
	 * Internal function.
	 */
	public struct function $init(
		boolean restful = true,
		boolean methods = arguments.restful,
		boolean mapFormat = true,
		string resourceControllerNaming = ""
	) {
		// Set up control variables.
		variables.scopeStack = [];
		variables.restful = arguments.restful;
		variables.methods = arguments.restful || arguments.methods;
		variables.mapFormat = arguments.mapFormat;

		// Set up default variable constraints.
		variables.constraints = {};
		variables.constraints.format = "\w+";
		variables.constraints.controller = "[^\/]+";

		// Set up constraint for globbed routes.
		variables.constraints["\*\w+"] = ".+";

		// Resource controller naming
		variables.resourceControllerNaming = arguments.resourceControllerNaming;
		// placeholder for return value
		variables.routes = [];

		// Performance indexes for faster route matching.
		// routeIndex: maps HTTP method -> array of routes for that method.
		// staticRoutes: maps "METHOD:/path" -> route struct for routes with no variables (O(1) lookup).
		variables.routeIndex = {};
		variables.staticRoutes = {};

		return this;
	}

	public function getRoutes(){
		return variables.routes;
	}

	/**
	 * Internal function.
	 * Validates that a regex string compiles correctly.
	 * Throws an error if the regex is invalid.
	 */
	public void function $compileRegex(required string regex) {
		local.patternClass = CreateObject("java", "java.util.regex.Pattern");
		try {
			local.patternClass.compile(arguments.regex);
			return;
		} catch (any e) {
			local.identifier = arguments.pattern;
			if (StructKeyExists(arguments, "name")) {
				local.identifier = arguments.name;
			}
			Throw(
				type = "Wheels.InvalidRegex",
				message = "The route `#local.identifier#` has created invalid regex of `#arguments.regex#`."
			);
		}
	}

	/**
	 * Internal function.
	 * Force leading slashes, remove trailing and duplicate slashes.
	 */
	public string function $normalizePattern(required string pattern) {
		// First clear the ending slashes.
		local.pattern = ReReplace(arguments.pattern, "(^\/+|\/+$)", "", "all");

		// Reset middle slashes to singles if they are multiple.
		local.pattern = ReReplace(local.pattern, "\/+", "/", "all");

		// Remove a slash next to a period.
		local.pattern = ReReplace(local.pattern, "\/+\.", ".", "all");

		// Return with a prepended slash.
		return "/" & Replace(local.pattern, "//", "/", "all");
	}

	/**
	 * Internal function.
	 * Transform route pattern into regular expression.
	 */
	public string function $patternToRegex(required string pattern, struct constraints = {}) {
		// Escape any dots in pattern.
		local.rv = Replace(arguments.pattern, ".", "\.", "all");

		// Further mask pattern variables.
		// This keeps constraint patterns from being replaced twice.
		local.rv = ReReplace(local.rv, "\[(\*?\w+)\]", ":::\1:::", "all");

		// Replace known variable keys using constraints.
		local.constraints = StructCopy(arguments.constraints);
		StructAppend(local.constraints, variables.constraints, false);
		for (local.key in local.constraints) {
			local.rv = ReReplaceNoCase(local.rv, ":::#local.key#:::", "(#local.constraints[local.key]#)", "all");
		}

		// Replace remaining variables with default regex.
		local.rv = ReReplace(local.rv, ":::\w+:::", "([^\./]+)", "all");
		local.rv = ReReplace(local.rv, "^\/*(.*)\/*$", "^\1/?$");

		// Escape any forward slashes.
		local.rv = ReReplace(local.rv, "(\/|\\\/)", "\/", "all");

		return local.rv;
	}

	/**
	 * Internal function.
	 * Pull list of variables out of route pattern.
	 */
	public string function $stripRouteVariables(required string pattern) {
		local.matchArray = ArrayToList(ReMatch("\[\*?(\w+)\]", arguments.pattern));
		return ReReplace(local.matchArray, "[\*\[\]]", "", "all");
	}

	/**
	 * Private internal function.
	 * Add route to Wheels, removing useless params.
	 * Also builds performance indexes for faster route matching:
	 * - routeIndex: Routes indexed by HTTP method (reduces search space)
	 * - staticRoutes: Hash map for routes with no variables (O(1) lookup)
	 */
	private void function $addRoute(required string pattern, required struct constraints) {
		// Remove controller and action if they are route variables.
		if (Find("[controller]", arguments.pattern) && StructKeyExists(arguments, "controller")) {
			StructDelete(arguments, "controller");
		}
		if (Find("[action]", arguments.pattern) && StructKeyExists(arguments, "action")) {
			StructDelete(arguments, "action");
		}

		// Normalize pattern, convert to regex, and strip out variable names.
		arguments.pattern = $normalizePattern(arguments.pattern);
		arguments.regex = $patternToRegex(arguments.pattern, arguments.constraints);
		arguments.foundvariables = $stripRouteVariables(arguments.pattern);

		// Validate the regex compiles correctly (do not store the Java Pattern object
		// in the route struct because Duplicate() cannot deep-copy Java objects reliably
		// across all CFML engines, and route structs are duplicated at match time).
		$compileRegex(argumentCollection = arguments);

		// Determine if this is a static route (no variables in the pattern).
		// Static routes can be matched via O(1) hash lookup instead of regex scanning.
		arguments.isStatic = !Find("[", arguments.pattern);

		// Add route to Wheels.
		ArrayAppend(variables.routes, arguments);
		ArrayAppend(application[$appKey()].routes, arguments);

		// Build method-indexed lookup for faster matching.
		// This allows $findMatchingRoute to only scan routes for the requested HTTP method.
		if (StructKeyExists(arguments, "methods")) {
			local.methodList = ListToArray(arguments.methods);
		} else {
			// If no method restriction, index under all methods.
			local.methodList = ["get", "post", "put", "patch", "delete", "head"];
		}

		for (local.method in local.methodList) {
			local.methodKey = UCase(local.method);

			// Initialize route index and static route map in application scope if needed.
			if (!StructKeyExists(application[$appKey()], "routeIndex")) {
				application[$appKey()].routeIndex = {};
			}
			if (!StructKeyExists(application[$appKey()], "staticRoutes")) {
				application[$appKey()].staticRoutes = {};
			}

			if (!StructKeyExists(application[$appKey()].routeIndex, local.methodKey)) {
				application[$appKey()].routeIndex[local.methodKey] = [];
			}
			ArrayAppend(application[$appKey()].routeIndex[local.methodKey], arguments);

			// Add to static route fast-path index.
			if (arguments.isStatic) {
				local.staticKey = local.methodKey & ":" & arguments.pattern;
				if (!StructKeyExists(application[$appKey()].staticRoutes, local.staticKey)) {
					application[$appKey()].staticRoutes[local.staticKey] = arguments;
				}
			}
		}
	}

	/**
	 * Private internal function.
	 * Get member name if defined.
	 */
	private string function $member() {
		return StructKeyExists(variables.scopeStack[1], "member") ? variables.scopeStack[1].member : "";
	}

	/**
	 * Private internal function.
	 * Get collection name if defined.
	 */
	private string function $collection() {
		return StructKeyExists(variables.scopeStack[1], "collection") ? variables.scopeStack[1].collection : "";
	}

	/**
	 * Private internal function.
	 * Get scoped route name if defined.
	 */
	private string function $scopeName() {
		return StructKeyExists(variables.scopeStack[1], "name") ? variables.scopeStack[1].name : "";
	}

	/**
	 * Private internal function.
	 * See if resource is shallow.
	 */
	private boolean function $shallow() {
		return StructKeyExists(variables.scopeStack[1], "shallow") && variables.scopeStack[1].shallow == true;
	}

	/**
	 * Private internal function.
	 * Get scoped shallow route name if defined.
	 */
	private string function $shallowName() {
		return StructKeyExists(variables.scopeStack[1], "shallowName") ? variables.scopeStack[1].shallowName : "";
	}

	/**
	 * Private internal function.
	 * Get scoped shallow path if defined.
	 */
	private string function $shallowPath() {
		return StructKeyExists(variables.scopeStack[1], "shallowPath") ? variables.scopeStack[1].shallowPath : "";
	}

	/**
	 * Private internal function.
	 */
	private string function $shallowNameForCall() {
		if (
			ListFindNoCase("collection,new", variables.scopeStack[1].$call) && StructKeyExists(
				variables.scopeStack[1],
				"parentResource"
			)
		) {
			return ListAppend($shallowName(), variables.scopeStack[1].parentResource.member);
		}
		return $shallowName();
	}

	/**
	 * Private internal function.
	 */
	private string function $shallowPathForCall() {
		local.path = "";
		switch (variables.scopeStack[1].$call) {
			case "member":
				local.path = variables.scopeStack[1].memberPath;
				break;
			case "collection":
			case "new":
				if (StructKeyExists(variables.scopeStack[1], "parentResource")) {
					local.path = variables.scopeStack[1].parentResource.nestedPath;
				}
				local.path &= "/" & variables.scopeStack[1].collectionPath;
				break;
		}
		return $shallowPath() & "/" & local.path;
	}

	/**
	 * Private internal function.
	 */
	private void function $resetScopeStack() {
		variables.scopeStack = [];
		ArrayPrepend(variables.scopeStack, {});
		variables.scopeStack[1].$call = "$draw";
	}

	/**
	 * Gets all the component files from the provided path
	 *
	 * @path The path to get component files from
	 */
	private function $integrateComponents(required string path) {
    local.basePath = arguments.path;
    local.folderPath = expandPath("/#replace(local.basePath, ".", "/", "all")#");

    // Get a list of all CFC files in the folder
    local.fileList = directoryList(local.folderPath, false, "name", "*.cfc");
    for (local.fileName in local.fileList) {
      // Remove the file extension to get the component name
      local.componentName = replace(local.fileName, ".cfc", "", "all");

      $integrateFunctions(createObject("component", "#local.basePath#.#local.componentName#"));
    }
	}

	/**
	 * Dynamically mix methods from a given component into this component.
	 * Only public, non-inherited methods are added.
	 *
	 * @param componentInstance The component instance to integrate methods from.
	 */
	private function $integrateFunctions(required any componentInstance) {
			// Get metadata for the component
			local.methods = getMetaData(componentInstance).functions;
			local.componentName = getMetaData(componentInstance).FULLNAME;

			// Iterate over the functions in the component
			for (local.method in local.methods) {
				local.functionName = local.method.name;
				local.excludeList = "get,controller";

				// Add only public, non-inherited methods excluding specific ones
				if (local.method.access == "public" && (!listFindNoCase(local.excludeList, local.functionName) || findNoCase("wheels.mapper", local.componentName))) {
					// Assign methods to `variables` and `this`
					variables[local.functionName] = componentInstance[local.functionName];
					this[local.functionName] = componentInstance[local.functionName];
				}
			}
	}

}
