/**
 * Adds common security headers to every response.
 * Covers OWASP recommended headers for clickjacking, XSS, MIME sniffing, referrer leakage,
 * content security policy, transport security, and browser feature permissions.
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
	 * @contentSecurityPolicy Content-Security-Policy value. Empty by default (opt-in) because a restrictive policy can break apps with inline scripts/styles.
	 * @strictTransportSecurity Strict-Transport-Security value. Auto-defaults to `max-age=31536000; includeSubDomains` in production when not explicitly set.
	 * @permissionsPolicy Permissions-Policy value. Empty by default (opt-in) because it is app-specific.
	 * @environment Application environment (e.g. "production", "development"). When empty, falls back to application.$wheels.environment if available.
	 */
	public SecurityHeaders function init(
		string frameOptions = "SAMEORIGIN",
		string contentTypeOptions = "nosniff",
		string xssProtection = "1; mode=block",
		string referrerPolicy = "strict-origin-when-cross-origin",
		string contentSecurityPolicy = "",
		string strictTransportSecurity = "",
		string permissionsPolicy = "",
		string environment = ""
	) {
		variables.headers = {};

		// Resolve environment: explicit parameter > application.$wheels.environment
		local.env = arguments.environment;
		if (!Len(local.env)) {
			try {
				if (StructKeyExists(application, "$wheels") && StructKeyExists(application.$wheels, "environment")) {
					local.env = application.$wheels.environment;
				}
			} catch (any e) {
				// application scope may not be available during testing
			}
		}

		// Default HSTS in production when not explicitly configured
		local.hsts = arguments.strictTransportSecurity;
		if (!Len(local.hsts) && local.env == "production") {
			local.hsts = "max-age=31536000; includeSubDomains";
		}

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
		if (Len(arguments.contentSecurityPolicy)) {
			variables.headers["Content-Security-Policy"] = arguments.contentSecurityPolicy;
		}
		if (Len(local.hsts)) {
			variables.headers["Strict-Transport-Security"] = local.hsts;
		}
		if (Len(arguments.permissionsPolicy)) {
			variables.headers["Permissions-Policy"] = arguments.permissionsPolicy;
		}
		return this;
	}

	public struct function $headers() {
		return variables.headers;
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
