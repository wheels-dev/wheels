component output="false" {

	// Put variables we just need internally inside a wheels struct.
	this.wheels = {};
	// Anchor to this file's directory, not the requested base template's, so
	// rootPath stays stable when a request bootstraps under a subfolder (e.g.
	// the test runner) — Hash(rootPath) below seeds this.name, and an unstable
	// value splits one app across two application scopes (issue #3025/#2887).
	this.wheels.rootPath = GetDirectoryFromPath(GetCurrentTemplatePath());

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
	this.mappings["/cli"] = expandPath("../cli/");
	// Mirror LuCLI's runtime mapping so production code under cli/lucli/services/
	// can resolve its own modules.wheels.X dotted-path refs when running inside
	// the framework's own test server (e.g. via /wheels/cli/tests). The CLI
	// services use modules.wheels.X for their internal cross-references because
	// that prefix resolves identically across every install context (dev
	// symlink, brew bottle, choco package). See PR #2309 for context.
	this.mappings["/modules/wheels"] = expandPath("../cli/lucli/");

	// Test double for LuCLI's modules.BaseModule under /wheels/cli/tests — see #2829 / PR #2831.
	this.mappings["/modules"] = expandPath("../cli/lucli/tests/_modules");

	// We turn on "sessionManagement" by default since the Flash uses it.
	this.sessionManagement = true;

	// If a plugin has a jar or class file, automatically add the mapping to this.javasettings.
	// Legacy plugins system (DEPRECATED — superseded by vendor/<name>/ packages).
	// Only scan when a plugins/ directory exists, so a removed plugins/ dir does not
	// error on engines whose directoryList() throws on a missing path (e.g. RustCFML;
	// Lucee tolerates it). This lookup is slated for removal in the next major.
	this.wheels.pluginDir = this.appDir & "../plugins";
	this.wheels.pluginFolders = DirectoryExists(this.wheels.pluginDir)
		? DirectoryList(this.wheels.pluginDir, "true", "path", "*.class|*.jar|*.java")
		: [];

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

	// Framework Java resources — the bundled jBCrypt jar used by the global
	// bcryptHash()/bcryptVerify() helpers. LoadPaths are read at app init, so
	// the jar must be present under vendor/wheels/resources/java before the
	// first request; on JVM engines this makes bcrypt run in native Java
	// instead of the slow pure-CFML Blowfish fallback.
	if (DirectoryExists(this.wheelsDir & "resources/java")) {
		if (!StructKeyExists(this, "javaSettings")) {
			this.javaSettings = {};
		}
		if (!StructKeyExists(this.javaSettings, "LoadPaths")) {
			this.javaSettings.LoadPaths = [];
		}
		if (!ArrayFind(this.javaSettings.LoadPaths, this.wheelsDir & "resources/java")) {
			ArrayAppend(this.javaSettings.LoadPaths, this.wheelsDir & "resources/java");
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

	// Load app-level configuration (datasources, custom settings, etc.). This
	// must run AFTER this.env is initialized above so user code in
	// config/app.cfm can reference this.env safely (issue #2325).
	include "../config/app.cfm";

	// Issue #3374: bind test-runner / TestClient / browser requests to a
	// separate CFML application name so the live application.wheels is never
	// swapped. No-op when vendor/wheels is absent (examples without a vendor tree).
	if (FileExists(GetDirectoryFromPath(GetCurrentTemplatePath()) & "../vendor/wheels/events/testcontext.cfm")) {
		include "../vendor/wheels/events/testcontext.cfm";
	}

	function onApplicationStart() {
		application.env = duplicate(this.env);

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
		// Release the application-scoped browser-test launcher (headless browser,
		// node driver process, URLClassLoader handles on the Playwright JARs)
		// before the scope is discarded. CFML has no destructors, so without this
		// every applicationStop() reload cycle would orphan those processes.
		if (StructKeyExists(arguments.applicationScope, "$wheelsBrowserLauncher")) {
			try {
				arguments.applicationScope.$wheelsBrowserLauncher.release();
			} catch (any e) {
				// Best-effort cleanup — never block application shutdown.
			}
		}

		// Run the framework's onApplicationEnd event through the Wheels global.
		// During applicationStop() teardown on Adobe CF 2023 the LIVE `application`
		// scope is unreliable — bare `application.wo` can resolve against a
		// stale/torn-down scope and land on a Java String[], throwing "Element wo
		// is undefined in a Java object of type class [Ljava.lang.String;" and
		// erroring the whole site until a CF service restart (issue #3379). The
		// passed-in arguments.applicationScope is the only dependable reference at
		// shutdown (it is what the $wheelsBrowserLauncher cleanup above uses), so
		// route the call through it and guard so a partially reclaimed scope
		// degrades to a no-op instead of a hard error.
		if (
			StructKeyExists(arguments.applicationScope, "wo")
			&& StructKeyExists(arguments.applicationScope, "wheels")
			&& StructKeyExists(arguments.applicationScope.wheels, "eventPath")
		) {
			arguments.applicationScope.wo.$include(
				template = "#arguments.applicationScope.wheels.eventPath#/onapplicationend.cfm",
				argumentCollection = arguments
			);
		}
	}

	public void function onSessionStart() {
		local.lockName = "reloadLock" & this.name;

		// Fix for shared application name (issue 359).
		if (!StructKeyExists(application, "wheels") || !StructKeyExists(application.wheels, "eventpath")) {
			// Case-exact "Application" (the file is Application.cfc): on case-sensitive
			// filesystems Adobe CF resolves CFC names by exact case then all-lowercase,
			// so a lowercase reference never matches Application.cfc and throws "Could
			// not find the ColdFusion component or interface application" (issue #3053
			// follow-up). Lucee matches case-insensitively either way.
			local.executeArgs = {"componentReference" = "Application"};

			application.wo.$simpleLock(name = local.lockName, execute = "onApplicationStart", type = "exclusive", timeout = 180, executeArgs = local.executeArgs);
		}

		local.executeArgs = {"componentReference" = "wheels.events.EventMethods"};
		application.wo.$simpleLock(name = local.lockName, execute = "$runOnSessionStart", type = "readOnly", timeout = 180, executeArgs = local.executeArgs);
	}

	public void function onSessionEnd( struct SessionScope, struct ApplicationScope ) {
		local.lockName = "reloadLock" & this.name;

		arguments.componentReference = "wheels.events.EventMethods";
		// Adobe SessionTracker.SessionCleanUpAgent calls onSessionEnd after the
		// live application scope can already be torn down (same class of failure
		// as onApplicationEnd, issue #3379). Route through the passed-in
		// arguments.applicationScope and guard so a reclaimed scope is a no-op.
		if (StructKeyExists(arguments.applicationScope, "wo")) {
			arguments.applicationScope.wo.$simpleLock(
				name = local.lockName,
				execute = "$runOnSessionEnd",
				executeArgs = arguments,
				type = "readOnly",
				timeout = 180
			);
		}
	}

	public boolean function onRequestStart( string targetPage ) {

		// Added this section so that whenever the format parameter is passed in the URL and it is junit, json or txt then the content will be served without the head and body tags
		if(structKeyExists(url, "format") && listFindNoCase("junit,json,txt", url.format))
		{
			application.contentOnly = true;
		}else{
			application.contentOnly = false;
		}

		// Reload password transport: the Wheels CLI sends it in the
		// X-Wheels-Reload-Password request header so it stays out of URLs, access
		// logs and proxy logs. Map it onto url.password so the reload gate below,
		// the cold-start path and the soft-reload skip all see one value.
		// ?reload=true&password=... from a browser keeps working unchanged, and
		// an explicit url.password wins over the header.
		//
		// RustCFML drops the cgi.http_* entries once onApplicationStart has run
		// inside the request — the first request after a reload restart — so the
		// cgi copy can be missing while the request still carries the header.
		// GetHttpRequestData() keeps it, so it is the fallback (#3913). Still
		// header-only: the password is never read from the form scope.
		if (StructKeyExists(url, "reload") && !StructKeyExists(url, "password")) {
			local.reloadPasswordHeader = "";
			if (IsDefined("cgi.http_x_wheels_reload_password")) {
				local.reloadPasswordHeader = ToString(cgi.http_x_wheels_reload_password);
			}
			if (!Len(local.reloadPasswordHeader)) {
				try {
					local.requestHeaders = GetHttpRequestData(false).headers;
					for (local.headerName in local.requestHeaders) {
						if (CompareNoCase(local.headerName, "X-Wheels-Reload-Password") == 0) {
							local.reloadPasswordHeader = ToString(local.requestHeaders[local.headerName]);
							break;
						}
					}
				} catch (any e) {
					// No readable raw headers on this engine: nothing to map.
				}
			}
			if (Len(local.reloadPasswordHeader)) {
				url.password = local.reloadPasswordHeader;
			}
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

		// IP-based debug access (set(allowIPBasedDebugAccess=true), outside development):
		// an allowed client IP gets the debug GUI and error details for THIS request
		// only. The framework keeps that grant in the request scope; never set
		// application.wheels.showErrorInformation / showDebugInformation /
		// enablePublicComponent per request, because every concurrent request reads them.
		application.wo.$applyIPDebugAccess();

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
		// SECURITY (issue #3062): the gate FAILS CLOSED. A URL-based reload requires a
		// non-empty configured reloadPassword AND a matching password parameter — an
		// empty or missing reloadPassword disables ?reload= entirely, matching the
		// environment-switch leg in wheels/events/onapplicationstart.cfc and the
		// warning the framework logs on boot when the password is blank. Wrong-password
		// attempts are logged to wheels_security.log with the trusted client IP and
		// feed the same per-IP rate limit as the cold-start path (5 failed attempts
		// within 5 minutes locks the source out).
		local.reloadRequested = StructKeyExists(url, "reload") && !local.environmentSwitchAlreadyApplied;
		local.reloadAuthorized = false;
		if (local.reloadRequested && StructKeyExists(application, "wheels") && StructKeyExists(application, "wo")) {
			// Same per-IP store and window as wheels/events/onapplicationstart.cfc, so
			// warm-path and cold-start attempts count against one shared bucket.
			local.reloadClientIp = application.wo.$trustedClientIp();
			if (!StructKeyExists(application, "$reloadRateLimit")) {
				application.$reloadRateLimit = {};
			}
			local.reloadRateLimited = false;
			if (StructKeyExists(application.$reloadRateLimit, local.reloadClientIp)) {
				local.reloadRateLimitEntry = application.$reloadRateLimit[local.reloadClientIp];
				if (local.reloadRateLimitEntry.count >= 5 && DateDiff("n", local.reloadRateLimitEntry.firstAttempt, Now()) < 5) {
					local.reloadRateLimited = true;
				}
				if (DateDiff("n", local.reloadRateLimitEntry.firstAttempt, Now()) >= 5) {
					StructDelete(application.$reloadRateLimit, local.reloadClientIp);
				}
			}
			if (
				!local.reloadRateLimited
				&& StructKeyExists(application.wheels, "reloadPassword")
				&& Len(application.wheels.reloadPassword)
				&& StructKeyExists(url, "password")
				// Case-sensitive, constant-time compare — same gate as the environment switch
				// in wheels/events/onapplicationstart.cfc (CFML == is case-insensitive and
				// exits early, which leaks timing information).
				&& application.wo.$secureCompare(url.password, application.wheels.reloadPassword)
			) {
				local.reloadAuthorized = true;
				try {
					writeLog(file="wheels_security", type="information", text="Reload accepted from #local.reloadClientIp#");
				} catch (any e) {
					// Fail silently if logging fails
				}
			} else if (!local.reloadRateLimited && StructKeyExists(url, "password")) {
				// Track the failed attempt: count it against the shared per-IP window
				// and log it, exactly like the cold-start path does.
				if (!StructKeyExists(application.$reloadRateLimit, local.reloadClientIp)) {
					application.$reloadRateLimit[local.reloadClientIp] = {count: 0, firstAttempt: Now()};
				}
				application.$reloadRateLimit[local.reloadClientIp].count++;
				try {
					writeLog(file="wheels_security", type="warning", text="Reload password rejected from #local.reloadClientIp#");
				} catch (any e) {
					// Fail silently if logging fails
				}
			}
			// Record WHY a requested reload did not fire so the framework's debug
			// bar can render a development-only notice instead of a silent no-op
			// (issue #3311). Recording is environment-agnostic — a request-scope
			// flag, no output; the message text and the development-environment
			// gate live framework-side in vendor/wheels/events/onrequestend/debug.cfm
			// so wording can improve without template drift. Wrong-password and
			// rate-limited attempts deliberately collapse into one generic reason
			// so the notice adds no oracle on top of $secureCompare().
			if (!local.reloadAuthorized && StructKeyExists(request, "wheels")) {
				local.reloadPasswordConfigured = StructKeyExists(application.wheels, "reloadPassword")
					&& Len(application.wheels.reloadPassword);
				if (!local.reloadPasswordConfigured) {
					request.wheels.reloadRefusedReason = "emptyPassword";
				} else if (!StructKeyExists(url, "password")) {
					request.wheels.reloadRefusedReason = "missingPasswordParam";
				} else {
					request.wheels.reloadRefusedReason = "refused";
				}
			}
		}
		if (local.reloadAuthorized) {
			application.wo.$debugPoint("total,reload");
			if (StructKeyExists(url, "lock") && !url.lock) {
				this.$handleRestartAppRequest();
			} else {
				// Case-exact "Application" — see the matching comment in onSessionStart().
				// A lowercase reference turns every authorized reload into an HTTP 500 on
				// Adobe CF + case-sensitive filesystems (issue #3053 follow-up).
				local.executeArgs = {"componentReference" = "Application"};
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
			application.wo.$get("showDebugInformation") && StructKeyExists(request.wheels, "showDebugInformation") && request.wheels.showDebugInformation
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
			application.wo.$include(template = "#application.wheels.eventPath#/onabort.cfm");
		}
		return true;
	}

	public void function onError( any Exception, string EventName ) {
		// Adobe ColdFusion 2025 without its optional graphqlclient package
		// calls onError with that notice before the application starts, then
		// continues the same request (onApplicationStart, onRequest).
		// Rendering it here would make that request an HTTP 500 (##3726).
		// Only that exact notice is passed over; it is logged to wheels.log.
		// Nothing here may throw or touch the application scope.
		try {
			local.startupNotice = new wheels.events.EngineStartupNotice();
			if (local.startupNotice.isBenign(arguments.Exception, arguments.EventName ?: "")) {
				local.startupNotice.record();
				return;
			}
		} catch (any e) {
			// Fall through to normal error handling.
		}

		try {
			// Only rebuild the DI container when it never came up (e.g. the
			// Injector failed during onApplicationStart). Injector.init()
			// self-registers at application.wheelsdi, so an unguarded
			// construction here would replace the live container on every
			// error page — wiping all config/services.cfm registrations and
			// cached singletons (issue ##3061).
			if (!StructKeyExists(application, "wheelsdi")) {
				application.wheelsdi = new wheels.Injector("wheels.Bindings");
			}
			if (!StructKeyExists(application, "wo")) {
				application.wo = application.wheelsdi.getInstance("global");
			}

			// Make exception available to the event template
			request.wheels = request.wheels ?: {};
			request.wheels.exception = Exception;
			request.wheels.eventName = EventName;

			// Run early error event if it exists
			application.wo.$include(template = "/wheels/events/onerror/onerrorstart.cfm");
		} catch (any e) {
			// Must never break error handling
		}

		// If the Wheels global never came up (e.g. the /wheels mapping is
		// stale or Injector.cfc can't be resolved), the original error is
		// already lost — fall back to a minimal HTML response rather than
		// cascading into "The key [WO] does not exist." (issue ##2773).
		if (!StructKeyExists(application, "wo")) {
			$renderMinimalError(arguments.Exception, arguments.EventName ?: "", true);
			return;
		}

		try {
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
		} catch (any e) {
			// Adobe CF can tear down the application scope mid-onError during
			// applicationStop() (issue ##3379): application.wo resolves to a
			// Java String[] and every dereference throws "Element wo is
			// undefined in a Java object of type class [Ljava.lang.String".
			// The StructKeyExists guard above can pass and the scope still be
			// reclaimed before the dereferences below run, so degrade to the
			// minimal fallback rather than cascade the torn-down-scope error
			// over the real one.
			$renderMinimalError(arguments.Exception, arguments.EventName ?: "", !StructKeyExists(application, "wheels"));
		}
	}

	// Shared minimal error response for the two onError failure modes: the
	// Wheels global never came up (issue ##2773), and the application scope
	// being torn down mid-onError (issue ##3379). Kept in one place so both
	// paths render identically.
	private void function $renderMinimalError( required any Exception, string eventName = "", boolean startupPhase = true ) {
		// Extend the request timeout before logging so WriteLog can run even when
		// the error is a request timeout — the non-fallback path above does the
		// same with onErrorRequestTimeout (issue ##3965). Otherwise a stuck
		// request swallows the wheels.log entry this page points the operator at.
		try {
			local.fallbackTimeout = 30;
			if (StructKeyExists(application, "wheels") && StructKeyExists(application.wheels, "onErrorRequestTimeout")) {
				local.fallbackTimeout = application.wheels.onErrorRequestTimeout;
			}
			setting requestTimeout=local.fallbackTimeout;
		} catch (any timeoutErr) {
			// setting may itself fail on a fully torn-down request; keep going.
		}
		// Write the real failure to wheels.log first, so the page's "check
		// the server log" points at an entry that exists (issue ##3671).
		$logStartupFailure(arguments.Exception, arguments.eventName, arguments.startupPhase);
		// Surface a real 5xx so monitoring tools and CDNs don't cache this
		// failure as a successful response. Use a plain struct for
		// attributeCollection — Adobe CF 2023/2025 reject the `arguments`
		// scope on built-in tags (CLAUDE.md cross-engine invariant ##10).
		try {
			local.statusArgs = {statusCode: 500, statusText: "Internal Server Error"};
			cfheader(attributeCollection=local.statusArgs);
		} catch (any headerErr) {
			// Header may already have been written; the body still renders.
		}
		WriteOutput("<h1>Application Error</h1>");
		if (arguments.startupPhase) {
			WriteOutput("<p>Wheels failed to initialize. Check the server log (wheels.log) for details.</p>");
		} else {
			WriteOutput("<p>The application could not complete this request. Check the server log (wheels.log) for details.</p>");
		}
		// How much to show follows the app's showErrorInformation setting
		// (false in production by default) once startup got far enough to set
		// it: the root cause in full, or nothing beyond the log pointer. Before
		// that, only the message, as always (issue ##3671).
		try {
			local.showDetail = $startupFailureShowDetail();
			if (local.showDetail == "yes") {
				WriteOutput($startupFailureDetailHtml(arguments.Exception, arguments.eventName));
			} else if (
				local.showDetail == "unknown"
				&& isStruct(arguments.Exception)
				&& StructKeyExists(arguments.Exception, "message")
			) {
				WriteOutput("<pre>" & encodeForHTML(arguments.Exception.message) & "</pre>");
			}
		} catch (any fallbackErr) {
			// Last-ditch render must never throw.
		}
	}

	// "yes" or "no" from showErrorInformation in the settings being started
	// (application.$wheels) or the live ones (application.wheels): "no" when
	// either says false. "unknown" when startup failed before either was set,
	// or the application scope is being torn down (issue ##3379).
	private string function $startupFailureShowDetail() {
		local.rv = "unknown";
		try {
			for (local.scopeKey in ["$wheels", "wheels"]) {
				if (
					StructKeyExists(application, local.scopeKey)
					&& IsStruct(application[local.scopeKey])
					&& StructKeyExists(application[local.scopeKey], "showErrorInformation")
					&& IsBoolean(application[local.scopeKey].showErrorInformation)
				) {
					if (!application[local.scopeKey].showErrorInformation) {
						return "no";
					}
					local.rv = "yes";
				}
			}
		} catch (any settingErr) {
			return "unknown";
		}
		return local.rv;
	}

	// The root cause behind the minimal error page as HTML: its type,
	// message, detail and tag context, plus the wrapper it was reported as.
	// Every value is HTML-encoded.
	private string function $startupFailureDetailHtml( required any Exception, string eventName = "" ) {
		local.root = $startupFailureRoot(arguments.Exception);
		local.html = "<h2>" & encodeForHTML(
			"[" & $startupFailureField(local.root, "Type") & "] " & $startupFailureField(local.root, "Message")
		) & "</h2>";
		local.detail = $startupFailureField(local.root, "Detail");
		if (Len(local.detail)) {
			local.html &= "<p>" & encodeForHTML(local.detail) & "</p>";
		}
		if (Len(arguments.eventName)) {
			local.html &= "<p>Event: " & encodeForHTML(arguments.eventName) & "</p>";
		}
		local.wrapper = "[" & $startupFailureField(arguments.Exception, "Type") & "] "
			& $startupFailureField(arguments.Exception, "Message");
		if (Compare(local.wrapper, "[" & $startupFailureField(local.root, "Type") & "] "
			& $startupFailureField(local.root, "Message")) != 0) {
			local.html &= "<p>Reported as: " & encodeForHTML(local.wrapper) & "</p>";
		}
		local.frames = $startupFailureFrames(local.root, arguments.Exception);
		if (ArrayLen(local.frames)) {
			local.html &= "<pre>" & encodeForHTML(ArrayToList(local.frames, Chr(10))) & "</pre>";
		}
		return local.html;
	}

	// Log the failure behind the minimal error page to wheels.log (issue
	// ##3671). Adobe CF wraps a failure inside an application event in an
	// event-handler exception whose message hides the real one, so walk
	// RootCause / Cause to the innermost error and log its type, message,
	// detail and first tag-context frame, plus the wrapper. Runs on the
	// last-ditch error path: it must never throw, and it only logs (the
	// rendered page stays minimal).
	private void function $logStartupFailure( required any Exception, string eventName = "", boolean startupPhase = true ) {
		try {
			local.root = $startupFailureRoot(arguments.Exception);

			local.text = arguments.startupPhase ? "Wheels failed to initialize" : "Wheels could not complete the request";
			if (Len(arguments.eventName)) {
				local.text &= " in " & arguments.eventName;
			}
			local.text &= ": [" & $startupFailureField(local.root, "Type") & "] "
				& $startupFailureField(local.root, "Message");
			local.detail = $startupFailureField(local.root, "Detail");
			if (Len(local.detail)) {
				local.text &= " -- " & local.detail;
			}
			local.frames = $startupFailureFrames(local.root, arguments.Exception);
			if (ArrayLen(local.frames)) {
				local.text &= " (at " & ArrayToList(local.frames, " < ") & ")";
			}
			local.wrapper = "[" & $startupFailureField(arguments.Exception, "Type") & "] "
				& $startupFailureField(arguments.Exception, "Message");
			if (Compare(local.wrapper, "[" & $startupFailureField(local.root, "Type") & "] "
				& $startupFailureField(local.root, "Message")) != 0) {
				local.text &= " (reported as " & local.wrapper & ")";
			}
			local.text = ReReplace(local.text, "[\r\n\t]+", " ", "all");
			if (Len(local.text) > 16000) {
				local.text = Left(local.text, 16000) & "...";
			}
			WriteLog(file = "wheels", type = "error", text = local.text);
		} catch (any logErr) {
			// Logging must never mask the original error.
		}
	}

	// The innermost cause of `failure` (at most 10 levels down), or `failure`
	// itself when it has none.
	private any function $startupFailureRoot( required any failure ) {
		local.root = arguments.failure;
		for (local.depth = 1; local.depth <= 10; local.depth++) {
			local.next = $startupFailureCause(local.root);
			if (IsSimpleValue(local.next)) {
				break;
			}
			local.root = local.next;
		}
		return local.root;
	}

	// The exception that caused this one (Adobe RootCause, Lucee/Java Cause),
	// or "" when there is none.
	private any function $startupFailureCause( required any failure ) {
		try {
			if (IsStruct(arguments.failure)) {
				for (local.key in ["RootCause", "Cause"]) {
					if (StructKeyExists(arguments.failure, local.key)) {
						local.candidate = arguments.failure[local.key];
						if (!IsNull(local.candidate) && !IsSimpleValue(local.candidate)
							&& Len($startupFailureField(local.candidate, "Message"))) {
							return local.candidate;
						}
					}
				}
			} else if (IsObject(arguments.failure)) {
				local.candidate = arguments.failure.getCause();
				if (!IsNull(local.candidate)) {
					return local.candidate;
				}
			}
		} catch (any causeErr) {
			// No usable cause.
		}
		return "";
	}

	// A simple field (Type, Message, Detail) of a CFML exception struct or a
	// Java Throwable, or "" when absent.
	private string function $startupFailureField( required any failure, required string key ) {
		try {
			if (IsStruct(arguments.failure)) {
				if (StructKeyExists(arguments.failure, arguments.key)) {
					local.value = arguments.failure[arguments.key];
					if (!IsNull(local.value) && IsSimpleValue(local.value)) {
						return Trim(ToString(local.value));
					}
				}
			} else if (IsObject(arguments.failure)) {
				if (arguments.key == "Type") {
					return arguments.failure.getClass().getName();
				}
				if (arguments.key == "Message") {
					local.value = arguments.failure.getMessage();
					if (!IsNull(local.value)) {
						return Trim(ToString(local.value));
					}
				}
			}
		} catch (any fieldErr) {
			// Unreadable field.
		}
		return "";
	}

	// Up to 20 "template:line" tag-context frames, innermost first: the root
	// cause's own, else the wrapper's. [] when neither has any.
	private array function $startupFailureFrames( required any root, required any wrapper ) {
		local.frames = [];
		try {
			for (local.failure in [arguments.root, arguments.wrapper]) {
				if (IsStruct(local.failure) && StructKeyExists(local.failure, "TagContext") && IsArray(local.failure.TagContext)) {
					for (local.frame in local.failure.TagContext) {
						ArrayAppend(local.frames, $startupFailureField(local.frame, "Template") & ":" & $startupFailureField(local.frame, "Line"));
						if (ArrayLen(local.frames) >= 20) {
							break;
						}
					}
					if (ArrayLen(local.frames)) {
						break;
					}
				}
			}
		} catch (any frameErr) {
			// No usable frames.
		}
		return local.frames;
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
					// Type casting for boolean and numeric values. STRING comparison,
					// never `==`: Lucee compares `"1.0" == "true"` NUMERICALLY (1 == 1,
					// so true), which turned every .env value of numeric 1 into the BOOLEAN
					// true and made numeric settings silently take their defaults instead.
					if (Compare(lCase(local.value), "true") == 0 || Compare(lCase(local.value), "false") == 0) {
						local.value = (Compare(lCase(local.value), "true") == 0);
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
