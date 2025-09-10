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
	 * @url Redirect to an external URL.
	 * @delay Set to `true` to delay the redirection until after the rest of your action code has executed.
	 * @encode [see:URLFor].
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
		$args(name = "redirectTo", args = arguments);

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
			if (Len(request.cgi.http_referer) && FindNoCase(request.cgi.server_name, request.cgi.http_referer)) {
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
}
