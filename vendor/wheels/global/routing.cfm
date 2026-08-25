<cfscript>
/**
 * wheels.Global include: routing
 * Routes, URLFor, mapper, and channel publish.
 *
 * Included from `vendor/wheels/Global.cfc` at component-body scope so
 * these functions compile into the Global component. Children inherit
 * them; there is no per-instance mixin copy. Keep every helper that
 * must mix onto models/controllers `public` and `$`-prefixed
 * (cross-engine invariant 7).
 */


	// ======================================================================
	// CHANNEL / PUB-SUB FUNCTIONS
	// ======================================================================

	/**
	 * Publish an event to a channel.
	 * Delegates to the in-memory Channel engine or the DatabaseAdapter
	 * depending on the adapter argument (or the global channelAdapter setting).
	 *
	 * Can be called from controllers, models, jobs, or anywhere with access
	 * to global helpers.
	 *
	 * [section: Global Helpers]
	 * [category: Channel Functions]
	 *
	 * @channel The channel name to publish to (e.g. "user.42").
	 * @event The event type (e.g. "notification", "update").
	 * @data The event data as a string (typically JSON).
	 * @adapter Adapter to use: "memory" (default) or "database".
	 */
	public struct function publish(
		required string channel,
		required string event,
		required string data,
		string adapter = ""
	) {
		local.engine = $getChannelEngine(arguments.adapter);
		return local.engine.publish(channel = arguments.channel, event = arguments.event, data = arguments.data);
	}


	/**
	 * Internal: Get or create the channel engine singleton for the given adapter type.
	 * Uses double-checked locking to ensure thread-safe lazy initialization.
	 *
	 * @adapter "memory" or "database". Defaults to application.wheels.channelAdapter or "memory".
	 */
	public any function $getChannelEngine(string adapter = "") {
		// Resolve adapter type
		if (!Len(arguments.adapter)) {
			if (StructKeyExists(application, "wheels") && StructKeyExists(application.wheels, "channelAdapter")) {
				local.adapterType = application.wheels.channelAdapter;
			} else {
				local.adapterType = "memory";
			}
		} else {
			local.adapterType = arguments.adapter;
		}

		if (local.adapterType == "database") {
			if (!StructKeyExists(application, "wheels") || !StructKeyExists(application.wheels, "channelDatabaseEngine")) {
				lock name="wheelsChannelDatabaseEngine" timeout="10" {
					if (!StructKeyExists(application, "wheels") || !StructKeyExists(application.wheels, "channelDatabaseEngine")) {
						application.wheels.channelDatabaseEngine = CreateObject("component", "wheels.channel.DatabaseAdapter").init();
					}
				}
			}
			return application.wheels.channelDatabaseEngine;
		}

		if (local.adapterType == "memory") {
			if (!StructKeyExists(application, "wheels") || !StructKeyExists(application.wheels, "channelEngine")) {
				lock name="wheelsChannelEngine" timeout="10" {
					if (!StructKeyExists(application, "wheels") || !StructKeyExists(application.wheels, "channelEngine")) {
						application.wheels.channelEngine = CreateObject("component", "wheels.Channel").init();
					}
				}
			}
			return application.wheels.channelEngine;
		}

		throw(
			type = "Wheels.Channel.UnknownAdapter",
			message = "Unknown channel adapter [#local.adapterType#]. Use memory or database."
		);
	}


	// ======================================================================
	// ROUTING FUNCTIONS
	// ======================================================================

	/**
	 * Internal function.
	 */
	public string function $routeVariables() {
		return $findRoute(argumentCollection = arguments).foundvariables;
	}


	/**
	 * Internal function.
	 */
	public struct function $findRoute() {
		// Throw error if no route was found.
		if (!StructKeyExists(application.wheels.namedRoutePositions, arguments.route)) {
			$throwErrorOrShow404Page(
				type = "Wheels.RouteNotFound",
				message = "Could not find the `#arguments.route#` route.",
				extendedInfo = "Make sure there is a route configured in your `config/routes.cfm` file named `#arguments.route#`."
			);
		}
		local.routePos = application.wheels.namedRoutePositions[arguments.route];
		if (Find(",", local.routePos)) {
			// there are several routes with this name so we need to figure out which one to use by checking the passed in arguments
			local.foundRoute = false;
			local.methodSpecified = StructKeyExists(arguments, "method") && Len(arguments.method);
			local.iEnd = ListLen(local.routePos);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.rv = application.wheels.routes[ListGetAt(local.routePos, local.i)];
				// Method is optional: URLFor / redirectTo do not pass it. When it
				// is present it must match; when it is absent, variables decide.
				local.foundRoute = !local.methodSpecified
				|| (
					StructKeyExists(local.rv, "methods")
					&& ListFindNoCase(local.rv.methods, arguments.method)
				);
				local.jEnd = ListLen(local.rv.foundvariables);
				for (local.j = 1; local.j <= local.jEnd; local.j++) {
					local.variable = ListGetAt(local.rv.foundvariables, local.j);
					if (!StructKeyExists(arguments, local.variable) || !Len(arguments[local.variable])) {
						local.foundRoute = false;
					}
				}
				if (local.foundRoute) {
					break;
				}
			}
			if (!local.foundRoute) {
				$throwErrorOrShow404Page(
					type = "Wheels.RouteNotFound",
					message = "Could not find a `#arguments.route#` route that matched the supplied arguments.",
					extendedInfo = "Same-named routes are distinguished by HTTP method and required path variables. Passing a method or variables that match none of the candidates is an error, not a fallback to the last declared route."
				);
			}
		} else {
			local.rv = application.wheels.routes[local.routePos];
		}
		return local.rv;
	}


	/**
	 * Internal function.
	 */
	public any function $constructParams(
		required string params,
		boolean encode = true,
		boolean $encodeForHtmlAttribute = false,
		string $URLRewriting = application.wheels.URLRewriting
	) {
		// When rewriting is off we will already have "?controller=" etc in the url so we have to continue with an ampersand.
		if (arguments.$URLRewriting == "Off") {
			local.delim = "&";
		} else {
			local.delim = "?";
		}

		local.rv = "";
		local.paramsArray = ListToArray(arguments.params, "&");
		local.iEnd = ArrayLen(local.paramsArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.params = ListToArray(local.paramsArray[local.i], "=");
			local.name = local.params[1];
			if (arguments.encode && $get("encodeURLs")) {
				local.name = EncodeForURL($canonicalize(local.name));
				if (arguments.$encodeForHtmlAttribute) {
					local.name = EncodeForHTMLAttribute(local.name);
				}
			}
			local.rv &= local.delim & local.name & "=";
			local.delim = "&";
			if (ArrayLen(local.params) == 2) {
				local.value = local.params[2];
				if (arguments.encode && $get("encodeURLs")) {
					local.value = EncodeForURL($canonicalize(local.value));
					if (arguments.$encodeForHtmlAttribute) {
						local.value = EncodeForHTMLAttribute(local.value);
					}
				}

				// Obfuscate the param if set globally and we're not processing cfid or cftoken (can't touch those).
				// Wrap in double quotes because in Lucee we have to pass it in as a string otherwise leading zeros are stripped.
				if (application.wheels.obfuscateUrls && !ListFindNoCase("cfid,cftoken", local.name)) {
					local.value = obfuscateParam("#local.value#");
				}

				local.rv &= local.value;
			}
		}
		return local.rv;
	}


	/**
	 * Internal function.
	 */
	public string function $prependUrl(required string path, string host = "", string protocol = "", numeric port = 0) {
		local.rv = arguments.path;
		if (arguments.port != 0) {
			// use the port that was passed in by the developer
			local.rv = ":" & arguments.port & local.rv;
		} else if (request.cgi.server_port != 80 && request.cgi.server_port != 443) {
			// if the port currently in use is not 80 or 443 we set it explicitly in the URL
			local.rv = ":" & request.cgi.server_port & local.rv;
		}
		if (Len(arguments.host)) {
			local.rv = arguments.host & local.rv;
		} else {
			local.rv = request.cgi.server_name & local.rv;
		}
		if (Len(arguments.protocol)) {
			local.rv = arguments.protocol & "://" & local.rv;
		} else if (request.cgi.http_x_forwarded_proto == "https" || request.cgi.server_port_secure == "true") {
			local.rv = "https://" & local.rv;
		} else {
			local.rv = "http://" & local.rv;
		}
		return local.rv;
	}


	/**
	 * Internal function.
	 */
	public void function $loadRoutes() {
		$simpleLock(name = "$mapperLoadRoutes", type = "exclusive", timeout = 5, execute = "$lockedLoadRoutes");
	}


	/**
	 * Internal function.
	 */
	public void function $lockedLoadRoutes() {
		local.appKey = $appKey();
		// clear out the route info (including the static-route index so a reload
		// can't serve stale first-write-wins entries from the previous route set)
		ArrayClear(application[local.appKey].routes);
		StructClear(application[local.appKey].namedRoutePositions);
		if (StructKeyExists(application[local.appKey], "staticRoutes")) {
			StructClear(application[local.appKey].staticRoutes);
		}
		// Drop the URLFor controller/action memo so cached lookups from the
		// previous route set (including negative-cached misses) can't leak
		// across a reload. `$addRoute` also clears the memo, but doing it
		// here guarantees a freshly-reloaded app starts with an empty cache
		// even before the first `$addRoute` call runs.
		if (StructKeyExists(application[local.appKey], "urlForCache")) {
			StructClear(application[local.appKey].urlForCache);
		}
		// load wheels internal gui routes
		// TODO skip this if mode != development|testing?
		$include(template = "/wheels/public/routes.cfm");
		// Browser-test fixture routes — opt-in, only mounted in testing/development.
		// See `vendor/wheels/public/browser-fixtures/routes.cfm` and issues #2135, #2138.
		// The fixture controllers live at `vendor/wheels/public/browser-fixtures/controllers/`
		// and render their own views via explicit `$include`, so only `controllerPath`
		// needs to be extended (viewPath is single-string and left alone).
		if (
			StructKeyExists(application[local.appKey], "loadBrowserTestFixtures")
			&& application[local.appKey].loadBrowserTestFixtures
			&& StructKeyExists(application[local.appKey], "environment")
			&& ListFindNoCase("testing,development", application[local.appKey].environment)
		) {
			local.fixtureControllerPath = "/wheels/public/browser-fixtures/controllers";
			if (!ListFindNoCase(application[local.appKey].controllerPath, local.fixtureControllerPath)) {
				application[local.appKey].controllerPath = ListAppend(
					application[local.appKey].controllerPath,
					local.fixtureControllerPath
				);
			}
			$include(template = "/wheels/public/browser-fixtures/routes.cfm");
		}
		// load developer routes next
		$include(template = "/config/routes.cfm");
		// set lookup info for the named routes
		$setNamedRoutePositions();
	}


	/**
	 * Internal function.
	 */
	public void function $setNamedRoutePositions() {
		local.appKey = $appKey();
		local.iEnd = ArrayLen(application[local.appKey].routes);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.route = application[local.appKey].routes[local.i];
			if (StructKeyExists(local.route, "name") && Len(local.route.name)) {
				if (!StructKeyExists(application[local.appKey].namedRoutePositions, local.route.name)) {
					application[local.appKey].namedRoutePositions[local.route.name] = "";
				}
				application[local.appKey].namedRoutePositions[local.route.name] = ListAppend(
					application[local.appKey].namedRoutePositions[local.route.name],
					local.i
				);
			}
		}
	}


	/**
	 * Creates an internal URL based on supplied arguments.
	 *
	 * [section: Global Helpers]
	 * [category: Miscellaneous Functions]
	 *
	 * @route Name of a route that you have configured in `config/routes.cfm`.
	 * @controller Name of the controller to include in the URL.
	 * @action Name of the action to include in the URL.
	 * @key Key(s) to include in the URL.
	 * @params Any additional parameters to be set in the query string (example: `wheels=cool&x=y`). Please note that Wheels uses the `&` and `=` characters to split the parameters and encode them properly for you. However, if you need to pass in `&` or `=` as part of the value, then you need to encode them (and only them), example: `a=cats%26dogs%3Dtrouble!&b=1`.
	 * @anchor Sets an anchor name to be appended to the path.
	 * @onlyPath If `true`, returns only the relative URL (no protocol, host name or port).
	 * @host Set this to override the current host.
	 * @protocol Set this to override the current protocol.
	 * @port Set this to override the current port number.
	 * @encode Encode URL parameters using `EncodeForURL()`. Please note that this does not make the string safe for placement in HTML attributes, for that you need to wrap the result in `EncodeForHtmlAttribute()` or use `linkTo()`, `startFormTag()` etc instead.
	 */
	public string function URLFor(
		string route = "",
		string controller = "",
		string action = "",
		any key = "",
		string params = "",
		string anchor = "",
		boolean onlyPath,
		string host,
		string protocol,
		numeric port,
		boolean encode,
		boolean $encodeForHtmlAttribute = false,
		string $URLRewriting = application.wheels.URLRewriting
	) {
		$args(name = "URLFor", args = arguments);
		local.coreVariables = "controller,action,key,format";
		local.params = {};
		if (StructKeyExists(variables, "params")) {
			StructAppend(local.params, variables.params);
		}

		// Throw error if host or protocol are passed with onlyPath=true.
		local.hostOrProtocolNotEmpty = Len(arguments.host) || Len(arguments.protocol);
		if (application.wheels.showErrorInformation && arguments.onlyPath && local.hostOrProtocolNotEmpty) {
			Throw(
				type = "Wheels.IncorrectArguments",
				message = "Can't use the `host` or `protocol` arguments when `onlyPath` is `true`.",
				extendedInfo = "Set `onlyPath` to `false` so that `linkTo` will create absolute URLs and thus allowing you to set the `host` and `protocol` on the link."
			);
		}

		// Look up actual route paths instead of providing default Wheels path generation.
		// Loop over all routes to find matching one, break the loop on first match.
		// The (controller, action) → route-name memo lives in application scope and
		// negative-caches misses (empty string sentinel) so wildcard-`[controller]`
		// apps — where `$addRoute` strips the `controller` key, guaranteeing no
		// match — don't re-scan the route table for every link helper. The cache
		// is invalidated by `$addRoute` and `$lockedLoadRoutes`.
		if (!Len(arguments.route) && Len(arguments.action)) {
			if (!Len(arguments.controller)) {
				arguments.controller = local.params.controller;
			}
			local.appKey = $appKey();
			if (!StructKeyExists(application[local.appKey], "urlForCache")) {
				application[local.appKey].urlForCache = {};
			}
			local.cache = application[local.appKey].urlForCache;
			local.key = arguments.controller & "##" & arguments.action;
			if (!StructKeyExists(local.cache, local.key)) {
				local.found = "";
				local.iEnd = ArrayLen(application[local.appKey].routes);
				for (local.i = 1; local.i <= local.iEnd; local.i++) {
					local.route = application[local.appKey].routes[local.i];
					local.controllerMatch = StructKeyExists(local.route, "controller") && local.route.controller == arguments.controller;
					local.actionMatch = StructKeyExists(local.route, "action") && local.route.action == arguments.action;
					if (local.controllerMatch && local.actionMatch) {
						local.found = local.route.name;
						break;
					}
				}
				local.cache[local.key] = local.found;
			}
			if (Len(local.cache[local.key])) {
				arguments.route = local.cache[local.key];
			}
		}

		// Start building the URL to return by setting the sub folder path and script name portion.
		// Script name index.cfm will be removed later if applicable (e.g. when URL rewriting is on).
		local.rv = application.wheels.webPath & ListLast(request.cgi.script_name, "/");

		// Look up route pattern to use and add it to the URL to return.
		// Either from a passed in route or the Wheels default one.
		// For the Wheels default we set the controller and action arguments to what's in the params struct.
		if (Len(arguments.route)) {
			local.route = $findRoute(argumentCollection = arguments);
			local.foundVariables = local.route.foundvariables;

			if (arguments.$URLRewriting neq "Off") {
				local.rv &= local.route.pattern;
			} else {
				// Always include core variables when not rewriting
				local.foundVariables &= "," & local.coreVariables;
				local.rv &= "?controller=[controller]&action=[action]&key=[key]&format=[format]";
			}
		} else {
			local.route = {};
			local.foundVariables = local.coreVariables;
			local.rv &= "?controller=[controller]&action=[action]&key=[key]&format=[format]";
		}

		// Shared fallback logic for controller/action
		if (StructKeyExists(local, "params")) {
			// Handle action
			if (!Len(arguments.action)) {
				if (StructKeyExists(local.route, "action")) {
					arguments.action = local.route.action;
				} else if (Len(arguments.controller)) {
					arguments.action = "index";
				} else if (StructKeyExists(local.params, "action")) {
					arguments.action = local.params.action;
				}
			}

			// Handle controller
			if (!Len(arguments.controller)) {
				if (StructKeyExists(local.route, "controller")) {
					arguments.controller = local.route.controller;
				} else if (StructKeyExists(local.params, "controller")) {
					arguments.controller = local.params.controller;
				}
			}
		}

		// Replace each params variable with the correct value.
		for (local.i = 1; local.i <= ListLen(local.foundVariables); local.i++) {
			local.property = ListGetAt(local.foundVariables, local.i);
			local.reg = "\[\*?#local.property#\]";

			// Read necessary variables from different sources.
			if (StructKeyExists(arguments, local.property) && Len(arguments[local.property])) {
				local.value = arguments[local.property];
			} else if (StructKeyExists(local.route, local.property)) {
				local.value = local.route[local.property];
			} else if (Len(arguments.route) && arguments.$URLRewriting != "Off") {
				Throw(
					type = "Wheels.IncorrectRoutingArguments",
					message = "Incorrect Arguments",
					extendedInfo = "The route chosen by Wheels `#local.route.name#` requires the argument `#local.property#`. Pass the argument `#local.property#` or change your routes to reflect the proper variables needed."
				);
			} else {
				continue;
			}

			// If value is a model object, get its key value.
			if (IsObject(local.value)) {
				local.value = local.value.key();
			}

			// Any value we find from above, URL encode it here.
			if (arguments.encode && $get("encodeURLs")) {
				local.value = EncodeForURL($canonicalize(local.value));
				if (arguments.$encodeForHtmlAttribute) {
					local.value = EncodeForHTMLAttribute(local.value);
				}
			}

			// If property is not in pattern, store it in the params argument.
			if (!ReFind(local.reg, local.rv)) {
				if (!ListFindNoCase(local.coreVariables, local.property)) {
					arguments.params = ListAppend(arguments.params, "#local.property#=#local.value#", "&");
				}
				continue;
			}

			// Transform value before setting it in pattern.
			if (local.property == "controller" || local.property == "action") {
				local.value = hyphenize(local.value);
			} else if (application.wheels.obfuscateUrls) {
				local.value = obfuscateParam(local.value);
			}
			local.rv = ReReplace(local.rv, local.reg, local.value);
		}

		// Clean up unused keys in pattern.
		local.rv = ReReplace(local.rv, "((&|\?)\w+=|\/|\.)\[\*?\w+\]", "", "ALL");

		// When URL rewriting is on (or partially) we replace the "?controller="" stuff in the URL with just "/".
		if (arguments.$URLRewriting != "Off") {
			local.rv = Replace(local.rv, "?controller=", "/");
			local.rv = Replace(local.rv, "&action=", "/");
			local.rv = Replace(local.rv, "&key=", "/");
		}

		// When URL rewriting is on we remove the rewrite file name (e.g. index.cfm) from the URL so it doesn't show.
		// Also get rid of the double "/" that this removal typically causes.
		if (arguments.$URLRewriting == "On") {
			local.rv = Replace(local.rv, application.wheels.rewriteFile, "");
			local.rv = Replace(local.rv, "//", "/");
		}

		// Add params to the URL when supplied.
		if (Len(arguments.params)) {
			local.rv &= $constructParams(
				params = arguments.params,
				encode = arguments.encode,
				$encodeForHtmlAttribute = arguments.$encodeForHtmlAttribute,
				$URLRewriting = arguments.$URLRewriting
			);
		}

		// Add an anchor to the the URL when supplied.
		if (Len(arguments.anchor)) {
			local.rv &= "##" & arguments.anchor;
		}

		// Prepend the full URL if directed.
		if (!arguments.onlyPath) {
			local.rv = $prependUrl(path = local.rv, argumentCollection = arguments);
		}

		return local.rv;
	}


	/**
	 * Returns the mapper object used to configure your application's routes. Usually you will use this method in `config/routes.cfm` to start chaining route mapping methods like `resources`, `namespace`, etc.
	 *
	 * [section: Configuration]
	 * [category: Routing]
	 *
	 * @restful Whether to turn on RESTful routing or not. Not recommended to set. Will probably be removed in a future version of wheels, as RESTful routes are the default.
	 * @methods If not RESTful, then specify allowed routes. Not recommended to set. Will probably be removed in a future version of wheels, as RESTful routes are the default.
	 * @mapFormat This is useful for providing formats via URL like `json`, `xml`, `pdf`, etc. Set to false to disable automatic .[format] generation for resource based routes
	 */
	public struct function mapper(boolean restful = true, boolean methods = arguments.restful, boolean mapFormat = true) {
		return application[$appKey()].mapper.$draw(argumentCollection = arguments);
	}
</cfscript>
