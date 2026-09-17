<cfscript>
/**
 * wheels.Global include: cors
 * CORS header helpers and wildcard domain matching.
 *
 * Included from `vendor/wheels/Global.cfc` at component-body scope so
 * these functions compile into the Global component. Children inherit
 * them; there is no per-instance mixin copy. Keep every helper that
 * must mix onto models/controllers `public` and `$`-prefixed
 * (cross-engine invariant 7).
 */


	// ======================================================================
	// CORS FUNCTIONS
	// ======================================================================

	/**
	 * Wildcard domain match: check if the current cgi.server_name and port satisfies
	 * the passed in domain string whilst checking for wildcards
	 *
	 * @domain string to test against e.g *.foo.com
	 * @cgi Fake CGI Scope for Testing; will default to normal cgi scope
	 */
	public boolean function $wildcardDomainMatchCGI(required string domain, struct cgi) {
		local.domain = arguments.domain;
		local.cgi = StructKeyExists(arguments, "cgi") ? arguments.cgi : $cgiScope();

		return $wildcardDomainMatch($fullDomainString(local.domain), $fullCgiDomainString(local.cgi));
	}


	/**
	 * Wildcard domain match: domain satisfies wildcard
	 *
	 * @domain string to test against e.g *.foo.com
	 * @origin string to test against e.g bar.foo.com
	 */
	public boolean function $wildcardDomainMatch(required string domain, required string origin) {
		local.domainfull = $fullDomainString(arguments.domain);
		local.originfull = $fullDomainString(arguments.origin);
		if (local.domainfull == local.originfull) {
			return true;
		}

		// Compare protocol, port, and every host label. Reverse+SpanExcluding
		// used to keep only TLD+port, so https://*.example.com matched
		// https://evil.com. Fail closed on a parse miss or a length mismatch.
		local.domainParts = $parseFullDomain(local.domainfull);
		local.originParts = $parseFullDomain(local.originfull);
		if (
			!Len(local.domainParts.host)
			|| !Len(local.originParts.host)
			|| CompareNoCase(local.domainParts.protocol, local.originParts.protocol)
			|| CompareNoCase(ToString(local.domainParts.port), ToString(local.originParts.port))
		) {
			return false;
		}

		local.domainLabels = ListToArray(local.domainParts.host, ".");
		local.originLabels = ListToArray(local.originParts.host, ".");
		if (ArrayLen(local.domainLabels) != ArrayLen(local.originLabels) || !ArrayLen(local.domainLabels)) {
			return false;
		}

		for (local.i = 1; local.i <= ArrayLen(local.domainLabels); local.i++) {
			if (local.domainLabels[local.i] == "*") {
				continue;
			}
			if (CompareNoCase(local.domainLabels[local.i], local.originLabels[local.i])) {
				return false;
			}
		}
		return true;
	}


	/**
	 * Split a $fullDomainString value (https://host:port) into protocol, host, port.
	 */
	public struct function $parseFullDomain(required string fullDomain) {
		local.rv = {protocol = "", host = "", port = ""};
		local.sep = Find("://", arguments.fullDomain);
		if (local.sep < 2) {
			return local.rv;
		}
		local.rv.protocol = Left(arguments.fullDomain, local.sep - 1);
		local.rest = Mid(arguments.fullDomain, local.sep + 3, Len(arguments.fullDomain));
		local.colon = Find(":", local.rest);
		if (local.colon < 1) {
			local.rv.host = local.rest;
			return local.rv;
		}
		if (local.colon > 1) {
			local.rv.host = Left(local.rest, local.colon - 1);
		}
		local.rv.port = Mid(local.rest, local.colon + 1, Len(local.rest));
		return local.rv;
	}


	/**
	 * Get full domain string from cgi scope: includes protocol and port
	 * e.g https://www.wheels.dev:443
	 *
	 * @cgi Fake CGI Scope for Testing; will default to normal cgi scope
	 **/
	public string function $fullCgiDomainString(struct cgi) {
		local.cgi = StructKeyExists(arguments, "cgi") ? arguments.cgi : $cgiScope();
		local.server_name = local.cgi.server_name;
		local.server_port = local.cgi.server_port;
		local.server_protocol =
		(
			(
				$trustProxyHeaders()
				&& StructKeyExists(local.cgi, "http_x_forwarded_proto")
				&& local.cgi.http_x_forwarded_proto == "https"
			)
			|| (StructKeyExists(local.cgi, "server_port_secure") && local.cgi.server_port_secure)
		)
		 ? "https" : "http";
		return local.server_protocol & '://' & local.server_name & ':' & local.server_port;
	}


	/**
	 * Get full domain string from a passed in string: includes protocol and port
	 * e.g https://www.wheels.dev -> https://www.wheels.dev:443
	 * e.g www.wheels.dev -> http://www.wheels.dev:80
	 *
	 * @domain The string to look at
	 **/
	public string function $fullDomainString(required string domain) {
		local.domain = arguments.domain;
		local.protocol = ListFirst(local.domain, "://");
		local.port = ListLast(local.domain, ":");

		if (!ListFindNoCase("http,https", local.protocol)) {
			if (local.port == 443) {
				local.protocol = "https";
			} else {
				local.protocol = "http";
			}
			local.domain = local.protocol & '://' & local.domain;
		}
		if (!IsNumeric(local.port)) {
			if (local.protocol == 'http') {
				local.port = 80;
			} else if (local.protocol == 'https') {
				local.port = 443;
			}
			local.domain &= ':' & local.port;
		}
		return local.domain;
	}


	/**
	 * Set CORS Headers: only triggered if application.wheels.allowCorsRequests = true
	 */
	public void function $setCORSHeaders(
		string allowOrigin = "",
		string allowCredentials = false,
		string allowHeaders = "Origin, Content-Type, X-Auth-Token, X-Requested-By, X-Requested-With",
		string allowMethods = "GET, POST, PATCH, PUT, DELETE, OPTIONS",
		boolean allowMethodsByRoute = false,
		string pathInfo = request.cgi.PATH_INFO,
		string scriptName = request.cgi.script_name
	) {
		local.incomingOrigin = StructKeyExists(request.wheels.httprequestdata.headers, "origin") ? request.wheels.httprequestdata.headers.origin : false;

		// No origins configured — skip all CORS headers (deny all by default)
		if (!Len(arguments.allowOrigin)) {
			return;
		}

		// Either a wildcard, or if a specific domain is set, we need to ensure the incoming request matches it
		if (arguments.allowOrigin == "*") {
			$header(name = "Access-Control-Allow-Origin", value = arguments.allowOrigin);
		} else {
			// Passed value may be a list or just a single entry
			local.originArr = ListToArray(arguments.allowOrigin);

			// Is this origin in the allowed Array?
			for (local.o in local.originArr) {
				if ($wildcardDomainMatch(local.o, local.incomingOrigin)) {
					$header(name = "Access-Control-Allow-Origin", value = local.incomingOrigin);
					$header(name = "Vary", value = "Origin");
					break;
				}
			}
		}

		// Set Origin, Content-Type, X-Auth-Token, X-Requested-By, X-Requested-With Allow Headers
		$header(name = "Access-Control-Allow-Headers", value = arguments.allowHeaders);

		// Either Look up Route specific allowed methods, or just use default
		if (arguments.allowMethodsByRoute) {
			local.permittedMethods = [];

			// NB this is basically duplicate logic: needs refactoring
			if (arguments.pathInfo == arguments.scriptName || arguments.pathInfo == "/" || !Len(arguments.pathInfo)) {
				local.path = "";
			} else {
				local.path = Right(arguments.pathInfo, Len(arguments.pathInfo) - 1);
			}

			// Attempt to match the requested route and only display the allowed methods for that route
			// Does this info already exist in scope? It seems silly to have to look it up again
			for (local.route in application.wheels.routes) {
				// Make sure route has been converted to regular expression.
				if (!StructKeyExists(local.route, "regex")) {
					local.route.regex = application.wheels.mapper.$patternToRegex(local.route.pattern);
				}

				// If route matches regular expression, get the methods
				if (ReFindNoCase(local.route.regex, local.path)) {
					ArrayAppend(local.permittedMethods, local.route.methods);
				}
			}
			if (ArrayLen(local.permittedMethods)) {
				$header(name = "Access-Control-Allow-Methods", value = UCase(ArrayToList(local.permittedMethods, ', ')));
			}
		} else {
			$header(name = "Access-Control-Allow-Methods", value = arguments.allowMethods);
		}

		// Only add this header if requested (false is an invalid value)
		if (arguments.allowCredentials) {
			$header(name = "Access-Control-Allow-Credentials", value = true);
		}
	}


	/**
	 * Internal. Returns true when a `wheels.middleware.Cors` instance (or its
	 * component path) is registered in `application.wheels.middleware`. When it
	 * is, the dispatch-level Cors middleware is the single source of truth for
	 * CORS headers and OPTIONS preflight, so the legacy global path
	 * (`$setCORSHeaders` + the `onRequestStart` OPTIONS abort) must step aside.
	 * Running both stacks duplicate `Access-Control-Allow-*` headers; a
	 * duplicate `Access-Control-Allow-Origin` makes browsers reject the
	 * response per the Fetch spec. Mirrors the detection in
	 * `Dispatch.$computePreflightCapable()`. (#3114)
	 */
	public boolean function $corsMiddlewareActive() {
		if (
			!StructKeyExists(application, "wheels")
			|| !StructKeyExists(application.wheels, "middleware")
			|| !IsArray(application.wheels.middleware)
		) {
			return false;
		}
		for (local.mw in application.wheels.middleware) {
			if (IsSimpleValue(local.mw)) {
				if (local.mw == "wheels.middleware.Cors") {
					return true;
				}
			} else if (IsObject(local.mw) && IsInstanceOf(local.mw, "wheels.middleware.Cors")) {
				return true;
			}
		}
		return false;
	}


	/**
	 * Internal. Logs a one-time warning when the legacy global CORS path is
	 * suppressed in favour of a registered `wheels.middleware.Cors` instance,
	 * so operators notice the redundant `allowCorsRequests=true` setting. (#3114)
	 */
	public void function $warnGlobalCorsDeferred() {
		if (StructKeyExists(application.wheels, "$corsGlobalDeferredWarned")) {
			return;
		}
		cflock(name = "wheels.corsGlobalDeferred.#application.applicationName#", type = "exclusive", timeout = 5) {
			if (!StructKeyExists(application.wheels, "$corsGlobalDeferredWarned")) {
				application.wheels.$corsGlobalDeferredWarned = true;
				cflog(
					type = "warning",
					file = "wheels",
					text = "CORS configuration conflict: both allowCorsRequests=true and a wheels.middleware.Cors "
						& "instance are active. The legacy global CORS path is deferring to the middleware to avoid "
						& "duplicate Access-Control-Allow-* headers. Disable allowCorsRequests once the Cors middleware "
						& "is configured. (##3114)"
				);
			}
		}
	}
</cfscript>
