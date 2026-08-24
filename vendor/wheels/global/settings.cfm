<cfscript>
/**
 * wheels.Global include: settings
 * get / set / env and multi-tenant helpers.
 *
 * Included from `vendor/wheels/Global.cfc` at component-body scope so
 * these functions compile into the Global component. Children inherit
 * them; there is no per-instance mixin copy. Keep every helper that
 * must mix onto models/controllers `public` and `$`-prefixed
 * (cross-engine invariant 7).
 */


	/**
	 * Returns the current setting for the supplied Wheels setting or the current default for the supplied Wheels function argument.
	 *
	 * [section: Configuration]
	 * [category: Miscellaneous Functions]
	 *
	 * @name Variable name to get setting for.
	 * @functionName Function name to get setting for.
	 */
	public any function get(required string name, string functionName = "") {
		return $get(argumentCollection = arguments);
	}


	/**
	 * Returns the value of an environment variable. Checks application.env (loaded from .env files) first, then falls back to system environment variables (server.system.environment). Returns the default if the variable is not found in either location.
	 *
	 * [section: Configuration]
	 * [category: Miscellaneous Functions]
	 *
	 * @name The environment variable name to look up.
	 * @defaultValue Value to return if the variable is not found. The legacy
	 *   named argument `default` is also accepted for backwards compatibility
	 *   with pre-rename callers.
	 */
	public any function env(required string name, any defaultValue = "") {
		if (StructKeyExists(application, "env") && StructKeyExists(application.env, arguments.name)) {
			return application.env[arguments.name];
		}
		if (
			StructKeyExists(server, "system")
			&& StructKeyExists(server.system, "environment")
			&& StructKeyExists(server.system.environment, arguments.name)
		) {
			return server.system.environment[arguments.name];
		}
		// Back-compat for the legacy `default = "Y"` named-arg form. The
		// parameter was renamed from `default` (a CFML reserved word Adobe CF
		// refuses to bind) to `defaultValue`; named arguments still land in
		// `arguments` under their literal key on every engine.
		if (StructKeyExists(arguments, "default")) {
			return arguments.default;
		}
		return arguments.defaultValue;
	}


	/**
	 * Use to configure a global setting or set a default for a function.
	 *
	 * [section: Configuration]
	 * [category: Miscellaneous Functions]
	 */
	public void function set() {
		$set(argumentCollection = arguments);
	}


	/**
	 * Internal function.
	 * Called from get().
	 */
	public any function $get(required string name, string functionName = "") {
		// Multi-tenant config override: per-tenant settings take precedence
		// over application-level settings (non-function settings only).
		// Security-sensitive settings cannot be overridden per-tenant.
		// Use a StructKeyExists chain for safe nested scope traversal during app
		// startup (IsDefined string-parses its dotted-path argument on every call
		// and $get runs on every settings read so it's too expensive here).
		if (
			!Len(arguments.functionName)
			&& StructKeyExists(request, "wheels")
			&& StructKeyExists(request.wheels, "tenant")
			&& StructKeyExists(request.wheels.tenant, "config")
			&& StructKeyExists(request.wheels.tenant.config, arguments.name)
			&& !ListFindNoCase(
				"encryptionAlgorithm,encryptionSecretKey,encryptionEncoding,CSRFProtection,csrfStore,reloadPassword,obfuscateUrls,massAssignmentStrict",
				arguments.name
			)
		) {
			return request.wheels.tenant.config[arguments.name];
		}
		local.appKey = $appKey();
		if (Len(arguments.functionName)) {
			local.rv = application[local.appKey].functions[arguments.functionName][arguments.name];
		} else {
			local.rv = application[local.appKey][arguments.name];
		}
		return local.rv;
	}


	/**
	 * Internal function.
	 * Called from set().
	 */
	public void function $set() {
		local.appKey = $appKey();
		if (ArrayLen(arguments) > 1) {
			for (local.key in arguments) {
				if (local.key != "functionName") {
					local.functionNameArray = ListToArray(arguments.functionName);
					local.iEnd = ArrayLen(local.functionNameArray);
					for (local.i = 1; local.i <= local.iEnd; local.i++) {
						local.functionName = Trim(local.functionNameArray[local.i]);
						application[local.appKey].functions[local.functionName][local.key] = arguments[local.key];
					}
				}
			}
		} else {
			application[local.appKey][StructKeyList(arguments)] = arguments[1];
		}
	}


	// ======================================================================
	// MULTI-TENANCY FUNCTIONS
	// ======================================================================

	/**
	 * Returns the current tenant struct, or an empty struct if no tenant is active.
	 * The tenant struct contains: `id`, `dataSource`, `config`, and `$locked`.
	 *
	 * A tenant only counts as active when it carries a non-empty `dataSource` — the same test
	 * `$tenantDataSource()` applies before it routes a query. Anything else on the key reads as
	 * no tenant rather than being handed back as though it were a resolved one, so a malformed
	 * value degrades to a no-op instead of wrong behaviour (#3336). Every framework producer
	 * (`switchTenant()`, `TenantResolver`, `Job.$restoreTenantContext()`, `TenantMigrator`)
	 * already guarantees a non-empty `dataSource`, so this only filters foreign values.
	 *
	 * [section: Configuration]
	 * [category: Multi-Tenancy]
	 */
	public struct function tenant() {
		if (
			IsDefined("request.wheels.tenant")
			&& IsStruct(request.wheels.tenant)
			&& StructKeyExists(request.wheels.tenant, "dataSource")
			&& Len(request.wheels.tenant.dataSource)
		) {
			return request.wheels.tenant;
		}
		return {};
	}


	/**
	 * Returns the current tenant's datasource name, or the application default if no tenant is active.
	 *
	 * [section: Configuration]
	 * [category: Multi-Tenancy]
	 */
	public string function $tenantDataSource() {
		if (
			IsDefined("request.wheels.tenant.dataSource")
			&& Len(request.wheels.tenant.dataSource)
		) {
			return request.wheels.tenant.dataSource;
		}
		return $get("dataSourceName");
	}


	/**
	 * Switches the active tenant mid-request. Throws if the current tenant is locked
	 * (set by TenantResolver middleware) unless `force` is true.
	 *
	 * [section: Configuration]
	 * [category: Multi-Tenancy]
	 *
	 * @tenant Struct with at minimum a `dataSource` key. Optional: `id`, `config`.
	 * @force If true, overrides the lock set by TenantResolver middleware.
	 */
	public void function switchTenant(required struct tenant, boolean force = false) {
		if (!StructKeyExists(arguments.tenant, "dataSource") || !Len(arguments.tenant.dataSource)) {
			Throw(type = "Wheels.InvalidTenant", message = "The tenant struct must contain a non-empty `dataSource` key.");
		}
		if (!StructKeyExists(request, "wheels")) {
			request.wheels = {};
		}
		// Check if current tenant is locked
		if (
			!arguments.force
			&& IsDefined("request.wheels.tenant")
			&& StructKeyExists(request.wheels.tenant, "$locked")
			&& request.wheels.tenant["$locked"]
		) {
			Throw(
				type = "Wheels.TenantLocked",
				message = "Cannot switch tenants mid-request. The current tenant was set by middleware and is locked.",
				extendedInfo = "Use `switchTenant(tenant={...}, force=true)` to override, or remove the lock in your middleware configuration."
			);
		}
		// Set defaults
		if (!StructKeyExists(arguments.tenant, "id")) {
			arguments.tenant.id = "";
		}
		if (!StructKeyExists(arguments.tenant, "config")) {
			arguments.tenant.config = {};
		}
		request.wheels.tenant = arguments.tenant;
	}
</cfscript>
