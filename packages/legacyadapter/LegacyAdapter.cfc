/**
 * wheels-legacy-adapter — Backward compatibility for Wheels 3.x applications.
 *
 * Provides deprecated API shims that delegate to current 4.0 implementations
 * while logging deprecation warnings. Install this package to ease migration
 * from 3.x to 4.0.
 *
 * Migration stages:
 *   Stage 1: Install adapter — existing code works unchanged
 *   Stage 2: Use migration scanner, update code incrementally
 *   Stage 3: Remove adapter when all legacy patterns eliminated
 *
 * Configuration (in config/settings.cfm):
 *   set(legacyAdapterMode = "log")   — silent, log, warn, or error
 */
component mixin="controller" output="false" {

	function init() {
		this.version = "1.0.0";
		$initLegacyAdapter();
		return this;
	}

	/**
	 * Initialize the deprecation logger instance.
	 * Reads mode from Wheels settings if available, falls back to "log".
	 */
	public void function $initLegacyAdapter() {
		var mode = "log";
		try {
			mode = get("legacyAdapterMode");
		} catch (any e) {
			/* setting not configured — use default */
		}
		variables.$legacyAdapterLogger = new DeprecationLogger(mode = mode);
	}

	/**
	 * Returns the adapter version string.
	 */
	public string function $legacyAdapterVersion() {
		return "1.0.0";
	}

	/**
	 * Returns a summary of the adapter status and any deprecations in this request.
	 */
	public struct function $legacyAdapterStatus() {
		var logger = $getLegacyLogger();
		return {
			version: $legacyAdapterVersion(),
			mode: logger.getMode(),
			deprecationsThisRequest: logger.getRequestDeprecationCount(),
			entries: logger.getRequestDeprecations()
		};
	}

	/* ------------------------------------------------------------------ */
	/*  Controller Shims                                                  */
	/* ------------------------------------------------------------------ */

	/**
	 * DEPRECATED: Use renderView() instead.
	 *
	 * Legacy shim for Wheels 1.x/2.x renderPage() method.
	 * Delegates to renderView() with all arguments passed through.
	 */
	public any function renderPage() {
		$getLegacyLogger().logDeprecation(
			oldMethod = "renderPage()",
			newMethod = "renderView()",
			message = "renderPage() was renamed in Wheels 3.0. Update your controller actions."
		);
		return renderView(argumentCollection = arguments);
	}

	/**
	 * DEPRECATED: Use renderView(returnAs="string") instead.
	 *
	 * Legacy shim for Wheels 1.x/2.x renderPageToString() method.
	 */
	public string function renderPageToString() {
		$getLegacyLogger().logDeprecation(
			oldMethod = "renderPageToString()",
			newMethod = "renderView(returnAs=""string"")",
			message = "renderPageToString() was removed in Wheels 3.0. Use renderView(returnAs=""string"") instead."
		);
		arguments.returnAs = "string";
		return renderView(argumentCollection = arguments);
	}

	/**
	 * DEPRECATED: Use sendEmail() with updated argument names.
	 *
	 * Legacy shim that maps old sendEmail argument names to current ones.
	 * In Wheels 2.x, the layout argument defaulted differently.
	 */
	public any function $legacySendEmail() {
		$getLegacyLogger().logDeprecation(
			oldMethod = "$legacySendEmail()",
			newMethod = "sendEmail()",
			message = "Use the standard sendEmail() function directly."
		);
		return sendEmail(argumentCollection = arguments);
	}

	/* ------------------------------------------------------------------ */
	/*  View Helper Shims                                                 */
	/* ------------------------------------------------------------------ */

	/**
	 * DEPRECATED: Use paginationNav() or the composable pagination helpers instead.
	 *
	 * This shim preserves the old paginationLinks() default markup behavior
	 * for applications that depend on the legacy HTML structure.
	 * The core paginationLinks() still exists in 4.0, so this is a no-op
	 * shim that just logs the deprecation.
	 */
	public string function $legacyPaginationLinks() {
		$getLegacyLogger().logDeprecation(
			oldMethod = "paginationLinks()",
			newMethod = "paginationNav()",
			message = "paginationLinks() still works but paginationNav() provides better composability. See: https://wheels.dev/docs/pagination"
		);
		return paginationLinks(argumentCollection = arguments);
	}

	/* ------------------------------------------------------------------ */
	/*  Configuration Shims                                               */
	/* ------------------------------------------------------------------ */

	/**
	 * DEPRECATED: Use the DI container via service() and injector() instead.
	 *
	 * Returns a value from the application.wheels struct, which was the
	 * pre-4.0 way to access framework internals. Logs deprecation.
	 *
	 * @key The application.wheels key to read
	 */
	public any function $legacyAppScopeGet(required string key) {
		$getLegacyLogger().logDeprecation(
			oldMethod = "application.wheels.#arguments.key#",
			newMethod = "service() or injector()",
			message = "Direct application.wheels access is discouraged. Use the DI container for service resolution."
		);
		var appKey = "$wheels";
		if (StructKeyExists(application, "wheels")) {
			appKey = "wheels";
		}
		if (StructKeyExists(application[appKey], arguments.key)) {
			return application[appKey][arguments.key];
		}
		Throw(
			type = "Wheels.LegacyAdapter.KeyNotFound",
			message = "Key '#arguments.key#' not found in application scope."
		);
	}

	/* ------------------------------------------------------------------ */
	/*  Plugin Compatibility Helpers                                      */
	/* ------------------------------------------------------------------ */

	/**
	 * Checks whether legacy plugins are loaded and returns info about them.
	 * Useful during migration to identify plugins that need conversion to packages.
	 */
	public struct function $legacyPluginInfo() {
		var info = {plugins: [], hasLegacyPlugins: false};
		var appKey = "$wheels";
		if (StructKeyExists(application, "wheels")) {
			appKey = "wheels";
		}
		if (StructKeyExists(application[appKey], "plugins")) {
			var pluginStruct = application[appKey].plugins;
			info.hasLegacyPlugins = !StructIsEmpty(pluginStruct);
			for (var key in pluginStruct) {
				ArrayAppend(info.plugins, {
					name: key,
					version: StructKeyExists(pluginStruct[key], "version") ? pluginStruct[key].version : "unknown"
				});
			}
		}
		return info;
	}

	/* ------------------------------------------------------------------ */
	/*  Migration Scanner Access                                          */
	/* ------------------------------------------------------------------ */

	/**
	 * Runs the migration scanner against the application directory.
	 * Returns a structured report of legacy patterns found.
	 *
	 * @appPath Path to scan (defaults to the app/ directory)
	 */
	public struct function $runMigrationScan(string appPath = "") {
		if (!Len(arguments.appPath)) {
			arguments.appPath = ExpandPath("/app");
		}
		var scanner = new MigrationScanner();
		return scanner.scan(appPath = arguments.appPath);
	}

	/* ------------------------------------------------------------------ */
	/*  Internal Helpers                                                   */
	/* ------------------------------------------------------------------ */

	/**
	 * Returns the deprecation logger, initializing if needed.
	 */
	public any function $getLegacyLogger() {
		if (!StructKeyExists(variables, "$legacyAdapterLogger")) {
			$initLegacyAdapter();
		}
		return variables.$legacyAdapterLogger;
	}

}
