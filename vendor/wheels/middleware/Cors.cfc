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
	 * @allowOrigins Comma-delimited list of allowed origins. Use "*" for any origin.
	 * @allowMethods Comma-delimited list of allowed HTTP methods.
	 * @allowHeaders Comma-delimited list of allowed request headers.
	 * @allowCredentials Whether to allow credentials (cookies, auth headers).
	 * @maxAge Preflight cache duration in seconds.
	 */
	public Cors function init(
		string allowOrigins = "*",
		string allowMethods = "GET,POST,PUT,PATCH,DELETE,OPTIONS",
		string allowHeaders = "Content-Type,Authorization,X-Requested-With",
		boolean allowCredentials = false,
		numeric maxAge = 86400
	) {
		variables.allowOrigins = arguments.allowOrigins;
		variables.allowMethods = arguments.allowMethods;
		variables.allowHeaders = arguments.allowHeaders;
		variables.allowCredentials = arguments.allowCredentials;
		variables.maxAge = arguments.maxAge;
		return this;
	}

	public string function handle(required struct request, required any next) {
		// Determine the request origin.
		local.origin = "";
		if (StructKeyExists(request, "cgi") && StructKeyExists(request.cgi, "http_origin")) {
			local.origin = request.cgi.http_origin;
		} else {
			try {
				local.origin = cgi.http_origin;
			} catch (any e) {
			}
		}

		// Set CORS headers.
		local.allowOrigin = variables.allowOrigins;
		if (variables.allowOrigins != "*" && Len(local.origin)) {
			// Only reflect the origin if it's in the allowed list.
			if (ListFindNoCase(variables.allowOrigins, local.origin)) {
				local.allowOrigin = local.origin;
			} else {
				local.allowOrigin = "";
			}
		}

		if (Len(local.allowOrigin)) {
			try {
				cfheader(name = "Access-Control-Allow-Origin", value = local.allowOrigin);
				cfheader(name = "Access-Control-Allow-Methods", value = variables.allowMethods);
				cfheader(name = "Access-Control-Allow-Headers", value = variables.allowHeaders);
				if (variables.allowCredentials) {
					cfheader(name = "Access-Control-Allow-Credentials", value = "true");
				}
			} catch (any e) {
			}
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
