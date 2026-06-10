component {
	/**
	 * Redirects the browser to the supplied controller/action/key, route or back to the referring page.
	 * Internally, this function uses the `URLFor` function to build the link and the `cflocation` tag to perform the redirect.
	 *
	 * [section: Controller]
	 * [category: Miscellaneous Functions]
	 *
	 * @back Set to `true` to redirect back to the referring page.
	 * @addToken See documentation for your CFML engine's implementation of `cflocation`.
	 * @statusCode See documentation for your CFML engine's implementation of `cflocation`.
	 * @route Name of a route that you have configured in `config/routes.cfm`.
	 * @controller Name of the controller to include in the URL.
	 * @action Name of the action to include in the URL.
	 * @key Key(s) to include in the URL.
	 * @params Any additional parameters to be set in the query string (example: `wheels=cool&x=y`). Please note that Wheels uses the `&` and `=` characters to split the parameters and encode them properly for you. However, if you need to pass in `&` or `=` as part of the value, then you need to encode them (and only them), example: `a=cats%26dogs%3Dtrouble!&b=1`.
	 * @anchor Sets an anchor name to be appended to the path.
	 * @onlyPath If `true`, returns only the relative URL (no protocol, host name or port).
	 * @host Set this to override the current host.
	 * @protocol Set this to override the current protocol.
	 * @port Set this to override the current port number.
	 * @method HTTP method constraint used when matching routes.
	 * @url Redirect to an external URL.
	 * @delay Set to `true` to delay the redirection until after the rest of your action code has executed.
	 * @encode Encode URL parameters using `EncodeForURL()`. Please note that this does not make the string safe for placement in HTML attributes, for that you need to wrap the result in `EncodeForHtmlAttribute()` or use `linkTo()`, `startFormTag()` etc instead.
	 */
	public void function redirectTo(
		boolean back = false,
		boolean addToken,
		numeric statusCode,
		string route = "",
		string method = "",
		string controller = "",
		string action = "",
		any key = "",
		string params = "",
		string anchor = "",
		boolean onlyPath,
		string host,
		string protocol,
		numeric port,
		string url = "",
		boolean delay,
		boolean encode
	) {
		// F5: capture whether the caller explicitly passed `statusCode` BEFORE
		// $args copies the framework default (302) in. Used below to upgrade
		// the default to 303 for non-idempotent request methods without
		// overriding an explicit user choice.
		local.userPassedStatusCode = StructKeyExists(arguments, "statusCode");

		$args(name = "redirectTo", args = arguments);

		// F5: When redirecting after a POST/PUT/PATCH/DELETE without an
		// explicit statusCode, upgrade the default 302 ("Found", historically
		// ambiguous on method handling) to 303 ("See Other", which always
		// downgrades the next request to GET regardless of the original
		// method). RFC 7231 §6.4.4 specifies 303 for the "redirect after
		// POST" pattern. Browsers treat 302 as 303 for compat, but scripted
		// clients (curl with -L, programmatic HTTP libs) follow the spec
		// literally — so the upgrade makes scripted smoke tests work
		// correctly without method-replay surprises.
		if (
			!local.userPassedStatusCode
			&& StructKeyExists(request, "cgi")
			&& StructKeyExists(request.cgi, "request_method")
			&& ListFindNoCase("POST,PUT,PATCH,DELETE", request.cgi.request_method)
		) {
			arguments.statusCode = 303;
		}

		// Set flash if passed in.
		// If more than the arguments listed in the function declaration was passed in it's possible that one of them is intended for the flash.
		local.functionInfo = GetMetadata(variables.redirectTo);
		if (StructCount(arguments) > ArrayLen(local.functionInfo.parameters)) {
			// Create a list of all the argument names that should not be set to the flash.
			// This includes arguments to the function itself or ones meant for a route.
			local.nonFlashArgumentNames = "";
			if (Len(arguments.route)) {
				local.nonFlashArgumentNames = ListAppend(
					local.nonFlashArgumentNames,
					$findRoute(argumentCollection = arguments).foundvariables
				);
			}
			local.iEnd = ArrayLen(local.functionInfo.parameters);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.nonFlashArgumentNames = ListAppend(local.nonFlashArgumentNames, local.functionInfo.parameters[local.i].name);
			}

			// Loop through arguments and when the first flash argument is found we set it.
			local.argumentNames = StructKeyList(arguments);
			local.argumentNamesArray = ListToArray(local.argumentNames);
			local.iEnd = ArrayLen(local.argumentNamesArray);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.item = local.argumentNamesArray[local.i];
				if (!ListFindNoCase(local.nonFlashArgumentNames, local.item)) {
					local.key = ReReplaceNoCase(local.item, "^flash(.)", "\l\1");
					local.flashArguments = {};
					local.flashArguments[local.key] = arguments[local.item];
					flashInsert(argumentCollection = local.flashArguments);
				}
			}
		}

		// Set the url that will be used in the cflocation tag.
		if (arguments.back) {
			if (Len(request.cgi.http_referer) && $isSafeRedirectUrl(url = request.cgi.http_referer, serverName = request.cgi.server_name)) {
				// Referrer exists and points to the same domain so it's ok to redirect to it.
				local.url = request.cgi.http_referer;
				if (Len(arguments.params)) {
					// Append params to the referrer url.
					local.params = $constructParams(params = arguments.params, encode = arguments.encode);
					if (Find("?", request.cgi.http_referer)) {
						local.params = Replace(local.params, "?", "&");
					} else if (Left(local.params, 1) == "&" && !Find(request.cgi.http_referer, "?")) {
						local.params = Replace(local.params, "&", "?", "one");
					}
					local.url &= local.params;
				}
			} else {
				// We can't redirect to the referrer so we either use a fallback route/controller/action combo or send to the root of the site.
				if (Len(arguments.route) || Len(arguments.controller) || Len(arguments.action)) {
					local.url = uRLFor(argumentCollection = arguments);
				} else {
					local.url = $get("webPath");
				}
			}
		} else if (Len(arguments.url)) {
			if (!$get("allowExternalRedirects") && !$isSafeRedirectUrl(url = arguments.url, serverName = request.cgi.server_name)) {
				Throw(
					type = "Wheels.UnsafeRedirect",
					message = "The URL passed to `redirectTo()` is not safe for redirection.",
					extendedInfo = "Only relative URLs and URLs matching the current domain are allowed. Set allowExternalRedirects=true to permit external redirects. URL: #EncodeForHTML(arguments.url)#"
				);
			}
			local.url = arguments.url;
			if (Len(arguments.params)) {
				if (Find("?", arguments.url)) {
					local.url = "#local.url#&#arguments.params#";
				} else {
					local.url = "#local.url#?#arguments.params#";
				}
			}
		} else {
			local.url = uRLFor(argumentCollection = arguments);
		}

		// Schedule or perform the redirect right away.
		if (arguments.delay) {
			if (StructKeyExists(variables.$instance, "redirect")) {
				// Throw an error if the developer has already scheduled a redirect previously in this request.
				Throw(type = "Wheels.RedirectToAlreadyCalled", message = "`redirectTo()` was already called.");
			} else {
				// Schedule a redirect that will happen after the action code has been completed.
				variables.$instance.redirect = {};
				variables.$instance.redirect.url = local.url;
				variables.$instance.redirect.addToken = arguments.addToken;
				variables.$instance.redirect.statusCode = arguments.statusCode;
				variables.$instance.redirect.$args = arguments;
			}
		} else {
			// Do the redirect now using cflocation.
			$location(url = local.url, addToken = arguments.addToken, statusCode = arguments.statusCode);
		}
	}

	/**
	 * Validates that a URL is safe for redirection (relative or same-domain).
	 * Prevents open redirect attacks by extracting the hostname from absolute URLs
	 * and comparing it exactly to the current server name.
	 *
	 * [section: Controller]
	 * [category: Miscellaneous Functions]
	 */
	public boolean function $isSafeRedirectUrl(required string url, required string serverName) {
		// Reject any URL containing a backslash outright. Browsers normalize backslashes to forward
		// slashes ("/\evil.com", "\/evil.com" and "\\evil.com" all navigate to evil.com), so a
		// backslash anywhere makes the URL unsafe. Literal backslashes in legitimate URLs should be
		// percent-encoded (matches the $generateIncludeTemplatePath precedent).
		if (Find(Chr(92), arguments.url)) {
			return false;
		}

		// Protocol-relative URL (//hostname/path): only safe when the hostname matches the current
		// server name exactly.
		if (Left(arguments.url, 2) == "//") {
			local.afterScheme = Mid(arguments.url, 3, Len(arguments.url) - 2);
			local.refererHost = ListFirst(local.afterScheme, ":/?##");
			return CompareNoCase(local.refererHost, arguments.serverName) == 0;
		}

		// Relative URLs (starting with a single "/") are always safe.
		if (Left(arguments.url, 1) == "/") {
			return true;
		}

		// No scheme (RFC 3986: ALPHA *( ALPHA / DIGIT / "+" / "-" / "." ) followed by ":") and not
		// "/"-rooted: a genuine relative path (e.g. "page", "dir/page").
		if (ReFindNoCase("^[a-z][a-z0-9+.-]*:", arguments.url) == 0) {
			return true;
		}

		// The URL has a scheme: it is only safe when it is a same-domain scheme://hostname/... URL.
		// Schemes without a "//" authority (javascript:, mailto:, data:, "https:/evil.com") are
		// rejected because browsers normalize or execute them in ways that escape the current domain.
		local.schemeEnd = Find("://", arguments.url);
		if (local.schemeEnd == 0) {
			return false;
		}
		local.afterScheme = Mid(arguments.url, local.schemeEnd + 3, Len(arguments.url) - local.schemeEnd - 2);

		// Extract hostname before any port, path, query, or fragment delimiter.
		local.refererHost = ListFirst(local.afterScheme, ":/?##");

		return CompareNoCase(local.refererHost, arguments.serverName) == 0;
	}
}
