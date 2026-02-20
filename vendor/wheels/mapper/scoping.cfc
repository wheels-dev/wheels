component {
	/**
	 * Set any number of parameters to be inherited by mappers called within this matcher's block. For example, set a package or URL path to be used by all child routes.
	 *
	 * [section: Configuration]
	 * [category: Routing]
	 *
	 * @name Name to prepend to child route names for use when building links, forms, and other URLs.
	 * @path Path to prefix to all child routes.
	 * @package Package namespace to append to controllers.
	 * @controller Controller to use for routes.
	 * @shallow Turn on shallow resources to eliminate routing added before this one.
	 * @shallowPath Shallow path prefix.
	 * @shallowName Shallow name prefix.
	 * @constraints Variable patterns to use for matching.
	 */
	public struct function scope(
		string name,
		string path,
		string package,
		string controller,
		boolean shallow,
		string shallowPath,
		string shallowName,
		struct constraints,
		string $call = "scope"
	) {
		// Set shallow path and prefix if not in a resource.
		if (!ListFindNoCase("resource,resources", variables.scopeStack[1].$call)) {
			if (!StructKeyExists(arguments, "shallowPath") && StructKeyExists(arguments, "path")) {
				arguments.shallowPath = arguments.path;
			}

			if (!StructKeyExists(arguments, "shallowName") && StructKeyExists(arguments, "name")) {
				arguments.shallowName = arguments.name;
			}
		}

		// Combine path with scope path.
		if (StructKeyExists(variables.scopeStack[1], "path") && StructKeyExists(arguments, "path")) {
			arguments.path = $normalizePattern(variables.scopeStack[1].path & "/" & arguments.path);
		}

		// Combine package with scope package.
		if (StructKeyExists(variables.scopeStack[1], "package") && StructKeyExists(arguments, "package")) {
			arguments.package = variables.scopeStack[1].package & "." & arguments.package;
		}

		// Combine name with scope name.
		if (StructKeyExists(arguments, "name") && StructKeyExists(variables.scopeStack[1], "name")) {
			arguments.name = variables.scopeStack[1].name & capitalize(arguments.name);
		}

		// Combine shallow path with scope shallow path.
		if (StructKeyExists(variables.scopeStack[1], "shallowPath") && StructKeyExists(arguments, "shallowPath")) {
			arguments.shallowPath = $normalizePattern(variables.scopeStack[1].shallowPath & "/" & arguments.shallowPath);
		}

		// Copy existing constraints if they were previously set.
		if (StructKeyExists(variables.scopeStack[1], "constraints") && StructKeyExists(arguments, "constraints")) {
			StructAppend(arguments.constraints, variables.scopeStack[1].constraints, false);
		}

		// Put scope arguments on the stack.
		if (structKeyExists(server, "boxlang")) {
			for (local.k in variables.scopeStack[1]) {
				if (!StructKeyExists(arguments, local.k) || isNull(arguments[local.k])) {
					arguments[local.k] = variables.scopeStack[1][local.k];
				}
			}
		} else {
			StructAppend(arguments, variables.scopeStack[1], false);
		}
		ArrayPrepend(variables.scopeStack, arguments);

		return this;
	}

	/**
	 * Scopes any the controllers for any routes configured within this block to a subfolder (package) and also adds the package name to the URL.
	 *
	 * [section: Configuration]
	 * [category: Routing]
	 *
	 * @name Name to prepend to child route names.
	 * @package Subfolder (package) to reference for controllers. This defaults to the value provided for `name`.
	 * @path Subfolder path to add to the URL.
	 */
	public struct function namespace(
		required string name,
		string package = arguments.name,
		string path = hyphenize(arguments.name)
	) {
		return scope(name = arguments.name, package = arguments.package, path = arguments.path, $call = "namespace");
	}

	/**
	 * Scopes any the controllers for any routes configured within this block to a subfolder (package) without adding the package name to the URL.
	 *
	 * [section: Configuration]
	 * [category: Routing]
	 *
	 * @name Name to prepend to child route names.
	 * @package Subfolder (package) to reference for controllers. This defaults to the value provided for `name`.
	 */
	public struct function package(required string name, string package = arguments.name) {
		return scope(name = arguments.name, package = arguments.package, $call = "package");
	}

	/**
	 * Considered deprecated as this doesn't conform to RESTful routing principles; Try not to use this.
	 *
	 * [section: Configuration]
	 * [category: Routing]
	 */
	public struct function controller(
		required string controller,
		string name = arguments.controller,
		string path = hyphenize(arguments.controller)
	) {
		return scope(argumentCollection = arguments, $call = "controller");
	}

	/**
	 * Set variable patterns to use for matching.
	 *
	 * [section: Configuration]
	 * [category: Routing]
	 */
	public struct function constraints() {
		return scope(constraints = arguments, $call = "constraints");
	}
}
