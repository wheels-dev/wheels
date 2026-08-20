<cfscript>
/**
 * wheels.Global include: request
 * Request scope, CGI, paths, abort/404, engine adapter, processRequest.
 *
 * Included from `vendor/wheels/Global.cfc` at component-body scope so
 * these functions compile into the Global component. Children inherit
 * them; there is no per-instance mixin copy. Keep every helper that
 * must mix onto models/controllers `public` and `$`-prefixed
 * (cross-engine invariant 7).
 */


	// ======================================================================
	// REQUEST FUNCTIONS
	// ======================================================================

	/**
	 * Internal function.
	 */
	public void function $initializeRequestScope() {
		if (!StructKeyExists(request, "wheels")) {
			request.wheels = {};
			request.wheels.params = {};
			request.wheels.cache = {};
			request.wheels.urlForCache = {};
			request.wheels.tickCountId = GetTickCount();

			// Copy HTTP request data (contains content, headers, method and protocol).
			// This makes internal testing easier since we can overwrite it temporarily from the test suite.
			request.wheels.httpRequestData = GetHTTPRequestData();

			// Create a structure to track the transaction status for all adapters.
			request.wheels.transactions = {};
		}
	}


	/**
	 * Get the status code (e.g. 200, 404 etc) of the response we're about to send.
	 */
	public string function $statusCode() {
		if ($hasEngineAdapter()) {
			return $engineAdapter().getStatusCode();
		}
		// Fallback when adapter not yet initialized (e.g. error during startup)
		if (StructKeyExists(server, "lucee") || StructKeyExists(server, "boxlang")) {
			return GetPageContext().getResponse().getStatus();
		}
		return GetPageContext()
			.getFusionContext()
			.getResponse()
			.getStatus();
	}


	/**
	 * Gets the value of the content type header (blank string if it doesn't exist) of the response we're about to send.
	 */
	public string function $contentType() {
		if ($hasEngineAdapter()) {
			return $engineAdapter().getContentType();
		}
		// Fallback when adapter not yet initialized
		local.rv = "";
		if (StructKeyExists(server, "lucee")) {
			local.response = GetPageContext().getResponse();
		} else if (StructKeyExists(server, "boxlang")) {
			local.response = GetPageContext();
		} else {
			local.response = GetPageContext().getFusionContext().getResponse();
		}
		try {
			if (StructKeyExists(server, "boxlang")) {
				local.header = local.response.getRequest().getHeader("Content-Type");
			} else {
				local.header = local.response.containsHeader("Content-Type") ? local.response.getHeader("Content-Type") : Javacast(
					"null",
					""
				);
			}
			if (!IsNull(local.header)) {
				local.rv = local.header;
			}
		} catch (any e) {
		}
		return local.rv;
	}


	/**
	 * This copies all the variables Wheels needs from the CGI scope to the request scope.
	 */
	public struct function $cgiScope(
		string keys = "request_method,http_x_requested_with,http_referer,server_name,path_info,script_name,query_string,remote_addr,server_port,server_port_secure,server_protocol,http_host,http_accept,content_type,http_x_rewrite_url,http_x_original_url,request_uri,redirect_url,http_x_forwarded_for,http_x_forwarded_proto",
		struct scope = cgi
	) {
		local.rv = {};
		local.keyArray = ListToArray(arguments.keys);
		local.iEnd = ArrayLen(local.keyArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.item = local.keyArray[local.i];
			local.rv[local.item] = arguments.scope[local.item];
		}

		// fix path_info if it contains any characters that are not ascii (see issue 138)
		if (StructKeyExists(arguments.scope, "unencoded_url") && Len(arguments.scope.unencoded_url)) {
			local.requestUrl = UrlDecode(arguments.scope.unencoded_url);
		} else if (IsSimpleValue(GetPageContext().getRequest().getRequestURL())) {
			// remove protocol, domain, port etc from the url
			local.requestUrl = "/" & ListDeleteAt(
				ListDeleteAt(UrlDecode(GetPageContext().getRequest().getRequestURL()), 1, "/"),
				1,
				"/"
			);
		}
		if (StructKeyExists(local, "requestUrl") && ReFind("[^\x00-\x80]", local.requestUrl)) {
			// strip out the script_name and query_string leaving us with only the part of the string that should go in path_info
			local.rv.path_info = Replace(
				Replace(local.requestUrl, arguments.scope.script_name, ""),
				"?" & UrlDecode(arguments.scope.query_string),
				""
			);
		}

		// fixes IIS issue that returns a blank cgi.path_info
		if (!Len(local.rv.path_info) && Right(local.rv.script_name, 10) == "/index.cfm") {
			if (Len(local.rv.http_x_rewrite_url)) {
				// IIS6 1/ IIRF (Ionics Isapi Rewrite Filter)
				local.rv.path_info = ListFirst(local.rv.http_x_rewrite_url, "?");
			} else if (Len(local.rv.http_x_original_url)) {
				// IIS7 rewrite default
				local.rv.path_info = ListFirst(local.rv.http_x_original_url, "?");
			} else if (Len(local.rv.request_uri)) {
				// Apache default
				local.rv.path_info = ListFirst(local.rv.request_uri, "?");
			} else if (Len(local.rv.redirect_url)) {
				// Apache fallback
				local.rv.path_info = ListFirst(local.rv.redirect_url, "?");
			}

			// finally lets remove the index.cfm because some of the custom cgi variables don't bring it back
			// like this it means at the root we are working with / instead of /index.cfm
			if (Len(local.rv.path_info) >= 10 && Right(local.rv.path_info, 10) == "/index.cfm") {
				// this will remove the index.cfm and the trailing slash
				local.rv.path_info = Replace(local.rv.path_info, "/index.cfm", "");
				if (!Len(local.rv.path_info)) {
					// add back the forward slash if path_info was "/index.cfm"
					local.rv.path_info = "/";
				}
			}
		}

		// some web servers incorrectly place index.cfm in the path_info but since that should never be there we can safely remove it
		if (Find("index.cfm/", local.rv.path_info)) {
			Replace(local.rv.path_info, "index.cfm/", "");
		}
		return local.rv;
	}


	/**
	 * Internal function. Returns whether the application has opted into trusting `X-Forwarded-*`
	 * headers via `set(trustProxyHeaders=true)`. Guarded so it is safe to call on a cold start
	 * before `application.wheels` exists (resolves to `false`, i.e. do not trust).
	 */
	public boolean function $trustProxyHeaders() {
		return StructKeyExists(application, "wheels")
		&& StructKeyExists(application.wheels, "trustProxyHeaders")
		&& IsBoolean(application.wheels.trustProxyHeaders)
		&& application.wheels.trustProxyHeaders;
	}


	/**
	 * Internal function. Resolves the trusted client IP for security decisions.
	 * Returns `REMOTE_ADDR` (the socket address) unless `trustProxyHeaders` is enabled and
	 * `X-Forwarded-For` is non-empty, in which case the rightmost hop is used — that is the entry
	 * appended by the trusted proxy nearest the app; earlier entries are client-supplied and
	 * spoofable. For this to be safe the proxy must overwrite — never append to — the incoming
	 * header.
	 */
	public string function $trustedClientIp(string remoteAddr, string forwardedFor) {
		if (!StructKeyExists(arguments, "remoteAddr")) {
			arguments.remoteAddr = cgi.remote_addr;
		}
		if (!StructKeyExists(arguments, "forwardedFor")) {
			arguments.forwardedFor = cgi.http_x_forwarded_for;
		}
		local.rv = Trim(arguments.remoteAddr);
		if ($trustProxyHeaders() && Len(Trim(arguments.forwardedFor))) {
			local.rv = Trim(ListLast(arguments.forwardedFor));
		}
		return local.rv;
	}


	/**
	 * Internal function. Returns whether the current client is exempt from maintenance mode.
	 * The exception list comes from config only (`set(ipExceptions="...")`). A list containing
	 * letters is matched against the user agent (legacy behavior preserved verbatim); otherwise
	 * it is matched against the trusted client IP.
	 */
	public boolean function $maintenanceModeExempt(
		required string exceptions,
		required string userAgent,
		required string clientIp
	) {
		if (!Len(arguments.exceptions)) {
			return false;
		}
		if (ReFindNoCase("[a-z]", arguments.exceptions)) {
			return ListFindNoCase(arguments.exceptions, arguments.userAgent) > 0;
		}
		return ListFind(arguments.exceptions, arguments.clientIp) > 0;
	}


	/**
	 * Internal function. Derives `webPath`, `rootPath`, `rootcomponentPath`,
	 * and `wheelsComponentPath` from either an explicit URL `subpath`
	 * (issue #2968 — subfolder installs where `cgi.script_name` does not
	 * reflect the public mount) or, when no subpath is given, the existing
	 * `cgi.script_name` derivation. Returning a struct keeps the helper
	 * pure so it can be unit-tested in isolation.
	 */
	public struct function $resolveFrameworkPaths(required string scriptName, string subpath = "") {
		local.rv = {};
		local.normalized = Trim(arguments.subpath);
		if (Len(local.normalized) && Left(local.normalized, 1) != "/") {
			local.normalized = "/" & local.normalized;
		}
		// Strip trailing slash(es) without falling through to Left(str, 0),
		// which crashes Lucee 7 (see CLAUDE.md § "Cross-Engine Invariants").
		while (Len(local.normalized) > 1 && Right(local.normalized, 1) == "/") {
			local.normalized = Left(local.normalized, Len(local.normalized) - 1);
		}
		if (Len(local.normalized)) {
			local.rv.webPath = local.normalized == "/" ? "/" : local.normalized & "/";
		} else {
			local.rv.webPath = Replace(
				arguments.scriptName,
				Reverse(SpanExcluding(Reverse(arguments.scriptName), "/")),
				""
			);
		}
		local.rv.rootPath = "/" & ListChangeDelims(local.rv.webPath, "/", "/");
		local.rv.rootcomponentPath = ListChangeDelims(local.rv.webPath, ".", "/");
		local.rv.wheelsComponentPath = ListAppend(local.rv.rootcomponentPath, "wheels", ".");
		return local.rv;
	}


	/**
	 * Internal function. Rewrites a framework-relative include path (e.g.
	 * `/wheels/tests/app-runner.cfm`) so it resolves under a URL subpath
	 * install (issue #3251). The shipped app test-runner template includes
	 * the built-in app runner via an absolute `/wheels/...` path, which only
	 * resolves when the app is mounted at the web root; under a CommandBox
	 * multi-subfolder / IIS-subfolder topology the `/wheels` mapping does not
	 * resolve and the include fails. Prefixing the resolved `webPath` (the
	 * same subpath derivation as $resolveFrameworkPaths) makes the include
	 * work in both root and subfolder installs. Pure so it can be unit-tested
	 * in isolation.
	 */
	public string function $resolveSubpathInclude(required string template, string webPath) {
		// Default to the app's resolved webPath without a runtime default-arg
		// expression (some engines evaluate those eagerly); callers in tests
		// pass webPath explicitly.
		local.wp = StructKeyExists(arguments, "webPath") ? arguments.webPath : application.wheels.webPath;
		local.base = Len(local.wp) ? local.wp : "/";
		if (Right(local.base, 1) != "/") {
			local.base &= "/";
		}
		// Strip any leading slash(es) from the framework-relative template so
		// the join produces a single boundary slash. Anchored to the start so
		// it never touches interior path separators.
		local.relative = ReReplace(arguments.template, "^/+", "");
		return local.base & local.relative;
	}


	/**
	 * Internal function. Builds the debug bar's base reload URL (issue #3344).
	 * The base is composed from the resolved `webPath` plus the front-controller
	 * filename — the same idiom `urlFor()` uses — instead of raw
	 * `cgi.script_name`, so subfolder (subpath) installs emit links like
	 * `/myapp/posts?reload=` rather than `/myapp/public/index.cfm/posts?reload=`
	 * (which the user's rewrite rules don't route). The caller selects which
	 * path_info to pass (`request.cgi.path_info` when available, `cgi.path_info`
	 * otherwise — engines report it differently). `webPath` and `rewriteFile`
	 * default from application scope; tests pass them explicitly, and early
	 * boot/error paths where they're missing fall back to the raw script name
	 * (the pre-#3344 behavior). Pure string logic so it can be unit-tested in
	 * isolation.
	 */
	public string function $buildDebugReloadUrl(
		required string scriptName,
		string pathInfo = "",
		string queryString = "",
		string webPath,
		string rewriteFile
	) {
		// Resolve webPath/rewriteFile from application scope unless overridden.
		// No runtime default-arg expressions (some engines evaluate those
		// eagerly) — same pattern as $resolveSubpathInclude.
		if (StructKeyExists(arguments, "webPath")) {
			local.resolvedWebPath = arguments.webPath;
		} else if (IsDefined("application.wheels.webPath")) {
			local.resolvedWebPath = application.wheels.webPath;
		} else {
			local.resolvedWebPath = "";
		}
		if (StructKeyExists(arguments, "rewriteFile")) {
			local.resolvedRewriteFile = arguments.rewriteFile;
		} else if (IsDefined("application.wheels.rewriteFile")) {
			local.resolvedRewriteFile = application.wheels.rewriteFile;
		} else {
			local.resolvedRewriteFile = "";
		}

		// Base: webPath + front-controller filename (matches urlFor()); fall
		// back to the raw script name when webPath isn't resolved yet.
		if (Len(local.resolvedWebPath)) {
			local.rv = local.resolvedWebPath & ListLast(arguments.scriptName, "/");
		} else {
			local.rv = arguments.scriptName;
		}
		if (arguments.pathInfo != arguments.scriptName) {
			local.rv &= arguments.pathInfo;
		}
		if (Len(arguments.queryString)) {
			local.rv &= "?" & arguments.queryString;
		}
		if (Len(local.resolvedRewriteFile)) {
			local.rv = ReplaceNoCase(local.rv, "/" & local.resolvedRewriteFile, "");
		}
		local.reloadTokens = "development,testing,maintenance,production,true";
		local.iEnd = ListLen(local.reloadTokens);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.token = ListGetAt(local.reloadTokens, local.i);
			local.rv = ReplaceNoCase(
				ReplaceNoCase(local.rv, "?reload=" & local.token, ""),
				"&reload=" & local.token,
				""
			);
		}
		if (Find("?", local.rv)) {
			local.rv &= "&";
		} else {
			local.rv &= "?";
		}
		local.rv &= "reload=";
		return local.rv;
	}


	/**
	 * Abort when the requested template is nested deeper than
	 * `vendor/wheels/Global.cfc`. The depth check MUST use
	 * `ExpandPath("/wheels/Global.cfc")`, not `GetCurrentTemplatePath()`.
	 *
	 * This function lives in a component-body include. Lucee compiles it
	 * as a UDF of `/wheels/global/request.cfm`, so `GetCurrentTemplatePath()`
	 * is that mapping-absolute include (3 path segments). The front
	 * controller is `.../public/index.cfm` (many more segments), so the
	 * old comparison treated every normal request as invalid, ran the
	 * 404/`onmissingtemplate` path, and — with `$include` also compiled
	 * from an include — 500'd `onAbort` (Lucee 7 smokes, issue ##3241).
	 * `ExpandPath("/wheels/Global.cfc")` is the same filesystem path
	 * `GetCurrentTemplatePath()` returned when this method lived on
	 * Global.cfc itself.
	 */
	public void function $abortInvalidRequest() {
		local.applicationPath = Replace(ExpandPath("/wheels/Global.cfc"), "\", "/", "all");
		local.callingPath = Replace(GetBaseTemplatePath(), "\", "/", "all");
		if (
			!(GetFileFromPath(local.callingPath) == "runner.cfm")
			&&
			ListLen(local.callingPath, "/") > ListLen(local.applicationPath, "/")
		) {
			if (StructKeyExists(application, "wheels")) {
				if (StructKeyExists(application.wheels, "showErrorInformation") && !application.wheels.showErrorInformation) {
					$header(statusCode = 404);
				}
				if (StructKeyExists(application.wheels, "eventPath")) {
					$includeAndOutput(template = "#application.wheels.eventPath#/onmissingtemplate.cfm");
				}
			}
			$header(statusCode = 404);
			abort;
		}
	}


	/**
	 * Throw a developer friendly Wheels error if set (typically in development mode).
	 * Otherwise show the 404 page for end users (typically in production mode).
	 */
	public void function $throwErrorOrShow404Page(required string type, required string message, string extendedInfo = "") {
		$header(statusCode = 404);
		if ($get("showErrorInformation")) {
			Throw(type = arguments.type, message = arguments.message, extendedInfo = arguments.extendedInfo);
		} else {
			local.template = $get("eventPath") & "/onmissingtemplate.cfm";
			$includeAndOutput(template = local.template);
			abort;
		}
	}


	/**
	 * Returns the request timeout value in seconds.
	 * Must be safe to call during onError before application.wheels is initialized.
	 */
	public numeric function $getRequestTimeout() {
		if ($hasEngineAdapter()) {
			return $engineAdapter().getRequestTimeout();
		}
		// Fallback when adapter not yet initialized (e.g. error during startup)
		if (StructKeyExists(server, "boxlang")) {
			return 10000;
		} else if (StructKeyExists(server, "lucee")) {
			return (GetPageContext().getRequestTimeout() / 1000);
		} else {
			return CreateObject("java", "coldfusion.runtime.RequestMonitor").GetRequestTimeout();
		}
	}


	/**
	 * Returns the engine adapter instance for centralized cross-engine behavior.
	 * Checks both application.wheels (post-init) and application.$wheels (during init).
	 */
	public any function $engineAdapter() {
		if (
			StructKeyExists(application, "wheels") && IsStruct(application.wheels) && StructKeyExists(
				application.wheels,
				"engineAdapter"
			)
		) {
			return application.wheels.engineAdapter;
		}
		if (
			StructKeyExists(application, "$wheels") && IsStruct(application.$wheels) && StructKeyExists(
				application.$wheels,
				"engineAdapter"
			)
		) {
			return application.$wheels.engineAdapter;
		}
		Throw(type = "Wheels.EngineAdapterNotInitialized", message = "Engine adapter has not been initialized yet.");
	}


	/**
	 * Returns true if the engine adapter is available in application scope.
	 * Used by functions that may be called before onApplicationStart completes.
	 */
	public boolean function $hasEngineAdapter() {
		return (
			StructKeyExists(application, "wheels") && IsStruct(application.wheels) && StructKeyExists(
				application.wheels,
				"engineAdapter"
			)
		)
		|| (
			StructKeyExists(application, "$wheels") && IsStruct(application.$wheels) && StructKeyExists(
				application.$wheels,
				"engineAdapter"
			)
		);
	}


	/**
	 * Creates a controller and calls an action on it.
	 * Which controller and action that's called is determined by the params passed in.
	 * Returns the result of the request either as a string or in a struct with `body`, `emails`, `files`, `flash`, `redirect`, `status`, and `type`.
	 * Primarily used for testing purposes.
	 *
	 * [section: Controller]
	 * [category: Miscellaneous Functions]
	 *
	 * @params The params struct to use in the request (make sure that at least `controller` and `action` are set).
	 * @method The HTTP method to use in the request (`get`, `post` etc).
	 * @returnAs Pass in `struct` to return all information about the request instead of just the final output (`body`).
	 * @rollback Pass in `true` to roll back all database transactions made during the request.
	 * @includeFilters Set to `before` to only execute "before" filters, `after` to only execute "after" filters or `false` to skip all filters.
	 */
	public any function processRequest(
		required struct params,
		string method,
		string returnAs,
		string rollback,
		string includeFilters = true
	) {
		$args(name = "processRequest", args = arguments);

		// Set the global transaction mode to rollback when specified.
		// Also save the current state so we can set it back after the tests have run.
		if (arguments.rollback) {
			local.transactionMode = $get("transactionMode");
			$set(transactionMode = "rollback");
		}

		// Before proceeding we set the request method to our internal CGI scope if passed in.
		// This way it's possible to mock a POST request so that an isPost() call in the action works as expected for example.
		if (arguments.method != "get") {
			request.cgi.request_method = arguments.method;
		}

		// Look up controller & action via route name and method
		if (StructKeyExists(arguments.params, "route")) {
			local.route = $findRoute(argumentCollection = arguments.params, method = arguments.method);
			arguments.params.controller = local.route.controller;
			arguments.params.action = local.route.action;
		}

		// Never deliver email or send files during test.
		local.deliverEmail = $get(functionName = "sendEmail", name = "deliver");
		$set(functionName = "sendEmail", deliver = false);
		local.deliverFile = $get(functionName = "sendFile", name = "deliver");
		$set(functionName = "sendFile", deliver = false);

		local.controller = controller(name = arguments.params.controller, params = arguments.params);

		// Set to ignore CSRF errors during testing.
		local.controller.protectsFromForgery(with = "ignore");

		local.controller.processAction(includeFilters = arguments.includeFilters);
		local.response = local.controller.response();

		// Get redirect info.
		// If a delayed redirect was made we use the status code for that and set the body to a blank string.
		// If not we use the current status code and response and set the redirect info to a blank string.
		local.redirectDetails = local.controller.getRedirect();
		if (StructCount(local.redirectDetails)) {
			local.body = "";
			local.redirect = local.redirectDetails.url;
			local.status = local.redirectDetails.statusCode;
		} else {
			local.status = $statusCode();
			local.body = local.response;
			local.redirect = "";
		}

		if (arguments.returnAs == "struct") {
			local.rv = {
				body = local.body,
				emails = local.controller.getEmails(),
				files = local.controller.getFiles(),
				flash = local.controller.flash(),
				redirect = local.redirect,
				status = local.status,
				type = $contentType()
			};
		} else {
			local.rv = local.body;
		}

		// Clear the Flash so we can run several processAction calls without the Flash sticking around.
		local.controller.$flashClear();

		// Set back the global transaction mode to the previous value if it has been changed.
		if (arguments.rollback) {
			$set(transactionMode = local.transactionMode);
		}

		// Set back the request method to GET (this is fine since the test suite is always run using GET).
		request.cgi.request_method = "get";

		// Set back email delivery setting to previous value.
		$set(functionName = "sendEmail", deliver = local.deliverEmail);
		$set(functionName = "sendFile", deliver = local.deliverFile);

		// Set back the status code to 200 so the test suite does not use the same code that the action that was tested did.
		// If the test suite fails it will set the status code to 500 later.
		$header(statusCode = 200);

		// Set the Content-Type header in case it was set to something else (e.g. application/json) during processing.
		// It's fine to do this because we always want to return the test page as text/html.
		$header(name = "Content-Type", value = "text/html", charset = "UTF-8");

		return local.rv;
	}
</cfscript>
