/**
 * Resolves the current tenant from the incoming request and sets `request.wheels.tenant`.
 * Supports subdomain, header, and custom resolver strategies.
 *
 * The resolved tenant struct must contain at minimum a `dataSource` key.
 * Optional keys: `id`, `config` (struct of per-tenant setting overrides).
 *
 * Usage in config/settings.cfm:
 *   set(middleware = [
 *     new wheels.middleware.TenantResolver(
 *       resolver = function(req) {
 *         var subdomain = ListFirst(cgi.server_name, ".");
 *         // 2-arg where binds the value — never interpolate request input into where=.
 *         var t = model("Tenant").where("subdomain", subdomain).findOne();
 *         if (IsObject(t)) return {id: t.id, dataSource: t.dataSourceName, config: {}};
 *         return {};
 *       }
 *     )
 *   ]);
 *
 * [section: Middleware]
 * [category: Built-in]
 */
component implements="wheels.middleware.MiddlewareInterface" output="false" {

	/**
	 * Creates the TenantResolver middleware.
	 *
	 * @resolver Closure that receives the request struct and returns a tenant struct ({id, dataSource, config}). Used when strategy is "custom".
	 * @strategy Resolution strategy: "subdomain", "header", or "custom" (default).
	 * @headerName HTTP header to read tenant ID from when strategy is "header".
	 * @failClosed When true, an unmatched resolver (empty struct / missing dataSource) short-circuits
	 *             with HTTP 403 instead of proceeding on the application default datasource.
	 *             Defaults to false so existing apps keep the documented tenant-free fallback.
	 */
	public TenantResolver function init(
		any resolver = "",
		string strategy = "custom",
		string headerName = "X-Tenant-ID",
		boolean failClosed = false
	) {
		variables.strategy = arguments.strategy;
		variables.headerName = arguments.headerName;
		variables.resolver = arguments.resolver;
		variables.failClosed = arguments.failClosed;

		return this;
	}

	/**
	 * Resolve the tenant, set request.wheels.tenant, then delegate to the next middleware.
	 */
	public string function handle(required struct request, required any next) {
		// Note: this function has a parameter named `request` (the MiddlewareInterface
		// signature mandates it), so the bare `request` token is ambiguous. On Lucee and
		// Adobe 2023 it resolves to the built-in request scope; on Adobe 2025 it does NOT
		// resolve consistently — the same token can mean the built-in scope in one
		// expression position and `arguments.request` in another within this function.
		//
		// So: use `arguments.request` explicitly for the middleware pipeline's request
		// struct, and touch the built-in scope (where $performQuery() and $get() read
		// tenant state from) only through one of two self-consistent forms —
		//   * `IsDefined("request.wheels.tenant")` before reading or deleting, which
		//     string-resolves the whole path in a single evaluation, or
		//   * assign before use: `if (!StructKeyExists(request, "wheels")) { request.wheels = {}; }`
		// Never guard with `StructKeyExists(request, ...)` and then access `request.x` —
		// the guard passes and the access throws `Element WHEELS is undefined in REQUEST`
		// on Adobe 2025 (cross-engine invariant 15).

		local.tenant = $resolveTenant(arguments.request);

		// Only set tenant context if the resolver returned a non-empty struct with a dataSource
		if (IsStruct(local.tenant) && !StructIsEmpty(local.tenant) && StructKeyExists(local.tenant, "dataSource") && Len(local.tenant.dataSource)) {
			// Ensure required keys exist with defaults
			if (!StructKeyExists(local.tenant, "id")) {
				local.tenant.id = "";
			}
			if (!StructKeyExists(local.tenant, "config")) {
				local.tenant.config = {};
			}

			// Lock the tenant to prevent mid-request switching
			local.tenant["$locked"] = true;

			// Ensure request.wheels exists (ACF won't auto-create nested keys)
			if (!StructKeyExists(request, "wheels")) {
				request.wheels = {};
			}

			// Set on the built-in request scope (where $performQuery reads it)
			request.wheels.tenant = local.tenant;
		} else {
			if (IsDefined("request.wheels.tenant")) {
				// The resolver found no match. Drop any value already sitting on the key so a stale
				// or foreign one can't outlive resolution and be read downstream as a resolved
				// tenant — an unresolved request must look unresolved for the whole request (#3336).
				//
				// Guard with IsDefined on the full path, matching the finally block below. A
				// `StructKeyExists(request, "wheels")` guard is NOT equivalent here: this function
				// takes a parameter named `request`, and on Adobe 2025 the bare `request` token
				// resolves differently between the StructKeyExists argument and the `request.wheels`
				// member-access expression, so the guard passed and the delete then threw
				// `Element WHEELS is undefined in REQUEST`. IsDefined resolves the whole dotted path
				// in one evaluation, so it cannot disagree with itself.
				StructDelete(request.wheels, "tenant");
			}
			if (variables.failClosed) {
				try {
					cfheader(statusCode = "403");
				} catch (any e) {
				}
				return "Forbidden";
			}
		}

		try {
			return arguments.next(arguments.request);
		} finally {
			// Clean up tenant context from the built-in request scope
			if (IsDefined("request.wheels.tenant")) {
				StructDelete(request.wheels, "tenant");
			}
		}
	}

	/**
	 * Resolve tenant based on the configured strategy.
	 */
	private struct function $resolveTenant(required struct request) {
		switch (variables.strategy) {
			case "subdomain":
				return $resolveFromSubdomain(arguments.request);
			case "header":
				return $resolveFromHeader(arguments.request);
			case "custom":
			default:
				return $resolveFromCustom(arguments.request);
		}
	}

	/**
	 * Extract tenant identifier from the first subdomain segment
	 * and pass it to the resolver closure.
	 */
	private struct function $resolveFromSubdomain(required struct request) {
		local.serverName = "";
		if (StructKeyExists(arguments.request, "cgi") && StructKeyExists(arguments.request.cgi, "server_name")) {
			local.serverName = arguments.request.cgi.server_name;
		} else {
			try {
				local.serverName = cgi.server_name;
			} catch (any e) {
			}
		}

		if (!Len(local.serverName) || ListLen(local.serverName, ".") < 3) {
			return {};
		}

		local.subdomain = ListFirst(local.serverName, ".");

		// Expose the extracted subdomain so the resolver can use it
		arguments.request.$tenantSubdomain = local.subdomain;

		// Delegate to the resolver (if configured). Without a resolver there is
		// no way to map the subdomain to a dataSource, so the tenant stays unresolved.
		return $invokeResolver(arguments.request);
	}

	/**
	 * Extract tenant identifier from the configured HTTP header
	 * and pass it to the resolver closure.
	 */
	private struct function $resolveFromHeader(required struct request) {
		local.headerValue = "";
		local.cgiHeaderName = "http_" & Replace(LCase(variables.headerName), "-", "_", "all");

		if (StructKeyExists(arguments.request, "cgi") && StructKeyExists(arguments.request.cgi, local.cgiHeaderName)) {
			local.headerValue = arguments.request.cgi[local.cgiHeaderName];
		} else {
			try {
				if (StructKeyExists(cgi, local.cgiHeaderName)) {
					local.headerValue = cgi[local.cgiHeaderName];
				}
			} catch (any e) {
			}
		}

		if (!Len(local.headerValue)) {
			return {};
		}

		// Expose the extracted header value so the resolver can use it
		arguments.request.$tenantHeaderValue = local.headerValue;

		return $invokeResolver(arguments.request);
	}

	/**
	 * Delegate entirely to the user-provided resolver closure.
	 */
	private struct function $resolveFromCustom(required struct request) {
		return $invokeResolver(arguments.request);
	}

	/**
	 * Invoke the user-provided resolver closure with consistent result handling
	 * shared by all strategies. Returns an empty struct when no resolver is
	 * configured or when the resolver returns a non-struct value (such as
	 * `false`, the not-resolved sentinel).
	 */
	private struct function $invokeResolver(required struct request) {
		if (!IsSimpleValue(variables.resolver)) {
			local.result = variables.resolver(arguments.request);
			if (IsStruct(local.result)) {
				return local.result;
			}
		}
		return {};
	}

}
