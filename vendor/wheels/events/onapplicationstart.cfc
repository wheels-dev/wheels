component {

	// Boot-time sentinel meaning "the developer has not explicitly set
	// allowEnvironmentSwitchViaUrl". Must never escape $init(): the setting is
	// resolved back to a real boolean by $resolveAllowEnvironmentSwitchViaUrl()
	// right after the config/settings.cfm includes (issue #3031).
	variables.$envSwitchUnset = "__wheels_unset__";

	public void function $init(struct keys = {}) {

		// Embedding values from `Application.cfc`'s `this` scope into the current component's `this` scope.
		for (key in keys) {
			application[key] = keys[key];
		}

		// Abort if called from incorrect file.
		application.wo.$abortInvalidRequest();

		// Setup the Wheels storage struct for the current request.
		application.wo.$initializeRequestScope();

		if (StructKeyExists(application, "wheels")) {
			// Set or reset all settings but make sure to pass along the reload password between forced reloads with "reload=x".
			if (StructKeyExists(application.wheels, "reloadPassword")) {
				local.oldReloadPassword = application.wheels.reloadPassword;
			}
			// Check old environment for environment switch
			if (StructKeyExists(application.wheels, "allowEnvironmentSwitchViaUrl")) {
				local.allowEnvironmentSwitchViaUrl = application.wheels.allowEnvironmentSwitchViaUrl;
				local.oldEnvironment = application.wheels.environment;
			}
		}

		application.$wheels = {};
		if (StructKeyExists(local, "oldReloadPassword")) {
			application.$wheels.reloadPassword = local.oldReloadPassword;
		}

		// Check and store server engine name, throw error if using a version that we don't support.
		// Note: this must NOT be chained to the reloadPassword carryover above with `else` —
		// engine detection has to run unconditionally or serverVersion is never set.
		if (StructKeyExists(server, "boxlang")) {
			application.$wheels.serverName = "BoxLang";
			application.$wheels.serverVersion = server.boxlang.version;
		} else if (StructKeyExists(server, "lucee")) {
			application.$wheels.serverName = "Lucee";
			application.$wheels.serverVersion = server.lucee.version;
		} else if (
			StructKeyExists(server, "coldfusion")
			&& StructKeyExists(server.coldfusion, "productName")
			&& server.coldfusion.productName == "RustCFML"
		) {
			// RustCFML reports itself via server.coldfusion.productName (no
			// server.lucee / server.boxlang), so it must be detected before
			// the Adobe fallback below or it gets misclassified as Adobe CF.
			application.$wheels.serverName = "RustCFML";
			application.$wheels.serverVersion = server.coldfusion.productVersion;
		} else {
			application.$wheels.serverName = "Adobe ColdFusion";
			application.$wheels.serverVersion = server.coldfusion.productVersion;
		}
		application.$wheels.serverVersionMajor = ListFirst(application.$wheels.serverVersion, ".,");

		// Instantiate the engine adapter for centralized cross-engine behavior.
		if (application.$wheels.serverName == "BoxLang") {
			application.$wheels.engineAdapter = new wheels.engineAdapters.BoxLang.BoxLangAdapter(application.$wheels.serverVersion);
		} else if (application.$wheels.serverName == "Lucee") {
			application.$wheels.engineAdapter = new wheels.engineAdapters.Lucee.LuceeAdapter(application.$wheels.serverVersion);
		} else if (application.$wheels.serverName == "RustCFML") {
			application.$wheels.engineAdapter = new wheels.engineAdapters.RustCFML.RustCFMLAdapter(application.$wheels.serverVersion);
		} else {
			application.$wheels.engineAdapter = new wheels.engineAdapters.Adobe.AdobeAdapter(application.$wheels.serverVersion);
		}

		local.upgradeTo = application.wo.$checkMinimumVersion(
			engine = application.$wheels.serverName,
			version = application.$wheels.serverVersion
		);
		if (
			Len(local.upgradeTo)
			&& !StructKeyExists(application, "disableEngineCheck")
			&& !StructKeyExists(url, "disableEngineCheck")
		) {
			local.type = "Wheels.EngineNotSupported";
			local.message = "#application.$wheels.serverName# #application.$wheels.serverVersion# is not supported by Wheels.";
			if (IsBoolean(local.upgradeTo)) {
				Throw(type = local.type, message = local.message, extendedInfo = "Please use Lucee or Adobe ColdFusion instead.");
			} else {
				Throw(
					type = local.type,
					message = local.message,
					extendedInfo = "Please upgrade to version #local.upgradeTo# or higher."
				);
			}
		}

		// Copy over the CGI variables we need to the request scope.
		// Since we use some of these to determine URL rewrite capabilities we need to be able to access them directly on application start for example.
		request.cgi = application.wo.$cgiScope();

		// Set up containers for routes, caches, settings etc.
		// BuildInfo is the authoritative source for version + build metadata.
		// Cached on the app scope; values cannot change without a full restart.
		application.$wheels.buildInfo = new wheels.BuildInfo();
		application.$wheels.version = application.$wheels.buildInfo.version();
		try {
			application.$wheels.hostName = CreateObject("java", "java.net.InetAddress").getLocalHost().getHostName();
		} catch (any e) {
		}
		application.$wheels.controllers = {};
		application.$wheels.models = {};
		// Per-app column-metadata cache (see databaseAdapters/Base.cfc $getColumns).
		// Deliberately a SIBLING of `cache`, not a `cache.*` category: it stores raw
		// query objects that live for the application lifetime, whereas every
		// `cache.*` category holds {value, expiresAt} envelopes that the cull/count
		// machinery ($addToCache / $cacheCount) walks and dereferences `.expiresAt`
		// on. Putting schema queries under `cache.*` makes the cull throw.
		application.$wheels.schemaColumnCache = {};
		application.$wheels.helperFileCache = {};
		application.$wheels.layoutFileCache = {};
		application.$wheels.existingObjectFiles = {};
		application.$wheels.nonExistingObjectFiles = {};
		application.$wheels.directoryFiles = {};
		application.$wheels.routes = [];
		application.$wheels.middleware = [];
		application.$wheels.pluginMiddleware = [];
		application.$wheels.resourceControllerNaming = "plural";
		application.$wheels.namedRoutePositions = {};
		application.$wheels.mixins = {};
		application.$wheels.cache = {};
		application.$wheels.cache.sql = {};
		application.$wheels.cache.image = {};
		application.$wheels.cache.main = {};
		application.$wheels.cache.action = {};
		application.$wheels.cache.page = {};
		application.$wheels.cache.partial = {};
		application.$wheels.cache.query = {};
		application.$wheels.cacheLastCulledAt = Now();

		// Set up paths to various folders in the framework. When the app
		// is deployed under a URL subpath (issue #2968), cgi.script_name
		// may not match the public mount point — typical with CommandBox
		// single-site → IIS subfolder migrations or reverse proxies that
		// fold `/public/` out of the URL. The default derivation runs
		// first so paths exist for any code that consumes them between
		// here and the config/settings.cfm include below; the override
		// (`set(subpath="/wheelsproject1")` or `WHEELS_SUBPATH` env var)
		// is reapplied after settings.cfm loads.
		local.paths = application.wo.$resolveFrameworkPaths(scriptName = request.cgi.script_name);
		application.$wheels.webPath = local.paths.webPath;
		application.$wheels.rootPath = local.paths.rootPath;
		application.$wheels.rootcomponentPath = local.paths.rootcomponentPath;
		application.$wheels.wheelsComponentPath = local.paths.wheelsComponentPath;

		// Check old environment to see whether we're allowed to switch configuration.
		// The setting boots as a non-boolean sentinel (NOT `true`) so that an explicit
		// set(allowEnvironmentSwitchViaUrl=true) in config/settings.cfm is distinguishable
		// from "the developer never set it" — see $resolveAllowEnvironmentSwitchViaUrl()
		// below, which runs right after the settings includes and always resolves the
		// setting back to a real boolean (issue #3031). The sentinel only ever exists
		// between here and that resolution point within a single application start.
		application.$wheels.allowEnvironmentSwitchViaUrl = variables.$envSwitchUnset;
		if (StructKeyExists(local, "allowEnvironmentSwitchViaUrl") && !local.allowEnvironmentSwitchViaUrl) {
			application.$wheels.allowEnvironmentSwitchViaUrl = false;
		}

		// Rate limit reload attempts: 5 failed password attempts within 5 minutes locks the IP
		if (!StructKeyExists(application, "$reloadRateLimit")) {
			application.$reloadRateLimit = {};
		}
		// Key on the trusted client IP: the socket address unless the running app's
		// trustProxyHeaders setting opted into X-Forwarded-For (rightmost hop). On a cold
		// start application.wheels does not exist yet, so trust resolves to false and the
		// key falls back to the socket address.
		local.reloadRateLimitKey = application.wo.$trustedClientIp();
		local.reloadRateLimited = false;
		if (StructKeyExists(application.$reloadRateLimit, local.reloadRateLimitKey)) {
			local.rl = application.$reloadRateLimit[local.reloadRateLimitKey];
			if (local.rl.count >= 5 && DateDiff("n", local.rl.firstAttempt, Now()) < 5) {
				local.reloadRateLimited = true;
			}
			if (DateDiff("n", local.rl.firstAttempt, Now()) >= 5) {
				StructDelete(application.$reloadRateLimit, local.reloadRateLimitKey);
			}
		}

		// Set environment either from the url or the developer's environment.cfm file.
		local.reloadPasswordMatched = false;
		if (
			!local.reloadRateLimited
			&& StructKeyExists(URL, "reload")
			&& !IsBoolean(URL.reload)
			&& Len(url.reload)
			&& StructKeyExists(application.$wheels, "reloadPassword")
			&& Len(application.$wheels.reloadPassword)
			&& StructKeyExists(URL, "password")
			&& application.wo.$secureCompare(URL.password, application.$wheels.reloadPassword)
		) {
			local.reloadPasswordMatched = true;
			application.$wheels.environment = URL.reload;
			try {
				writeLog(
					file="wheels_security",
					type="warning",
					text="Environment switched to '" & URL.reload & "' via URL from " & local.reloadRateLimitKey
				);
			} catch (any e) {
				// Fail silently if logging fails
			}
		} else {
			application.wo.$include(template = "/config/environment.cfm");
		}

		// Track failed reload password attempts
		if (
			StructKeyExists(URL, "reload")
			&& StructKeyExists(URL, "password")
			&& !local.reloadRateLimited
			&& !local.reloadPasswordMatched
		) {
			if (!StructKeyExists(application.$reloadRateLimit, local.reloadRateLimitKey)) {
				application.$reloadRateLimit[local.reloadRateLimitKey] = {count: 0, firstAttempt: Now()};
			}
			application.$reloadRateLimit[local.reloadRateLimitKey].count++;
			try {
				writeLog(file="wheels_security", type="warning", text="Reload password rejected from #local.reloadRateLimitKey#");
			} catch (any e) {
			}
		}

		// Log successful reload
		if (local.reloadPasswordMatched) {
			try {
				writeLog(file="wheels_security", type="information", text="Reload accepted from #local.reloadRateLimitKey# (environment: #URL.reload#)");
			} catch (any e) {
			}
		}

		// If we're not allowed to switch, override and replace with the old environment.
		// At this point the setting can still be the boot sentinel (= "not explicitly
		// set", which historically meant `true` here), so only an explicit or
		// carried-over boolean false blocks the switch.
		if (
			IsBoolean(application.$wheels.allowEnvironmentSwitchViaUrl)
			&& !application.$wheels.allowEnvironmentSwitchViaUrl
			&& StructKeyExists(local, "oldEnvironment")
		) {
			application.$wheels.environment = local.oldEnvironment;
		}

		// Rewrite settings based on web server rewrite capabilites.
		application.$wheels.rewriteFile = "index.cfm";
		if (Right(request.cgi.script_name, 12) == "/" & application.$wheels.rewriteFile) {
			application.$wheels.URLRewriting = "On";
		} else if (Len(request.cgi.path_info)) {
			application.$wheels.URLRewriting = "Partial";
		} else {
			application.$wheels.URLRewriting = "Off";
		}

		// Set datasource name to same as the folder the app resides in unless the developer has set it with the global setting already.
		if (StructKeyExists(application, "dataSource")) {
			application.$wheels.dataSourceName = application.dataSource;
		} else {
			application.$wheels.dataSourceName = LCase(
				ListLast(GetDirectoryFromPath(GetBaseTemplatePath()), Right(GetDirectoryFromPath(GetBaseTemplatePath()), 1))
			);
		}

		// Set the coreTestDatasourceName to the application dataSourceName if it doesn't exits
		if (!StructKeyExists(application.$wheels, "coreTestDataSourceName")) {
			application.$wheels.coreTestDataSourceName = application.$wheels.dataSourceName;
		}

		// Test framework: "testbox" (default) or "rocketunit"
		if (!StructKeyExists(application.$wheels, "testFramework")) {
			application.$wheels.testFramework = "testbox";
		}

		// Enable or disable major components
		application.$wheels.enablePluginsComponent = true;
		application.$wheels.enableMigratorComponent = true;
		application.$wheels.enablePublicComponent = false;
		if (application.$wheels.environment == "development") {
			application.$wheels.enablePublicComponent = true;
		}

		// Create migrations object and set default settings.
		application.$wheels.autoMigrateDatabase = false;
		// New default names (F15 Phase 1). The migrator's $detectSystemTables()
		// helper at runtime will flip these back to the legacy `c_o_r_e_*`
		// names if it finds those tables already in the database, so existing
		// 4.0-SNAPSHOT apps continue to work without manual intervention.
		// New installs get the clean `wheels_*` prefix.
		application.$wheels.migratorTableName = "wheels_migrator_versions";
		application.$wheels.levelsTableName = "wheels_levels";
		application.$wheels.createMigratorTable = true;
		application.$wheels.writeMigratorSQLFiles = false;
		// Preserve column / table / index name case as written in the migration.
		// Set to "lower" or "upper" to fold names. Issue #2313 (F19): the
		// previous "lower" default silently rewrote `t.string("publishedAt")`
		// into a `publishedat` column on case-preserving engines (notably
		// SQLite), which surprised users. Apps that depended on the old
		// behavior can opt back in via `set("migratorObjectCase", "lower")`
		// in `config/settings.cfm`.
		application.$wheels.migratorObjectCase = "";
		application.$wheels.allowMigrationDown = false;
		application.$wheels.migrationLevel = 1;
		if (application.$wheels.environment == "development") {
			application.$wheels.allowMigrationDown = true;
		}

		// Load domain-specific settings from includes
		include "/wheels/events/init/caching.cfm";
		include "/wheels/events/init/security.cfm";
		include "/wheels/events/init/debugging.cfm";
		include "/wheels/events/init/orm.cfm";
		include "/wheels/events/init/views.cfm";
		include "/wheels/events/init/formats.cfm";
		include "/wheels/events/init/functions.cfm";

		// Set a flag to indicate that all settings have been loaded.
		application.$wheels.initialized = true;

		// Load general developer settings first, then override with environment specific ones.
		// $includeConfig captures any output the file produces and warns via the application
		// log if non-empty — usually the signal that a config/*.cfm file is missing its
		// cfscript wrapper, in which case the engine parses cfscript-style code as markup
		// and the registrations silently never run. (Note: Lucee 7's tag scanner reads
		// CFC comments before compilation and treats literal cf-tags as unclosed errors,
		// so this comment deliberately avoids putting the angle-bracketed form inline.)
		application.wo.$includeConfig(template = "/config/settings.cfm");
		if (FileExists(ExpandPath("/config/#application.$wheels.environment#/settings.cfm"))) {
			application.wo.$includeConfig(template = "/config/#application.$wheels.environment#/settings.cfm");
		}

		// Re-derive framework paths now that settings.cfm has loaded. Detection
		// priority for the URL subpath (issue #2968):
		//   1. set(subpath="/wheelsproject1") in config/settings.cfm
		//   2. WHEELS_SUBPATH environment variable (CommandBox / IIS deploys)
		//   3. existing cgi.script_name derivation (no-op when both are empty)
		// `server.system.environment` is the cross-engine-safe env read; Lucee's
		// `getSystemSetting()` is not portable.
		local.configuredSubpath = "";
		if (StructKeyExists(application.$wheels, "subpath") && Len(Trim(application.$wheels.subpath))) {
			local.configuredSubpath = application.$wheels.subpath;
		} else if (
			StructKeyExists(server, "system")
			&& StructKeyExists(server.system, "environment")
			&& StructKeyExists(server.system.environment, "WHEELS_SUBPATH")
			&& Len(Trim(server.system.environment.WHEELS_SUBPATH))
		) {
			local.configuredSubpath = server.system.environment.WHEELS_SUBPATH;
		}
		if (Len(local.configuredSubpath)) {
			local.paths = application.wo.$resolveFrameworkPaths(
				scriptName = request.cgi.script_name,
				subpath = local.configuredSubpath
			);
			application.$wheels.webPath = local.paths.webPath;
			application.$wheels.rootPath = local.paths.rootPath;
			application.$wheels.rootcomponentPath = local.paths.rootcomponentPath;
			application.$wheels.wheelsComponentPath = local.paths.wheelsComponentPath;
			application.$wheels.subpath = local.configuredSubpath;
		}

		// Resolve allowEnvironmentSwitchViaUrl to a real boolean now that the developer's
		// settings have loaded. If it is still the boot sentinel the framework default
		// applies: disabled in production-like environments, enabled everywhere else.
		// An explicit boolean from config/settings.cfm — including explicit `true`, which
		// used to be indistinguishable from the default and silently discarded — is
		// honored as-is in every environment (issue #3031).
		application.$wheels.allowEnvironmentSwitchViaUrl = $resolveAllowEnvironmentSwitchViaUrl(
			settingValue = application.$wheels.allowEnvironmentSwitchViaUrl,
			environment = application.$wheels.environment
		);

		// Warn if reloadPassword is empty — URL-based reload and environment switching are disabled.
		if (!Len(application.$wheels.reloadPassword)) {
			try {
				writeLog(file="wheels_security", type="warning", text="Wheels: reloadPassword is empty — URL-based environment switching and application reload are disabled until a password is set in config/settings.cfm");
			} catch (any e) {}
		}

		// Load DI service registrations. $includeConfig captures any output the file
		// produces — see the matching note on the settings.cfm include above.
		if (FileExists(ExpandPath("/config/services.cfm"))) {
			application.wo.$includeConfig(template = "/config/services.cfm");
		}
		// Environment-specific services override.
		if (FileExists(ExpandPath("/config/#application.$wheels.environment#/services.cfm"))) {
			application.wo.$includeConfig(template = "/config/#application.$wheels.environment#/services.cfm");
		}

		// Clear query (cfquery) and page (cfcache) caches.
		if (application.$wheels.clearQueryCacheOnReload or !StructKeyExists(application.$wheels, "cacheKey")) {
			application.$wheels.cacheKey = Hash(CreateUUID());
		}
		if (application.$wheels.clearTemplateCacheOnReload) {
			application.wo.$cache(action = "flush");
		}

		// Build the list of public framework helper methods mixed onto every
		// controller (from wheels.Global + wheels.controller.* + wheels.view.*).
		// $callAction() in vendor/wheels/controller/processing.cfc rejects any
		// request whose action segment matches one of these names so global
		// helpers like env(), model(), redirectTo() are never URL-invokable.
		application.$wheels.protectedControllerMethods = application.wo.$buildProtectedControllerMethods();

		// Companion struct-as-set for O(1) membership checks on the dispatch hot
		// path (see $callAction()); the comma-list above is kept for callers that
		// expect that shape.
		application.$wheels.protectedControllerMethodsLookup = application.wo.$protectedControllerMethodsLookup(
			application.$wheels.protectedControllerMethods
		);

		// Enable the main GUI Component
		if (application.$wheels.enablePublicComponent) {
			application.$wheels.public = application.wo.$createObjectFromRoot(path = "wheels", fileName = "Public", method = "$init");
		}

		// Reload the plugins each time we reload the application.
		if (application.$wheels.enablePluginsComponent) {
			application.wo.$loadPlugins();
		}

		// Discover and load packages from vendor/ (after plugins, before mixin injection).
		if (application.$wheels.enablePackagesComponent) {
			application.wo.$loadPackages();
		}

		// Allow developers to inject plugins and packages into the application variables scope.
		if (!StructIsEmpty(application.$wheels.mixins)) {
			application.$wheels.engineAdapter.prepareDIComplete(variables, this);
			new wheels.Plugins().$initializeMixins(variables);
		}

		// Create the mapper that will handle creating routes.
		// Needs to be before $loadRoutes and after $loadPlugins/$loadPackages.
		application.$wheels.mapper = application.wo.$createObjectFromRoot(path = "wheels", fileName = "Mapper", method = "$init");

		// Load developer routes and adds the default Wheels routes (unless the developer has specified not to).
		application.wo.$loadRoutes();

		// Create the dispatcher that will handle all incoming requests.
		application.$wheels.dispatch = application.wo.$createObjectFromRoot(path = "wheels", fileName = "Dispatch", method = "$init");

		// Snapshot the app/global/*.cfm mtimes so the per-request soft-reload
		// check (in $runOnRequestStart) has a baseline to compare against.
		application.$wheels.globalIncludesSnapshot = application.wo.$snapshotGlobalIncludes();

		// Assign it all to the application scope in one atomic call.
		application.wheels = application.$wheels;
		StructDelete(application, "$wheels");

		// Enable the migrator component
		if (application.wheels.enableMigratorComponent) {
			application.wheels.migrator = application.wo.$createObjectFromRoot(path = "wheels", fileName = "Migrator", method = "init");
		}

		// Initialize the seeder component (always available when migrator is enabled)
		if (application.wheels.enableMigratorComponent) {
			application.wheels.seeder = application.wo.$createObjectFromRoot(path = "wheels", fileName = "Seeder", method = "init");
		}

		// Run the developer's on application start code.
		application.wo.$include(template = "#application.wheels.eventPath#/onapplicationstart.cfm");

		// Dev-mode: verify interface contracts after all mixins are loaded
		if (application.wheels.environment == "development") {
			application.wo.$verifyInterfaceContracts();
		}

		// Auto Migrate Database if requested
		if (application.wheels.enableMigratorComponent && application.wheels.autoMigrateDatabase) {
			application.wheels.migrator.migrateToLatest();
		}

		// Redirect away from reloads on GET requests.
		if (application.wheels.redirectAfterReload && StructKeyExists(url, "reload") && cgi.request_method == "get") {
			if (StructKeyExists(cgi, "path_info") && Len(cgi.path_info)) {
				local.url = cgi.path_info;
			} else if (StructKeyExists(cgi, "path_info")) {
				local.url = "/";
			} else {
				local.url = cgi.script_name;
			}
			local.oldQueryString = ListToArray(cgi.query_string, "&");
			local.newQueryString = [];
			local.iEnd = ArrayLen(local.oldQueryString);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.keyValue = local.oldQueryString[local.i];
				local.key = ListFirst(local.keyValue, "=");
				if (!ListFindNoCase("reload,password,lock", local.key)) {
					ArrayAppend(local.newQueryString, local.keyValue);
				}
			}
			if (ArrayLen(local.newQueryString)) {
				local.queryString = ArrayToList(local.newQueryString, "&");
				local.url = "#local.url#?#local.queryString#";
			}
			// Defer the actual redirect to EventMethods.$runOnRequestStart (issue #3054).
			// Two reasons this block must not redirect directly:
			// 1. This component is a plain `component {` with no extends and no mixins,
			//    so framework helpers like $location() (vendor/wheels/Global.cfc) are not
			//    in scope — the bare $location() that used to sit here threw "No matching
			//    function [$LOCATION] found" during the post-switch cold start.
			// 2. Even a resolvable cflocation is wrong here: it aborts the request while
			//    onApplicationStart is still running, the engine then discards the
			//    half-started application, and the next request cold-starts from
			//    config/environment.cfm — silently reverting URL environment switches
			//    into production/maintenance (the two environments that auto-enable
			//    redirectAfterReload, see events/init/orm.cfm). Verified on Lucee 7.
			// The request scope survives into $runOnRequestStart, which runs in this
			// same request after the application (including a switched environment)
			// has been fully initialized and persisted, so aborting there is safe.
			request.wheels.redirectAfterReloadUrl = local.url;
		}
	}

	/**
	 * Resolves the allowEnvironmentSwitchViaUrl setting to a real boolean after the
	 * config/settings.cfm includes have run. Any explicit boolean the developer set is
	 * honored as-is in every environment — this is what makes the documented production
	 * override set(allowEnvironmentSwitchViaUrl=true) actually work (issue #3031).
	 * A non-boolean value means the developer never touched the setting (it still holds
	 * the boot sentinel), so the framework default applies: disabled in production-like
	 * environments, enabled everywhere else.
	 */
	public boolean function $resolveAllowEnvironmentSwitchViaUrl(
		required any settingValue,
		required string environment
	) {
		if (IsBoolean(arguments.settingValue)) {
			return arguments.settingValue;
		}
		return !ListFindNoCase("production,testing,maintenance", arguments.environment);
	}
}
