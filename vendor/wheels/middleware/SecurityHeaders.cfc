/**
 * Adds common security headers to every response.
 * Covers OWASP recommended headers for clickjacking, XSS, MIME sniffing, and referrer leakage.
 *
 * [section: Middleware]
 * [category: Built-in]
 */
component implements="wheels.middleware.MiddlewareInterface" output="false" {

	/**
	 * Creates the SecurityHeaders middleware with configurable options.
	 *
	 * @frameOptions X-Frame-Options value. Set to empty string to disable.
	 * @contentTypeOptions X-Content-Type-Options value.
	 * @xssProtection X-XSS-Protection value.
	 * @referrerPolicy Referrer-Policy value.
	 */
	public SecurityHeaders function init(
		string frameOptions = "SAMEORIGIN",
		string contentTypeOptions = "nosniff",
		string xssProtection = "1; mode=block",
		string referrerPolicy = "strict-origin-when-cross-origin"
	) {
		variables.headers = {};
		if (Len(arguments.frameOptions)) {
			variables.headers["X-Frame-Options"] = arguments.frameOptions;
		}
		if (Len(arguments.contentTypeOptions)) {
			variables.headers["X-Content-Type-Options"] = arguments.contentTypeOptions;
		}
		if (Len(arguments.xssProtection)) {
			variables.headers["X-XSS-Protection"] = arguments.xssProtection;
		}
		if (Len(arguments.referrerPolicy)) {
			variables.headers["Referrer-Policy"] = arguments.referrerPolicy;
		}
		return this;
	}

	public string function handle(required struct request, required any next) {
		// Execute the rest of the pipeline first.
		local.response = arguments.next(arguments.request);

		// Apply security headers.
		try {
			for (local.name in variables.headers) {
				cfheader(name = local.name, value = variables.headers[local.name]);
			}
		} catch (any e) {
			// Headers may already be flushed.
		}

		return local.response;
	}

}
