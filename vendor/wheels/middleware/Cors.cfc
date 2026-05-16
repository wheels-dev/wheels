/**
 * Handles Cross-Origin Resource Sharing (CORS) headers.
 * Responds to preflight OPTIONS requests and sets appropriate CORS headers on all responses.
 *
 * [section: Middleware]
 * [category: Built-in]
 */
component implements="wheels.middleware.MiddlewareInterface" output="false" {

	/**
	 * Creates the CORS middleware with configurable options.
	 *
	 * @allowOrigins Comma-delimited list of allowed origins, or "*" for any origin. Defaults to "" (no origins allowed). You must explicitly configure allowed origins for CORS to function.
	 * @allowMethods Comma-delimited list of allowed HTTP methods.
	 * @allowHeaders Comma-delimited list of allowed request headers.
	 * @allowCredentials Whether to allow credentials (cookies, auth headers).
	 * @maxAge Preflight cache duration in seconds.
	 */
	public Cors function init(
		string allowOrigins = "",
		string allowMethods = "GET,POST,PUT,PATCH,DELETE,OPTIONS",
		string allowHeaders = "Content-Type,Authorization,X-Requested-With",
		boolean allowCredentials = false,
		numeric maxAge = 86400
	) {
		// The CORS spec forbids Access-Control-Allow-Origin: * with
		// Access-Control-Allow-Credentials: true.  Browsers silently
		// reject the response, which often leads developers to weaken
		// security further.  Fail fast with a clear message instead.
		if (arguments.allowOrigins == "*" && arguments.allowCredentials) {
			Throw(
				type    = "Wheels.Cors.InvalidConfiguration",
				message = "CORS misconfiguration: allowOrigins=""*"" cannot be combined with allowCredentials=true. "
					& "The CORS specification forbids this combination and browsers will reject the response. "
					& "Either list specific origins (e.g. allowOrigins=""https://myapp.com"") or set allowCredentials=false."
			);
		}

		variables.allowOrigins = arguments.allowOrigins;
		variables.allowMethods = arguments.allowMethods;
		variables.allowHeaders = arguments.allowHeaders;
		variables.allowCredentials = arguments.allowCredentials;
		variables.maxAge = arguments.maxAge;
		return this;
	}

	/**
	 * Computes the response headers this middleware would emit for the given request,
	 * without actually writing them. Exposed for testability and so the handle()
	 * path has a single source of truth.
	 *
	 * Emits `Vary: Origin` whenever the response varies by request Origin — i.e.
	 * when a specific origin is reflected back. Skipped on wildcard responses
	 * (the response is identical for every caller) and on disallowed origins
	 * (no CORS headers are emitted at all).
	 */
	public struct function $headersFor(required struct request) {
		local.headers = {};

		// Determine the request origin.
		local.origin = "";
		if (StructKeyExists(arguments.request, "cgi") && StructKeyExists(arguments.request.cgi, "http_origin")) {
			local.origin = arguments.request.cgi.http_origin;
		} else {
			try {
				local.origin = cgi.http_origin;
			} catch (any e) {
			}
		}

		// Resolve the value of Access-Control-Allow-Origin.
		local.allowOrigin = variables.allowOrigins;
		local.reflected = false;
		if (variables.allowOrigins != "*" && Len(local.origin)) {
			if (ListFindNoCase(variables.allowOrigins, local.origin)) {
				local.allowOrigin = local.origin;
				local.reflected = true;
			} else {
				local.allowOrigin = "";
			}
		}

		if (Len(local.allowOrigin)) {
			local.headers["Access-Control-Allow-Origin"] = local.allowOrigin;
			local.headers["Access-Control-Allow-Methods"] = variables.allowMethods;
			local.headers["Access-Control-Allow-Headers"] = variables.allowHeaders;
			if (variables.allowCredentials) {
				local.headers["Access-Control-Allow-Credentials"] = "true";
			}
			// When the response is keyed on the request Origin, intermediary caches
			// must not serve a cached response to a request with a different Origin.
			if (local.reflected) {
				local.headers["Vary"] = "Origin";
			}
		}

		return local.headers;
	}

	public string function handle(required struct request, required any next) {
		local.headers = $headersFor(request = arguments.request);

		try {
			for (local.name in local.headers) {
				cfheader(name = local.name, value = local.headers[local.name]);
			}
		} catch (any e) {
		}

		// Handle preflight OPTIONS request — return empty response immediately.
		local.requestMethod = "GET";
		try {
			local.requestMethod = cgi.request_method;
		} catch (any e) {
		}

		if (local.requestMethod == "OPTIONS") {
			try {
				cfheader(name = "Access-Control-Max-Age", value = variables.maxAge);
			} catch (any e) {
			}
			return "";
		}

		return arguments.next(arguments.request);
	}

}
