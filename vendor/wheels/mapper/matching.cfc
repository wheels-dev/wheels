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
		// BoxLang compatibility: Use different regex pattern to match globs
		local.globRegex = StructKeyExists(server, "boxlang") ? "\*\[([^\]]+)\]" : "\*([^\/]+)";
		if (ReFindNoCase(local.globRegex, arguments.pattern)) {
			local.globs = ReMatch(local.globRegex, arguments.pattern);
			for (local.glob in local.globs) {
				// For BoxLang: extract variable name from *[varname] pattern
				if (StructKeyExists(server, "boxlang")) {
					local.var = ReReplace(local.glob, "\*\[([^\]]+)\]", "\1");
				} else {
					local.var = ReplaceList(local.glob, "*,[,]", "");
				}
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

	// ---------------------------------------------------------------------------
	// Typed Constraint Helpers
	// ---------------------------------------------------------------------------
	// These methods apply regex constraints to the most recently registered route's
	// variables, similar to Laravel's whereNumber(), whereAlpha(), etc.
	// They operate on the last route added to application.wheels.routes.

	/**
	 * Constrain a route variable to only match numeric values (digits). Similar to Laravel's `whereNumber()` or ASP.NET's `:int` constraint.
	 *
	 * [section: Configuration]
	 * [category: Routing]
	 *
	 * @variableName The route variable name to constrain (e.g., `"id"`). Can also be a comma-delimited list to constrain multiple variables.
	 */
	public struct function whereNumber(required string variableName) {
		return $applyConstraintToLastRoute(arguments.variableName, "\d+");
	}

	/**
	 * Constrain a route variable to only match alphabetic characters (a-zA-Z). Similar to Laravel's `whereAlpha()` or ASP.NET's `:alpha` constraint.
	 *
	 * [section: Configuration]
	 * [category: Routing]
	 *
	 * @variableName The route variable name to constrain. Can also be a comma-delimited list.
	 */
	public struct function whereAlpha(required string variableName) {
		return $applyConstraintToLastRoute(arguments.variableName, "[a-zA-Z]+");
	}

	/**
	 * Constrain a route variable to only match alphanumeric characters (a-zA-Z0-9). Similar to Laravel's `whereAlphaNumeric()`.
	 *
	 * [section: Configuration]
	 * [category: Routing]
	 *
	 * @variableName The route variable name to constrain. Can also be a comma-delimited list.
	 */
	public struct function whereAlphaNumeric(required string variableName) {
		return $applyConstraintToLastRoute(arguments.variableName, "[a-zA-Z0-9]+");
	}

	/**
	 * Constrain a route variable to only match UUID values. Similar to ASP.NET's `:guid` constraint.
	 *
	 * [section: Configuration]
	 * [category: Routing]
	 *
	 * @variableName The route variable name to constrain. Can also be a comma-delimited list.
	 */
	public struct function whereUuid(required string variableName) {
		return $applyConstraintToLastRoute(arguments.variableName, "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}");
	}

	/**
	 * Constrain a route variable to only match URL-friendly slug values (lowercase alphanumeric and hyphens).
	 *
	 * [section: Configuration]
	 * [category: Routing]
	 *
	 * @variableName The route variable name to constrain. Can also be a comma-delimited list.
	 */
	public struct function whereSlug(required string variableName) {
		return $applyConstraintToLastRoute(arguments.variableName, "[a-z0-9]+(?:-[a-z0-9]+)*");
	}

	/**
	 * Constrain a route variable to only match one of a set of allowed values. Similar to an enum constraint.
	 *
	 * [section: Configuration]
	 * [category: Routing]
	 *
	 * @variableName The route variable name to constrain.
	 * @values A comma-delimited list of allowed values (e.g., `"active,inactive,pending"`).
	 */
	public struct function whereIn(required string variableName, required string values) {
		local.pattern = Replace(arguments.values, ",", "|", "all");
		local.pattern = Replace(local.pattern, " ", "", "all");
		return $applyConstraintToLastRoute(arguments.variableName, "(?:#local.pattern#)");
	}

	/**
	 * Constrain a route variable with a custom regex pattern.
	 *
	 * [section: Configuration]
	 * [category: Routing]
	 *
	 * @variableName The route variable name to constrain.
	 * @pattern The regex pattern the variable must match.
	 */
	public struct function whereMatch(required string variableName, required string pattern) {
		return $applyConstraintToLastRoute(arguments.variableName, arguments.pattern);
	}

	/**
	 * Internal function.
	 * Applies a regex constraint to the specified variable(s) on the most recently added route(s).
	 * Supports comma-delimited variable names to constrain multiple variables at once.
	 */
	public struct function $applyConstraintToLastRoute(required string variableName, required string pattern) {
		// Use this.getRoutes() to access routes via the Mapper's own method,
		// which returns variables.routes from the Mapper's scope. This avoids
		// both application-scope access issues on Adobe CF and potential mixin
		// scope issues where `variables` may not reference the Mapper's state.
		local.routes = this.getRoutes();
		local.routeCount = ArrayLen(local.routes);
		if (local.routeCount == 0) {
			Throw(
				type = "Wheels.NoRouteToConstrain",
				message = "Cannot apply constraint: no routes have been defined yet."
			);
		}

		// Apply constraint to the last route (and its optional-segment variants).
		// When optional segments are used, $match adds multiple routes. We apply the
		// constraint to all routes that share the same name as the last one.
		local.lastRoute = local.routes[local.routeCount];
		local.lastRouteName = StructKeyExists(local.lastRoute, "name") ? local.lastRoute.name : "";

		local.variables = ListToArray(arguments.variableName);
		for (local.varName in local.variables) {
			local.varName = Trim(local.varName);

			// Walk backward through routes to find all variants of the same named route.
			for (local.i = local.routeCount; local.i >= 1; local.i--) {
				local.route = local.routes[local.i];
				local.routeName = StructKeyExists(local.route, "name") ? local.route.name : "";

				// Stop if we've gone past the related routes.
				if (Len(local.lastRouteName) && local.routeName != local.lastRouteName && local.i < local.routeCount) {
					break;
				}

				// Only update if this variable exists in the route's pattern.
				if (Find("[#local.varName#]", local.route.pattern)) {
					if (!StructKeyExists(local.route, "constraints")) {
						local.route.constraints = {};
					}
					local.route.constraints[local.varName] = arguments.pattern;

					// Recompile the regex with the new constraint.
					local.route.regex = $patternToRegex(local.route.pattern, local.route.constraints);

					// Write modified route back to the local array reference.
					local.routes[local.i] = local.route;
				}

				// If no name, only update the very last route.
				if (!Len(local.lastRouteName)) {
					break;
				}
			}
		}

		// Sync routes back to application scope. On Lucee/BoxLang, routes
		// are pass-by-reference so this is redundant but harmless. On Adobe CF,
		// this ensures the application-scoped copy reflects the modifications.
		local.appKey = "wheels";
		if (StructKeyExists(application, "$wheels")) {
			local.appKey = "$wheels";
		}
		application[local.appKey].routes = local.routes;

		return this;
	}

	// ---------------------------------------------------------------------------
	// Health Check Route
	// ---------------------------------------------------------------------------

	/**
	 * Register a health check route at `/health` (or a custom path). Returns a JSON response with status and timestamp by default, or delegates to a custom controller action.
	 *
	 * This is useful for container orchestration (Kubernetes liveness/readiness probes), load balancer health checks, and monitoring tools.
	 *
	 * [section: Configuration]
	 * [category: Routing]
	 *
	 * @to Set `controller##action` combination for a custom health check handler. If not provided, a default handler returns `{"status":"ok","timestamp":"..."}`.
	 * @path Override the URL path. Defaults to `"health"`.
	 * @name Override the route name. Defaults to `"health"`.
	 */
	public struct function health(
		string to = "wheels##health",
		string path = "health",
		string name = "health"
	) {
		return get(name = arguments.name, pattern = arguments.path, to = arguments.to);
	}
}
