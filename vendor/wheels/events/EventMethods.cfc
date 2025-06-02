component extends="wheels.Global" {
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
			if (application.wheels.showErrorInformation) {
				if (StructKeyExists(arguments.exception, "rootCause") && Left(arguments.exception.rootCause.type, 6) == "Wheels") {
					local.wheelsError = arguments.exception.rootCause;
				} else if (
					StructKeyExists(arguments.exception, "cause")
					&& StructKeyExists(arguments.exception.cause, "rootCause")
					&& Left(arguments.exception.cause.rootCause.type, 6) == "Wheels"
				) {
					local.wheelsError = arguments.exception.cause.rootCause;
				}
				if (StructKeyExists(local, "wheelsError")) {
					local.rv = "";

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
				} else {
					Throw(object = arguments.exception);
				}
			} else {
				$header(statusCode = 500);
				local.rv = $includeAndReturnOutput(
					$template = "#application.wheels.eventPath#/onerror.cfm",
					eventName = arguments.eventName,
					exception = arguments.exception
				);
			}
		} else {
			Throw(object = arguments.exception);
		}
		return local.rv;
	}

	public void function $runOnRequestStart(required targetPage) {
		local.Mixins = new wheels.Plugins();
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
		if (!StructKeyExists(request, "$wheelsHeader")) {
			request.$wheelsHeaders = GetHTTPRequestData().headers;
		}

		// Reload the plugins on each request if cachePlugins is set to false.
		if (!application.wheels.cachePlugins) {
			$loadPlugins();
		}

		// Inject methods from plugins directly to Application.cfc.
		if (!StructIsEmpty(application.wheels.mixins)) {
			local.Mixins.$initializeMixins(variables);
		}

		if (application.wheels.environment == "maintenance") {
			if (StructKeyExists(url, "except")) {
				application.wheels.ipExceptions = url.except;
			}
			local.makeException = false;
			if (Len(application.wheels.ipExceptions)) {
				if (ReFindNoCase("[a-z]", application.wheels.ipExceptions)) {
					if (ListFindNoCase(application.wheels.ipExceptions, cgi.http_user_agent)) {
						local.makeException = true;
					}
				} else {
					local.ipAddress = cgi.remote_addr;
					if (Len(request.cgi.http_x_forwarded_for)) {
						local.ipAddress = request.cgi.http_x_forwarded_for;
					}
					if (ListFind(application.wheels.ipExceptions, local.ipAddress)) {
						local.makeException = true;
					}
				}
			}
			if (!local.makeException) {
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
			$setCORSHeaders(
				allowOrigin = application.wheels.accessControlAllowOrigin,
				allowCredentials = application.wheels.accessControlAllowCredentials,
				allowHeaders = application.wheels.accessControlAllowHeaders,
				allowMethods = application.wheels.accessControlAllowMethods,
				allowMethodsByRoute = application.wheels.accessControlAllowMethodsByRoute
			);
		}
		$include(template = "#application.wheels.eventPath#/onrequeststart.cfm");
		if (application.wheels.showDebugInformation) {
			$debugPoint("requestStart");
		}

		// Also for CORS compliance, an OPTIONS request must return 200 and the above headers. No data is required.
		// This will be remove when OPTIONS is implemented in the mapper (issue #623)
		if (
			application.wheels.allowCorsRequests
			&& StructKeyExists(request, "CGI")
			&& StructKeyExists(request.CGI, "request_method")
			&& request.CGI.request_method eq "OPTIONS"
		) {
			abort;
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
}
