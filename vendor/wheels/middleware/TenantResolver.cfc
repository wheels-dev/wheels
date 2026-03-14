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
 *         var t = model("Tenant").findOne(where="subdomain='#subdomain#'");
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
	 */
	public TenantResolver function init(
		any resolver,
		string strategy = "custom",
		string headerName = "X-Tenant-ID"
	) {
		variables.strategy = arguments.strategy;
		variables.headerName = arguments.headerName;

		if (StructKeyExists(arguments, "resolver") && IsClosure(arguments.resolver)) {
			variables.resolver = arguments.resolver;
		} else {
			variables.resolver = JavaCast("null", "");
		}

		return this;
	}

	/**
	 * Resolve the tenant, set request.wheels.tenant, then delegate to the next middleware.
	 */
	public string function handle(required struct request, required any next) {
		// Note: In CFML, bare `request` inside a function always refers to the
		// built-in request scope, even when a parameter is named `request`.
		// We use `arguments.request` to access the middleware pipeline's request struct,
		// but set tenant state on the built-in `request` scope since that's what
		// $performQuery() and $get() read from.

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

			// Set on the built-in request scope (where $performQuery reads it)
			request.wheels.tenant = local.tenant;
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

		// If a custom resolver is provided, pass the request to it
		if (!IsNull(variables.resolver)) {
			return variables.resolver(arguments.request);
		}

		// Without a resolver, return just the subdomain as the ID (user must provide dataSource via resolver)
		return {};
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

		// If a custom resolver is provided, pass the request to it
		if (!IsNull(variables.resolver)) {
			return variables.resolver(arguments.request);
		}

		return {};
	}

	/**
	 * Delegate entirely to the user-provided resolver closure.
	 */
	private struct function $resolveFromCustom(required struct request) {
		if (!IsNull(variables.resolver)) {
			local.result = variables.resolver(arguments.request);
			if (IsStruct(local.result)) {
				return local.result;
			}
		}
		return {};
	}

}
