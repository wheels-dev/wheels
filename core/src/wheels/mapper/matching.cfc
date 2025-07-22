component {
	/**
	 * Create a route that matches a URL requiring an HTTP `GET` method. We recommend only using this matcher to expose actions that display data. See `post`, `patch`, `delete`, and `put` for matchers that are appropriate for actions that change data in your database.
	 *
	 * [section: Configuration]
	 * [category: Routing]
	 *
	 * @name Camel-case name of route to reference when build links and form actions (e.g., `blogPost`).
	 * @pattern Overrides the URL pattern that will match the route. The default value is a dasherized version of `name` (e.g., a `name` of `blogPost` generates a pattern of `blog-post`).
	 * @to Set `controller##action` combination to map the route to. You may use either this argument or a combination of `controller` and `action`.
	 * @controller Map the route to a given controller. This must be passed along with the `action` argument.
	 * @action Map the route to a given action within the `controller`. This must be passed along with the `controller` argument.
	 * @package Indicates a subfolder that the controller will be referenced from (but not added to the URL pattern). For example, if you set this to `admin`, the controller will be located at `admin/YourController.cfc`, but the URL path will not contain `admin/`.
	 * @on If this route is within a nested resource, you can set this argument to `member` or `collection`. A `member` route contains a reference to the resource's `key`, while a `collection` route does not.
	 * @redirect Redirect via 302 to this URL when this route is matched. Has precedence over controller/action. Use either an absolute link like `/about/`, or a full canonical link.
	 */
	public struct function get(
		string name,
		string pattern,
		string to,
		string controller,
		string action,
		string package,
		string on,
		string redirect
	) {
		return $match(argumentCollection = arguments, method = "get");
	}

	/**
	 * Create a route that matches a URL requiring an HTTP `POST` method. We recommend using this matcher to expose actions that create database records.
	 *
	 * [section: Configuration]
	 * [category: Routing]
	 *
	 * @name Camel-case name of route to reference when build links and form actions (e.g., `blogPosts`).
	 * @pattern Overrides the URL pattern that will match the route. The default value is a dasherized version of `name` (e.g., a `name` of `blogPosts` generates a pattern of `blog-posts`).
	 * @to Set `controller##action` combination to map the route to. You may use either this argument or a combination of `controller` and `action`.
	 * @controller Map the route to a given controller. This must be passed along with the `action` argument.
	 * @action Map the route to a given action within the `controller`. This must be passed along with the `controller` argument.
	 * @package Indicates a subfolder that the controller will be referenced from (but not added to the URL pattern). For example, if you set this to `admin`, the controller will be located at `admin/YourController.cfc`, but the URL path will not contain `admin/`.
	 * @on If this route is within a nested resource, you can set this argument to `member` or `collection`. A `member` route contains a reference to the resource's `key`, while a `collection` route does not.
	 * @redirect Redirect via 302 to this URL when this route is matched. Has precedence over controller/action. Use either an absolute link like `/about/`, or a full canonical link.
	 */
	public struct function post(
		string name,
		string pattern,
		string to,
		string controller,
		string action,
		string package,
		string on,
		string redirect
	) {
		return $match(argumentCollection = arguments, method = "post");
	}

	/**
	 * Create a route that matches a URL requiring an HTTP `PATCH` method. We recommend using this matcher to expose actions that update database records.
	 *
	 * [section: Configuration]
	 * [category: Routing]
	 *
	 * @name Camel-case name of route to reference when build links and form actions (e.g., `blogPost`).
	 * @pattern Overrides the URL pattern that will match the route. The default value is a dasherized version of `name` (e.g., a `name` of `blogPost` generates a pattern of `blog-post`).
	 * @to Set `controller##action` combination to map the route to. You may use either this argument or a combination of `controller` and `action`.
	 * @controller Map the route to a given controller. This must be passed along with the `action` argument.
	 * @action Map the route to a given action within the `controller`. This must be passed along with the `controller` argument.
	 * @package Indicates a subfolder that the controller will be referenced from (but not added to the URL pattern). For example, if you set this to `admin`, the controller will be located at `admin/YourController.cfc`, but the URL path will not contain `admin/`.
	 * @on If this route is within a nested resource, you can set this argument to `member` or `collection`. A `member` route contains a reference to the resource's `key`, while a `collection` route does not.
	 * @redirect Redirect via 302 to this URL when this route is matched. Has precedence over controller/action. Use either an absolute link like `/about/`, or a full canonical link.
	 */
	public struct function patch(
		string name,
		string pattern,
		string to,
		string controller,
		string action,
		string package,
		string on,
		string redirect
	) {
		return $match(argumentCollection = arguments, method = "patch");
	}

	/**
	 * Create a route that matches a URL requiring an HTTP `PUT` method. We recommend using this matcher to expose actions that update database records. This method is provided as a convenience for when you really need to support the `PUT` verb; consider using the `patch` matcher instead of this one.
	 *
	 * [section: Configuration]
	 * [category: Routing]
	 *
	 * @name Camel-case name of route to reference when build links and form actions (e.g., `blogPost`).
	 * @pattern Overrides the URL pattern that will match the route. The default value is a dasherized version of `name` (e.g., a `name` of `blogPost` generates a pattern of `blog-post`).
	 * @to Set `controller##action` combination to map the route to. You may use either this argument or a combination of `controller` and `action`.
	 * @controller Map the route to a given controller. This must be passed along with the `action` argument.
	 * @action Map the route to a given action within the `controller`. This must be passed along with the `controller` argument.
	 * @package Indicates a subfolder that the controller will be referenced from (but not added to the URL pattern). For example, if you set this to `admin`, the controller will be located at `admin/YourController.cfc`, but the URL path will not contain `admin/`.
	 * @on If this route is within a nested resource, you can set this argument to `member` or `collection`. A `member` route contains a reference to the resource's `key`, while a `collection` route does not.
	 * @redirect Redirect via 302 to this URL when this route is matched. Has precedence over controller/action. Use either an absolute link like `/about/`, or a full canonical link.
	 */
	public struct function put(
		string name,
		string pattern,
		string to,
		string controller,
		string action,
		string package,
		string on,
		string redirect
	) {
		return $match(argumentCollection = arguments, method = "put");
	}

	/**
	 * Create a route that matches a URL requiring an HTTP `DELETE` method. We recommend using this matcher to expose actions that delete database records.
	 *
	 * [section: Configuration]
	 * [category: Routing]
	 *
	 * @name Camel-case name of route to reference when build links and form actions (e.g., `blogPost`).
	 * @pattern Overrides the URL pattern that will match the route. The default value is a dasherized version of `name` (e.g., a `name` of `blogPost` generates a pattern of `blog-post`).
	 * @to Set `controller##action` combination to map the route to. You may use either this argument or a combination of `controller` and `action`.
	 * @controller Map the route to a given controller. This must be passed along with the `action` argument.
	 * @action Map the route to a given action within the `controller`. This must be passed along with the `controller` argument.
	 * @package Indicates a subfolder that the controller will be referenced from (but not added to the URL pattern). For example, if you set this to `admin`, the controller will be located at `admin/YourController.cfc`, but the URL path will not contain `admin/`.
	 * @on If this route is within a nested resource, you can set this argument to `member` or `collection`. A `member` route contains a reference to the resource's `key`, while a `collection` route does not.
	 * @redirect Redirect via 302 to this URL when this route is matched. Has precedence over controller/action. Use either an absolute link like `/about/`, or a full canonical link.
	 */
	public struct function delete(
		string name,
		string pattern,
		string to,
		string controller,
		string action,
		string package,
		string on,
		string redirect
	) {
		return $match(argumentCollection = arguments, method = "delete");
	}

	/**
	 * Create a route that matches the root of its current context. This mapper can be used for the application's web root (or home page), or it can generate a route for the root of a namespace or other path scoping mapper.
	 *
	 * [section: Configuration]
	 * [category: Routing]
	 *
	 * @to Set `controller##action` combination to map the route to. You may use either this argument or a combination of `controller` and `action`.
	 * @controller Map the route to a given controller. This must be passed along with the `action` argument.
	 * @action Map the route to a given action within the `controller`. This must be passed along with the `controller` argument.
	 * @mapFormat Set to `true` to include the format (e.g. `.json`) in the route.
	 */
	public struct function root(string to, boolean mapFormat) {
		// If mapFormat is not passed in we default it to true on all calls except the web root.
		if (!StructKeyExists(arguments, "mapFormat")) {
			if (ArrayLen(variables.scopeStack) > 1) {
				arguments.mapFormat = true;
			} else {
				arguments.mapFormat = false;
			}
		}

		if (arguments.mapFormat) {
			local.pattern = "/(.[format])";
		} else {
			local.pattern = "/";
		}

	  // If arguments.to is not passed in, we check for the existence of app/views/home/index.cfm if found we set that as the root
	  // else we set wheels##wheels as the root.
	  if (!structKeyExists(arguments, "to")) {
	    if (fileExists(application.AppDir & "views/home/index.cfm")) {
	      arguments.to = "home##index";
	      arguments.method = "get";
	    } else {
	      arguments.to = "wheels##wheels";
	      arguments.method = "get";
	    }
	  }

		return $match(name = "root", pattern = local.pattern, argumentCollection = arguments);

	}

	/**
	 * Special wildcard matching generates routes with `[controller]/[action]` and `[controller]` patterns. The `mapKey` argument also enables a `[controller]/[action]/[key]` pattern as well.
	 *
	 * [section: Configuration]
	 * [category: Routing]
	 *
	 * @method List of HTTP methods (verbs) to generate the wildcard routes for. We strongly recommend leaving the default value of `get` and using other routing mappers if you need to `POST` to a URL endpoint. For better readability, you can also pass this argument as `methods` if you're listing multiple methods.
	 * @action Default action to specify if the value for the `[action]` placeholder is not provided.
	 * @mapKey Whether or not to enable a `[key]` matcher, enabling a `[controller]/[action]/[key]` pattern.
	 * @mapFormat Whether or not to add an optional `.[format]` pattern to the end of the generated routes. This is useful for providing formats via URL like `json`, `xml`, `pdf`, etc.
	 */
	public struct function wildcard(
		string method = "get",
		string action = "index",
		boolean mapKey = false,
		boolean mapFormat = false
	) {
		if (StructKeyExists(arguments, "methods") && Len(arguments.methods)) {
			local.methods = arguments.methods;
		} else if (Len(arguments.method)) {
			local.methods = ListToArray(arguments.method);
		} else {
			local.methods = ["get", "post", "put", "patch", "delete"];
		}

		local.formatPattern = "";
		if (arguments.mapFormat) {
			local.formatPattern = "(.[format])";
		}

		if (StructKeyExists(variables.scopeStack[1], "controller")) {
			for (local.method in local.methods) {
				if (arguments.mapKey) {
					$match(
						method = local.method,
						name = "wildcard",
						pattern = "[action]/[key]#local.formatPattern#",
						action = arguments.action
					);
				}
				$match(
					method = local.method,
					name = "wildcard",
					pattern = "[action]#local.formatPattern#",
					action = arguments.action
				);
				$match(method = local.method, name = "wildcard", pattern = local.formatPattern, action = arguments.action);
			}
		} else {
			for (local.method in local.methods) {
				if (arguments.mapKey) {
					$match(
						method = local.method,
						name = "wildcard",
						pattern = "[controller]/[action]/[key]#local.formatPattern#",
						action = arguments.action
					);
				}
				$match(
					method = local.method,
					name = "wildcard",
					pattern = "[controller]/[action]#local.formatPattern#",
					action = arguments.action
				);

				$match(
					method = local.method,
					name = "wildcard",
					pattern = "[controller]#local.formatPattern#",
					action = arguments.action
				);
			}
		}
		return this;
	}

	/**
	 * Internal function.
	 * Match a URL.
	 *
	 * @name Name for route. Used for path helpers.
	 * @pattern Pattern to match for route.
	 * @to Set controller##action for route.
	 * @methods HTTP verbs that match route.
	 * @package Namespace to append to controller.
	 * @on Created resource route under "member" or "collection".
	 */
	public struct function $match(
		string name,
		string pattern,
		string to,
		string methods,
		string package,
		string on,
		struct constraints = {}
	) {
		// Evaluate match on member or collection.
		if (StructKeyExists(arguments, "on")) {
			switch (arguments.on) {
				case "member":
					return member().$match(argumentCollection = arguments, on = "").end();
				case "collection":
					return collection().$match(argumentCollection = arguments, on = "").end();
			}
		}

		// Use scoped controller if found.
		if (StructKeyExists(variables.scopeStack[1], "controller") && !StructKeyExists(arguments, "controller")) {
			arguments.controller = variables.scopeStack[1].controller;
		}

		// Use scoped package if found.
		if (StructKeyExists(variables.scopeStack[1], "package")) {
			if (StructKeyExists(arguments, "package")) {
				arguments.package &= "." & variables.scopeStack[1].package;
			} else {
				arguments.package = variables.scopeStack[1].package;
			}
		}

		// Interpret "to" as "controller##action".
		if (StructKeyExists(arguments, "to")) {
			arguments.controller = ListFirst(arguments.to, "##");
			arguments.action = ListLast(arguments.to, "##");
			StructDelete(arguments, "to");
		}

		// Pull route name from arguments if it exists.
		local.name = "";
		if (StructKeyExists(arguments, "name")) {
			local.name = arguments.name;

			// Guess pattern and/or action.
			if (!StructKeyExists(arguments, "pattern")) {
				arguments.pattern = hyphenize(arguments.name);
			}
			if (!StructKeyExists(arguments, "action") && !Find("[action]", arguments.pattern)) {
				arguments.action = arguments.name;
			}
		}

		// Die if pattern is not defined.
		if (!StructKeyExists(arguments, "pattern")) {
			Throw(type = "Wheels.MapperArgumentMissing", message = "Either 'pattern' or 'name' must be defined.");
		}

		// Accept either "method" or "methods".
		if (StructKeyExists(arguments, "method")) {
			arguments.methods = arguments.method;
			StructDelete(arguments, "method");
		}

		// Remove 'methods' argument if settings disable it.
		if (!variables.methods && StructKeyExists(arguments, "methods")) {
			StructDelete(arguments, "methods");
		}

		// See if we have any globing in the pattern and if so add a constraint for each glob.
		if (ReFindNoCase("\*([^\/]+)", arguments.pattern)) {
			local.globs = ReMatch("\*([^\/]+)", arguments.pattern);
			for (local.glob in local.globs) {
				local.var = ReplaceList(local.glob, "*,[,]", "");
				arguments.pattern = Replace(arguments.pattern, local.glob, "[#local.var#]");
				arguments.constraints[local.var] = ".*";
			}
		}

		// Use constraints from stack.
		if (StructKeyExists(variables.scopeStack[1], "constraints")) {
			StructAppend(arguments.constraints, variables.scopeStack[1].constraints, false);
		}

		// Add shallow path to pattern.
		// Or, add scoped path to pattern.
		if ($shallow()) {
			arguments.pattern = $shallowPathForCall() & "/" & arguments.pattern;
		} else if (StructKeyExists(variables.scopeStack[1], "path")) {
			arguments.pattern = variables.scopeStack[1].path & "/" & arguments.pattern;
		}

		// If both package and controller are set, combine them.
		if (StructKeyExists(arguments, "package") && StructKeyExists(arguments, "controller")) {
			arguments.controller = arguments.package & "." & arguments.controller;
			StructDelete(arguments, "package");
		}

		// Build named routes in correct order according to rails conventions.
		switch (variables.scopeStack[1].$call) {
			case "resource":
			case "resources":
			case "collection":
				local.nameStruct = [local.name, $shallow() ? $shallowNameForCall() : $scopeName(), $collection()];
				break;
			case "member":
			case "new":
				local.nameStruct = [local.name, $shallow() ? $shallowNameForCall() : $scopeName(), $member()];
				break;
			default:
				local.nameStruct = [$scopeName(), $collection(), local.name];
		}

		// Transform array into named route.
		local.name = ArrayToList(local.nameStruct);
		local.name = ReReplace(local.name, "^,+|,+$", "", "all");
		local.name = ReReplace(local.name, ",+(\w)", "\U\1", "all");
		local.name = ReReplace(local.name, ",", "", "all");

		// If we have a name, add it to arguments.
		if (Len(local.name)) {
			arguments.name = local.name;
		}

		// Handle optional pattern segments.
		if (Find("(", arguments.pattern)) {
			// Confirm nesting of optional segments.
			if (ReFind("\).*\(", arguments.pattern)) {
				Throw(type = "Wheels.InvalidRoute", message = "Optional pattern segments must be nested.");
			}

			// Strip closing parens from pattern.
			local.pattern = Replace(arguments.pattern, ")", "", "all");

			// Loop over all possible patterns.
			while (Len(local.pattern)) {
				// Add current route to Wheels.
				$addRoute(argumentCollection = arguments, pattern = Replace(local.pattern, "(", "", "all"));

				// Remove last optional segment.
				local.pattern = ReReplace(local.pattern, "(^|\()[^(]+$", "");
			}
		} else {
			// Add route to Wheels as is.
			$addRoute(argumentCollection = arguments);
		}

		return this;
	}
}
