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
		boolean pageNumberAsParam,
		any encode
	) {
		$args(name = "pageNumberLinks", args = arguments);
		local.pg = pagination(arguments.handle);
		local.rv = "";

		// Calculate window boundaries
		local.startPage = Max(1, local.pg.currentPage - arguments.windowSize);
		local.endPage = Min(local.pg.totalPages, local.pg.currentPage + arguments.windowSize);

		for (local.i = local.startPage; local.i <= local.endPage; local.i++) {
			if (Len(arguments.prependToPage)) {
				local.rv &= arguments.prependToPage;
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
	 * The `showFirst` / `showLast` / `showPrevious` / `showNext` args accept the
	 * strings `"auto"`, `"always"`, or `"never"`. Booleans are normalized for
	 * backwards compatibility: `true` maps to `"always"`, `false` maps to `"never"`.
	 * Under `"auto"` the first/last anchors only render when the visible page-number
	 * window does not already reach the boundary (matching legacy 3.x semantics).
	 *
	 * [section: View Helpers]
	 * [category: Pagination Functions]
	 *
	 * @handle The handle given to the query that the pagination should be displayed for.
	 * @navClass CSS class for the wrapping nav element.
	 * @showFirst Anchor display mode for the first page link: "auto" (default), "always", "never", or boolean.
	 * @showLast Anchor display mode for the last page link: "auto" (default), "always", "never", or boolean.
	 * @showPrevious Anchor display mode for the previous page link: "auto" (default), "always", "never", or boolean.
	 * @showNext Anchor display mode for the next page link: "auto" (default), "always", "never", or boolean.
	 * @showInfo Whether to show the pagination info text.
	 * @showSinglePage Whether to show pagination when there is only one page.
	 * @windowSize Number of page links shown around the current page in `pageNumberLinks` and used by the auto-mode predicates.
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function paginationNav(
		string handle = "query",
		string navClass,
		any showFirst,
		any showLast,
		any showPrevious,
		any showNext,
		boolean showInfo,
		boolean showSinglePage,
		numeric windowSize,
		any encode
	) {
		$args(name = "paginationNav", args = arguments);
		local.pg = pagination(arguments.handle);

		// Return empty if only one page and showSinglePage is false
		if (local.pg.totalPages <= 1 && !arguments.showSinglePage) {
			return "";
		}

		// Build passthrough arguments for sub-helpers
		local.subArgs = {};
		local.subArgs.handle = arguments.handle;
		local.subArgs.encode = arguments.encode;
		// Pass through any extra arguments (route, controller, action, key, params, etc.)
		local.skipArgs = "handle,navClass,showFirst,showLast,showPrevious,showNext,showInfo,showSinglePage,encode";
		for (local.key in arguments) {
			if (!ListFindNoCase(local.skipArgs, local.key)) {
				local.subArgs[local.key] = arguments[local.key];
			}
		}

		local.firstMode = $paginationAnchorMode(value = arguments.showFirst, argName = "showFirst");
		local.lastMode = $paginationAnchorMode(value = arguments.showLast, argName = "showLast");
		local.previousMode = $paginationAnchorMode(value = arguments.showPrevious, argName = "showPrevious");
		local.nextMode = $paginationAnchorMode(value = arguments.showNext, argName = "showNext");

		local.content = "";

		if (arguments.showInfo) {
			local.content &= paginationInfo(argumentCollection = local.subArgs);
			local.content &= " ";
		}

		if ($paginationShouldShowAnchor(mode = local.firstMode, side = "first", pg = local.pg, windowSize = arguments.windowSize)) {
			local.content &= firstPageLink(argumentCollection = local.subArgs);
			local.content &= " ";
		}

		if ($paginationShouldShowAnchor(mode = local.previousMode, side = "previous", pg = local.pg, windowSize = arguments.windowSize)) {
			local.content &= previousPageLink(argumentCollection = local.subArgs);
			local.content &= " ";
		}

		local.content &= pageNumberLinks(argumentCollection = local.subArgs);

		if ($paginationShouldShowAnchor(mode = local.nextMode, side = "next", pg = local.pg, windowSize = arguments.windowSize)) {
			local.content &= " ";
			local.content &= nextPageLink(argumentCollection = local.subArgs);
		}

		if ($paginationShouldShowAnchor(mode = local.lastMode, side = "last", pg = local.pg, windowSize = arguments.windowSize)) {
			local.content &= " ";
			local.content &= lastPageLink(argumentCollection = local.subArgs);
		}

		return $element(
			name = "nav",
			content = local.content,
			class = arguments.navClass,
			encode = false
		);
	}

	/**
	 * Internal: normalizes a showFirst/showLast/showPrevious/showNext value into "auto" | "always" | "never".
	 * Booleans are coerced: true -> "always", false -> "never". Strings are matched case-insensitively.
	 * Public access required so $integrateComponents() pulls it into the view mixin scope on Lucee/Adobe.
	 */
	public string function $paginationAnchorMode(required any value, string argName = "anchor mode") {
		if (IsBoolean(arguments.value)) {
			return arguments.value ? "always" : "never";
		}
		if (ListFindNoCase("auto,always,never", arguments.value)) {
			return LCase(arguments.value);
		}
		Throw(
			type = "Wheels.InvalidArgument",
			message = "Invalid pagination anchor mode '#arguments.value#' for argument '#arguments.argName#'.",
			detail = "The argument must be one of 'auto', 'always', 'never', or a boolean."
		);
	}

	/**
	 * Internal: decides whether a first/previous/next/last anchor should render
	 * given a normalized mode and the current pagination state.
	 *
	 * Under "auto" the first/last anchors only render when the visible page-number
	 * window does not already reach the boundary. Previous/next render whenever
	 * the current page is not at that boundary.
	 */
	public boolean function $paginationShouldShowAnchor(
		required string mode,
		required string side,
		required struct pg,
		required numeric windowSize
	) {
		if (arguments.mode == "never") {
			return false;
		}
		if (arguments.mode == "always") {
			return true;
		}
		switch (arguments.side) {
			case "first":
				return (arguments.pg.currentPage - arguments.windowSize) > 1;
			case "previous":
				return arguments.pg.currentPage > 1;
			case "next":
				return arguments.pg.currentPage < arguments.pg.totalPages;
			case "last":
				return arguments.pg.totalPages > (arguments.pg.currentPage + arguments.windowSize);
		}
		return true;
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
