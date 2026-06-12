component output="false" {

	// Put variables we just need internally inside a wheels struct.
	this.wheels = {};
	this.wheels.rootPath = GetDirectoryFromPath(GetBaseTemplatePath());

	this.name = createUUID();
	// Give this application a unique name by taking the path to the root and hashing it.
	// this.name = Hash(this.wheels.rootPath);

	this.bufferOutput = true;

	// Set up the application paths.
	this.appDir     = expandPath("../app/");
	this.vendorDir  = expandPath("../vendor/");
	this.wheelsDir  = this.vendorDir & "wheels/";
	// Set up the mappings for the application.
	this.mappings["/app"]     = this.appDir;
	this.mappings["/vendor"]  = this.vendorDir;
	this.mappings["/wheels"]  = this.wheelsDir;
	this.mappings["/tests"] = expandPath("../tests");
	this.mappings["/config"] = expandPath("../config");
	this.mappings["/plugins"] = expandPath("../plugins");

	// We turn on "sessionManagement" by default since the Flash uses it.
	this.sessionManagement = true;

	// If a plugin has a jar or class file, automatically add the mapping to this.javasettings.
	this.wheels.pluginDir = this.appDir & "../plugins";
	this.wheels.pluginFolders = DirectoryList(
		this.wheels.pluginDir,
		"true",
		"path",
		"*.class|*.jar|*.java"
	);

	for (this.wheels.folder in this.wheels.pluginFolders) {
		if (!StructKeyExists(this, "javaSettings")) {
			this.javaSettings = {};
		}
		if (!StructKeyExists(this.javaSettings, "LoadPaths")) {
			this.javaSettings.LoadPaths = [];
		}
		this.wheels.pluginPath = GetDirectoryFromPath(this.wheels.folder);
		if (!ArrayFind(this.javaSettings.LoadPaths, this.wheels.pluginPath)) {
			ArrayAppend(this.javaSettings.LoadPaths, this.wheels.pluginPath);
		}
	}

	// Put environment vars into env struct
	if ( !structKeyExists(this,"env") ) {
		this.env = {};
		
		// Load base .env file
		envFilePath = this.appDir & "../.env";
		if (fileExists(envFilePath)) {
			loadEnvFile(envFilePath, this.env);
		}
		
		// Determine current environment
		currentEnv = "";
		if (structKeyExists(this.env, "WHEELS_ENV")) {
			currentEnv = this.env["WHEELS_ENV"];
		} else {
			// Try system environment variable
			try {
				javaSystem = createObject("java", "java.lang.System");
				systemEnv = javaSystem.getenv("WHEELS_ENV");
				if (!isNull(systemEnv) && len(systemEnv)) {
					currentEnv = systemEnv;
				}
			} catch (any e) {
				// Ignore errors accessing system environment
			}
		}
		
		// Load environment-specific .env file if it exists
		if (len(currentEnv)) {
			envSpecificPath = this.appDir & "../.env." & currentEnv;
			if (fileExists(envSpecificPath)) {
				loadEnvFile(envSpecificPath, this.env);
			}
		}
		
		// Perform variable interpolation
		performVariableInterpolation(this.env);
	}

	function onServerStart() {}

	include "../config/app.cfm";

	function onApplicationStart() {
		// Consume the single-use reload-password handoff left by
		// $handleRestartAppRequest() for environment-switch restarts (issue #3030).
		// The framework's switch code in wheels/events/onapplicationstart.cfc runs
		// before config/settings.cfm is loaded and gets the configured password via
		// carryover from application.wheels.reloadPassword — which applicationStop()
		// destroys. Seeding this.wheels.reloadPassword here restores that carryover
		// on the post-restart cold start ($init copies this.wheels into
		// application.wheels before the carryover check).
		local.handoffKey = "$wheelsReloadPasswordHandoff_" & this.name;
		if (StructKeyExists(server, local.handoffKey)) {
			local.handoff = server[local.handoffKey];
			StructDelete(server, local.handoffKey);
			if (
				IsStruct(local.handoff)
				&& StructKeyExists(local.handoff, "reloadPassword")
				&& StructKeyExists(local.handoff, "expiresAt")
				&& DateCompare(Now(), local.handoff.expiresAt) < 0
			) {
				this.wheels.reloadPassword = local.handoff.reloadPassword;
			}
		}

		application.wheelsdi = new wheels.Injector("wheels.Bindings");

		/* wheels/global object */
		application.wo = application.wheelsdi.getInstance("global");
		initArgs.path="wheels";
		initArgs.filename="onapplicationstart";
		application.wheelsdi.getInstance(name = "wheels.events.onapplicationstart", initArguments = initArgs).$init(this);
	}

	public void function onApplicationEnd( struct ApplicationScope ) {
		application.wo.$include(
			template = "../../#arguments.applicationScope.wheels.eventPath#/onapplicationend.cfm",
			argumentCollection = arguments
		);
	}

	public void function onSessionStart() {
		local.lockName = "reloadLock" & this.name;

		// Fix for shared application name (issue 359).
		if (!StructKeyExists(application, "wheels") || !StructKeyExists(application.wheels, "eventpath")) {
			local.executeArgs = {"componentReference" = "application"};

			application.wo.$simpleLock(name = local.lockName, execute = "onApplicationStart", type = "exclusive", timeout = 180, executeArgs = local.executeArgs);
		}

		local.executeArgs = {"componentReference" = "wheels.events.EventMethods"};
		application.wo.$simpleLock(name = local.lockName, execute = "$runOnSessionStart", type = "readOnly", timeout = 180, executeArgs = local.executeArgs);
	}

	public void function onSessionEnd( struct SessionScope, struct ApplicationScope ) {
		local.lockName = "reloadLock" & this.name;

		arguments.componentReference = "wheels.events.EventMethods";
		application.wo.$simpleLock(
			name = local.lockName,
			execute = "$runOnSessionEnd",
			executeArgs = arguments,
			type = "readOnly",
			timeout = 180
		);
	}

	public boolean function onRequestStart( string targetPage ) {

		// Added this section so that whenever the format parameter is passed in the URL and it is junit, json or txt then the content will be served without the head and body tags
		if(structKeyExists(url, "format") && listFindNoCase("junit,json,txt", url.format))
		{
			application.contentOnly = true;
		}else{
			application.contentOnly = false;
		}

		local.lockName = "reloadLock" & this.name;

		// Abort if called from incorrect file.
		application.wo.$abortInvalidRequest();

		// Fix for shared application name issue 359.
		if (!StructKeyExists(application, "wheels") || !StructKeyExists(application.wheels, "eventPath")) {
			this.onApplicationStart();
		}

		// Need to setup the wheels struct up here since it's used to store debugging info below if this is a reload request.
		application.wo.$initializeRequestScope();

		// IP-based access to public Component/debug GUI (only if allowed in settings)
		if (!structKeyExists(application.wheels, "debugIPAccess")) {
			application.wheels.debugIPAccess.originalEnablePublicComponent = application.wheels.enablePublicComponent;
			application.wheels.debugIPAccess.originalShowDebugInformation  = application.wheels.showDebugInformation;
			application.wheels.debugIPAccess.originalShowErrorInformation  = application.wheels.showErrorInformation;
		}

		// Conditional override for allowed IPs (but only in non-dev mode)
		if (
			StructKeyExists(application.wheels, "allowIPBasedDebugAccess") &&
			application.wheels.environment != "development" &&
			(application.wheels.allowIPBasedDebugAccess)
		) {
			// Client IP comes from the socket address. X-Forwarded-For is client-controlled
			// and trivially spoofed, so it is only consulted when the app explicitly opts in
			// via set(debugAccessTrustProxy=true) behind a trusted reverse proxy.
			local.clientIP = Trim(CGI.REMOTE_ADDR);
			if (
				StructKeyExists(application.wheels, "debugAccessTrustProxy")
				&& application.wheels.debugAccessTrustProxy
				&& Len(Trim(CGI.HTTP_X_FORWARDED_FOR))
			) {
				// Rightmost entry is the one appended by the trusted proxy nearest the app.
				local.clientIP = Trim(ListLast(CGI.HTTP_X_FORWARDED_FOR));
			}
			local.allowedIPs = application.wheels.debugAccessIPs;

			if (arrayContains(local.allowedIPs, local.clientIP)) {
				// Temporarily override — per request
				application.wheels.enablePublicComponent = true;
				application.wheels.showDebugInformation = true;
				application.wheels.showErrorInformation = true;

				// Enable the main GUI Component
				application.wheels.public = application.wo.$createObjectFromRoot(path = "wheels", fileName = "Public", method = "$init");
			} else {
				application.wheels.enablePublicComponent = application.wheels.debugIPAccess.originalEnablePublicComponent;
				application.wheels.showDebugInformation = application.wheels.debugIPAccess.originalShowDebugInformation;
				application.wheels.showErrorInformation = application.wheels.debugIPAccess.originalShowErrorInformation;
			}
		}

		// Loop-break for URL environment switches (issue #3030): $buildRedirectUrl()
		// keeps ?reload=<environment>&password=... on the post-restart redirect so the
		// framework's switch code (vendor/wheels/events/onapplicationstart.cfc) can see
		// them on the request that starts the new application. When that redirected
		// request arrives here the switch has already been applied, so firing another
		// applicationStop() would redirect forever. If the requested environment is
		// already active, skip the restart and serve the request normally.
		// Trade-off: ?reload=<current-environment> is a no-op — use ?reload=true for a
		// same-environment restart.
		local.environmentSwitchAlreadyApplied = StructKeyExists(url, "reload")
			&& !IsBoolean(url.reload)
			&& StructKeyExists(application, "wheels")
			&& StructKeyExists(application.wheels, "environment")
			&& application.wheels.environment == url.reload;

		// Reload application properly using applicationStop() if requested.
		if (
			StructKeyExists(url, "reload")
			&& !local.environmentSwitchAlreadyApplied
			&& (
				!StructKeyExists(application, "wheels") || !StructKeyExists(application.wheels, "reloadPassword")
				|| !Len(application.wheels.reloadPassword)
				|| (StructKeyExists(url, "password") && url.password == application.wheels.reloadPassword)
			)
		) {
			application.wo.$debugPoint("total,reload");
			if (StructKeyExists(url, "lock") && !url.lock) {
				this.$handleRestartAppRequest();
			} else {
				local.executeArgs = {"componentReference" = "application"};
				application.wo.$simpleLock(name = local.lockName, execute = "$handleRestartAppRequest", type = "exclusive", timeout = 180, executeArgs = local.executeArgs);
			}
			return false; // Stop processing this request after restart
		}

		// Run the rest of the request start code.
		arguments.componentReference = "wheels.events.EventMethods";
		application.wo.$simpleLock(
			name = local.lockName,
			execute = "$runOnRequestStart",
			executeArgs = arguments,
			type = "readOnly",
			timeout = 180
		);

		return true;
	}

	public boolean function onRequest( string targetPage ) {
		lock name="reloadLock#this.name#" type="readOnly" timeout="180" {
			include "#arguments.targetpage#";
		}

		return true;
	}

	public void function onRequestEnd( string targetPage ) {
		local.lockName = "reloadLock" & this.name;

		arguments.componentReference = "wheels.events.EventMethods";

		application.wo.$simpleLock(
			name = local.lockName,
			execute = "$runOnRequestEnd",
			executeArgs = arguments,
			type = "readOnly",
			timeout = 180
		);
		if (
			application.wheels.showDebugInformation && StructKeyExists(request.wheels, "showDebugInformation") && request.wheels.showDebugInformation
		) {
			if(!structKeyExists(url, "format")){
				application.wo.$includeAndOutput(template = "/wheels/events/onrequestend/debug.cfm");
			}
		}
	}

	public boolean function onAbort( string targetPage ) {
		if (
			StructKeyExists(application, "wo")
			&& StructKeyExists(application.wo, "$restoreTestRunnerApplicationScope")
		) {
			application.wo.$restoreTestRunnerApplicationScope();
			application.wo.$include(template = "../../#application.wheels.eventPath#/onabort.cfm");
		}
		return true;
	}

	public void function onError( any Exception, string EventName ) {
		application.wheelsdi = new wheels.Injector("wheels.Bindings");
		application.wo = application.wheelsdi.getInstance("global");

		// In case the error was caused by a timeout we have to add extra time for error handling.
		// We have to check if onErrorRequestTimeout exists since errors can be triggered before the application.wheels struct has been created.
		local.requestTimeout = application.wo.$getRequestTimeout() + 30;
		if (StructKeyExists(application, "wheels") && StructKeyExists(application.wheels, "onErrorRequestTimeout")) {
			local.requestTimeout = application.wheels.onErrorRequestTimeout;
		}
		setting requestTimeout=local.requestTimeout;

		application.wo.$initializeRequestScope();
		arguments.componentReference = "wheels.events.EventMethods";

		local.lockName = "reloadLock" & this.name;
		local.rv = application.wo.$simpleLock(
			name = local.lockName,
			execute = "$runOnError",
			executeArgs = arguments,
			type = "readOnly",
			timeout = 180
		);
		WriteOutput(local.rv);
	}

	public boolean function onMissingTemplate( string targetPage ) {
		local.lockName = "reloadLock" & this.name;

		arguments.componentReference = "wheels.events.EventMethods";

		application.wo.$simpleLock(
			name = local.lockName,
			execute = "$runOnMissingTemplate",
			executeArgs = arguments,
			type = "readOnly",
			timeout = 180
		);

		return true;
	}

	public void function $handleRestartAppRequest() {
		local.redirectUrl = this.$buildRedirectUrl();

		// Environment-switch restarts (?reload=<environment>) need the configured
		// reloadPassword available when the NEW application starts: the switch code
		// in wheels/events/onapplicationstart.cfc runs before config/settings.cfm is
		// loaded and normally reads the password via carryover from the live
		// application scope, which applicationStop() destroys. Hand it across the
		// restart via a single-use, short-lived server-scope entry consumed by
		// onApplicationStart() (issue #3030). The value is the app's own configured
		// password (the request's password was already verified against it by the
		// reload gate), and the server scope is only reachable by code running on
		// this engine — the same trust domain as config/settings.cfm itself.
		// Skipped when allowEnvironmentSwitchViaUrl is explicitly disabled (covers
		// both set(allowEnvironmentSwitchViaUrl=false) and the framework's
		// production/testing/maintenance auto-disable): after applicationStop()
		// the framework cannot enforce the flag itself — its revert in
		// wheels/events/onapplicationstart.cfc needs carryover state the restart
		// destroys — so this pre-restart gate is the only place the off-switch
		// holds. A missing flag counts as allowed, matching the framework's
		// carryover default.
		if (
			StructKeyExists(url, "reload")
			&& !IsBoolean(url.reload)
			&& Len(url.reload)
			&& StructKeyExists(url, "password")
			&& StructKeyExists(application, "wheels")
			&& StructKeyExists(application.wheels, "reloadPassword")
			&& Len(application.wheels.reloadPassword)
			&& (
				!StructKeyExists(application.wheels, "allowEnvironmentSwitchViaUrl")
				|| application.wheels.allowEnvironmentSwitchViaUrl
			)
		) {
			server["$wheelsReloadPasswordHandoff_" & this.name] = {
				reloadPassword: application.wheels.reloadPassword,
				expiresAt: DateAdd("n", 1, Now())
			};
		}

		applicationStop();
		location(url = local.redirectUrl, addToken = false);
	}

	public string function $buildRedirectUrl() {
		// The local carrying the redirect target must NOT be named "url": this
		// function reads the URL scope unscoped below (StructKeyExists(url, ...)),
		// and on Adobe CF an unscoped url resolves to a local of that name first,
		// turning every password reload into an HTTP 500 (issue #3053, CLAUDE.md
		// anti-pattern #11 — reserved scope names).
		// Determine the base URL
		if (StructKeyExists(cgi, "path_info") && Len(cgi.path_info)) {
			local.redirectPath = cgi.path_info;
		} else if (StructKeyExists(cgi, "path_info")) {
			local.redirectPath = "/";
		} else {
			local.redirectPath = cgi.script_name;
		}

		// For a plain restart (?reload=true) every reload-related parameter is
		// stripped so the redirected request cannot trigger another restart. For an
		// environment switch (?reload=<environment>) the framework needs URL.reload
		// and URL.password present on the request that starts the new application
		// (vendor/wheels/events/onapplicationstart.cfc), so those two survive the
		// redirect; the restart loop is broken in onRequestStart instead, which
		// skips the restart once the requested environment is active (issue #3030).
		// Only preserve when the switch can actually be applied (a non-empty
		// reloadPassword is configured and the request carries a password) —
		// otherwise the new application could never switch and the preserved
		// parameters would redirect forever. The same goes for
		// allowEnvironmentSwitchViaUrl: when switching is explicitly disallowed
		// (set(allowEnvironmentSwitchViaUrl=false) or the framework's
		// production/testing/maintenance auto-disable) the parameters are
		// stripped and the request degrades to a plain restart — the framework
		// cannot enforce the flag on the post-applicationStop() cold start, so
		// it must be enforced here, pre-restart. A missing flag counts as
		// allowed, matching the framework's carryover default.
		local.stripParams = "reload,password,lock";
		if (
			StructKeyExists(url, "reload")
			&& !IsBoolean(url.reload)
			&& Len(url.reload)
			&& StructKeyExists(url, "password")
			&& StructKeyExists(application, "wheels")
			&& StructKeyExists(application.wheels, "reloadPassword")
			&& Len(application.wheels.reloadPassword)
			&& (
				!StructKeyExists(application.wheels, "allowEnvironmentSwitchViaUrl")
				|| application.wheels.allowEnvironmentSwitchViaUrl
			)
		) {
			local.stripParams = "lock";
		}

		// Process query string parameters, removing reload-related ones
		if (StructKeyExists(cgi, "query_string") && Len(cgi.query_string)) {
			local.oldQueryString = ListToArray(cgi.query_string, "&");
			local.newQueryString = [];
			local.iEnd = ArrayLen(local.oldQueryString);
			
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.keyValue = local.oldQueryString[local.i];
				local.key = ListFirst(local.keyValue, "=");
				
				// Remove reload-related parameters
				if (!ListFindNoCase(local.stripParams, local.key)) {
					ArrayAppend(local.newQueryString, local.keyValue);
				}
			}
			
			// Add query string to URL if any parameters remain
			if (ArrayLen(local.newQueryString)) {
				local.queryString = ArrayToList(local.newQueryString, "&");
				local.redirectPath = "#local.redirectPath#?#local.queryString#";
			}
		}

		return local.redirectPath;
	}

	/**
	 * Load environment variables from a file into the provided struct
	 */
	private void function loadEnvFile(required string filePath, required struct envStruct) {
		local.envFile = fileRead(arguments.filePath);
		local.tempStruct = {};
		
		if (isJSON(local.envFile)) {
			local.tempStruct = deserializeJSON(local.envFile);
		} else {
			// Parse as properties file with enhanced features
			local.lines = listToArray(local.envFile, chr(10));
			
			for (local.line in local.lines) {
				local.trimmedLine = trim(local.line);
				
				// Skip empty lines and comments
				if (!len(local.trimmedLine) || left(local.trimmedLine, 1) == "##") {
					continue;
				}
				
				// Parse key=value pairs
				if (find("=", local.trimmedLine)) {
					local.key = trim(listFirst(local.trimmedLine, "="));
					local.value = trim(listRest(local.trimmedLine, "="));
					
					// Remove surrounding quotes if present
					if ((left(local.value, 1) == '"' && right(local.value, 1) == '"') ||
						(left(local.value, 1) == "'" && right(local.value, 1) == "'")) {
						local.value = mid(local.value, 2, len(local.value) - 2);
					}
					
					// Type casting for boolean and numeric values
					if (local.value == "true" || local.value == "false") {
						local.value = (local.value == "true");
					} else if (isNumeric(local.value) && !find(".", local.value)) {
						// Only convert integers, leave decimals as strings
						local.value = val(local.value);
					}
					
					local.tempStruct[local.key] = local.value;
				}
			}
		}
		
		// Merge into the main env struct
		for (local.key in local.tempStruct) {
			arguments.envStruct[local.key] = local.tempStruct[local.key];
		}
	}
	
	/**
	 * Perform variable interpolation on env values using ${VAR} syntax
	 */
	private void function performVariableInterpolation(required struct envStruct) {
		local.maxIterations = 10; // Prevent infinite loops
		local.iteration = 0;
		local.hasChanges = true;
		
		while (local.hasChanges && local.iteration < local.maxIterations) {
			local.hasChanges = false;
			local.iteration++;
			
			for (local.key in arguments.envStruct) {
				local.value = arguments.envStruct[local.key];
				
				if (isSimpleValue(local.value) && isString(local.value)) {
					local.newValue = local.value;
					
					// Find all ${VAR} patterns
					local.matches = reMatchNoCase("\$\{([^}]+)\}", local.value);
					
					for (local.match in local.matches) {
						// Extract variable name
						local.varName = reReplaceNoCase(local.match, "\$\{([^}]+)\}", "\1");
						
						// Replace with actual value if it exists
						if (structKeyExists(arguments.envStruct, local.varName)) {
							local.replacement = arguments.envStruct[local.varName];
							if (isSimpleValue(local.replacement)) {
								local.newValue = replace(local.newValue, local.match, local.replacement, "all");
								local.hasChanges = true;
							}
						}
					}
					
					arguments.envStruct[local.key] = local.newValue;
				}
			}
		}
	}
	
	/**
	 * Helper to check if a value is a string (not boolean or numeric after parsing)
	 */
	private boolean function isString(required any value) {
		return isSimpleValue(arguments.value) && !isBoolean(arguments.value) && !isNumeric(arguments.value);
	}

}
