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
	this.wireboxDir = this.vendorDir & "wirebox/";
	this.testboxDir = this.vendorDir & "testbox/";

	// Set up the mappings for the application.
	this.mappings["/app"]     = this.appDir;
	this.mappings["/vendor"]  = this.vendorDir;
	this.mappings["/wheels"]  = this.wheelsDir;
	this.mappings["/wirebox"] = this.wireboxDir;
	this.mappings["/testbox"] = this.testboxDir;
	this.mappings["/tests"] = expandPath("../tests");

	// We turn on "sessionManagement" by default since the Flash uses it.
	this.sessionManagement = true;

	// If a plugin has a jar or class file, automatically add the mapping to this.javasettings.
	this.wheels.pluginDir = this.appDir & "plugins";
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

	include "../app/config/app.cfm";

	function onApplicationStart() {
		wirebox = new wirebox.system.ioc.Injector("wheels.Wirebox");

		/* wheels/global object */
		application.wo = wirebox.getInstance("global");
		initArgs.path="wheels";
		initArgs.filename="onapplicationstart";
		application.wirebox.getInstance(name = "wheels.events.onapplicationstart", initArguments = initArgs).$init(this);
	}

	public void function onApplicationEnd( struct ApplicationScope ) {
		application.wo.$include(
			template = "/app/#arguments.applicationScope.wheels.eventPath#/onapplicationend.cfm",
			argumentCollection = arguments
		);
	}

	public void function onSessionStart() {
		local.lockName = "reloadLock" & application.applicationName;

		// Fix for shared application name (issue 359).
		if (!StructKeyExists(application, "wheels") || !StructKeyExists(application.wheels, "eventpath")) {
			local.executeArgs = {"componentReference" = "application"};

			application.wo.$simpleLock(name = local.lockName, execute = "onApplicationStart", type = "exclusive", timeout = 180, executeArgs = local.executeArgs);
		}

		local.executeArgs = {"componentReference" = "wheels.events.EventMethods"};
		application.wo.$simpleLock(name = local.lockName, execute = "$runOnSessionStart", type = "readOnly", timeout = 180, executeArgs = local.executeArgs);
	}

	public void function onSessionEnd( struct SessionScope, struct ApplicationScope ) {
		local.lockName = "reloadLock" & arguments.applicationScope.applicationName;

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

		local.lockName = "reloadLock" & application.applicationName;

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
			local.clientIP = CGI.HTTP_X_FORWARDED_FOR ?: CGI.REMOTE_ADDR;
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

		// Reload application by calling onApplicationStart if requested.
		if (
			StructKeyExists(url, "reload")
			&& (
				!StructKeyExists(application, "wheels") || !StructKeyExists(application.wheels, "reloadPassword")
				|| !Len(application.wheels.reloadPassword)
				|| (StructKeyExists(url, "password") && url.password == application.wheels.reloadPassword)
			)
		) {
			application.wo.$debugPoint("total,reload");
			if (StructKeyExists(url, "lock") && !url.lock) {
				this.onApplicationStart();
			} else {
				local.executeArgs = {"componentReference" = "application"};
				application.wo.$simpleLock(name = local.lockName, execute = "onApplicationStart", type = "exclusive", timeout = 180, executeArgs = local.executeArgs);
			}
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
		lock name="reloadLock#application.applicationName#" type="readOnly" timeout="180" {
			include "#arguments.targetpage#";
		}

		return true;
	}

	public void function onRequestEnd( string targetPage ) {
		local.lockName = "reloadLock" & application.applicationName;

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
		application.wo.$restoreTestRunnerApplicationScope();
		application.wo.$include(template = "#application.wheels.eventPath#/onabort.cfm");
		return true;
	}

	public void function onError( any Exception, string EventName ) {
		wirebox = new wirebox.system.ioc.Injector("wheels.Wirebox");
		application.wo = wirebox.getInstance("global");

		// In case the error was caused by a timeout we have to add extra time for error handling.
		// We have to check if onErrorRequestTimeout exists since errors can be triggered before the application.wheels struct has been created.
		local.requestTimeout = application.wo.$getRequestTimeout() + 30;
		if (StructKeyExists(application, "wheels") && StructKeyExists(application.wheels, "onErrorRequestTimeout")) {
			local.requestTimeout = application.wheels.onErrorRequestTimeout;
		}
		setting requestTimeout=local.requestTimeout;

		application.wo.$initializeRequestScope();
		arguments.componentReference = "wheels.events.EventMethods";

		local.lockName = "reloadLock" & application.applicationName;
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
		local.lockName = "reloadLock" & application.applicationName;

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
