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
	public void function $compileRegex(required string regex, string pattern = "", string name = "") {
		local.patternClass = CreateObject("java", "java.util.regex.Pattern");
		try {
			local.patternClass.compile(arguments.regex);
			return;
		} catch (any e) {
			local.identifier = arguments.pattern;
			if (Len(arguments.name)) {
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
		return "/" & local.pattern;
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
		// Constraint patterns are rewritten to use non-capturing groups because route
		// variables are extracted from the compiled regex by group position (see
		// $mergeRoutePattern in Dispatch.cfc) — an extra capturing group inside a
		// constraint would silently shift every subsequent variable's value.
		local.constraints = StructCopy(arguments.constraints);
		StructAppend(local.constraints, variables.constraints, false);
		for (local.key in local.constraints) {
			local.rv = ReReplaceNoCase(
				local.rv,
				":::#local.key#:::",
				"(#$nonCapturingConstraint(local.constraints[local.key])#)",
				"all"
			);
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
	 * Rewrites unescaped capturing groups (`(`) in a constraint pattern to non-capturing
	 * groups (`(?:`). Route variables are extracted from the compiled route regex by group
	 * position, so a capturing group inside a constraint (e.g., `whereMatch("size", "[0-9]+(px|em)")`)
	 * would shift every subsequent variable to the wrong value or crash param extraction.
	 * Java named capture groups (`(?<name>...)`) are also capturing — they too shift positions —
	 * so they are normalized to `(?:...)`. The `<name>` token is stripped because positional
	 * extraction in $mergeRoutePattern doesn't consult group names. Lookbehind shapes
	 * `(?<=...)` and `(?<!...)` start with `(?<` but are non-capturing and are left alone.
	 * Parentheses inside character classes (e.g., `[\w()-]+`) are literal characters, not
	 * groups, so the scanner tracks unescaped bracket depth and leaves them untouched
	 * (rewriting them would silently widen the class to also match `?` and `:`).
	 */
	public string function $nonCapturingConstraint(required string pattern) {
		local.rv = "";
		local.length = Len(arguments.pattern);
		local.backslashCount = 0;
		local.charClassDepth = 0;
		local.classJustOpened = false;
		for (local.i = 1; local.i <= local.length; local.i++) {
			local.char = Mid(arguments.pattern, local.i, 1);
			if (local.char == "\") {
				local.backslashCount++;
				local.rv &= local.char;
				local.classJustOpened = false;
				continue;
			}
			local.escaped = local.backslashCount % 2 != 0;
			local.backslashCount = 0;
			if (!local.escaped && local.char == "[") {
				// Unescaped `[` opens a character class (Java regex allows nested classes too).
				local.charClassDepth++;
				local.rv &= local.char;
				local.classJustOpened = true;
				continue;
			}
			if (!local.escaped && local.char == "]" && local.charClassDepth > 0 && !local.classJustOpened) {
				// Unescaped `]` closes the innermost character class — unless it is the first
				// member of a just-opened class (`[]]` or `[^]]`), which Java treats as a literal.
				local.charClassDepth--;
				local.rv &= local.char;
				continue;
			}
			if (!local.escaped && local.char == "(" && local.charClassDepth == 0) {
				local.nextChar = local.i < local.length ? Mid(arguments.pattern, local.i + 1, 1) : "";
				if (local.nextChar != "?") {
					// Unescaped capturing group outside any character class: make it non-capturing.
					local.rv &= "(?:";
				} else {
					// `(?...)` flavor. The only capturing flavor is Java named capture `(?<name>...)`.
					// Disambiguate from lookbehinds: `(?<=...)` / `(?<!...)` have `=` or `!` after `<`.
					local.afterQ = local.i + 1 < local.length ? Mid(arguments.pattern, local.i + 2, 1) : "";
					local.afterBracket = local.i + 2 < local.length ? Mid(arguments.pattern, local.i + 3, 1) : "";
					if (local.afterQ == "<" && local.afterBracket != "=" && local.afterBracket != "!" && Len(local.afterBracket)) {
						local.closeIdx = Find(">", arguments.pattern, local.i + 3);
						if (local.closeIdx > 0) {
							// Consume the `(?<name>` prefix and emit `(?:` in its place.
							local.rv &= "(?:";
							local.i = local.closeIdx;
							local.classJustOpened = false;
							continue;
						}
					}
					// Any other `(?...)` flavor is already non-capturing or a lookaround — leave it alone.
					local.rv &= local.char;
				}
			} else {
				local.rv &= local.char;
			}
			// `^` directly after the class opener negates the class, keeping the next
			// character in first-member position; anything else ends that position.
			if (!(local.classJustOpened && !local.escaped && local.char == "^")) {
				local.classJustOpened = false;
			}
		}
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
	 * Also builds a static route index for O(1) lookup of routes with no variables.
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
		// across all CFML engines, and route structs are copied at match time with their
		// non-simple members duplicated — see $copyRouteForRequest in Dispatch.cfc).
		$compileRegex(argumentCollection = arguments);

		// Determine if this is a static route (no variables in the pattern).
		// Static routes can be matched via O(1) hash lookup instead of regex scanning.
		arguments.isStatic = !Find("[", arguments.pattern);

		// Create a plain struct copy of the route data. On Adobe CF, the arguments
		// scope is a special struct type that can cause Duplicate() failures when
		// stored in shared scopes and later deep-copied. StructCopy() produces a
		// plain CFML struct that is safe to Duplicate() on all engines.
		local.routeStruct = StructCopy(arguments);

		// Add route to Wheels.
		ArrayAppend(variables.routes, local.routeStruct);
		ArrayAppend(application[$appKey()].routes, local.routeStruct);

		// Invalidate the URLFor controller/action memo on every mutation.
		// A previous lookup might have negative-cached a (controller, action)
		// pair that this new route now matches — keeping the old empty-string
		// sentinel would silently break link helpers until the next reload.
		if (StructKeyExists(application[$appKey()], "urlForCache")) {
			StructClear(application[$appKey()].urlForCache);
		}

		// Build static route index for O(1) lookup of routes with no variables.
		if (local.routeStruct.isStatic) {
			if (!StructKeyExists(application[$appKey()], "staticRoutes")) {
				application[$appKey()].staticRoutes = {};
			}

			if (StructKeyExists(local.routeStruct, "methods")) {
				local.methodList = ListToArray(local.routeStruct.methods);
			} else {
				local.methodList = ["get", "post", "put", "patch", "delete", "head"];
			}

			for (local.method in local.methodList) {
				local.staticKey = UCase(local.method) & ":" & local.routeStruct.pattern;
				if (!StructKeyExists(application[$appKey()].staticRoutes, local.staticKey)) {
					application[$appKey()].staticRoutes[local.staticKey] = local.routeStruct;
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
