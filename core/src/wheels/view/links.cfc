component {
	/**
	 * Creates a link to another page in your application.
	 * Pass in the name of a route to use your configured routes or a controller/action/key combination.
	 * Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.
	 *
	 * [section: View Helpers]
	 * [category: Link Functions]
	 *
	 * @text The text content of the link.
	 * @route Name of a route that you have configured in config/routes.cfm.
	 * @controller Name of the controller to include in the URL.
	 * @action Name of the action to include in the URL.
	 * @key Key(s) to include in the URL.
	 * @params Any additional parameters to be set in the query string (example: wheels=cool&x=y). Please note that CFWheels uses the & and = characters to split the parameters and encode them properly for you. However, if you need to pass in & or = as part of the value, then you need to encode them (and only them), example: a=cats%26dogs%3Dtrouble!&b=1.
	 * @anchor Sets an anchor name to be appended to the path.
	 * @onlyPath If true, returns only the relative URL (no protocol, host name or port).
	 * @host Set this to override the current host.
	 * @protocol Set this to override the current protocol.
	 * @port Set this to override the current port number.
	 * @href Pass a link to an external site here if you want to bypass the CFWheels routing system altogether and link to an external URL.
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function linkTo(
		string text,
		string route = "",
		string controller = "",
		string action = "",
		any key = "",
		string params = "",
		string anchor = "",
		boolean onlyPath,
		string host,
		string protocol,
		numeric port,
		string href,
		any encode
	) {
		$args(name = "linkTo", args = arguments);

		// look for passed in rest method
		if (StructKeyExists(arguments, "method")) {
			// if dealing with delete, keep robots from following link
			if (arguments.method == "delete") {
				if (!StructKeyExists(arguments, "rel")) {
					arguments.rel = "";
				}
				arguments.rel = ListAppend(arguments.rel, "no-follow", " ");
			}
		}

		local.encodeExcept = "";
		if (!StructKeyExists(arguments, "href")) {
			local.args = Duplicate(arguments);
			local.args.$encodeForHtmlAttribute = true;
			if (local.args.encode == "attributes") {
				local.args.encode = true;
			}
			arguments.href = uRLFor(argumentCollection = local.args);
			local.encodeExcept = "href";
		}
		if (!StructKeyExists(arguments, "text")) {
			arguments.text = arguments.href;
		}
		local.skip = "text,route,controller,action,key,params,anchor,onlyPath,host,protocol,port,encode";
		if (Len(arguments.route)) {
			// variables passed in as route arguments should not be added to the html element
			local.skip = ListAppend(local.skip, $routeVariables(argumentCollection = arguments));
		}
		return $element(
			name = "a",
			skip = local.skip,
			content = arguments.text,
			attributes = arguments,
			encode = arguments.encode,
			encodeExcept = local.encodeExcept
		);
	}

	/**
	 * Creates a form containing a single button that submits to the URL. Note: Pass any additional arguments by prefixing them with "input" like inputClass, inputRel, and inputId, and the generated tag will also include those values as HTML attributes.
	 * The URL is built the same way as the `linkTo` function.
	 *
	 * [section: View Helpers]
	 * [category: Link Functions]
	 *
	 * @text The text content of the button.
	 * @image If you want to use an image for the button pass in the link to it here (relative from the `images` folder).
	 * @route [see:URLFor].
	 * @controller [see:URLFor].
	 * @action [see:URLFor].
	 * @key [see:URLFor].
	 * @params [see:URLFor].
	 * @anchor [see:URLFor].
	 * @method [see:startFormTag].
	 * @onlyPath [see:URLFor].
	 * @host [see:URLFor].
	 * @protocol [see:URLFor].
	 * @port [see:URLFor].
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function buttonTo(
		string text,
		string image,
		string route = "",
		string controller = "",
		string action = "",
		any key = "",
		string params = "",
		string anchor = "",
		string method,
		boolean onlyPath,
		string host,
		string protocol,
		numeric port,
		any encode
	) {
		local.method = "post";
		$args(name = "buttonTo", args = arguments);
		local.content = "";
		if (StructKeyExists(arguments, "method")) {
			if (!ListFindNoCase("post,get", arguments.method)) {
				local.methodField = hiddenFieldTag(name = "_method", value = arguments.method);
				// Delete the id="_method" part of the string.
				// There could be multiple forms on a page and duplicate "id" attributes are not allowed in HTML.
				local.methodField = Replace(local.methodField, ' id="_method" ', " ");
				local.content &= local.methodField;
			} else if (arguments.method == "get") {
				local.method = "get";
			}
		}
		arguments.method = local.method;
		local.args = Duplicate(arguments);
		local.args.$encodeForHtmlAttribute = true;
		if (local.args.encode == "attributes") {
			local.args.encode = true;
		}
		arguments.action = uRLFor(argumentCollection = local.args);
		local.encodeExcept = "action";
		local.args = $innerArgs(name = "input", args = arguments);
		local.args.image = arguments.image;
		local.args.encode = arguments.encode;
		local.content &= buttonTag(argumentCollection = local.args, content = arguments.text);
		local.skip = "image,text,route,controller,key,params,anchor,onlyPath,host,protocol,port,encode";
		if (Len(arguments.route)) {
			// variables passed in as route arguments should not be added to the html element
			local.skip = ListAppend(local.skip, $routeVariables(argumentCollection = arguments));
		}
		local.encode = IsBoolean(arguments.encode) && arguments.encode ? "attributes" : false;
		if ($isRequestProtectedFromForgery() && ListFindNoCase("post,put,patch,delete", arguments.method)) {
			local.content &= authenticityTokenField();
		}
		return $element(
			name = "form",
			skip = local.skip,
			content = local.content,
			attributes = arguments,
			encode = local.encode,
			encodeExcept = local.encodeExcept
		);
	}

	/**
	 * Creates a `mailto` link tag to the specified email address, which is also used as the name of the link unless name is specified.
	 *
	 * [section: View Helpers]
	 * [category: Link Functions]
	 *
	 * @emailAddress The email address to link to.
	 * @name A string to use as the link text ("Joe" or "Support Department", for example).
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function mailTo(required string emailAddress, string name = "", any encode) {
		$args(name = "mailTo", reserved = "href", args = arguments);
		arguments.href = "mailto:" & arguments.emailAddress;
		local.content = Len(arguments.name) ? arguments.name : arguments.emailAddress;
		return $element(
			name = "a",
			skip = "emailAddress,name,encode",
			content = local.content,
			attributes = arguments,
			encode = arguments.encode
		);
	}

	/**
	 * Builds and returns a string containing links to pages based on a paginated query.
	 * Uses `linkTo()` internally to build the link, so you need to pass in a route name or a controller/action/key combination.
	 * All other `linkTo()` arguments can be supplied as well, in which case they are passed through directly to `linkTo()`.
	 * If you have paginated more than one query in the controller, you can use the handle argument to reference them. (Don't forget to pass in a handle to the `findAll()` function in your controller first.)
	 *
	 * [section: View Helpers]
	 * [category: Link Functions]
	 *
	 * @windowSize The number of page links to show around the current page.
	 * @alwaysShowAnchors Whether or not links to the first and last page should always be displayed.
	 * @anchorDivider String to place next to the anchors on either side of the list.
	 * @linkToCurrentPage Whether or not the current page should be linked to.
	 * @prepend String or HTML to be prepended before result.
	 * @append String or HTML to be appended after result.
	 * @prependToPage String or HTML to be prepended before each page number.
	 * @prependOnFirst Whether or not to prepend the prependToPage string on the first page in the list.
	 * @prependOnAnchor Whether or not to prepend the prependToPage string on the anchors.
	 * @appendToPage String or HTML to be appended after each page number.
	 * @appendOnLast Whether or not to append the appendToPage string on the last page in the list.
	 * @appendOnAnchor Whether or not to append the appendToPage string on the anchors.
	 * @classForCurrent Class name for the current page number (if linkToCurrentPage is true, the class name will go on the a element. If not, a span element will be used).
	 * @handle The handle given to the query that the pagination links should be displayed for.
	 * @name The name of the param that holds the current page number.
	 * @showSinglePage Will show a single page when set to true. (The default behavior is to return an empty string when there is only one page in the pagination).
	 * @pageNumberAsParam Decides whether to link the page number as a param or as part of a route. (The default behavior is true).
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function paginationLinks(
		numeric windowSize,
		boolean alwaysShowAnchors,
		string anchorDivider,
		boolean linkToCurrentPage,
		string prepend,
		string append,
		string prependToPage,
		boolean addActiveClassToPrependedParent,
		boolean prependOnFirst,
		boolean prependOnAnchor,
		string appendToPage,
		boolean appendOnLast,
		boolean appendOnAnchor,
		string classForCurrent,
		string handle = "query",
		string name,
		boolean showSinglePage,
		boolean pageNumberAsParam,
		any encode
	) {
		/* To fix the bug below:
			https://github.com/cfwheels/cfwheels/issues/942

			The paginationLinks() function does not set the correct URL on the anchor tag if route is not passed in. Added condition to default the route, if it is not passed in, to the route defined in the request.wheels.params, if the action is index.
		*/
		if (!StructKeyExists(arguments, "route")) {
			if(structKeyExists(request.wheels, 'params') AND structKeyExists(request.wheels.params, 'route')) {
				if(request.wheels.params.action EQ "index"){
					arguments.route = request.wheels.params.route;
				}
			}
		}

		$args(name = "paginationLinks", args = arguments);
		if (StructKeyExists(arguments, "params") && isStruct(arguments.params)) {
			arguments.params = $paramsToQueryString(arguments.params);
		}
		local.skipArgs = "windowSize,alwaysShowAnchors,anchorDivider,linkToCurrentPage,prepend,append,prependToPage,addActiveClassToPrependedParent,prependOnFirst,prependOnAnchor,appendToPage,appendOnLast,appendOnAnchor,classForCurrent,handle,name,showSinglePage,pageNumberAsParam";
		local.linkToArguments = Duplicate(arguments);
		local.iEnd = ListLen(local.skipArgs);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			StructDelete(local.linkToArguments, ListGetAt(local.skipArgs, local.i));
		}
		local.currentPage = pagination(arguments.handle).currentPage;
		local.totalPages = pagination(arguments.handle).totalPages;
		local.start = "";
		local.middle = "";
		local.end = "";
		if (StructKeyExists(arguments, "route")) {
			// when a route name is specified and the name argument is part
			// of the route variables specified, we need to force the
			// arguments.pageNumberAsParam to be false
			local.routeConfig = $findRoute(argumentCollection = arguments);
			if (ListFindNoCase(local.routeConfig.foundvariables, arguments.name)) {
				arguments.pageNumberAsParam = false;
			}
		}

		// Encode all prepend / append type arguments if specified.
		if (IsBoolean(arguments.encode) && arguments.encode && $get("encodeHtmlTags")) {
			if (Len(arguments.prepend)) {
				arguments.prepend = EncodeForHTML($canonicalize(arguments.prepend));
			}
			if (Len(arguments.prependToPage)) {
				arguments.prependToPage = EncodeForHTML($canonicalize(arguments.prependToPage));
			}
			if (Len(arguments.append)) {
				arguments.append = EncodeForHTML($canonicalize(arguments.append));
			}
			if (Len(arguments.appendToPage)) {
				arguments.appendToPage = EncodeForHTML($canonicalize(arguments.appendToPage));
			}
		}

		if (arguments.showSinglePage || local.totalPages > 1) {
			if (Len(arguments.prepend)) {
				local.start &= arguments.prepend;
			}
			if (arguments.alwaysShowAnchors) {
				if ((local.currentPage - arguments.windowSize) > 1) {
					local.pageNumber = 1;
					if (!arguments.pageNumberAsParam) {
						local.linkToArguments[arguments.name] = local.pageNumber;
					} else {
						local.linkToArguments.params = arguments.name & "=" & local.pageNumber;
						if (StructKeyExists(arguments, "params")) {
							local.linkToArguments.params &= "&" & arguments.params;
						}
					}
					local.linkToArguments.text = NumberFormat(local.pageNumber);
					if (Len(arguments.prependToPage) && arguments.prependOnAnchor) {
						local.start &= arguments.prependToPage;
					}
					local.start &= linkTo(argumentCollection = local.linkToArguments);
					if (Len(arguments.appendToPage) && arguments.appendOnAnchor) {
						local.start &= arguments.appendToPage;
					}
					local.start &= arguments.anchorDivider;
				}
			}
			local.middle = "";
			for (local.i = 1; local.i <= local.totalPages; local.i++) {
				if (
					(local.i >= (local.currentPage - arguments.windowSize) && local.i <= local.currentPage)
					|| (local.i <= (local.currentPage + arguments.windowSize) && local.i >= local.currentPage)
				) {
					if (!arguments.pageNumberAsParam) {
						local.linkToArguments[arguments.name] = local.i;
					} else {
						local.linkToArguments.params = arguments.name & "=" & local.i;
						if (StructKeyExists(arguments, "params")) {
							local.linkToArguments.params &= "&" & arguments.params;
						}
					}
					local.linkToArguments.text = NumberFormat(local.i);
					if (Len(arguments.classForCurrent) && local.currentPage == local.i) {
						// apply the classForCurrent class if specified and this is the current page
						local.linkToArguments.class = arguments.classForCurrent;
					} else if (StructKeyExists(arguments, "class") && Len(arguments.class)) {
						// allow the class attribute to be applied to the anchor tag if specified
						local.linkToArguments.class = arguments.class;
					} else {
						// clear the class argument if not provided
						StructDelete(local.linkToArguments, "class");
					}
					if (Len(arguments.prependToPage)) {

						/*
							To fix the bug below:
							https://github.com/cfwheels/cfwheels/issues/908

							We need the paginationLinks() function to set the active class to the parent of the current page item.
							The changes made here set the active class to the immediate parent of the current page element in case nested elements are passed in.
						 */
						if(local.currentPage == local.i  && arguments.addActiveClassToPrependedParent && findNoCase('class', arguments.prependToPage)) {
							local.prependToPageElementArr = listToArray(arguments.prependToPage, '<');
							local.lastElementArrIndex = arrayLen(local.prependToPageElementArr);
							local.lastElement = local.prependToPageElementArr[local.lastElementArrIndex];
							local.classStringIndex = findNoCase('class=', local.lastElement) + 6;
							local.startString = mid(local.lastElement, 1, local.classStringIndex);
							local.midString = mid(local.lastElement, local.classStringIndex+1, len(local.lastElement)-local.classStringIndex+1);
							local.activeMidString = 'active ' & local.midString;
							local.modifiedLastElement = local.startString & local.activeMidString;
							local.prependToPageElementArr[local.lastElementArrIndex] = local.modifiedLastElement;
							local.activePrependToPage = arrayToList(local.prependToPageElementArr, '<');
							local.activePrependToPage = '<' & local.activePrependToPage;
							local.middle &= local.activePrependToPage;
						} else {
							local.middle &= arguments.prependToPage;
						}
					}
					if (local.currentPage != local.i || arguments.linkToCurrentPage) {
						local.middle &= linkTo(argumentCollection = local.linkToArguments);
					} else {
						if (Len(arguments.classForCurrent)) {
							local.middle &= $element(
								name = "span",
								content = NumberFormat(local.i),
								class = arguments.classForCurrent,
								encode = arguments.encode
							);
						} else {
							local.middle &= NumberFormat(local.i);
						}
					}
					if (Len(arguments.appendToPage)) {
						local.middle &= arguments.appendToPage;
					}
				}
			}
			if (arguments.alwaysShowAnchors) {
				if (local.totalPages > (local.currentPage + arguments.windowSize)) {
					if (!arguments.pageNumberAsParam) {
						local.linkToArguments[arguments.name] = local.totalPages;
					} else {
						local.linkToArguments.params = arguments.name & "=" & local.totalPages;
						if (StructKeyExists(arguments, "params")) {
							local.linkToArguments.params &= "&" & arguments.params;
						}
					}
					local.linkToArguments.text = NumberFormat(local.totalPages);
					local.end &= arguments.anchorDivider;
					if (Len(arguments.prependToPage) && arguments.prependOnAnchor) {
						local.end &= arguments.prependToPage;
					}
					local.end &= linkTo(argumentCollection = local.linkToArguments);
					if (Len(arguments.appendToPage) && arguments.appendOnAnchor) {
						local.end &= arguments.appendToPage;
					}
				}
			}
			if (Len(arguments.append)) {
				local.end &= arguments.append;
			}
		}
		if (Len(local.middle)) {
			if (Len(arguments.prependToPage) && !arguments.prependOnFirst) {
				local.middle = Mid(
					local.middle,
					Len(arguments.prependToPage) + 1,
					Len(local.middle) - Len(arguments.prependToPage)
				);
			}
			if (Len(arguments.appendToPage) && !arguments.appendOnLast) {
				local.middle = Mid(local.middle, 1, Len(local.middle) - Len(arguments.appendToPage));
			}
		}
		return local.start & local.middle & local.end;
	}

	/**
	 * Turns all URLs and email addresses into links.
	 *
	 * [section: View Helpers]
	 * [category: Link Functions]
	 *
	 * @text The text to create links in.
	 * @link Whether to link URLs, email addresses or both. Possible values are: `all` (default), `URLs` and `emailAddresses`.
	 * @relative Should we auto-link relative urls.
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function autoLink(required string text, string link, boolean relative = true, any encode) {
		$args(name = "autoLink", args = arguments);
		local.rv = arguments.text;

		// Create anchor elements with an href attribute for all URLs found in the text.
		if (arguments.link != "emailAddresses") {
			// For BoxLang compatibility
			if (structKeyExists(server, "boxlang")) {
				local.anchors = [];
				local.tempText = arguments.text;
				local.anchorMatches = ReMatchNoCase("<a\s[^>]*>.*?</a>", local.tempText);
				for (local.i = 1; local.i <= ArrayLen(local.anchorMatches); local.i++) {
					ArrayAppend(local.anchors, local.anchorMatches[local.i]);
					local.tempText = Replace(local.tempText, local.anchorMatches[local.i], "___ANCHOR_PLACEHOLDER_" & local.i & "___", "one");
				}
				
				if (arguments.relative) {
					arguments.regex = "(?:https?://[a-zA-Z0-9][a-zA-Z0-9./_~:?####@!$&'()*+,;=%-]*|www\\.[a-zA-Z0-9][a-zA-Z0-9./_~:?####@!$&'()*+,;=%-]*|/[a-zA-Z0-9][a-zA-Z0-9./_~:?####@!$&'()*+,;=%-]*)";
				} else {
					arguments.regex = "(?:https?://[a-zA-Z0-9][a-zA-Z0-9./_~:?####@!$&'()*+,;=%-]*|www\\.[a-zA-Z0-9][a-zA-Z0-9./_~:?####@!$&'()*+,;=%-]*)";
				}
				local.rv = $autoLinkLoop(text = local.tempText, argumentCollection = arguments);
				
				for (local.i = 1; local.i <= ArrayLen(local.anchors); local.i++) {
					local.rv = Replace(local.rv, "___ANCHOR_PLACEHOLDER_" & local.i & "___", local.anchors[local.i], "one");
				}
			} else {
				if (arguments.relative) {
					arguments.regex = "(?:(?:<a\s[^>]+)?(?:https?://|www\.|\/)[^\s\b]+)";
				} else {
					arguments.regex = "(?:(?:<a\s[^>]+)?(?:https?://|www\.)[^\s\b]+)";
				}
				local.rv = $autoLinkLoop(text = local.rv, argumentCollection = arguments);
			}
		}

		// Create anchor elements with a "mailto:" link in an href attribute for all email addresses found in the text.
		if (arguments.link != "urls") {
			arguments.regex = "(?:(?:<a\s[^>]+)?(?:[^@\s]+)@(?:(?:[-a-z0-9]+\.)+[a-z]{2,}))";
			arguments.protocol = "mailto:";
			local.rv = $autoLinkLoop(text = local.rv, argumentCollection = arguments);
		}

		return local.rv;
	}

	/**
	 * Called from the autoLink function.
	 */
	public string function $autoLinkLoop(required string text, required string regex, string protocol = "") {
		local.punctuationRegEx = "([^\w\/-]+)$";
		local.startPosition = 1;
		local.match = ReFindNoCase(arguments.regex, arguments.text, local.startPosition, true);
		while (local.match.pos[1] > 0) {
			local.startPosition = local.match.pos[1] + local.match.len[1];
			local.str = Mid(arguments.text, local.match.pos[1], local.match.len[1]);
			if (Left(local.str, 2) != "<a") {
				arguments.text = RemoveChars(arguments.text, local.match.pos[1], local.match.len[1]);
				local.punctuation = ArrayToList(ReMatchNoCase(local.punctuationRegEx, local.str));
				local.str = ReReplaceNoCase(local.str, local.punctuationRegEx, "", "all");

				// Make sure that links beginning with "www." have a protocol.
				if (Left(local.str, 4) == "www." && !Len(arguments.protocol)) {
					arguments.protocol = "http://";
				}

				arguments.href = arguments.protocol & local.str;
				local.element = $element(
					name = "a",
					content = local.str,
					attributes = arguments,
					skip = "text,regex,link,protocol,relative,encode",
					encode = arguments.encode
				) & local.punctuation;
				arguments.text = Insert(local.element, arguments.text, local.match.pos[1] - 1);
				local.startPosition = local.match.pos[1] + Len(local.element);
			}
			local.startPosition++;
			// BoxLang compatibility: Add bounds check to prevent IndexOutOfBoundsException
			if (local.startPosition > Len(arguments.text)) {
				break;
			}
			local.match = ReFindNoCase(arguments.regex, arguments.text, local.startPosition, true);
		}
		return arguments.text;
	}

	public string function $paramsToQueryString(required any params) {
		if (!isStruct(arguments.params)) {
			return arguments.params;
		}
		local.queryString = "";
		for (key in arguments.params) {
			local.value = arguments.params[key];
			if (!isNull(local.value) && local.value != "") {
				local.queryString &= (Len(local.queryString) ? "&" : "") & key & "=" & encodeForUrl(local.value);
			}
		}
		return local.queryString;
	}

}
