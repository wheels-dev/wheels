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
				local.name = $encodeUrlParam(local.name);
				if (arguments.$encodeForHtmlAttribute) {
					local.name = EncodeForHTMLAttribute(local.name);
				}
			}
			local.rv &= local.delim & local.name & "=";
			local.delim = "&";
			if (ArrayLen(local.params) == 2) {
				local.value = local.params[2];
				if (arguments.encode && $get("encodeURLs")) {
					local.value = $encodeUrlParam(local.value);
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

		// Canonical base URL: when set(baseUrl="https://host[:port]") is configured
		// it supplies the authority for absolute URLs. Precedence for each part is
		// explicit argument > baseUrl > the incoming request. A caller reading this
		// before application.wheels exists (cold start) resolves to "unset".
		local.baseUrl = "";
		if (StructKeyExists(application, "wheels") && StructKeyExists(application.wheels, "baseUrl")) {
			local.baseUrl = application.wheels.baseUrl;
		}
		if (Len(local.baseUrl)) {
			// Parsed once at application start ($cacheBaseUrl); a value changed at
			// runtime with set(baseUrl=...) is parsed here instead.
			if (
				StructKeyExists(application.wheels, "$baseUrlParts")
				&& Compare(application.wheels.$baseUrlParts.source, local.baseUrl) == 0
			) {
				local.base = application.wheels.$baseUrlParts.parts;
			} else {
				local.base = $parseBaseUrl(baseUrl = local.baseUrl);
			}
		} else {
			local.base = {protocol = "", host = "", port = 0, hasPort = false};
		}

		if (arguments.port != 0) {
			// use the port that was passed in by the developer
			local.rv = ":" & arguments.port & local.rv;
		} else if (Len(local.base.host)) {
			// baseUrl governs the authority: use its port (or none) — never the
			// request port, so a dev server on :8080 still yields the canonical host.
			if (local.base.hasPort) {
				local.rv = ":" & local.base.port & local.rv;
			}
		} else if (request.cgi.server_port != 80 && request.cgi.server_port != 443) {
			// if the port currently in use is not 80 or 443 we set it explicitly in the URL
			local.rv = ":" & request.cgi.server_port & local.rv;
		}

		if (Len(arguments.host)) {
			local.rv = arguments.host & local.rv;
		} else if (Len(local.base.host)) {
			local.rv = local.base.host & local.rv;
		} else {
			local.rv = request.cgi.server_name & local.rv;
		}

		if (Len(arguments.protocol)) {
			local.rv = arguments.protocol & "://" & local.rv;
		} else if (Len(local.base.protocol)) {
			local.rv = local.base.protocol & "://" & local.rv;
		} else if (
			request.cgi.server_port_secure == "true"
			|| ($trustProxyHeaders() && request.cgi.http_x_forwarded_proto == "https")
		) {
			// The real socket TLS state (server_port_secure) always wins. The
			// X-Forwarded-Proto header is client-controlled, so since 4.2 it only
			// selects https:// when the app has opted in with
			// set(trustProxyHeaders=true) — the same gate isSecure() applies.
			// Without the opt-in a spoofed header can no longer induce https://
			// absolute URLs (#3836).
			local.rv = "https://" & local.rv;
		} else {
			local.rv = "http://" & local.rv;
		}

		// Advisory: in production an unset baseUrl means every absolute URL depends
		// on the incoming request's host and scheme. Nudge once toward pinning it.
		if (!Len(local.baseUrl)) {
			$warnBaseUrlUnsetOnce();
		}

		return local.rv;
	}

	/**
	 * Internal. Parses `set(baseUrl=...)` once at application start (#3842), so a
	 * malformed value stops the application from starting instead of failing the
	 * first absolute URL a request builds. Caches the parts on `settings` (the
	 * application.$wheels struct being started) for $prependUrl().
	 */
	public void function $cacheBaseUrl(required struct settings) {
		StructDelete(arguments.settings, "$baseUrlParts");
		if (StructKeyExists(arguments.settings, "baseUrl") && Len(Trim(arguments.settings.baseUrl))) {
			arguments.settings.$baseUrlParts = {
				source = arguments.settings.baseUrl,
				parts = $parseBaseUrl(baseUrl = arguments.settings.baseUrl)
			};
		}
	}

	/**
	 * Internal. Parses a configured `baseUrl` ("https://host[:port]", or a
	 * bracketed IPv6 host such as "https://[::1]:8443") into its scheme, host, and
	 * optional port using plain string operations (regex subexpression indexing
	 * drifts across CFML engines). Throws `Wheels.IncorrectConfiguration` when the
	 * value is not an absolute http(s) URL, or carries a path, query, fragment,
	 * user info, or an invalid host or port.
	 */
	public struct function $parseBaseUrl(required string baseUrl) {
		local.rv = {protocol = "", host = "", port = 0, hasPort = false};
		local.value = Trim(arguments.baseUrl);

		if (Left(LCase(local.value), 8) == "https://") {
			local.rv.protocol = "https";
			local.rest = Mid(local.value, 9, Len(local.value));
		} else if (Left(LCase(local.value), 7) == "http://") {
			local.rv.protocol = "http";
			local.rest = Mid(local.value, 8, Len(local.value));
		} else {
			$throwBadBaseUrl("must be an absolute http:// or https:// URL (for example ""https://example.com"")", arguments.baseUrl);
		}

		// Tolerate a single trailing slash, then reject any remaining path.
		if (Len(local.rest) && Right(local.rest, 1) == "/") {
			local.rest = Mid(local.rest, 1, Len(local.rest) - 1);
		}
		if (Find("/", local.rest)) {
			$throwBadBaseUrl("must not include a path — only the scheme, host, and optional port (for example ""https://example.com:8443"")", arguments.baseUrl);
		}
		if (ReFind("[?##@\\]", local.rest)) {
			$throwBadBaseUrl("must not include a query (?), fragment (##), user info (@) or backslash — only the scheme, host, and optional port", arguments.baseUrl);
		}

		// Split host and port. A bracketed IPv6 literal keeps its brackets in the
		// host (that is how it appears in a URL); any other host has at most one colon.
		local.portText = "";
		local.hasPort = false;
		if (Left(local.rest, 1) == "[") {
			local.close = Find("]", local.rest);
			if (local.close < 3) {
				$throwBadBaseUrl("has an invalid IPv6 host: use a bracketed literal such as ""https://[::1]:8443""", arguments.baseUrl);
			}
			local.literal = Mid(local.rest, 2, local.close - 2);
			if (ReFind("[^0-9A-Fa-f:.]", local.literal) || !Find(":", local.literal)) {
				$throwBadBaseUrl("has an invalid IPv6 host: use a bracketed literal such as ""https://[::1]:8443""", arguments.baseUrl);
			}
			local.rv.host = "[" & local.literal & "]";
			local.after = Mid(local.rest, local.close + 1, Len(local.rest));
			if (Len(local.after)) {
				if (Left(local.after, 1) != ":") {
					$throwBadBaseUrl("has unexpected text after the IPv6 host", arguments.baseUrl);
				}
				local.hasPort = true;
				local.portText = Mid(local.after, 2, Len(local.after));
			}
		} else {
			local.colon = Find(":", local.rest);
			if (local.colon) {
				if (Find(":", local.rest, local.colon + 1)) {
					$throwBadBaseUrl("has more than one colon: put an IPv6 host in brackets (for example ""https://[::1]:8443"")", arguments.baseUrl);
				}
				local.rv.host = local.colon > 1 ? Left(local.rest, local.colon - 1) : "";
				local.hasPort = true;
				local.portText = Mid(local.rest, local.colon + 1, Len(local.rest));
			} else {
				local.rv.host = local.rest;
			}
			if (Len(local.rv.host) && ReFind("[^A-Za-z0-9._-]", local.rv.host)) {
				$throwBadBaseUrl("has an invalid host: use letters, digits, dots and hyphens (or a bracketed IPv6 address)", arguments.baseUrl);
			}
		}

		if (!Len(local.rv.host)) {
			$throwBadBaseUrl("is missing a host", arguments.baseUrl);
		}
		if (local.hasPort) {
			if (ReFind("^[0-9]{1,5}$", local.portText) == 0 || Val(local.portText) < 1 || Val(local.portText) > 65535) {
				$throwBadBaseUrl("has an invalid port (use 1-65535)", arguments.baseUrl);
			}
			local.rv.port = Int(Val(local.portText));
			local.rv.hasPort = true;
		}

		return local.rv;
	}

	/** Internal. Throws the configuration error for a bad `baseUrl`. */
	public void function $throwBadBaseUrl(required string problem, required string baseUrl) {
		Throw(
			type = "Wheels.IncorrectConfiguration",
			message = "The `baseUrl` setting #arguments.problem#. Received: #arguments.baseUrl#"
		);
	}

	/**
	 * Internal. Logs a one-time advisory when an absolute URL is generated in
	 * production with no `baseUrl` configured, so links, redirects, and emails
	 * depend on the incoming request's host and scheme.
	 */
	public void function $warnBaseUrlUnsetOnce() {
		if (!StructKeyExists(application, "wheels") || StructKeyExists(application.wheels, "$baseUrlUnsetWarned")) {
			return;
		}
		if (!StructKeyExists(application.wheels, "environment") || application.wheels.environment != "production") {
			return;
		}
		cflock(name = "wheels.baseUrlUnset.#application.applicationName#", type = "exclusive", timeout = 5) {
			if (!StructKeyExists(application.wheels, "$baseUrlUnsetWarned")) {
				application.wheels.$baseUrlUnsetWarned = true;
				cflog(
					type = "warning",
					file = "wheels",
					text = "An absolute URL was generated from the incoming request's host and scheme because baseUrl is not set. "
						& "Set set(baseUrl=""https://your-canonical-host"") in production so links, redirects, and emails "
						& "always use your canonical address regardless of how the request arrived."
				);
			}
		}
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
	 * Internal function. Resolves a (controller, action) pair to a named route
	 * via the application-scoped memo, mutating `args.route` (and `args.controller`
	 * when empty) in place when a match is found. Extracted from URLFor; behavior
	 * is unchanged.
	 */
	public void function $urlForResolveRouteFromMemo(required struct args, required struct params) {
		if (!Len(arguments.args.route) && Len(arguments.args.action)) {
			if (!Len(arguments.args.controller)) {
				arguments.args.controller = arguments.params.controller;
			}
			// Look up actual route paths instead of providing default Wheels path generation.
			// Loop over all routes to find matching one, break the loop on first match.
			// The (controller, action) → route-name memo lives in application scope and
			// negative-caches misses (empty string sentinel) so wildcard-`[controller]`
			// apps — where `$addRoute` strips the `controller` key, guaranteeing no
			// match — don't re-scan the route table for every link helper. The cache
			// is invalidated by `$addRoute` and `$lockedLoadRoutes`.
			local.appKey = $appKey();
			if (!StructKeyExists(application[local.appKey], "urlForCache")) {
				application[local.appKey].urlForCache = {};
			}
			local.cache = application[local.appKey].urlForCache;
			local.key = arguments.args.controller & "##" & arguments.args.action;
			if (!StructKeyExists(local.cache, local.key)) {
				local.found = "";
				local.iEnd = ArrayLen(application[local.appKey].routes);
				for (local.i = 1; local.i <= local.iEnd; local.i++) {
					local.route = application[local.appKey].routes[local.i];
					local.controllerMatch = StructKeyExists(local.route, "controller") && local.route.controller == arguments.args.controller;
					local.actionMatch = StructKeyExists(local.route, "action") && local.route.action == arguments.args.action;
					if (local.controllerMatch && local.actionMatch) {
						local.found = local.route.name;
						break;
					}
				}
				local.cache[local.key] = local.found;
			}
			if (Len(local.cache[local.key])) {
				arguments.args.route = local.cache[local.key];
			}
		}
	}


	/**
	 * Internal function. Fills in `args.action` / `args.controller` from the
	 * matched route or request params when they were not supplied. Extracted from
	 * URLFor; behavior is unchanged.
	 */
	public void function $urlForControllerActionFallback(required struct args, required struct route, required struct params) {
		// Handle action
		if (!Len(arguments.args.action)) {
			if (StructKeyExists(arguments.route, "action")) {
				arguments.args.action = arguments.route.action;
			} else if (Len(arguments.args.controller)) {
				arguments.args.action = "index";
			} else if (StructKeyExists(arguments.params, "action")) {
				arguments.args.action = arguments.params.action;
			}
		}
		// Handle controller
		if (!Len(arguments.args.controller)) {
			if (StructKeyExists(arguments.route, "controller")) {
				arguments.args.controller = arguments.route.controller;
			} else if (StructKeyExists(arguments.params, "controller")) {
				arguments.args.controller = arguments.params.controller;
			}
		}
	}


	/**
	 * Internal function. Substitutes route/path variables into the URL, appending
	 * unmatched variables to `args.params` and returning the updated path. Extracted
	 * from URLFor; behavior (including the Wheels.IncorrectRoutingArguments throw)
	 * is unchanged.
	 */
	public string function $urlForSubstituteVariables(
		required string rv,
		required struct args,
		required string foundVariables,
		required string coreVariables,
		required struct route
	) {
		local.rv = arguments.rv;
		for (local.i = 1; local.i <= ListLen(arguments.foundVariables); local.i++) {
			local.property = ListGetAt(arguments.foundVariables, local.i);
			local.reg = "\[\*?#local.property#\]";

			// Read necessary variables from different sources.
			if (StructKeyExists(arguments.args, local.property) && Len(arguments.args[local.property])) {
				local.value = arguments.args[local.property];
			} else if (StructKeyExists(arguments.route, local.property)) {
				local.value = arguments.route[local.property];
			} else if (Len(arguments.args.route) && arguments.args.$URLRewriting != "Off") {
				Throw(
					type = "Wheels.IncorrectRoutingArguments",
					message = "Incorrect Arguments",
					extendedInfo = "The route chosen by Wheels `#arguments.route.name#` requires the argument `#local.property#`. Pass the argument `#local.property#` or change your routes to reflect the proper variables needed."
				);
			} else {
				continue;
			}

			// If value is a model object, get its key value.
			if (IsObject(local.value)) {
				local.value = local.value.key();
			}

			// Keep the unencoded value for the query-string branch below.
			local.rawValue = local.value;

			// Any value we find from above, URL encode it here.
			if (arguments.args.encode && $get("encodeURLs")) {
				local.value = $encodeUrlParam(local.value);
				if (arguments.args.$encodeForHtmlAttribute) {
					local.value = EncodeForHTMLAttribute(local.value);
				}
			}

			// The placeholder for this property is the literal `[prop]` or, for a wildcard
			// segment, `[*prop]`. Locating and substituting it with literal Find/Replace avoids
			// a regex per variable (the hot spot on every engine, #4151). Property names are
			// alphanumeric route tokens with no regex metacharacters, so literal matching is
			// equivalent to the `\[\*?prop\]` pattern.
			local.lit = "[" & local.property & "]";
			local.litStar = "[*" & local.property & "]";
			local.posLit = Find(local.lit, local.rv);
			local.posStar = Find(local.litStar, local.rv);

			// If property is not in pattern, store it in the params argument.
			// `$constructParams` encodes params itself, so append the raw value (escaping only the
			// `&` / `=` delimiters it splits on, as the `params` argument documents) to avoid
			// double-encoding, e.g. a space becoming `%2B` when URL rewriting is off.
			if (!local.posLit && !local.posStar) {
				if (!ListFindNoCase(arguments.coreVariables, local.property)) {
					if (arguments.args.encode && $get("encodeURLs")) {
						local.rawValue = Replace(Replace(local.rawValue, "&", "%26", "all"), "=", "%3D", "all");
					}
					arguments.args.params = ListAppend(arguments.args.params, "#local.property#=#local.rawValue#", "&");
				}
				continue;
			}

			// Transform value before setting it in pattern.
			if (local.property == "controller" || local.property == "action") {
				local.value = hyphenize(local.value);
			} else if (application.wheels.obfuscateUrls) {
				local.value = obfuscateParam(local.value);
			}
			// A value containing a backslash or `$` is a regex-replacement metacharacter to
			// ReReplace (which has no capture groups here, so its behaviour is engine-specific);
			// keep ReReplace for those to stay byte-identical. Otherwise substitute the first
			// matching literal placeholder (Replace is first-occurrence, matching ReReplace's
			// one scope) — replacing whichever of `[prop]` / `[*prop]` appears first.
			if (Find("\", local.value) || Find("$", local.value)) {
				local.rv = ReReplace(local.rv, local.reg, local.value);
			} else if (local.posStar && (!local.posLit || local.posStar < local.posLit)) {
				local.rv = Replace(local.rv, local.litStar, local.value);
			} else {
				local.rv = Replace(local.rv, local.lit, local.value);
			}
		}
		return local.rv;
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
		string $URLRewriting = application.wheels.URLRewriting,
		boolean $argsResolved = false
	) {
		// An internal caller (e.g. linkTo) that has already run its own $args passes
		// $argsResolved=true so we skip the redundant generic normalisation. We still apply any
		// app-level `set(functionName="URLFor", …)` defaults here, since those belong to URLFor's
		// default set (not the caller's) and would otherwise not reach the URL (#4151). Declaring
		// $argsResolved as a real argument keeps the sentinel out of the generated query string.
		if (!arguments.$argsResolved) {
			$args(name = "URLFor", args = arguments);
		} else if (StructKeyExists(application.wheels.functions, "URLFor")) {
			$engineAdapter().structAppendDefaults(arguments, application.wheels.functions.URLFor);
		}
		local.coreVariables = "controller,action,key,format";
		local.params = {};
		if (StructKeyExists(variables, "params")) {
			StructAppend(local.params, variables.params);
		}

		// Throw error if host or protocol are passed with onlyPath=true.
		local.hostOrProtocolNotEmpty = Len(arguments.host) || Len(arguments.protocol);
		if ($get("showErrorInformation") && arguments.onlyPath && local.hostOrProtocolNotEmpty) {
			Throw(
				type = "Wheels.IncorrectArguments",
				message = "Can't use the `host` or `protocol` arguments when `onlyPath` is `true`.",
				extendedInfo = "Set `onlyPath` to `false` so that `linkTo` will create absolute URLs and thus allowing you to set the `host` and `protocol` on the link."
			);
		}

		// Look up actual route paths instead of providing default Wheels path generation.
		$urlForResolveRouteFromMemo(args = arguments, params = local.params);

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
		$urlForControllerActionFallback(args = arguments, route = local.route, params = local.params);

		// Replace each params variable with the correct value.
		local.rv = $urlForSubstituteVariables(
			rv = local.rv,
			args = arguments,
			foundVariables = local.foundVariables,
			coreVariables = local.coreVariables,
			route = local.route
		);

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
