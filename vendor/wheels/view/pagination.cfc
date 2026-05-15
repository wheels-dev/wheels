component {

	/**
	 * Displays a text summary of the current pagination state, e.g. "Showing 26-50 of 1,000 records".
	 * Uses token replacement in the format string: [startRow], [endRow], [totalRecords], [currentPage], [totalPages].
	 *
	 * [section: View Helpers]
	 * [category: Pagination Functions]
	 *
	 * @handle The handle given to the query that the pagination info should be displayed for.
	 * @format Format string with tokens: [startRow], [endRow], [totalRecords], [currentPage], [totalPages].
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function paginationInfo(
		string handle = "query",
		string format,
		any encode
	) {
		$args(name = "paginationInfo", args = arguments);
		local.pg = pagination(arguments.handle);

		if (local.pg.totalRecords == 0) {
			return "No records found";
		}

		local.rv = arguments.format;
		local.rv = ReplaceNoCase(local.rv, "[startRow]", NumberFormat(local.pg.startRow), "all");
		local.rv = ReplaceNoCase(local.rv, "[endRow]", NumberFormat(local.pg.endRow), "all");
		local.rv = ReplaceNoCase(local.rv, "[totalRecords]", NumberFormat(local.pg.totalRecords), "all");
		local.rv = ReplaceNoCase(local.rv, "[currentPage]", NumberFormat(local.pg.currentPage), "all");
		local.rv = ReplaceNoCase(local.rv, "[totalPages]", NumberFormat(local.pg.totalPages), "all");

		if (IsBoolean(arguments.encode) && arguments.encode && $get("encodeHtmlTags")) {
			local.rv = EncodeForHTML($canonicalize(local.rv));
		}

		return local.rv;
	}

	/**
	 * Creates a link to the previous page, or a disabled span when on the first page.
	 *
	 * [section: View Helpers]
	 * [category: Pagination Functions]
	 *
	 * @text The text for the link.
	 * @handle The handle given to the query that the pagination should be displayed for.
	 * @name The name of the param that holds the current page number.
	 * @class CSS class for the link element.
	 * @disabledClass CSS class for the disabled span element.
	 * @showDisabled Whether to render a disabled span when on the first page.
	 * @pageNumberAsParam Decides whether to link the page number as a param or as part of a route.
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function previousPageLink(
		string text,
		string handle = "query",
		string name,
		string class,
		string disabledClass,
		boolean showDisabled,
		boolean pageNumberAsParam,
		any encode
	) {
		$args(name = "previousPageLink", args = arguments);
		local.pg = pagination(arguments.handle);

		if (local.pg.currentPage <= 1) {
			if (!arguments.showDisabled) {
				return "";
			}
			return $paginationDisabledElement(text = arguments.text, class = arguments.disabledClass, encode = arguments.encode);
		}

		return $paginationPageLink(
			page = local.pg.currentPage - 1,
			text = arguments.text,
			name = arguments.name,
			class = arguments.class,
			pageNumberAsParam = arguments.pageNumberAsParam,
			encode = arguments.encode,
			args = arguments
		);
	}

	/**
	 * Creates a link to the next page, or a disabled span when on the last page.
	 *
	 * [section: View Helpers]
	 * [category: Pagination Functions]
	 *
	 * @text The text for the link.
	 * @handle The handle given to the query that the pagination should be displayed for.
	 * @name The name of the param that holds the current page number.
	 * @class CSS class for the link element.
	 * @disabledClass CSS class for the disabled span element.
	 * @showDisabled Whether to render a disabled span when on the last page.
	 * @pageNumberAsParam Decides whether to link the page number as a param or as part of a route.
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function nextPageLink(
		string text,
		string handle = "query",
		string name,
		string class,
		string disabledClass,
		boolean showDisabled,
		boolean pageNumberAsParam,
		any encode
	) {
		$args(name = "nextPageLink", args = arguments);
		local.pg = pagination(arguments.handle);

		if (local.pg.currentPage >= local.pg.totalPages) {
			if (!arguments.showDisabled) {
				return "";
			}
			return $paginationDisabledElement(text = arguments.text, class = arguments.disabledClass, encode = arguments.encode);
		}

		return $paginationPageLink(
			page = local.pg.currentPage + 1,
			text = arguments.text,
			name = arguments.name,
			class = arguments.class,
			pageNumberAsParam = arguments.pageNumberAsParam,
			encode = arguments.encode,
			args = arguments
		);
	}

	/**
	 * Creates a link to the first page, or a disabled span when already on the first page.
	 *
	 * [section: View Helpers]
	 * [category: Pagination Functions]
	 *
	 * @text The text for the link.
	 * @handle The handle given to the query that the pagination should be displayed for.
	 * @name The name of the param that holds the current page number.
	 * @class CSS class for the link element.
	 * @disabledClass CSS class for the disabled span element.
	 * @showDisabled Whether to render a disabled span when already on the first page.
	 * @pageNumberAsParam Decides whether to link the page number as a param or as part of a route.
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function firstPageLink(
		string text,
		string handle = "query",
		string name,
		string class,
		string disabledClass,
		boolean showDisabled,
		boolean pageNumberAsParam,
		any encode
	) {
		$args(name = "firstPageLink", args = arguments);
		local.pg = pagination(arguments.handle);

		if (local.pg.currentPage <= 1) {
			if (!arguments.showDisabled) {
				return "";
			}
			return $paginationDisabledElement(text = arguments.text, class = arguments.disabledClass, encode = arguments.encode);
		}

		return $paginationPageLink(
			page = 1,
			text = arguments.text,
			name = arguments.name,
			class = arguments.class,
			pageNumberAsParam = arguments.pageNumberAsParam,
			encode = arguments.encode,
			args = arguments
		);
	}

	/**
	 * Creates a link to the last page, or a disabled span when already on the last page.
	 *
	 * [section: View Helpers]
	 * [category: Pagination Functions]
	 *
	 * @text The text for the link.
	 * @handle The handle given to the query that the pagination should be displayed for.
	 * @name The name of the param that holds the current page number.
	 * @class CSS class for the link element.
	 * @disabledClass CSS class for the disabled span element.
	 * @showDisabled Whether to render a disabled span when already on the last page.
	 * @pageNumberAsParam Decides whether to link the page number as a param or as part of a route.
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function lastPageLink(
		string text,
		string handle = "query",
		string name,
		string class,
		string disabledClass,
		boolean showDisabled,
		boolean pageNumberAsParam,
		any encode
	) {
		$args(name = "lastPageLink", args = arguments);
		local.pg = pagination(arguments.handle);

		if (local.pg.currentPage >= local.pg.totalPages) {
			if (!arguments.showDisabled) {
				return "";
			}
			return $paginationDisabledElement(text = arguments.text, class = arguments.disabledClass, encode = arguments.encode);
		}

		return $paginationPageLink(
			page = local.pg.totalPages,
			text = arguments.text,
			name = arguments.name,
			class = arguments.class,
			pageNumberAsParam = arguments.pageNumberAsParam,
			encode = arguments.encode,
			args = arguments
		);
	}

	/**
	 * Creates a windowed set of page number links around the current page.
	 * The current page is rendered as a span (not a link) unless `linkToCurrentPage` is true.
	 *
	 * [section: View Helpers]
	 * [category: Pagination Functions]
	 *
	 * @windowSize The number of page links to show around the current page.
	 * @handle The handle given to the query that the pagination should be displayed for.
	 * @name The name of the param that holds the current page number.
	 * @class CSS class for each page number link.
	 * @classForCurrent CSS class for the current page span or link.
	 * @linkToCurrentPage Whether to render the current page as a link.
	 * @prependToPage String to prepend before each page number.
	 * @appendToPage String to append after each page number.
	 * @addActiveClassToPrependedParent Whether to inject `active ` into the prependToPage `class` attribute on the current page (Bootstrap idiom).
	 * @pageNumberAsParam Decides whether to link the page number as a param or as part of a route.
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function pageNumberLinks(
		numeric windowSize,
		string handle = "query",
		string name,
		string class,
		string classForCurrent,
		boolean linkToCurrentPage,
		string prependToPage,
		string appendToPage,
		boolean addActiveClassToPrependedParent,
		boolean pageNumberAsParam,
		any encode
	) {
		$args(name = "pageNumberLinks", args = arguments);
		local.pg = pagination(arguments.handle);
		local.rv = "";

		// Calculate window boundaries
		local.startPage = Max(1, local.pg.currentPage - arguments.windowSize);
		local.endPage = Min(local.pg.totalPages, local.pg.currentPage + arguments.windowSize);

		// Resolve addActiveClassToPrependedParent default locally to tolerate callers that don't pass it
		// (e.g. paginationNav passthrough on Lucee where $args defaults haven't been re-applied after reload).
		local.addActiveOnParent = StructKeyExists(arguments, "addActiveClassToPrependedParent")
			? arguments.addActiveClassToPrependedParent
			: false;

		for (local.i = local.startPage; local.i <= local.endPage; local.i++) {
			if (Len(arguments.prependToPage)) {
				local.prependForThisPage = arguments.prependToPage;
				if (local.i == local.pg.currentPage && local.addActiveOnParent) {
					if (reFindNoCase('class\s*=\s*[''"]', arguments.prependToPage)) {
						local.prependForThisPage = reReplaceNoCase(arguments.prependToPage, '(class\s*=\s*[''"])', '\1active ', 'one');
					} else if (reFindNoCase('class\s*=', arguments.prependToPage)) {
						local.prependForThisPage = reReplaceNoCase(arguments.prependToPage, '(class\s*=\s*)', '\1active ', 'one');
					}
				}
				local.rv &= local.prependForThisPage;
			}

			if (local.i == local.pg.currentPage && !arguments.linkToCurrentPage) {
				// Current page as span
				if (Len(arguments.classForCurrent)) {
					local.rv &= $element(
						name = "span",
						content = NumberFormat(local.i),
						class = arguments.classForCurrent,
						encode = arguments.encode
					);
				} else {
					local.rv &= NumberFormat(local.i);
				}
			} else {
				// Build link for this page
				local.linkClass = "";
				if (local.i == local.pg.currentPage && Len(arguments.classForCurrent)) {
					local.linkClass = arguments.classForCurrent;
				} else if (Len(arguments.class)) {
					local.linkClass = arguments.class;
				}

				local.linkArgs = $paginationLinkToArgs(
					page = local.i,
					text = NumberFormat(local.i),
					name = arguments.name,
					pageNumberAsParam = arguments.pageNumberAsParam,
					encode = arguments.encode,
					args = arguments
				);
				if (Len(local.linkClass)) {
					local.linkArgs.class = local.linkClass;
				}
				local.rv &= linkTo(argumentCollection = local.linkArgs);
			}

			if (Len(arguments.appendToPage)) {
				local.rv &= arguments.appendToPage;
			}
		}

		return local.rv;
	}

	/**
	 * Creates a complete pagination navigation element wrapping individual pagination helpers.
	 * Outputs a `<nav>` element containing first/previous/page-numbers/next/last links and optional info text.
	 *
	 * [section: View Helpers]
	 * [category: Pagination Functions]
	 *
	 * @handle The handle given to the query that the pagination should be displayed for.
	 * @navClass CSS class for the wrapping nav element.
	 * @showFirst Whether to show the first page link.
	 * @showLast Whether to show the last page link.
	 * @showPrevious Whether to show the previous page link.
	 * @showNext Whether to show the next page link.
	 * @showInfo Whether to show the pagination info text.
	 * @showSinglePage Whether to show pagination when there is only one page.
	 * @prepend String or HTML to be prepended inside the `<nav>` before the link list (e.g. `<ul class="pagination">`).
	 * @append String or HTML to be appended inside the `<nav>` after the link list (e.g. `</ul>`).
	 * @prependToPage String or HTML to wrap before each anchor (first/previous/page numbers/next/last). Forwards to `pageNumberLinks` for the numbered links.
	 * @appendToPage String or HTML to wrap after each anchor (first/previous/page numbers/next/last). Forwards to `pageNumberLinks` for the numbered links.
	 * @addActiveClassToPrependedParent Whether to inject `active ` into the prependToPage `class` attribute on the current page (Bootstrap idiom — forwards to `pageNumberLinks`).
	 * @anchorDivider Separator inserted between the first/previous/page-numbers/next/last sections.
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function paginationNav(
		string handle = "query",
		string navClass,
		boolean showFirst,
		boolean showLast,
		boolean showPrevious,
		boolean showNext,
		boolean showInfo,
		boolean showSinglePage,
		string prepend,
		string append,
		string prependToPage,
		string appendToPage,
		boolean addActiveClassToPrependedParent,
		string anchorDivider,
		any encode
	) {
		$args(name = "paginationNav", args = arguments);

		// Build passthrough arguments for sub-helpers
		local.subArgs = {};
		local.subArgs.handle = arguments.handle;
		local.subArgs.encode = arguments.encode;
		// Pass through any extra arguments (route, controller, action, key, params, etc.)
		// prepend/append are paginationNav-only and are NOT forwarded — they wrap the whole content.
		// prependToPage/appendToPage forward to pageNumberLinks AND wrap the first/prev/next/last anchors here.
		// anchorDivider is paginationNav-only and is NOT forwarded.
		local.skipArgs = "handle,navClass,showFirst,showLast,showPrevious,showNext,showInfo,showSinglePage,prepend,append,anchorDivider,encode";
		// Union of args accepted by sub-helpers (paginationInfo, firstPageLink,
		// previousPageLink, pageNumberLinks, nextPageLink, lastPageLink) plus the
		// URL-building keys forwarded by $paginationLinkToArgs. Keys outside this
		// allowlist are silently dropped by CFML's argumentCollection dispatch,
		// which makes typos like prependToList="<ul>" invisible — see issue #2717.
		// `addActiveClassToPrependedParent` is forwarded to `pageNumberLinks` per #2715
		// so it must appear in the allowlist alongside `prependToPage`/`appendToPage`.
		local.allowedSubArgs = "format,text,name,class,disabledClass,showDisabled,pageNumberAsParam"
			& ",windowSize,classForCurrent,linkToCurrentPage,prependToPage,appendToPage,addActiveClassToPrependedParent"
			& ",route,controller,action,key,anchor,onlyPath,host,protocol,port,params";
		local.unknownArgs = "";
		for (local.key in arguments) {
			if (!ListFindNoCase(local.skipArgs, local.key)) {
				local.subArgs[local.key] = arguments[local.key];
				if (!ListFindNoCase(local.allowedSubArgs, local.key)) {
					local.unknownArgs = ListAppend(local.unknownArgs, local.key);
				}
			}
		}
		// Validate before the totalPages early-return so the check fires on
		// single-page (or empty) result sets too. Gated on showErrorInformation
		// so production skips both the $findRoute lookup and the throw entirely.
		if (Len(local.unknownArgs) && application.wheels.showErrorInformation) {
			// Named-route segment variables (e.g. userId in route "userTimeline") are
			// forwarded by $paginationLinkToArgs at link-build time but are not in the
			// static allowlist. Filter them out before throwing — otherwise
			// paginationNav(route="userTimeline", userId=user.id) trips a false-positive
			// InvalidArgument.
			if (StructKeyExists(local.subArgs, "route") && Len(local.subArgs.route)) {
				local.routeVarList = $findRoute(argumentCollection = local.subArgs).foundvariables;
				local.filteredUnknown = "";
				for (local.uk in ListToArray(local.unknownArgs)) {
					if (!ListFindNoCase(local.routeVarList, local.uk)) {
						local.filteredUnknown = ListAppend(local.filteredUnknown, local.uk);
					}
				}
				local.unknownArgs = local.filteredUnknown;
			}
			if (Len(local.unknownArgs)) {
				Throw(
					type = "Wheels.PaginationNav.InvalidArgument",
					message = "paginationNav() received unknown argument(s): [#local.unknownArgs#].",
					detail = "Accepted pass-through arguments are: #local.allowedSubArgs#. paginationNav's own arguments are: #local.skipArgs#."
				);
			}
		}

		local.pg = pagination(arguments.handle);

		// Return empty if only one page and showSinglePage is false
		if (local.pg.totalPages <= 1 && !arguments.showSinglePage) {
			return "";
		}

		local.sections = [];

		if (arguments.showInfo) {
			ArrayAppend(local.sections, paginationInfo(argumentCollection = local.subArgs));
		}

		if (arguments.showFirst) {
			local.firstLink = firstPageLink(argumentCollection = local.subArgs);
			if (Len(local.firstLink)) {
				ArrayAppend(local.sections, $paginationWrapAnchor(
					anchor = local.firstLink,
					prependToPage = arguments.prependToPage,
					appendToPage = arguments.appendToPage
				));
			}
		}

		if (arguments.showPrevious) {
			local.prevLink = previousPageLink(argumentCollection = local.subArgs);
			if (Len(local.prevLink)) {
				ArrayAppend(local.sections, $paginationWrapAnchor(
					anchor = local.prevLink,
					prependToPage = arguments.prependToPage,
					appendToPage = arguments.appendToPage
				));
			}
		}

		local.numberLinks = pageNumberLinks(argumentCollection = local.subArgs);
		if (Len(local.numberLinks)) {
			ArrayAppend(local.sections, local.numberLinks);
		}

		if (arguments.showNext) {
			local.nextLink = nextPageLink(argumentCollection = local.subArgs);
			if (Len(local.nextLink)) {
				ArrayAppend(local.sections, $paginationWrapAnchor(
					anchor = local.nextLink,
					prependToPage = arguments.prependToPage,
					appendToPage = arguments.appendToPage
				));
			}
		}

		if (arguments.showLast) {
			local.lastLink = lastPageLink(argumentCollection = local.subArgs);
			if (Len(local.lastLink)) {
				ArrayAppend(local.sections, $paginationWrapAnchor(
					anchor = local.lastLink,
					prependToPage = arguments.prependToPage,
					appendToPage = arguments.appendToPage
				));
			}
		}

		local.content = arguments.prepend & ArrayToList(local.sections, arguments.anchorDivider) & arguments.append;

		return $element(
			name = "nav",
			content = local.content,
			class = arguments.navClass,
			encode = false
		);
	}

	/**
	 * Internal: wraps a single anchor in prependToPage/appendToPage, mirroring pageNumberLinks's wrapping behavior.
	 */
	public string function $paginationWrapAnchor(
		required string anchor,
		string prependToPage = "",
		string appendToPage = ""
	) {
		if (!Len(arguments.anchor)) {
			return "";
		}
		return arguments.prependToPage & arguments.anchor & arguments.appendToPage;
	}

	/**
	 * Internal: renders a disabled span element for pagination.
	 */
	public string function $paginationDisabledElement(
		required string text,
		string class = "",
		any encode = false
	) {
		if (Len(arguments.class)) {
			return $element(
				name = "span",
				content = arguments.text,
				class = arguments.class,
				encode = arguments.encode
			);
		}
		return $element(
			name = "span",
			content = arguments.text,
			encode = arguments.encode
		);
	}

	/**
	 * Internal: builds linkTo arguments for a specific page number.
	 */
	public struct function $paginationLinkToArgs(
		required numeric page,
		required string text,
		required string name,
		required boolean pageNumberAsParam,
		required any encode,
		required struct args
	) {
		local.linkArgs = {};
		local.linkArgs.text = arguments.text;
		local.linkArgs.encode = arguments.encode;

		// Pass through route/controller/action/key from original args
		local.passThrough = "route,controller,action,key,anchor,onlyPath,host,protocol,port";
		for (local.key in ListToArray(local.passThrough)) {
			if (StructKeyExists(arguments.args, local.key)) {
				local.linkArgs[local.key] = arguments.args[local.key];
			}
		}

		// Pass through route variables if a route is specified
		if (StructKeyExists(arguments.args, "route") && Len(arguments.args.route)) {
			local.routeConfig = $findRoute(argumentCollection = arguments.args);
			local.routeVars = ListToArray(local.routeConfig.foundvariables);
			for (local.key in local.routeVars) {
				if (StructKeyExists(arguments.args, local.key) && local.key != arguments.name) {
					local.linkArgs[local.key] = arguments.args[local.key];
				}
			}
		}

		if (!arguments.pageNumberAsParam) {
			local.linkArgs[arguments.name] = arguments.page;
		} else {
			local.linkArgs.params = arguments.name & "=" & arguments.page;
			if (StructKeyExists(arguments.args, "params") && Len(arguments.args.params)) {
				if (IsStruct(arguments.args.params)) {
					local.linkArgs.params &= "&" & $paramsToQueryString(arguments.args.params);
				} else {
					local.linkArgs.params &= "&" & arguments.args.params;
				}
			}
		}

		return local.linkArgs;
	}

	/**
	 * Internal: creates a page link via linkTo().
	 */
	public string function $paginationPageLink(
		required numeric page,
		required string text,
		required string name,
		string class = "",
		required boolean pageNumberAsParam,
		required any encode,
		required struct args
	) {
		local.linkArgs = $paginationLinkToArgs(argumentCollection = arguments);
		if (Len(arguments.class)) {
			local.linkArgs.class = arguments.class;
		}
		return linkTo(argumentCollection = local.linkArgs);
	}

}
