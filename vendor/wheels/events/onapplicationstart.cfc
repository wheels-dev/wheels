component {


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
		else if (StructKeyExists(server, "boxlang")) {
			application.$wheels.serverName = "BoxLang";
			application.$wheels.serverVersion = server.boxlang.version;
		} else if (StructKeyExists(server, "lucee")) {
			application.$wheels.serverName = "Lucee";
			application.$wheels.serverVersion = server.lucee.version;
		} else {
			application.$wheels.serverName = "Adobe ColdFusion";
			application.$wheels.serverVersion = server.coldfusion.productVersion;
		}
		application.$wheels.serverVersionMajor = ListFirst(application.$wheels.serverVersion, ".,");

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
		// TODO remove the static version number
		application.$wheels.version = "3.0.0";
		try {
			application.$wheels.hostName = CreateObject("java", "java.net.InetAddress").getLocalHost().getHostName();
		} catch (any e) {
		}
		application.$wheels.controllers = {};
		application.$wheels.models = {};
		application.$wheels.existingHelperFiles = "";
		application.$wheels.existingLayoutFiles = "";
		application.$wheels.existingObjectFiles = "";
		application.$wheels.nonExistingHelperFiles = "";
		application.$wheels.nonExistingLayoutFiles = "";
		application.$wheels.nonExistingObjectFiles = "";
		application.$wheels.directoryFiles = {};
		application.$wheels.routes = [];
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

		// Set up paths to various folders in the framework.
		application.$wheels.webPath = Replace(
			request.cgi.script_name,
			Reverse(SpanExcluding(Reverse(request.cgi.script_name), "/")),
			""
		);
		application.$wheels.rootPath = "/" & ListChangeDelims(application.$wheels.webPath, "/", "/");
		application.$wheels.rootcomponentPath = ListChangeDelims(application.$wheels.webPath, ".", "/");
		application.$wheels.wheelsComponentPath = ListAppend(application.$wheels.rootcomponentPath, "wheels", ".");

		// Check old environment to see whether we're allowed to switch configuration
		application.$wheels.allowEnvironmentSwitchViaUrl = true;
		if (StructKeyExists(local, "allowEnvironmentSwitchViaUrl") && !local.allowEnvironmentSwitchViaUrl) {
			application.$wheels.allowEnvironmentSwitchViaUrl = false;
		}

		// Set environment either from the url or the developer's environment.cfm file.
		if (
			StructKeyExists(URL, "reload")
			&& !IsBoolean(URL.reload)
			&& Len(url.reload)
			&& StructKeyExists(application.$wheels, "reloadPassword")
			&& (
				!Len(application.$wheels.reloadPassword)
				|| (StructKeyExists(URL, "password") && URL.password == application.$wheels.reloadPassword)
			)
		) {
			application.$wheels.environment = URL.reload;
		} else {
			application.wo.$include(template = "/config/environment.cfm");
		}

		// If we're not allowed to switch, override and replace with the old environment
		if (!application.$wheels.allowEnvironmentSwitchViaUrl && StructKeyExists(local, "oldEnvironment")) {
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
		application.$wheels.migratorTableName = "c_o_r_e_migrator_versions";
		application.$wheels.createMigratorTable = true;
		application.$wheels.writeMigratorSQLFiles = false;
		application.$wheels.migratorObjectCase = "lower";
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
		application.wo.$include(template = "/config/settings.cfm");
		if (FileExists(ExpandPath("/config/#application.$wheels.environment#/settings.cfm"))) {
			application.wo.$include(template = "/config/#application.$wheels.environment#/settings.cfm");
		}

		// Clear query (cfquery) and page (cfcache) caches.
		if (application.$wheels.clearQueryCacheOnReload or !StructKeyExists(application.$wheels, "cacheKey")) {
			application.$wheels.cacheKey = Hash(CreateUUID());
		}
		if (application.$wheels.clearTemplateCacheOnReload) {
			application.wo.$cache(action = "flush");
		}

		// Add all public controller / view methods to a list of methods that you should not be allowed to call as a controller action from the url.
		local.allowedGlobalMethods = "get,set,mapper";
		application.$wheels.protectedControllerMethods = "";

		// Enable the main GUI Component
		if (application.$wheels.enablePublicComponent) {
			application.$wheels.public = application.wo.$createObjectFromRoot(path = "wheels", fileName = "Public", method = "$init");
		}

		// Reload the plugins each time we reload the application.
		if (application.$wheels.enablePluginsComponent) {
			application.wo.$loadPlugins();
		}

		// Allow developers to inject plugins into the application variables scope.
		if (!StructIsEmpty(application.$wheels.mixins)) {
			if (structKeyExists(server, "boxlang")) {
				variables.this = this;
			}
			new wheels.Plugins().$initializeMixins(variables);
		}

		// Create the mapper that will handle creating routes.
		// Needs to be before $loadRoutes and after $loadPlugins.
		application.$wheels.mapper = application.wo.$createObjectFromRoot(path = "wheels", fileName = "Mapper", method = "$init");

		// Load developer routes and adds the default Wheels routes (unless the developer has specified not to).
		application.wo.$loadRoutes();

		// Create the dispatcher that will handle all incoming requests.
		application.$wheels.dispatch = application.wo.$createObjectFromRoot(path = "wheels", fileName = "Dispatch", method = "$init");

		// Assign it all to the application scope in one atomic call.
		application.wheels = application.$wheels;
		StructDelete(application, "$wheels");

		// Enable the migrator component
		if (application.wheels.enableMigratorComponent) {
			application.wheels.migrator = application.wo.$createObjectFromRoot(path = "wheels", fileName = "Migrator", method = "init");
		}

		// Run the developer's on application start code.
		application.wo.$include(template = "#application.wheels.eventPath#/onapplicationstart.cfm");

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
			$location(url = local.url, addToken = false);
		}
	}
}
