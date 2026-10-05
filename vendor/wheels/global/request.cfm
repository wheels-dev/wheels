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
		// Each key is initialized on its own, and only when missing. request.wheels
		// can exist without them: on Adobe CF 2025 the engine raises an error during
		// application startup and the app's onError sets request.wheels.exception /
		// eventName before this runs, and helpers (cache, pagination, settings,
		// middleware) create request.wheels on demand. The old all-or-nothing guard
		// then left httpRequestData unset, and Dispatch failed with "Element
		// WHEELS.HTTPREQUESTDATA.HEADERS is undefined" (#3726). Keys that are already
		// present, including what onError recorded, are kept.
		if (!StructKeyExists(request, "wheels")) {
			request.wheels = {};
		}
		if (!StructKeyExists(request.wheels, "params")) {
			request.wheels.params = {};
		}
		if (!StructKeyExists(request.wheels, "cache")) {
			request.wheels.cache = {};
		}
		if (!StructKeyExists(request.wheels, "urlForCache")) {
			request.wheels.urlForCache = {};
		}
		if (!StructKeyExists(request.wheels, "tickCountId")) {
			request.wheels.tickCountId = GetTickCount();
		}
		if (!StructKeyExists(request.wheels, "httpRequestData")) {
			// Copy HTTP request data (contains content, headers, method and protocol).
			// This makes internal testing easier since we can overwrite it temporarily from the test suite.
			request.wheels.httpRequestData = GetHTTPRequestData();
		}
		if (!StructKeyExists(request.wheels, "transactions")) {
			// Create a structure to track the transaction status for all adapters.
			request.wheels.transactions = {};
		}
		// GHSA-8r22: apply the per-request IP-debug grant here, before the app's
		// Application.cfc runs its own debug-IP handling. Every 4.x Application.cfc
		// calls $initializeRequestScope() first, so an app that still carries the
		// pre-4.1.2 block still gets the correct request-scoped grant; this is
		// idempotent with the new template's explicit application.wo call. Guarded
		// for the cold-start path where application.wheels is not built yet.
		if (StructKeyExists(application, "wheels")) {
			$applyIPDebugAccess();
		}
	}


	/**
	 * Internal function. IP-based debug access (`set(allowIPBasedDebugAccess=true)`
	 * outside development): when the client IP is in `debugAccessIPs`, THIS request
	 * gets the public component plus debug and error information. The grant is
	 * stored in request.wheels.debugAccess, which $get() reads first, and never in
	 * application.wheels: that scope is shared by every concurrent request, so
	 * writing the grant there showed one client's permission to the others.
	 * Called from Application.cfc's onRequestStart().
	 */
	public void function $applyIPDebugAccess(string clientIP = "") {
		if (!StructKeyExists(request, "wheels")) {
			request.wheels = {};
		}
		StructDelete(request.wheels, "debugAccess");
		if (
			!StructKeyExists(application.wheels, "allowIPBasedDebugAccess")
			|| !IsBoolean(application.wheels.allowIPBasedDebugAccess)
			|| !application.wheels.allowIPBasedDebugAccess
			|| application.wheels.environment == "development"
			|| !StructKeyExists(application.wheels, "debugAccessIPs")
			|| !IsArray(application.wheels.debugAccessIPs)
		) {
			return;
		}
		local.clientIP = Len(arguments.clientIP) ? arguments.clientIP : $ipDebugAccessClientIP();
		if (!Len(local.clientIP) || !ArrayContains(application.wheels.debugAccessIPs, local.clientIP)) {
			return;
		}
		request.wheels.debugAccess = {enablePublicComponent = true, showDebugInformation = true, showErrorInformation = true};
		// The GUI component object is only created at startup when the public
		// component is enabled for everyone; create it once for granted requests.
		// Creating it grants nothing: Dispatch still checks the per-request setting.
		if (!StructKeyExists(application.wheels, "public")) {
			application.wheels.public = $createObjectFromRoot(path = "wheels", fileName = "Public", method = "$init");
		}
	}

	/**
	 * Internal function. The client address for IP-based debug access: the socket
	 * address, or the rightmost X-Forwarded-For entry (the one the nearest proxy
	 * appended) only when `set(debugAccessTrustProxy=true)`.
	 */
	public string function $ipDebugAccessClientIP() {
		local.clientIP = Trim(CGI.REMOTE_ADDR);
		if (
			StructKeyExists(application.wheels, "debugAccessTrustProxy")
			&& IsBoolean(application.wheels.debugAccessTrustProxy)
			&& application.wheels.debugAccessTrustProxy
			&& Len(Trim(CGI.HTTP_X_FORWARDED_FOR))
		) {
			local.clientIP = Trim(ListLast(CGI.HTTP_X_FORWARDED_FOR));
		}
		return local.clientIP;
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
			if ($trustProxyHeaders() && Len(local.rv.http_x_rewrite_url)) {
				// IIS6 1/ IIRF (Ionics Isapi Rewrite Filter). Client-supplied;
				// only trusted when the app opted in via trustProxyHeaders.
				local.rv.path_info = ListFirst(local.rv.http_x_rewrite_url, "?");
			} else if ($trustProxyHeaders() && Len(local.rv.http_x_original_url)) {
				// IIS7 rewrite default. Same trust gate as X-Forwarded-*.
				local.rv.path_info = ListFirst(local.rv.http_x_original_url, "?");
			} else if (Len(local.rv.request_uri)) {
				// Apache default
				local.rv.path_info = ListFirst(local.rv.request_uri, "?");
			} else if (Len(local.rv.redirect_url)) {
				// Apache fallback
				local.rv.path_info = ListFirst(local.rv.redirect_url, "?");
			}

			// Under a subfolder (script_name "/app1/index.cfm") these fallbacks carry the
			// subfolder, which the router would read as a controller name (#3948).
			local.rv.path_info = $stripScriptDirectory(pathInfo = local.rv.path_info, scriptName = local.rv.script_name);

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

		// some web servers incorrectly place index.cfm in the path_info (e.g. the IIS fallbacks above copy
		// request_uri "/index.cfm/users/list" verbatim) but since that should never be there we can safely
		// remove it. Anchored to the start so a later segment such as "/docs/myindex.cfm/x" is left alone.
		if (ReFindNoCase("^/index\.cfm/", local.rv.path_info)) {
			local.rv.path_info = ReReplaceNoCase(local.rv.path_info, "^/index\.cfm/", "/");
		}
		return local.rv;
	}


	/**
	 * Internal function. Removes the front controller's directory (`/app1` for a
	 * script name of `/app1/index.cfm`) from the start of a request path, so a path
	 * taken from `request_uri` or a rewrite header under a subfolder install becomes
	 * app-relative (#3948). Paths outside that directory, and root installs, are
	 * returned unchanged; the directory itself becomes "/".
	 */
	public string function $stripScriptDirectory(required string pathInfo, required string scriptName) {
		local.directory = ReReplace(arguments.scriptName, "/[^/]*$", "");
		if (!Len(local.directory) || !Len(arguments.pathInfo)) {
			return arguments.pathInfo;
		}
		if (CompareNoCase(arguments.pathInfo, local.directory) == 0) {
			return "/";
		}
		local.prefixLength = Len(local.directory) + 1;
		if (
			Len(arguments.pathInfo) > local.prefixLength
			&& CompareNoCase(Left(arguments.pathInfo, local.prefixLength), local.directory & "/") == 0
		) {
			return Mid(arguments.pathInfo, local.prefixLength, Len(arguments.pathInfo));
		}
		if (CompareNoCase(arguments.pathInfo, local.directory & "/") == 0) {
			return "/";
		}
		return arguments.pathInfo;
	}

	/**
	 * Internal function. Returns whether the application has opted into trusting
	 * proxy-supplied headers via `set(trustProxyHeaders=true)`: `X-Forwarded-*`
	 * plus the IIS rewrite headers `X-Rewrite-URL` / `X-Original-URL` used by
	 * `$cgiScope()`. Guarded so it is safe to call on a cold start before
	 * `application.wheels` exists (resolves to `false`, i.e. do not trust).
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
		local.rv = local.base & local.relative;
		// The production call shape (no webPath): when the subfolder maps to the app's
		// public/ folder (an IIS virtual directory or a Tomcat context), the prefixed
		// path does not exist but the `/wheels` mapping resolves, so keep the plain
		// path (#3948).
		if (
			!StructKeyExists(arguments, "webPath")
			&& local.base != "/"
			&& !FileExists(ExpandPath(local.rv))
			&& FileExists(ExpandPath("/" & local.relative))
		) {
			local.rv = "/" & local.relative;
		}
		return local.rv;
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
		string rewriteFile,
		string urlRewriting
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
		if (StructKeyExists(arguments, "urlRewriting")) {
			local.resolvedUrlRewriting = arguments.urlRewriting;
		} else if (IsDefined("application.wheels.URLRewriting")) {
			local.resolvedUrlRewriting = application.wheels.URLRewriting;
		} else {
			local.resolvedUrlRewriting = "";
		}
		// Partial rewriting routes only through the front controller, so the link keeps
		// it (/app1/index.cfm/posts?reload=); without it the link 404s (#3948).
		if (Len(local.resolvedRewriteFile) && CompareNoCase(local.resolvedUrlRewriting, "Partial") != 0) {
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
	 * Internal function. Prefixes the app's `webPath` onto the redirect-after-reload URL,
	 * which is built from the app-relative `cgi.path_info`, so a reload under a subfolder
	 * returns to `/app1/widgets` instead of `/widgets` (#3948). URLs already under the
	 * subfolder, root installs and absolute URLs are returned unchanged.
	 */
	public string function $prefixWebPath(required string path, string webPath) {
		if (StructKeyExists(arguments, "webPath")) {
			local.wp = arguments.webPath;
		} else if (IsDefined("application.wheels.webPath")) {
			local.wp = application.wheels.webPath;
		} else {
			local.wp = "";
		}
		local.base = ReReplace(local.wp, "/+$", "");
		if (!Len(local.base) || Left(arguments.path, 1) != "/" || Left(arguments.path, 2) == "//") {
			return arguments.path;
		}
		local.pathOnly = ListFirst(arguments.path, "?");
		if (
			CompareNoCase(local.pathOnly, local.base) == 0
			|| (Len(local.pathOnly) > Len(local.base) && CompareNoCase(Left(local.pathOnly, Len(local.base) + 1), local.base & "/") == 0)
		) {
			return arguments.path;
		}
		return local.base & arguments.path;
	}

	/**
	 * Internal function. Where the redirect after a reload goes: the request's app-relative
	 * path with any leading run of slashes, backslashes, spaces and control characters
	 * collapsed to a single `/` (browsers drop tab, CR and LF from a URL), so the location is
	 * always a path on this site, then prefixed with the app's `webPath`.
	 */
	public string function $reloadRedirectPath(required string path, string webPath) {
		local.len = Len(arguments.path);
		local.i = 1;
		while (local.i <= local.len) {
			local.code = Asc(Mid(arguments.path, local.i, 1));
			if (local.code == 47 || local.code == 92 || local.code <= 32 || local.code == 127) {
				local.i++;
			} else {
				break;
			}
		}
		if (local.i == 1) {
			local.cleanPath = arguments.path;
		} else if (local.i > local.len) {
			local.cleanPath = "/";
		} else {
			local.cleanPath = "/" & Mid(arguments.path, local.i, local.len - local.i + 1);
		}
		local.args = {path = local.cleanPath};
		if (StructKeyExists(arguments, "webPath")) {
			local.args.webPath = arguments.webPath;
		}
		return $prefixWebPath(argumentCollection = local.args);
	}

	/**
	 * Internal function. The URL of a page in the offline docs bundle, which is served
	 * by the `docsBundle` route: the app's `webPath`, the front controller unless URL
	 * rewriting is fully on, then `wheels-docs/<path>`. A hard-coded `/wheels-docs/`
	 * link 404s under a subfolder install (#3948).
	 */
	public string function $debugDocsUrl(
		string path = "",
		string webPath,
		string rewriteFile,
		string urlRewriting
	) {
		local.wp = StructKeyExists(arguments, "webPath") ? arguments.webPath : (IsDefined("application.wheels.webPath") ? application.wheels.webPath : "/");
		local.file = StructKeyExists(arguments, "rewriteFile") ? arguments.rewriteFile : (IsDefined("application.wheels.rewriteFile") ? application.wheels.rewriteFile : "");
		local.mode = StructKeyExists(arguments, "urlRewriting") ? arguments.urlRewriting : (IsDefined("application.wheels.URLRewriting") ? application.wheels.URLRewriting : "On");
		local.rv = Len(local.wp) ? local.wp : "/";
		if (Right(local.rv, 1) != "/") {
			local.rv &= "/";
		}
		if (CompareNoCase(local.mode, "On") != 0 && Len(local.file)) {
			local.rv &= local.file & "/";
		}
		return local.rv & "wheels-docs/" & ReReplace(arguments.path, "^/+", "");
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
				if (StructKeyExists(application.wheels, "showErrorInformation") && !$get("showErrorInformation")) {
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
	 * @csrf CSRF handling for this request. Default `ignore` preserves the historic test helper. Pass `exception` or `abort` to enforce; this is opt-in and does not change the production `protectsFromForgery()` default.
	 */
	public any function processRequest(
		required struct params,
		string method,
		string returnAs,
		string rollback,
		string includeFilters = true,
		string csrf = "ignore"
	) {
		$args(name = "processRequest", args = arguments);

		// Capture the state processRequest() changes so the finally below can restore it on EVERY exit —
		// including when the action throws and the caller catches it. Restoring only on the success path
		// leaked the request method / transaction mode / deliver=false into later specs (reported by a
		// downstream app: request.cgi.request_method stayed "post", so a later redirectTo() answered 303
		// instead of 302). The request method is restored to its PREVIOUS value, not a hard-coded "get",
		// so nested callers stay correct.
		local.restore = {
			requestMethod = (StructKeyExists(request, "cgi") && StructKeyExists(request.cgi, "request_method")) ? request.cgi.request_method : "get",
			rollback = arguments.rollback,
			transactionMode = arguments.rollback ? $get("transactionMode") : "",
			deliverEmail = $get(functionName = "sendEmail", name = "deliver"),
			deliverFile = $get(functionName = "sendFile", name = "deliver")
		};

		try {
			// Set the global transaction mode to rollback when specified.
			if (arguments.rollback) {
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
			$set(functionName = "sendEmail", deliver = false);
			$set(functionName = "sendFile", deliver = false);

			local.controller = controller(name = arguments.params.controller, params = arguments.params);

			// Historic test helper defaults to ignore. Opt in to exception/abort
			// without flipping the production protectsFromForgery() default.
			// The override is applied to this controller instance only: protectsFromForgery() would
			// write it into the application-wide cached controller class (#3843).
			local.controller.$setCsrfOverride(type = arguments.csrf);

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

			return local.rv;
		} finally {
			// Restore everything processRequest() changed, on every exit (success, throw or abort).
			// This try has NO catch, so BoxLang runs this finally on an abort too (cross-engine
			// invariant 22); there is no for-loop here (Lucee 7 miscompiles loops in a finally,
			// invariant 12) — only plain assignments and calls.
			if (local.restore.rollback) {
				$set(transactionMode = local.restore.transactionMode);
			}
			request.cgi.request_method = local.restore.requestMethod;
			$set(functionName = "sendEmail", deliver = local.restore.deliverEmail);
			$set(functionName = "sendFile", deliver = local.restore.deliverFile);
			// Reset the status code and Content-Type so a later processAction / assertion starts clean
			// (the test suite sets 500 later if it fails).
			$header(statusCode = 200);
			$header(name = "Content-Type", value = "text/html", charset = "UTF-8");
		}
	}
</cfscript>
