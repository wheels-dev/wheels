component output="false" extends="wheels.Global"{


	/**
	 * Returns itself (the Dispatch object).
	 *
	 * Middleware lifecycle contract (see #2954):
	 *   - Global middleware is resolved once here and reused for every request.
	 *   - Route-scoped string middleware is resolved on first encounter and
	 *     cached in `application[$appKey()].$middlewareInstanceCache` keyed by
	 *     component path so subsequent requests reuse the same instance. The
	 *     cache lives in application scope so a hard reload (which calls
	 *     `applicationStop()`) clears it alongside `application.wheels.*`.
	 *   - The preflight-capability boolean is computed once here and stored
	 *     on `variables.$preflightCapable` instead of being re-scanned per
	 *     OPTIONS request.
	 *
	 * Implication: middleware components must be safe to share across
	 * concurrent requests (mutate only via thread-safe state, e.g. CFML
	 * locks). All built-in middleware already follow this contract.
	 */
	public any function $init() {
		// Initialize the middleware pipeline from application settings.
		variables.$middlewarePipeline = $buildMiddlewarePipeline();
		variables.$preflightCapable = $computePreflightCapable(variables.$middlewarePipeline.getMiddleware());
		return this;
	}

	/**
	 * Build the middleware pipeline from application.wheels.middleware (user-configured)
	 * and application.wheels.pluginMiddleware (registered by plugins via onPluginLoad).
	 * Plugin middleware runs after user-configured global middleware.
	 */
	private any function $buildMiddlewarePipeline() {
		local.appKey = $appKey();
		local.middlewareInstances = [];

		// 1. Load user-configured global middleware.
		local.configured = StructKeyExists(application[local.appKey], "middleware")
			? application[local.appKey].middleware
			: [];

		for (local.item in local.configured) {
			ArrayAppend(local.middlewareInstances, $resolveMiddlewareInstance(local.item));
		}

		// 2. Append plugin-registered middleware, sorted by priority and before/after constraints.
		local.pluginMiddleware = $getPluginMiddlewareConfig();
		if (ArrayLen(local.pluginMiddleware)) {
			local.resolver = new wheels.middleware.MiddlewareOrderResolver();
			local.sorted = local.resolver.resolve(local.pluginMiddleware);
			for (local.entry in local.sorted) {
				ArrayAppend(local.middlewareInstances, $resolveMiddlewareInstance(local.entry.middleware));
			}
		}

		return new wheels.middleware.Pipeline(middleware = local.middlewareInstances);
	}

	/**
	 * Retrieve plugin-registered middleware from the application scope.
	 * Returns the pluginMiddleware array or an empty array if not present.
	 */
	private array function $getPluginMiddlewareConfig() {
		local.appKey = $appKey();
		if (StructKeyExists(application[local.appKey], "pluginMiddleware")) {
			return application[local.appKey].pluginMiddleware;
		}
		return [];
	}

	/**
	 * Resolve a middleware item: instantiate from component path string, or return as-is if already an object.
	 *
	 * String paths resolve to cached singletons keyed by the path so route-scoped
	 * middleware survives across requests (#2954). The cache lives under
	 * `application[$appKey()].$middlewareInstanceCache` and is cleared whenever
	 * `applicationStop()` runs (the password-gated reload path).
	 *
	 * Concurrency: cache population uses double-checked locking via a named
	 * `cflock` (matching the pattern in `wheels.middleware.RateLimiter`) so two
	 * threads racing on the first request for the same component path cannot
	 * each instantiate their own copy and silently drop the loser's state
	 * mutations. The fast path is a lock-free struct read once the slot is
	 * populated; the slow path takes an exclusive lock and re-checks before
	 * creating the instance.
	 */
	public any function $resolveMiddlewareInstance(required any middleware) {
		if (!IsSimpleValue(arguments.middleware)) {
			return arguments.middleware;
		}
		local.appKey = $appKey();
		// Fast path: once the slot is populated, the struct read is safe without a lock.
		if (
			StructKeyExists(application[local.appKey], "$middlewareInstanceCache")
			&& StructKeyExists(application[local.appKey].$middlewareInstanceCache, arguments.middleware)
		) {
			return application[local.appKey].$middlewareInstanceCache[arguments.middleware];
		}
		// Slow path: exclusive lock guards the check-then-create against concurrent first-touch races.
		cflock(name = "wheels.middlewareCache.#local.appKey#", type = "exclusive", timeout = 10) {
			if (!StructKeyExists(application[local.appKey], "$middlewareInstanceCache")) {
				application[local.appKey].$middlewareInstanceCache = {};
			}
			if (!StructKeyExists(application[local.appKey].$middlewareInstanceCache, arguments.middleware)) {
				application[local.appKey].$middlewareInstanceCache[arguments.middleware] = CreateObject("component", arguments.middleware).init();
			}
		}
		return application[local.appKey].$middlewareInstanceCache[arguments.middleware];
	}

	/**
	 * Create a struct to hold the params, merge form and url scopes into it, add JSON body etc.
	 */
	public struct function $createParams(
		required string path,
		required struct route,
		required struct formScope,
		required struct urlScope
	) {
		local.rv = {};
		local.rv = $mergeUrlAndFormScopes(params = local.rv, urlScope = arguments.urlScope, formScope = arguments.formScope);
		local.rv = $parseJsonBody(params = local.rv);
		local.rv = $mergeRoutePattern(params = local.rv, route = arguments.route, path = arguments.path);
		local.rv = $deobfuscateParams(params = local.rv);
		local.rv = $resolveRouteModelBinding(params = local.rv, route = arguments.route);
		local.rv = $translateBlankCheckBoxSubmissions(params = local.rv);
		local.rv = $translateDatePartSubmissions(params = local.rv);
		local.rv = $createNestedParamStruct(params = local.rv);

		// Do the routing / controller params after all other params so that we don't have more logic around params in arrays.
		local.rv = $ensureControllerAndAction(params = local.rv, route = arguments.route);
		local.rv = $addRouteFormat(params = local.rv, route = arguments.route);
		local.rv = $addRouteName(params = local.rv, route = arguments.route);

		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public struct function $createNestedParamStruct(required struct params) {
		local.rv = arguments.params;
		for (local.key in local.rv) {
			if (Find("[", local.key) && Right(local.key, 1) == "]") {
				// Object form field.
				local.name = SpanExcluding(local.key, "[");

				// Use engine adapter for cross-engine bracket-parsing differences
				local.nested = application.wheels.engineAdapter.parseFormKey(local.key, local.name);
				if (!StructKeyExists(local.rv, local.name)) {
					local.rv[local.name] = {};
				}

				// We need a reference to the struct so we can nest other structs if needed.
				// Looping over the array allows for infinite nesting.
				local.struct = local.rv[local.name];
				local.iEnd = ArrayLen(local.nested);
				for (local.i = 1; local.i <= local.iEnd; local.i++) {
					if (IsStruct(local.struct)) {
						local.item = local.nested[local.i];
						if (!StructKeyExists(local.struct, local.item)) {
							local.struct[local.item] = {};
						}
						if (local.i != local.iEnd) {
							// Pass the new reference (structs pass a reference instead of a copy) to the next iteration.
							local.struct = local.struct[local.item];
						} else {
							local.struct[local.item] = local.rv[local.key];
						}
					}
				}

				// Delete the original key so it doesn't show up in the params.
				StructDelete(local.rv, local.key);
			}
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public struct function $findMatchingRoute(
		required string path,
		string requestMethod = $getRequestMethod(),
		array routes = application.wheels.routes,
		component mapper = application.wheels.mapper
	) {
		// If this is a HEAD request, look for the corresponding GET route.
		if (arguments.requestMethod == 'HEAD') {
			arguments.requestMethod = 'GET';
		}

		local.methodKey = UCase(arguments.requestMethod);

		// --- Fast path: Static route O(1) lookup ---
		// Static routes (no variables in pattern) are indexed in a hash map at registration time.
		// This avoids regex matching entirely for common static paths like /login, /about, etc.
		if (StructKeyExists(application.wheels, "staticRoutes")) {
			local.staticKey = local.methodKey & ":/" & arguments.path;
			if (StructKeyExists(application.wheels.staticRoutes, local.staticKey)) {
				local.rv = $copyRouteForRequest(application.wheels.staticRoutes[local.staticKey]);
			}
			// Also try the root path.
			if (!StructKeyExists(local, "rv") && !Len(arguments.path)) {
				local.staticKey = local.methodKey & ":/";
				if (StructKeyExists(application.wheels.staticRoutes, local.staticKey)) {
					local.rv = $copyRouteForRequest(application.wheels.staticRoutes[local.staticKey]);
				}
			}
		}

		// --- Fallback: Full linear scan ---
		// Scan all routes in registration order, filtering by HTTP method.
		if (!StructKeyExists(local, "rv")) {
			for (local.route in arguments.routes) {
				// If method doesn't match, skip this route.
				if (StructKeyExists(local.route, "methods") && !ListFindNoCase(local.route.methods, arguments.requestMethod)) {
					continue;
				}

				// Make sure route has been converted to regular expression.
				if (!StructKeyExists(local.route, "regex")) {
					local.route.regex = arguments.mapper.$patternToRegex(local.route.pattern);
				}

				// If route matches regular expression, set it for return.
				// Run the regex once with sub-expressions and stash the result on the
				// per-request copy so $mergeRoutePattern can reuse it instead of
				// re-executing the same regex against the same path.
				local.match = ReFindNoCase(local.route.regex, arguments.path, 1, true);
				if (local.match.pos[1] > 0 || (!Len(arguments.path) && local.route.pattern == "/")) {
					local.rv = $copyRouteForRequest(local.route);
					local.rv.regexMatch = local.match;
					break;
				}
			}
		}

		// If returned route contains a redirect, execute that asap.
		if (StructKeyExists(local, "rv") && StructKeyExists(local.rv, "redirect")) {
			$location(url = local.rv.redirect, addToken = false);
		}

		// Throw error if no route was found.
		if (!StructKeyExists(local, "rv")) {
			local.alternativeMatchingMethodsForURL = "";

			// Try and provide some more information for why the route hasn't matched:
			// For example, the developer is accidentally GETing to a route which only allows POST.
			for (local.route in arguments.routes) {
				// If route matches regular expression, append to alternatives to display.
				// (regex was already compiled during the main matching loop above)
				if (ReFindNoCase(local.route.regex, arguments.path) || (!Len(arguments.path) && local.route.pattern == "/")) {
					local.alternativeMatchingMethodsForURL = ListAppend(local.alternativeMatchingMethodsForURL, local.route.methods);
				}
			}

			// If we have any routes which match the regex, but not the method, add this information to the error message.
			if (Len(local.alternativeMatchingMethodsForURL)) {
				$throwErrorOrShow404Page(
					type = "Wheels.RouteNotFound",
					message = "Incorrect HTTP Verb for route",
					extendedInfo = "The `#arguments.path#` path does not allow `#EncodeForHTML(arguments.requestMethod)#` requests, only `#UCase(local.alternativeMatchingMethodsForURL)#` requests. Ensure you are using the correct HTTP Verb and that your `config/routes.cfm` file is configured correctly."
				);
			} else {
				$throwErrorOrShow404Page(
					type = "Wheels.RouteNotFound",
					message = "Could not find a route that matched this request.",
					extendedInfo = "Make sure there is a route configured in your `config/routes.cfm` file that matches the `#EncodeForHTML(arguments.path)#` request."
				);
			}
		}

		return local.rv;
	}

	/**
	 * Returns a per-request copy of a matched route struct. Top-level keys are shallow-copied
	 * and any non-simple members (constraints, etc.) are duplicated so request
	 * code (middleware reading request.wheels.currentRoute, for example) can never mutate
	 * the shared route table through the copy. Used by both the static fast path and the
	 * regex fallback in $findMatchingRoute so the two paths share identical copy semantics.
	 *
	 * The `middleware` key is intentionally exempted from the Duplicate pass — instances
	 * registered there are singletons under the dispatch lifecycle contract (see #2954),
	 * and Adobe CF's Duplicate() of an array containing CFCs clones the instances, which
	 * would silently reset any state the middleware holds across requests. The array itself
	 * is shallow-copied so callers can append/replace entries without mutating the route
	 * table; the instance references inside the new array are preserved.
	 */
	public struct function $copyRouteForRequest(required struct route) {
		local.rv = StructCopy(arguments.route);
		for (local.key in local.rv) {
			if (local.key == "middleware") {
				if (IsArray(local.rv[local.key])) {
					local.copy = [];
					for (local.mw in local.rv[local.key]) {
						ArrayAppend(local.copy, local.mw);
					}
					local.rv[local.key] = local.copy;
				}
				continue;
			}
			if (!IsSimpleValue(local.rv[local.key])) {
				local.rv[local.key] = Duplicate(local.rv[local.key]);
			}
		}
		return local.rv;
	}

	/**
	 * Return the path without the leading "/".
	 */
	public string function $getPathFromRequest(required string pathInfo, required string scriptName) {
		if (arguments.pathInfo == arguments.scriptName || arguments.pathInfo == "/" || !Len(arguments.pathInfo)) {
			return "";
		} else {
			return Right(arguments.pathInfo, Len(arguments.pathInfo) - 1);
		}
	}

	/**
	 * Parse incoming params, create controller object, call an action on it and return the response.
	 * Called from index.cfm in the root so what we return here is the final result of the request processing.
	 * This currently needs to be public as it's called from elsewhere
	 */
	public string function $request(
		string pathInfo = request.cgi.path_info,
		string scriptName = request.cgi.script_name,
		struct formScope = form,
		struct urlScope = url
	) {
		// If something has been set to the request.$wheelsAbortContent variable we just return it directly so it gets rendered.
		// This is used for maintenance mode content.
		if (StructKeyExists(request, "$wheelsAbortContent")) {
			return request.$wheelsAbortContent;
		}

		if ($get("showDebugInformation")) {
			$debugPoint("setup");
		}

		// CORS preflight short-circuit: when the global middleware pipeline contains
		// a `wheels.middleware.Cors` instance, run OPTIONS through the pipeline
		// before route matching so unmatched preflight verbs reach the CORS handler
		// instead of 404ing in $findMatchingRoute. The legacy
		// `set(allowCorsRequests=true)` path aborted OPTIONS in EventMethods.cfc
		// before dispatch; this preserves that contract for middleware users.
		// See issue #2703.
		local.preflightMethod = "";
		try {
			local.preflightMethod = $getRequestMethod();
		} catch (any e) {
			// Swallow intentionally: when request.cgi is not yet populated
			// (e.g. test contexts or unusual dispatch paths) we fail closed by
			// leaving preflightMethod empty so the short-circuit guard below is
			// skipped and normal routing proceeds.
		}
		if (UCase(local.preflightMethod) == "OPTIONS" && $hasPreflightCapableMiddleware()) {
			request.wheels.params = {};
			// Cors.handle() reads the verb from arguments.request.cgi.request_method
			// rather than arguments.request.method, so we don't carry the method
			// field on this context. Cors is the only middleware that gates on
			// this path; once it short-circuits, middleware registered after it
			// does not run. Middleware registered before Cors still executes.
			local.preflightContext = {
				params = {},
				route = {},
				pathInfo = arguments.pathInfo
			};
			local.preflightHandler = function(required struct request) {
				return "";
			};
			return variables.$middlewarePipeline.run(
				request = local.preflightContext,
				coreHandler = local.preflightHandler
			);
		}

		local.params = $paramParser(argumentCollection = arguments);

		// Set params in the request scope as well so we can display it in the debug info outside of the controller context.
		request.wheels.params = local.params;

		if ($get("showDebugInformation")) {
			$debugPoint("setup");
		}

		// Hi-jack any wheels controller requests for GUI
		if (ListFirst(local.params.controller, '.') EQ "wheels") {
			if (!application.wheels.enablePublicComponent) {
				// Return 404 so the surface is not fingerprintable. A bare
				// cfabort responds HTTP 200 with an empty body, which leaks
				// the existence of the internal GUI routes. See issue #2233.
				cfheader(statuscode=404);
				cfcontent(type="text/plain");
				writeOutput("Not Found");
				cfabort;
			} else {
				// BoxLang compatibility: Check for null action parameter
				if (IsNull(local.params.action) || !Len(local.params.action)) {
					throw(
						type="Wheels.ActionParameterMissing", 
						message="The action parameter is missing or null. Controller: #local.params.controller#");
				}

				$engineAdapter().invokeMethod(application.wheels.public, local.params.action);
				// The wheels controller methods handle their own output and abort
				// So we need to ensure we don't continue processing
				return "";
			}
		} else {
			// Build the request context for middleware.
			local.requestContext = {
				params = local.params,
				route = StructKeyExists(request.wheels, "currentRoute") ? request.wheels.currentRoute : {},
				pathInfo = arguments.pathInfo,
				method = $getRequestMethod()
			};

			// The core handler that middleware wraps around.
			local.coreHandler = function(required struct request) {
				local.ctrl = controller(name = arguments.request.params.controller, params = arguments.request.params);
				local.ctrl.processAction();

				if (local.ctrl.$performedRedirect()) {
					$location(argumentCollection = local.ctrl.getRedirect());
				}

				local.ctrl.$flashClear();
				return local.ctrl.response();
			};

			// Merge global + route-scoped middleware and run through the pipeline.
			local.routeMiddleware = $getRouteMiddleware(local.params);
			if (ArrayLen(local.routeMiddleware)) {
				local.allMiddleware = [];
				ArrayAppend(local.allMiddleware, variables.$middlewarePipeline.getMiddleware(), true);
				ArrayAppend(local.allMiddleware, local.routeMiddleware, true);
				local.pipeline = new wheels.middleware.Pipeline(middleware = local.allMiddleware);
				return local.pipeline.run(request = local.requestContext, coreHandler = local.coreHandler);
			}

			return variables.$middlewarePipeline.run(request = local.requestContext, coreHandler = local.coreHandler);
		}
	}

	/**
	 * Returns true if the global middleware pipeline contains a CORS middleware
	 * instance capable of handling an OPTIONS preflight short-circuit. Used to
	 * preserve the legacy `allowCorsRequests=true` short-circuit semantics in
	 * the new middleware pipeline. See issue #2703.
	 *
	 * The boolean is computed once at `$init` from the pipeline snapshot and
	 * stored on `variables.$preflightCapable`; this method is a single struct
	 * read on the dispatch hot path instead of an `IsInstanceOf` scan per
	 * OPTIONS request (#2954).
	 */
	public boolean function $hasPreflightCapableMiddleware() {
		return variables.$preflightCapable;
	}

	/**
	 * Internal: scan the given middleware array for a CORS instance. Called
	 * once at `$init` to compute the cached preflight-capability boolean.
	 */
	private boolean function $computePreflightCapable(required array middleware) {
		for (local.mw in arguments.middleware) {
			if (IsObject(local.mw) && IsInstanceOf(local.mw, "wheels.middleware.Cors")) {
				return true;
			}
		}
		return false;
	}

	/**
	 * Resolve route-scoped middleware from the matched route's `middleware` property.
	 * Returns an array of instantiated middleware components. String paths resolve
	 * to cached singletons via `$resolveMiddlewareInstance` so route-scoped
	 * stateful middleware (e.g. an in-memory RateLimiter) survives across requests
	 * (#2954).
	 */
	public array function $getRouteMiddleware(required struct params) {
		local.instances = [];
		// The matched route is stored on request.wheels.currentRoute during $findMatchingRoute.
		if (!StructKeyExists(request.wheels, "currentRoute") || !StructKeyExists(request.wheels.currentRoute, "middleware")) {
			return local.instances;
		}

		local.routeMiddleware = request.wheels.currentRoute.middleware;
		if (IsSimpleValue(local.routeMiddleware)) {
			local.routeMiddleware = ListToArray(local.routeMiddleware);
		}

		for (local.item in local.routeMiddleware) {
			ArrayAppend(local.instances, $resolveMiddlewareInstance(local.item));
		}

		return local.instances;
	}

	/**
	 * Find the route that matches the path, create params struct and return it.
	 */
	public struct function $paramParser(
		string pathInfo = request.cgi.path_info,
		string scriptName = request.cgi.script_name,
		struct formScope = form,
		struct urlScope = url
	) {
		local.path = $getPathFromRequest(pathInfo = arguments.pathInfo, scriptName = arguments.scriptName);
		local.route = $findMatchingRoute(path = local.path);

		// Store the matched route so middleware and other components can inspect it.
		request.wheels.currentRoute = local.route;

		return $createParams(
			path = local.path,
			route = local.route,
			formScope = arguments.formScope,
			urlScope = arguments.urlScope
		);
	}

	/**
	 * Merges the URL and form scope into a single structure, URL scope has precedence.
	 */
	public struct function $mergeUrlAndFormScopes(
		required struct params,
		required struct urlScope,
		required struct formScope
	) {
		StructAppend(arguments.params, arguments.formScope);
		StructAppend(arguments.params, arguments.urlScope);

		// Get rid of the unnecessary "fieldnames" key that ACF always adds to the form scope.
		StructDelete(arguments.params, "fieldnames");

		return arguments.params;
	}

	/**
	 * If content type is JSON, deserialize it into a struct and add to the params struct.
	 */
	public struct function $parseJsonBody(required struct params) {
		local.headers = request.wheels.httpRequestData.headers;
		local.content = request.wheels.httpRequestData.content;
		if (StructKeyExists(local.headers, "Content-Type")) {
			// Content-Type may also include charset so we need only check the first item in the list
			local.type = SpanExcluding(local.headers["Content-Type"], ";");

			// Only proceed if the content type is JSON.
			// Allow multiple JSON content types by checking the start and end of the string.
			// This way we allow both "application/json" and "application/vnd.api+json" (JSON API) for example.
			if (Left(local.type, 12) == "application/" && Right(local.type, 4) == "json") {
				// On ACF we need to convert from binary to a string before we can work with it.
				if (IsBinary(local.content)) {
					local.content = ToString(local.content);
				}

				// If what we have now is valid JSON, deserialize it to a struct and append to params.
				// Call with "false" so existing form and URL values take precedence.
				if (IsJSON(local.content)) {
					local.deserializedContent = DeserializeJSON(local.content);
					if (IsStruct(local.deserializedContent)) {
						StructAppend(arguments.params, local.deserializedContent, false);
					}
					// If the incoming root element is an array, add it to params in the _json key
					// This appears to follow Rails conventions
					if (IsArray(local.deserializedContent)) {
						arguments.params['_json'] = local.deserializedContent;
					}
				}
			}
		}
		return arguments.params;
	}

	/**
	 * Parses the route pattern, identifies the variable markers within the pattern and assigns the value from the url variables with the path.
	 */
	public struct function $mergeRoutePattern(required struct params, required struct route, required string path) {
		local.rv = arguments.params;
		// Reuse the match result stashed by $findMatchingRoute when present so the route
		// regex only executes once per request. Fall back to a fresh match for routes that
		// did not go through the regex fallback (static fast path or direct calls).
		if (StructKeyExists(arguments.route, "regexMatch")) {
			local.matches = arguments.route.regexMatch;
		} else {
			local.matches = ReFindNoCase(arguments.route.regex, arguments.path, 1, true);
		}

		// Bound the loop by the number of route variables. Constraint patterns are
		// normalized to non-capturing groups at draw time, but this guard ensures an
		// unexpected extra capturing group can never push extraction past the variable
		// list (wrong values or a ListGetAt out-of-bounds crash).
		local.variableCount = StructKeyExists(arguments.route, "foundVariables") ? ListLen(arguments.route.foundVariables) : 0;
		local.iEnd = Min(ArrayLen(local.matches.pos), local.variableCount + 1);
		for (local.i = 2; local.i <= local.iEnd; local.i++) {
			local.key = ListGetAt(arguments.route.foundVariables, local.i - 1);
			local.rv[local.key] = Mid(arguments.path, local.matches.pos[local.i], local.matches.len[local.i]);
		}
		return local.rv;
	}

	/**
	 * Loops through the params struct passed in and attempts to deobfuscate it.
	 * Ignores the controller and action params values.
	 */
	public struct function $deobfuscateParams(required struct params) {
		local.rv = arguments.params;
		if ($get("obfuscateUrls")) {
			for (local.key in local.rv) {
				if (local.key != "controller" && local.key != "action") {
					try {
						local.rv[local.key] = deobfuscateParam(local.rv[local.key]);
					} catch (any e) {
					}
				}
			}
		}
		return local.rv;
	}

	/**
	 * Resolves a model instance from params.key when route model binding is enabled.
	 * The resolved model is stored in params under the singularized controller name (e.g., params.user).
	 * Throws Wheels.RecordNotFound if the record doesn't exist. Convention-derived bindings skip
	 * silently (with a negative cache, cleared on reload) when the model class can't be resolved;
	 * explicit bindings (binding="BlogPost") rethrow resolution failures since they indicate a
	 * configuration error. Query errors from the finder always propagate.
	 */
	public struct function $resolveRouteModelBinding(required struct params, required struct route) {
		local.rv = arguments.params;

		// Determine if binding is enabled: route-level takes precedence, then global setting.
		local.binding = false;
		if (StructKeyExists(arguments.route, "binding")) {
			local.binding = arguments.route.binding;
		} else if ($get("routeModelBinding")) {
			local.binding = true;
		}

		// Skip if disabled or no key parameter exists.
		if (IsBoolean(local.binding) && !local.binding) {
			// Binding is off. Emit a dev-mode hint if this route looks like a binding
			// candidate (has a key and dispatches to a member action). See gap tracker
			// item #5: silent failure when developers write `params.post` without
			// setting `binding=true`.
			$maybeWarnRouteBinding(params = local.rv, route = arguments.route);
			return local.rv;
		}
		if (!StructKeyExists(local.rv, "key")) {
			return local.rv;
		}

		// Derive the model name.
		local.explicitBinding = IsSimpleValue(local.binding) && !IsBoolean(local.binding) && Len(local.binding);
		if (local.explicitBinding) {
			// Explicit model name override (e.g., binding="BlogPost").
			local.modelName = local.binding;
		} else {
			// Convention: singularize + capitalize controller name.
			// Check params first, then fall back to route struct (controller may not be in params yet).
			if (StructKeyExists(local.rv, "controller")) {
				local.controllerName = local.rv.controller;
			} else if (StructKeyExists(arguments.route, "controller")) {
				local.controllerName = arguments.route.controller;
			} else {
				return local.rv;
			}
			local.modelName = capitalize(singularize(local.controllerName));
		}

		// Negative cache: a conventional binding that previously failed to resolve is skipped
		// without re-acquiring the app-wide model lock and re-running the model bootstrap
		// (including its DB metadata query) on every request. Lives in the application.wheels
		// struct so it's cleared on reload.
		local.appKey = $appKey();
		if (
			!local.explicitBinding
			&& StructKeyExists(application[local.appKey], "unresolvableRouteBindings")
			&& StructKeyExists(application[local.appKey].unresolvableRouteBindings, local.modelName)
		) {
			return local.rv;
		}

		// Resolve the model class in its own try so only class/bootstrap resolution failures
		// are handled here.
		try {
			local.modelClass = model(local.modelName);
		} catch (any e) {
			// An explicit binding name (binding="BlogPost") that fails to resolve is a
			// configuration error — surface it instead of silently skipping.
			if (local.explicitBinding) {
				rethrow;
			}
			// Conventional binding against a non-model-backed controller: skip silently so
			// non-model routes keep working, but negative-cache the miss so the failed
			// bootstrap doesn't repeat on every request, and leave a dev-mode breadcrumb.
			if (!StructKeyExists(application[local.appKey], "unresolvableRouteBindings")) {
				application[local.appKey].unresolvableRouteBindings = {};
			}
			application[local.appKey].unresolvableRouteBindings[local.modelName] = true;
			if ($get("environment") != "production") {
				writeLog(
					file = "wheels",
					type = "warning",
					text = "Route model binding could not resolve model `#local.modelName#` (#e.type#: #e.message#). Binding is skipped for this model until reload."
				);
			}
			return local.rv;
		}

		// Run the finder outside the try so query errors (DB connection failures, missing
		// tables at query time, SQL errors) propagate instead of being masked as a missing
		// model class.
		local.instance = local.modelClass.findByKey(local.rv.key);

		// If no record was found, throw a 404.
		if (IsBoolean(local.instance) && !local.instance) {
			$throwErrorOrShow404Page(
				type = "Wheels.RecordNotFound",
				message = "#local.modelName# record not found.",
				extendedInfo = "A #local.modelName# record with key `#EncodeForHTML(local.rv.key)#` could not be found."
			);
		}

		// Store the resolved model in params under the singular name.
		local.paramKey = LCase(Left(local.modelName, 1)) & Mid(local.modelName, 2, Len(local.modelName) - 1);
		local.rv[local.paramKey] = local.instance;

		return local.rv;
	}

	/**
	 * Emits a one-time dev-mode log warning when a route looks like a route-model-binding
	 * candidate but binding is not enabled. The heuristic: params.key is present AND the
	 * resolved action is one of the member binding-eligible actions (show, edit, update,
	 * delete). Writes one line per unique controller+action pair per JVM process to avoid
	 * log spam. Gated behind environment != "production" and suppressRouteBindingWarnings=false.
	 * The warning points the developer at either the per-resource `binding=true` flag or the
	 * global `routeModelBinding` setting. Safe to call regardless of state — returns silently
	 * on any error so it never interferes with dispatch.
	 */
	public boolean function $maybeWarnRouteBinding(required struct params, required struct route) {
		try {
			// Resolve the settings namespace ($wheels or wheels depending on runtime).
			local.appKey = $appKey();
			local.settings = application[local.appKey];

			// Gate: production skips entirely.
			local.env = StructKeyExists(local.settings, "environment") ? local.settings.environment : "";
			if (local.env == "production") {
				return false;
			}

			// Gate: user opt-out.
			if (StructKeyExists(local.settings, "suppressRouteBindingWarnings") && local.settings.suppressRouteBindingWarnings) {
				return false;
			}

			// Only warn when a key is in the URL (binding wouldn't fire without one).
			if (!StructKeyExists(arguments.params, "key")) {
				return false;
			}

			// Only warn for member binding-eligible actions.
			local.action = StructKeyExists(arguments.params, "action") ? arguments.params.action : (StructKeyExists(arguments.route, "action") ? arguments.route.action : "");
			if (!ListFindNoCase("show,edit,update,delete", local.action)) {
				return false;
			}

			// Derive controller (for log detail + dedup key).
			local.controller = StructKeyExists(arguments.params, "controller") ? arguments.params.controller : (StructKeyExists(arguments.route, "controller") ? arguments.route.controller : "");
			if (!Len(local.controller)) {
				return false;
			}

			// Dedup: one warning per controller+action per application lifetime.
			// Resets on reload (application scope rebuild).
			if (!StructKeyExists(application, "$wheelsRouteBindingWarnings")) {
				application.$wheelsRouteBindingWarnings = {};
			}
			local.dedupKey = local.controller & "##" & local.action;
			if (StructKeyExists(application.$wheelsRouteBindingWarnings, local.dedupKey)) {
				return false;
			}
			application.$wheelsRouteBindingWarnings[local.dedupKey] = true;

			// Derive the singular name binding would use (matches $resolveRouteModelBinding logic).
			local.modelName = capitalize(singularize(local.controller));
			local.singular = LCase(Left(local.modelName, 1)) & Mid(local.modelName, 2, Len(local.modelName) - 1);
			local.routeName = StructKeyExists(arguments.route, "name") ? arguments.route.name : "";

			local.msg = "Wheels Route Binding Hint: #UCase(local.action)# on controller '#local.controller#'"
				& (Len(local.routeName) ? " (route '#local.routeName#')" : "")
				& " dispatched with params.key but route model binding is not enabled on this resource."
				& " If you intended params.#local.singular# to be auto-loaded from the #local.modelName# model, add binding=true to the resource:"
				& "  .resources(name=""#local.controller#"", binding=true)."
				& " Or enable globally in config/settings.cfm: set(routeModelBinding=true)."
				& " To silence this hint: set(suppressRouteBindingWarnings=true) in config/settings.cfm."
				& " (Hint fires in development only.)";

			writeLog(file="wheels", type="warning", text=local.msg);
			return true;
		} catch (any ignored) {
			// Warning emission is best-effort; never block dispatch.
			return false;
		}
	}

	/**
	 * Loops through the params struct and handle the cases where checkboxes are unchecked.
	 */
	public struct function $translateBlankCheckBoxSubmissions(required struct params) {
		local.rv = arguments.params;
		for (local.key in local.rv) {
			if (FindNoCase("($checkbox)", local.key)) {
				// If no other form parameter exists with this name it means that the checkbox was left blank.
				// Therefore we force the value to the unchecked value for the checkbox.
				// This gets around the problem that unchecked checkboxes don't post at all.
				local.formParamName = ReplaceNoCase(local.key, "($checkbox)", "");
				if (!StructKeyExists(local.rv, local.formParamName)) {
					local.rv[local.formParamName] = local.rv[local.key];
				}

				StructDelete(local.rv, local.key);
			}
		}
		return local.rv;
	}

	/**
	 * Combines date parts into a single value.
	 */
	public struct function $translateDatePartSubmissions(required struct params) {
		local.rv = arguments.params;
		local.dates = {};
		for (local.key in local.rv) {
			if (ReFindNoCase(".*\((\$year|\$month|\$day|\$hour|\$minute|\$second|\$ampm)\)$", local.key)) {
				local.temp = ListToArray(local.key, "(");
				local.firstKey = local.temp[1];
				local.secondKey = SpanExcluding(local.temp[2], ")");
				if (!StructKeyExists(local.dates, local.firstKey)) {
					local.dates[local.firstKey] = {};
				}
				local.dates[local.firstKey][ReplaceNoCase(local.secondKey, "$", "")] = local.rv[local.key];
			}
		}
		for (local.key in local.dates) {
			if (!StructKeyExists(local.dates[local.key], "year")) {
				local.dates[local.key].year = 1899;
			}
			if (!StructKeyExists(local.dates[local.key], "month")) {
				local.dates[local.key].month = 1;
			}
			if (!StructKeyExists(local.dates[local.key], "day")) {
				local.dates[local.key].day = 1;
			}
			if (!StructKeyExists(local.dates[local.key], "hour")) {
				local.dates[local.key].hour = 0;
			}
			if (!StructKeyExists(local.dates[local.key], "minute")) {
				local.dates[local.key].minute = 0;
			}
			if (!StructKeyExists(local.dates[local.key], "second")) {
				local.dates[local.key].second = 0;
			}
			if (StructKeyExists(local.dates[local.key], "ampm")) {
				if (local.dates[local.key].ampm == "am" && local.dates[local.key].hour == 12) {
					local.dates[local.key].hour = 0;
				} else if (local.dates[local.key].ampm == "pm" && local.dates[local.key].hour != 12) {
					local.dates[local.key].hour += 12;
				}
			}
			try {
				local.rv[local.key] = CreateDateTime(
					local.dates[local.key].year,
					local.dates[local.key].month,
					local.dates[local.key].day,
					local.dates[local.key].hour,
					local.dates[local.key].minute,
					local.dates[local.key].second
				);
			} catch (any e) {
				local.rv[local.key] = "";
			}
			StructDelete(local.rv, local.key & "($year)");
			StructDelete(local.rv, local.key & "($month)");
			StructDelete(local.rv, local.key & "($day)");
			StructDelete(local.rv, local.key & "($hour)");
			StructDelete(local.rv, local.key & "($minute)");
			StructDelete(local.rv, local.key & "($second)");
			StructDelete(local.rv, local.key & "($ampm)");
		}
		return local.rv;
	}

	/**
	 * Ensure that the controller and action params exist and are camelized.
	 */
	public struct function $ensureControllerAndAction(required struct params, required struct route) {
		local.rv = arguments.params;
		if (!StructKeyExists(local.rv, "controller")) {
			local.rv.controller = arguments.route.controller;
		}
		if (!StructKeyExists(local.rv, "action")) {
			local.rv.action = arguments.route.action;
		}

		// We now need to have dot notation allowed in the controller hence the \.
		local.rv.controller = ReReplace(local.rv.controller, "[^0-9A-Za-z-_\.]", "", "all");

		// Filter out illegal characters from the controller and action arguments.
		local.rv.action = ReReplace(local.rv.action, "[^0-9A-Za-z-_\.]", "", "all");

		// Convert controller to upperCamelCase via engine adapter
		local.rv.controller = application.wheels.engineAdapter.controllerNameToUpperCamelCase(local.rv.controller);

		// Action to normal camelCase.
		local.rv.action = ReReplace(local.rv.action, "-([a-z])", "\u\1", "all");

		return local.rv;
	}

	/**
	 * Adds in the format variable from the route if it exists.
	 */
	public struct function $addRouteFormat(required struct params, required struct route) {
		local.rv = arguments.params;
		if (StructKeyExists(arguments.route, "formatVariable") && StructKeyExists(arguments.route, "format")) {
			local.rv[arguments.route.formatVariable] = arguments.route.format;
		}
		return local.rv;
	}

	/**
	 * Adds in the name variable from the route if it exists.
	 */
	public struct function $addRouteName(required struct params, required struct route) {
		local.rv = arguments.params;
		if (StructKeyExists(arguments.route, "name") && Len(arguments.route.name) && !StructKeyExists(local.rv, "route")) {
			local.rv.route = arguments.route.name;
		}
		return local.rv;
	}

	/**
	 * Determine HTTP verb used in request.
	 */
	public string function $getRequestMethod() {
		// If request is a post, check for alternate verb.
		if (request.cgi.request_method == "post" && StructKeyExists(form, "_method")) {
			return form["_method"];
		}

		return request.cgi.request_method;
	}

	function onDIComplete(){
		$engineAdapter().prepareDIComplete(variables, this);
		new wheels.Plugins().$initializeMixins(variables);
	}
}
