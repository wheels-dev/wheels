component extends="wheels.Global" implements="wheels.interfaces.events.EventHandlerInterface" {
	public string function $runOnError(required exception, required eventName) {
		if (StructKeyExists(application, "wheels") && StructKeyExists(application.wheels, "initialized")) {
			$restoreTestRunnerApplicationScope();
			if (application.wheels.sendEmailOnError) {
				local.args = {};
				$args(name = "sendEmail", args = local.args);
				local.args.from = application.wheels.errorEmailAddress;
				if (Len(application.wheels.errorEmailFromAddress)) {
					local.args.from = application.wheels.errorEmailFromAddress;
				}
				local.args.to = application.wheels.errorEmailAddress;
				if (Len(application.wheels.errorEmailToAddress)) {
					local.args.to = application.wheels.errorEmailToAddress;
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
			// Fire registered onError callbacks (packages like Sentry hook in here).
			$fireOnErrorCallbacks(arguments.exception);
			if (application.wheels.showErrorInformation) {
				// Detect request format for format-specific error handling
				local.format = $getRequestFormat();
				
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
				if (StructKeyExists(local, "wheelsError")) {
					// Map Wheels error types to HTTP status codes. Any
					// `Wheels.*NotFound` (RouteNotFound, RecordNotFound,
					// ViewNotFound, etc) is a 404, as is `Wheels.ActionNotAllowed`
					// — the action-dispatch gate blocks framework helpers and
					// $-prefixed internals by treating them as missing actions
					// (#2845, #3075); everything else is a 500.
					// Set the status BEFORE writing the body so the response
					// header is committed at the right code regardless of
					// when the servlet engine flushes (HTML-format Wheels
					// errors used to render with HTTP 200 because no
					// $header(statusCode=...) fired before the body was
					// written — see GH #2319). Note: $throwErrorOrShow404Page
					// already calls $header(statusCode=404) before throwing,
					// but onError reaches us via Application.cfc which can
					// reset the response, so we re-assert the status here.
					if (
						StructKeyExists(local.wheelsError, "type")
						&& ReFindNoCase("^Wheels\.([A-Za-z]*NotFound|ActionNotAllowed)$", local.wheelsError.type)
					) {
						$header(statusCode = 404);
					} else {
						$header(statusCode = 500);
					}
					local.rv = "";
					if (local.format == "json") {
						$header(name = "Content-Type", value = "application/json");
						local.rv = SerializeJSON(local.wheelsError);
					} else if (local.format == "xml") {
						$header(name = "Content-Type", value = "text/xml");
						local.rv = $toXml(local.wheelsError);
					} else {
						// Default HTML error display
						if (!StructKeyExists(request.wheels, "internalHeaderLoaded")) {
							local.rv &= $includeAndReturnOutput($template = "/wheels/public/layout/_header_simple.cfm");
						}
						local.rv &= $includeAndReturnOutput(
							$template = "/wheels/events/onerror/wheelserror.cfm",
							wheelsError = local.wheelsError
						);
						if (!StructKeyExists(request.wheels, "internalHeaderLoaded")) {
							local.rv &= $includeAndReturnOutput($template = "/wheels/public/layout/_footer_simple.cfm");
						}
					}
				} else {
					if (local.format == "json") {
						$header(name = "Content-Type", value = "application/json");
						$header(statusCode = 500);
						local.rv = SerializeJSON(arguments.exception);
					} else if (local.format == "xml") {
						$header(name = "Content-Type", value = "text/xml");
						$header(statusCode = 500);
						local.rv = $toXml(arguments.exception);
					} else {
						// Default behavior: throw the exception for HTML display
						Throw(object = arguments.exception);
					}
				}
			} else {
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
			}
		} else {
			Throw(object = arguments.exception);
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
			local.redirectAfterReloadUrl = request.wheels.redirectAfterReloadUrl;
			StructDelete(request.wheels, "redirectAfterReloadUrl");
			$location(url = local.redirectAfterReloadUrl, addToken = false);
		}
		// If the first debug point has not already been set in a reload request we set it here.
		if (application.wheels.showDebugInformation) {
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
		if (application.wheels.showDebugInformation) {
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
		if (application.wheels.showDebugInformation) {
			$debugPoint("requestEnd");
		}
		$restoreTestRunnerApplicationScope();
		$include(template = "#application.wheels.eventPath#/onrequestend.cfm");
		if (application.wheels.showDebugInformation) {
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
		if (!application.wheels.showErrorInformation) {
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
