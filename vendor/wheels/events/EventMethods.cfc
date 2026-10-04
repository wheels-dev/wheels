component extends="wheels.Global" implements="wheels.interfaces.events.EventHandlerInterface" {
	public string function $runOnError(required exception, required eventName) {
		if (StructKeyExists(application, "wheels") && StructKeyExists(application.wheels, "initialized")) {
			$restoreTestRunnerApplicationScope();
			if (application.wheels.sendEmailOnError) {
				$runOnErrorSendEmail(arguments.exception);
			}
			// Fire registered onError callbacks (packages like Sentry hook in here).
			$fireOnErrorCallbacks(arguments.exception);
			if ($get("showErrorInformation")) {
				// Detect request format for format-specific error handling
				local.format = $getRequestFormat();
				local.wheelsError = $runOnErrorResolveWheelsError(arguments.exception);
				if (!StructIsEmpty(local.wheelsError)) {
					local.rv = $runOnErrorRenderWheelsError(local.wheelsError, local.format);
				} else {
					local.rv = $runOnErrorRenderException(arguments.exception, local.format);
				}
			} else {
				local.rv = $runOnErrorRenderTemplate(arguments.exception, arguments.eventName);
			}
		} else {
			Throw(object = arguments.exception);
		}
		return local.rv;
	}

	public void function $runOnErrorSendEmail(required exception) {
		local.args = {};
		$args(name = "sendEmail", args = local.args);
		// Only configured addresses: errorEmailToAddress, else errorEmailAddress.
		// The sender falls back to the recipient.
		local.args.to = application.wheels.errorEmailToAddress;
		if (!Len(local.args.to)) {
			local.args.to = application.wheels.errorEmailAddress;
		}
		local.args.from = application.wheels.errorEmailFromAddress;
		if (!Len(local.args.from)) {
			local.args.from = application.wheels.errorEmailAddress;
		}
		if (!Len(local.args.from)) {
			local.args.from = local.args.to;
		}
		if (!Len(local.args.to)) {
			$warnNoErrorEmailRecipient();
			return;
		}
		if (Len(local.args.from) && Len(local.args.to)) {
			if (StructKeyExists(application.wheels, "errorEmailServer") && Len(application.wheels.errorEmailServer)) {
				local.args.server = application.wheels.errorEmailServer;
			}
			local.args.subject = application.wheels.errorEmailSubject;
			local.rootCause = "";
			if (
				StructKeyExists(arguments.exception, "rootCause") && StructKeyExists(arguments.exception.rootCause, "message")
			) {
				local.rootCause = arguments.exception.rootCause.message;
			}
			if (application.wheels.includeErrorInEmailSubject && Len(local.rootCause)) {
				local.args.subject &= ": " & local.rootCause;
			}
			local.args.type = "html";
			local.args.tagContent = $includeAndReturnOutput(
				$template = "/wheels/events/onerror/cfmlerror.cfm",
				exception = arguments.exception
			);
			StructDelete(local.args, "layouts", false);
			StructDelete(local.args, "detectMultiPart", false);
			try {
				$mail(argumentCollection = local.args);
			} catch (any e) {
			}
		}
	}

	/**
	 * sendEmailOnError is on but no recipient is configured: say so once per
	 * application start in wheels.log instead of sending anything.
	 */
	public void function $warnNoErrorEmailRecipient() {
		if (StructKeyExists(application.wheels, "$errorEmailRecipientWarned")) {
			return;
		}
		application.wheels["$errorEmailRecipientWarned"] = true;
		try {
			WriteLog(
				file = "wheels",
				type = "warning",
				text = "Wheels: sendEmailOnError is on but no error email recipient is configured, so no error email was sent. Set errorEmailAddress (or errorEmailToAddress) in config/settings.cfm or config/production/settings.cfm."
			);
		} catch (any e) {
		}
	}

	// Untyped return: this returns either {} or a cfcatch/exception object,
	// and Adobe's struct return-type validator rejects the latter.
	public any function $runOnErrorResolveWheelsError(required exception) {
		// Returns {} when the exception is not a Wheels-raised error.
		local.wheelsError = {};
		if ($engineAdapter().isBoxLang()) {
			if (StructKeyExists(arguments.exception, "type") && Left(arguments.exception.type, 6) == "Wheels") {
				local.wheelsError = arguments.exception;
			} else if (
				StructKeyExists(arguments.exception, "cause")
				&& !IsNull(arguments.exception.cause) && IsStruct(arguments.exception.cause)
				&& StructKeyExists(arguments.exception.cause, "rootCause")
				&& !IsNull(arguments.exception.cause.rootCause)
				&& IsStruct(arguments.exception.cause.rootCause)
				&& StructKeyExists(arguments.exception.cause.rootCause, "type")
				&& Left(arguments.exception.cause.rootCause.type, 6) == "Wheels"
			) {
				local.wheelsError = arguments.exception.cause.rootCause;
			}
		} else {
			if (StructKeyExists(arguments.exception, "rootCause") && Left(arguments.exception.rootCause.type, 6) == "Wheels") {
				local.wheelsError = arguments.exception.rootCause;
			} else if (
				StructKeyExists(arguments.exception, "cause")
				&& !IsNull(arguments.exception.cause) && IsStruct(arguments.exception.cause)
				&& StructKeyExists(arguments.exception.cause, "rootCause")
				&& !IsNull(arguments.exception.cause.rootCause)
				&& IsStruct(arguments.exception.cause.rootCause)
				&& StructKeyExists(arguments.exception.cause.rootCause, "type")
				&& Left(arguments.exception.cause.rootCause.type, 6) == "Wheels"
			) {
				local.wheelsError = arguments.exception.cause.rootCause;
			}
		}
		return local.wheelsError;
	}

	/**
	 * Maps a `Wheels.*` error type to the HTTP status its error page should carry.
	 * Single source of truth for both the render path and onerrorSpec.
	 *
	 * 404 is a client-triggerable ALLOW-LIST, not "any `Wheels.*NotFound`". Only the
	 * not-found types a client URL can produce get a 404; every other `*NotFound`
	 * (and every unmatched type) defaults to 500 so monitoring sees the server
	 * fault. This reverses the earlier "any `*NotFound` -> 404" rule.
	 *
	 * - 404: `Wheels.RouteNotFound`, `Wheels.RecordNotFound`, `Wheels.ViewNotFound`
	 *   (a URL naming a non-existent view-only action), `Wheels.ActionNotAllowed`
	 *   (a helper/$-named action treated as missing, #2845/#3075),
	 *   `Wheels.ActionParameterMissing` (a /wheels/ dev-GUI URL that names no
	 *   action), and `Wheels.FileNotFound` (`sendFile()` for a missing file: it
	 *   usually serves a client-addressed download route). `Wheels.ImageFileNotFound`
	 *   stays 500. #2319/#3075.
	 * - 403: a policy denial (`Wheels.NotAuthorized`, #3156) or a missing/invalid
	 *   CSRF token (`Wheels.InvalidAuthenticityToken`) — a forged or expired-form
	 *   post is a client error, not a server error (A-F7).
	 * - 406: `Wheels.FormatNotAcceptable` — an explicit `.ext` / `?format=` the
	 *   action cannot answer (#3866).
	 * - 500: everything else, including server-side schema/config misses
	 *   (`Wheels.TableNotFound`, `Wheels.DataSourceNotFound`,
	 *   `Wheels.ColumnNotFound` — a misconfigured or unmigrated deploy, A-F4),
	 *   every other `*NotFound` (Model, Method, Filter, Association, Package,
	 *   Vite assets/manifest, …), and any future type. Serving 404 for these
	 *   hides a server fault from monitoring.
	 */
	public numeric function $wheelsErrorStatusCode(required string type) {
		// 404 is a client-triggerable ALLOW-LIST: only the not-found types a client
		// URL can produce — an unknown route, or a missing record/view/action for a
		// resolved route. The framework commits 404 at these throw sites via
		// $throwErrorOrShow404Page (RouteNotFound in Dispatch; RecordNotFound and
		// ViewNotFound — a URL naming a non-existent view-only action — in
		// controller/processing; ActionNotAllowed, a helper/$-named action treated
		// as missing, #2845/#3075), plus FileNotFound: sendFile() usually serves a
		// client-addressed download route, so a missing file is the client's "not
		// found" (ImageFileNotFound is not on the list). Every OTHER Wheels.*NotFound is a server-side
		// config/code fault (a missing table, datasource, column, model, method,
		// filter, association, calculated property, group column, identity, key,
		// object, package, query handle, service, job class, Vite asset/manifest,
		// image file, …) and defaults to 500 so monitoring sees it — including any
		// future *NotFound type. (A-F4; follows #2319/#3075/#3156.)
		if (
			ReFindNoCase("^Wheels\.(Route|Record|View|File)NotFound$", arguments.type)
			|| arguments.type == "Wheels.ActionNotAllowed"
			|| arguments.type == "Wheels.ActionParameterMissing"
		) {
			return 404;
		}
		// 403: a policy denial (#3156) or a missing/invalid CSRF token (A-F7).
		if (ReFindNoCase("^Wheels\.(NotAuthorized|InvalidAuthenticityToken)$", arguments.type)) {
			return 403;
		}
		// 406: an explicit .[format] / ?format= the action cannot answer (#3866).
		if (arguments.type == "Wheels.FormatNotAcceptable") {
			return 406;
		}
		return 500;
	}


	public string function $runOnErrorRenderWheelsError(required wheelsError, required format) {
		// Map Wheels error types to HTTP status codes via the
		// $wheelsErrorStatusCode allow-list: the client-triggerable
		// not-found types (RouteNotFound, RecordNotFound, ViewNotFound,
		// FileNotFound, ActionNotAllowed, ActionParameterMissing) are 404; a policy
		// denial or missing/invalid CSRF token is 403; FormatNotAcceptable
		// is 406; everything else — including server-side *NotFound
		// (table/datasource/column/model/package/…) — is 500. See
		// $wheelsErrorStatusCode for the full rationale (#2319/#3075/#3156).
		// Set the status BEFORE writing the body so the response
		// header is committed at the right code regardless of
		// when the servlet engine flushes (HTML-format Wheels
		// errors used to render with HTTP 200 because no
		// $header(statusCode=...) fired before the body was
		// written — see GH #2319). Note: $throwErrorOrShow404Page
		// already calls $header(statusCode=404) before throwing
		// (and the authorization mixin's $notAuthorized() calls
		// $header(statusCode=403)), but onError reaches us via
		// Application.cfc which can reset the response, so we
		// re-assert the status here.
		$header(
			statusCode = StructKeyExists(arguments.wheelsError, "type")
				? $wheelsErrorStatusCode(arguments.wheelsError.type)
				: 500
		);
		local.rv = "";
		if (arguments.format == "json") {
			$header(name = "Content-Type", value = "application/json");
			local.rv = SerializeJSON(arguments.wheelsError);
		} else if (arguments.format == "xml") {
			$header(name = "Content-Type", value = "text/xml");
			local.rv = $toXml(arguments.wheelsError);
		} else {
			// Default HTML error display
			if (!StructKeyExists(request.wheels, "internalHeaderLoaded")) {
				local.rv &= $includeAndReturnOutput($template = "/wheels/public/layout/_header_simple.cfm");
			}
			local.rv &= $includeAndReturnOutput(
				$template = "/wheels/events/onerror/wheelserror.cfm",
				wheelsError = arguments.wheelsError
			);
			if (!StructKeyExists(request.wheels, "internalHeaderLoaded")) {
				local.rv &= $includeAndReturnOutput($template = "/wheels/public/layout/_footer_simple.cfm");
			}
		}
		return local.rv;
	}

	public string function $runOnErrorRenderException(required exception, required format) {
		if (arguments.format == "json") {
			$header(name = "Content-Type", value = "application/json");
			$header(statusCode = 500);
			local.rv = SerializeJSON(arguments.exception);
		} else if (arguments.format == "xml") {
			$header(name = "Content-Type", value = "text/xml");
			$header(statusCode = 500);
			local.rv = $toXml(arguments.exception);
		} else {
			// Default behavior: throw the exception for HTML display
			Throw(object = arguments.exception);
		}
		return local.rv;
	}

	public string function $runOnErrorRenderTemplate(required exception, required eventName) {
		$header(statusCode = 500);

		local.format = $getRequestFormat();
		local.formatSpecificTemplate = "#application.wheels.eventPath#/onerror.#local.format#.cfm";

		if (FileExists(ExpandPath(local.formatSpecificTemplate))) {
			local.errorTemplate = local.formatSpecificTemplate;
		} else {
			local.errorTemplate = "#application.wheels.eventPath#/onerror.cfm";
		}

		local.rv = $includeAndReturnOutput(
			$template = local.errorTemplate,
			eventName = arguments.eventName,
			exception = arguments.exception
		);

		if (local.format == "json") {
			$header(name = "Content-Type", value = "application/json");
		} else if (local.format == "xml") {
			$header(name = "Content-Type", value = "application/xml");
		}
		return local.rv;
	}

	public void function $runOnRequestStart(required targetPage) {
		// Perform the redirect-after-reload that onApplicationStart deferred
		// (issue #3054). The redirect must not fire inside onApplicationStart
		// itself: cflocation aborts the event mid-flight and the engine then
		// discards the half-started application, silently reverting URL
		// environment switches into production/maintenance (the two
		// environments that auto-enable redirectAfterReload). By the time this
		// event runs, the new application — including a switched environment —
		// has been persisted, so aborting here is safe. Runs first on purpose:
		// nothing else in this event matters for a request being redirected.
		if (StructKeyExists(request, "wheels") && StructKeyExists(request.wheels, "redirectAfterReloadUrl")) {
			// The URL is built from the app-relative path_info: keep it a path on this site
			// and put the subfolder back (#3948).
			local.redirectAfterReloadUrl = $reloadRedirectPath(path = request.wheels.redirectAfterReloadUrl);
			StructDelete(request.wheels, "redirectAfterReloadUrl");
			$location(url = local.redirectAfterReloadUrl, addToken = false);
		}
		// A test run that died before restoring the datasource settings it switched
		// (its request was killed, so its finally block never ran) leaves markers
		// behind. Once that run's deadline has passed, put the settings back so the
		// app does not keep reading and writing the test datasource.
		if (StructKeyExists(application, "$$$appTestOriginalDataSource")) {
			application.wo.$recoverStrandedTestRun(force = false);
		}

		// If the first debug point has not already been set in a reload request we set it here.
		if ($get("showDebugInformation")) {
			if (StructKeyExists(request.wheels, "execution")) {
				$debugPoint("reload");
			} else {
				$debugPoint("total");
			}
			$debugPoint("requestStart");
		}

		// Copy over the cgi variables we need to the request scope unless it's already been done on application start.
		if (!StructKeyExists(request, "cgi")) {
			request.cgi = $cgiScope();
		}

		// Copy HTTP headers.
		$initializeRequestHeaders();

		// Soft-reload of app/global/*.cfm when bare ?reload=true is hit in dev
		// and any tracked include has a newer mtime. The password-gated
		// applicationStop() path already does a full re-init, so we skip the
		// check when url.password is present (issue 2792).
		//
		// The environment guard is intentional: this soft-reload is a
		// development-only convenience. Use the password-gated reload for
		// non-dev environments — setting reloadOnGlobalChange=true outside
		// development is a deliberate no-op.
		if (
			StructKeyExists(url, "reload")
			&& !StructKeyExists(url, "password")
			&& StructKeyExists(application.wheels, "reloadOnGlobalChange")
			&& application.wheels.reloadOnGlobalChange
			&& application.wheels.environment == "development"
			&& StructKeyExists(application.wheels, "globalIncludesSnapshot")
			&& application.wo.$globalIncludesChanged(snapshot = application.wheels.globalIncludesSnapshot)
		) {
			// Double-checked locking — two concurrent ?reload=true hits would
			// otherwise both pass the outer check and race on $reincludeGlobals
			// against the same application.wo instance. Lock name is
			// per-application so shared Adobe CF servers running multiple
			// apps don't serialize on a single global lock.
			lock type="exclusive" name="wheels_reload_globals_#application.applicationName#" timeout="5" {
				if (application.wo.$globalIncludesChanged(snapshot = application.wheels.globalIncludesSnapshot)) {
					application.wo.$reincludeGlobals();
					application.wheels.globalIncludesSnapshot = application.wo.$snapshotGlobalIncludes();
				}
			}
		}

		// Reload the plugins on each request if cachePlugins is set to false.
		if (!application.wheels.cachePlugins) {
			$loadPlugins();
		}

		// Reload packages on each request if cachePlugins is set to false.
		if (!application.wheels.cachePlugins && StructKeyExists(application.wheels, "enablePackagesComponent") && application.wheels.enablePackagesComponent) {
			$loadPackages();
		}

		// Inject methods from plugins and packages directly to Application.cfc.
		// Uses the shared application-cached Plugins instance ($pluginObj). The
		// previous unconditional `new wheels.Plugins()` at the top of this event
		// paid a full Plugins + wheels.Global pseudo-constructor on every
		// request; #3160 (Stage 3 PR A) moved the construction inside this
		// mixins-nonempty guard so mixin-free apps skip it, and this change
		// (PR B) drops the per-request construction entirely in favor of the
		// cached instance (issue #2897).
		if (!StructIsEmpty(application.wheels.mixins)) {
			$engineAdapter().prepareDIComplete(variables, this);
			$pluginObj().$initializeMixins(variables);
		}

		if (application.wheels.environment == "maintenance") {
			// Exceptions come from config only (set(ipExceptions="...")). The legacy ?except=
			// URL parameter let any anonymous client rewrite the exception list for everyone
			// (issue #2953), so request data is no longer written into the application scope.
			// The client IP is the socket address unless the app opted into X-Forwarded-For
			// (rightmost hop) via set(trustProxyHeaders=true).
			if (
				!$maintenanceModeExempt(
					exceptions = application.wheels.ipExceptions,
					userAgent = cgi.http_user_agent,
					clientIp = $trustedClientIp()
				)
			) {
				$header(statusCode = 503);

				// Set the content to be displayed in maintenance mode to a request variable and exit the function.
				// This variable is then checked in the Wheels $request function (which is what sets what to render).
				request.$wheelsAbortContent = $includeAndReturnOutput(
					$template = "#application.wheels.eventPath#/onmaintenance.cfm"
				);
				return;
			}
		}
		if (Right(arguments.targetPage, 4) == ".cfc") {
			StructDelete(this, "onRequest");
			StructDelete(variables, "onRequest");
		}
		if (!application.wheels.cacheModelConfig) {
			local.lockName = "modelLock" & application.applicationName;
			$simpleLock(name = local.lockName, execute = "$clearModelInitializationCache", type = "exclusive");
		}
		if (!application.wheels.cacheControllerConfig) {
			local.lockName = "controllerLock" & application.applicationName;
			$simpleLock(name = local.lockName, execute = "$clearControllerInitializationCache", type = "exclusive");
		}
		if (!application.wheels.cacheDatabaseSchema) {
			$clearCache("sql");
		}
		if (application.wheels.allowCorsRequests) {
			// When a wheels.middleware.Cors instance is registered it owns CORS
			// headers + preflight; emitting the global headers here too would
			// stack duplicate Access-Control-Allow-* values (a duplicate
			// Access-Control-Allow-Origin makes browsers reject the response).
			// Defer to the middleware pipeline and warn once. (#3114)
			if ($corsMiddlewareActive()) {
				$warnGlobalCorsDeferred();
			} else {
				$setCORSHeaders(
					allowOrigin = application.wheels.accessControlAllowOrigin,
					allowCredentials = application.wheels.accessControlAllowCredentials,
					allowHeaders = application.wheels.accessControlAllowHeaders,
					allowMethods = application.wheels.accessControlAllowMethods,
					allowMethodsByRoute = application.wheels.accessControlAllowMethodsByRoute
				);
			}
		}
		$include(template = "#application.wheels.eventPath#/onrequeststart.cfm");
		if ($get("showDebugInformation")) {
			$debugPoint("requestStart");
		}

		// Also for CORS compliance, an OPTIONS request must return 200 and the above headers. No data is required.
		// This will be remove when OPTIONS is implemented in the mapper (issue #623)
		// Skipped when a wheels.middleware.Cors instance is registered — the
		// dispatch pipeline answers preflight via $hasPreflightCapableMiddleware()
		// so aborting here (with no headers, since $setCORSHeaders was deferred)
		// would break the preflight. (#3114)
		if (
			application.wheels.allowCorsRequests
			&& !$corsMiddlewareActive()
			&& StructKeyExists(request, "CGI")
			&& StructKeyExists(request.CGI, "request_method")
			&& request.CGI.request_method eq "OPTIONS"
		) {
			abort;
		}
	}

	/**
	 * Internal function. Memoizes HTTP request headers in request.$wheelsHeaders.
	 * Reuses the GetHTTPRequestData() result stored by $initializeRequestScope()
	 * so the request body is not materialized a second time per request.
	 */
	public void function $initializeRequestHeaders() {
		if (!StructKeyExists(request, "$wheelsHeaders")) {
			if (StructKeyExists(request, "wheels") && StructKeyExists(request.wheels, "httpRequestData")) {
				request.$wheelsHeaders = request.wheels.httpRequestData.headers;
			} else {
				request.$wheelsHeaders = GetHTTPRequestData().headers;
			}
		}
	}

	public void function $runOnRequestEnd(required targetpage) {
		if ($get("showDebugInformation")) {
			$debugPoint("requestEnd");
		}
		$restoreTestRunnerApplicationScope();
		$include(template = "#application.wheels.eventPath#/onrequestend.cfm");
		if ($get("showDebugInformation")) {
			$debugPoint("requestEnd,total");
		}
	}

	public void function $runOnSessionStart() {
		$initializeRequestScope();
		$include(template = "#application.wheels.eventPath#/onsessionstart.cfm");
	}

	public void function $runOnSessionEnd(required sessionScope, required applicationScope) {
		$include(template = "#arguments.applicationScope.wheels.eventPath#/onsessionend.cfm", argumentCollection = arguments);
	}

	public void function $runOnMissingTemplate(required targetpage) {
		if (!$get("showErrorInformation")) {
			$header(statusCode = 404);
		}
		$includeAndOutput(template = "#application.wheels.eventPath#/onmissingtemplate.cfm");
		abort;
	}
	
	/**
	 * Internal function to detect the request format.
	 */
	public string function $getRequestFormat() {
		local.rv = "html";
		if (StructKeyExists(url, "format")) {
			// Security: reject non-alphanumeric url.format to prevent LFI via the error-template include path in $runOnError.
			if (ReFind("^[A-Za-z0-9]+$", url.format)) {
				local.rv = url.format;
			}
		} else if ((StructKeyExists(request, "cgi") && StructKeyExists(request.cgi, "http_accept"))){
			local.httpAccept = request.cgi.http_accept;
			local.formats = $get("formats");
			for (local.item in local.formats) {
				if (FindNoCase(local.formats[local.item], local.httpAccept)) {
					local.rv = local.item;
					break;
				}
			}
		}

		return local.rv;
	}

}
