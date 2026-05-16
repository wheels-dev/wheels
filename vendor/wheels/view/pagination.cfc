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
	 * @addActiveClassToPrependedParent Whether to inject `active ` into the prependToPage `class` attribute on the current page (Bootstrap idiom). Has no effect if `prependToPage` contains no `class` attribute.
	 * @pageNumberAsParam Decides whether to link the page number as a param or as part of a route.
	 * @viewStyle CSS-framework preset for markup: "plain" (default), "bootstrap5", "bootstrap4", or "tailwind".
	 *           When non-plain, emits the canonical wrapper markup for that framework (e.g. `<li class="page-item active">`)
	 *           and ignores `prependToPage` / `appendToPage` / `classForCurrent` / `class` in favor of the preset.
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
		string viewStyle,
		any encode
	) {
		$args(name = "pageNumberLinks", args = arguments);
		local.pg = pagination(arguments.handle);
		local.rv = "";

		local.useViewStyle = Len(arguments.viewStyle) && arguments.viewStyle != "plain";

		// Calculate window boundaries
		local.startPage = Max(1, local.pg.currentPage - arguments.windowSize);
		local.endPage = Min(local.pg.totalPages, local.pg.currentPage + arguments.windowSize);

		// Scrub event-handler attributes and javascript: URIs from author-supplied wrappers once,
		// before the loop. Applies the same entity-decode + on\w+= / javascript: strip contract that
		// `paginationLinks()` applies to `prependToPage`, extended here to `appendToPage` as well so
		// the new `pageNumberLinks` / `paginationNav` code path inherits the full defense-in-depth.
		arguments.prependToPage = $paginationSanitizeWrapper(arguments.prependToPage);
		arguments.appendToPage = $paginationSanitizeWrapper(arguments.appendToPage);

		// Resolve addActiveClassToPrependedParent default locally to tolerate callers that don't pass it
		// (e.g. paginationNav passthrough on Lucee where $args defaults haven't been re-applied after reload).
		local.addActiveOnParent = StructKeyExists(arguments, "addActiveClassToPrependedParent")
			? arguments.addActiveClassToPrependedParent
			: false;

		for (local.i = local.startPage; local.i <= local.endPage; local.i++) {
			if (local.useViewStyle) {
				local.linkArgs = $paginationLinkToArgs(
					page = local.i,
					text = NumberFormat(local.i),
					name = arguments.name,
					pageNumberAsParam = arguments.pageNumberAsParam,
					encode = arguments.encode,
					args = arguments
				);
				local.rv &= $renderPaginationPage(
					pageNumber = local.i,
					isCurrent = (local.i == local.pg.currentPage),
					viewStyle = arguments.viewStyle,
					linkArgs = local.linkArgs
				);
				continue;
			}

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
	 * The `showFirst` / `showLast` / `showPrevious` / `showNext` args accept the
	 * strings `"auto"`, `"always"`, or `"never"`. Booleans are normalized for
	 * backwards compatibility: `true` maps to `"always"`, `false` maps to `"never"`.
	 * Under `"auto"` the first/last anchors only render when the visible page-number
	 * window does not already reach the boundary (matching legacy 3.x semantics).
	 * Under `"auto"` the previous/next anchors always delegate to their sub-helper,
	 * which renders a disabled `<span class="disabled">` at the boundary by default —
	 * use `"never"` to suppress the boundary indicator entirely.
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
	 * @viewStyle CSS-framework preset for markup: "plain" (default), "bootstrap5", "bootstrap4", or "tailwind".
	 *           When non-plain, the entire nav is rendered with the framework's canonical structure
	 *           (e.g. `<nav><ul class="pagination"><li class="page-item active">...`), removing the need
	 *           for `Replace()` post-processing in app code. Passed through to `pageNumberLinks()`.
	 * @prepend String or HTML to be prepended inside the `<nav>` before the link list (e.g. `<ul class="pagination">`).
	 * @append String or HTML to be appended inside the `<nav>` after the link list (e.g. `</ul>`).
	 * @prependToPage String or HTML to wrap before each anchor (first/previous/page numbers/next/last). Forwards to `pageNumberLinks` for the numbered links.
	 * @appendToPage String or HTML to wrap after each anchor (first/previous/page numbers/next/last). Forwards to `pageNumberLinks` for the numbered links.
	 * @addActiveClassToPrependedParent Whether to inject `active ` into the prependToPage `class` attribute on the current page (Bootstrap idiom — forwards to `pageNumberLinks`). Applies only to numbered-page anchors, not to first / previous / next / last (which are never "current" in the Bootstrap sense). Has no effect if `prependToPage` contains no `class` attribute.
	 * @anchorDivider Separator inserted between the first/previous/page-numbers/next/last sections.
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
		string viewStyle,
		string prepend,
		string append,
		string prependToPage,
		string appendToPage,
		boolean addActiveClassToPrependedParent,
		string anchorDivider,
		any encode
	) {
		$args(name = "paginationNav", args = arguments);

		// Sanitize the per-anchor wrappers once at this entry point so the four downstream
		// `$paginationWrapAnchor()` calls receive pre-scrubbed input and don't each repeat the
		// strip. `pageNumberLinks()` still scrubs its own inputs as a defense-in-depth measure for
		// direct callers; the redundant pass when invoked from here is idempotent. Single audit
		// surface: any future contributor only has to verify scrubbing happens here, not at every
		// downstream wrap call.
		arguments.prependToPage = $paginationSanitizeWrapper(arguments.prependToPage);
		arguments.appendToPage = $paginationSanitizeWrapper(arguments.appendToPage);

		// Build passthrough arguments for sub-helpers
		local.subArgs = {};
		local.subArgs.handle = arguments.handle;
		local.subArgs.encode = arguments.encode;
		// Pass through any extra arguments (route, controller, action, key, params, etc.).
		// `windowSize` is excluded because the anchor sub-helpers do not declare it; it
		// is delivered explicitly to `pageNumberLinks()` below.
		// viewStyle is paginationNav's own arg consumed by the $renderPaginationNav early-return path.
		// prepend/append are paginationNav-only and are NOT forwarded — they wrap the whole content.
		// prependToPage/appendToPage forward to pageNumberLinks AND wrap the first/prev/next/last anchors here.
		// anchorDivider is paginationNav-only and is NOT forwarded.
		local.skipArgs = "handle,navClass,showFirst,showLast,showPrevious,showNext,showInfo,showSinglePage,windowSize,viewStyle,prepend,append,anchorDivider,encode";
		// Union of args accepted by sub-helpers (paginationInfo, firstPageLink,
		// previousPageLink, pageNumberLinks, nextPageLink, lastPageLink) plus the
		// URL-building keys forwarded by $paginationLinkToArgs. Keys outside this
		// allowlist are silently dropped by CFML's argumentCollection dispatch,
		// which makes typos like prependToList="<ul>" invisible — see issue #2717.
		// `addActiveClassToPrependedParent` is forwarded to `pageNumberLinks` per #2715
		// so it must appear in the allowlist alongside `prependToPage`/`appendToPage`.
		local.allowedSubArgs = "format,text,name,class,disabledClass,showDisabled,pageNumberAsParam"
			& ",classForCurrent,linkToCurrentPage,prependToPage,appendToPage,addActiveClassToPrependedParent"
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

		// Validate anchor mode strings before the totalPages early-return so an invalid
		// mode like showFirst="bogus" throws on single-page (or empty) result sets too,
		// matching the unknown-arg validation rationale above. Invalid mode strings are
		// coding errors, so $paginationAnchorMode always throws — no showErrorInformation
		// gate.
		local.firstMode = $paginationAnchorMode(value = arguments.showFirst, argName = "showFirst");
		local.lastMode = $paginationAnchorMode(value = arguments.showLast, argName = "showLast");
		local.previousMode = $paginationAnchorMode(value = arguments.showPrevious, argName = "showPrevious");
		local.nextMode = $paginationAnchorMode(value = arguments.showNext, argName = "showNext");

		local.pg = pagination(arguments.handle);

		// Return empty if only one page and showSinglePage is false
		if (local.pg.totalPages <= 1 && !arguments.showSinglePage) {
			return "";
		}

		local.useViewStyle = Len(arguments.viewStyle) && arguments.viewStyle != "plain";

		if (local.useViewStyle) {
			// $renderPaginationNav takes booleans; resolve the tri-state anchor modes
			// here so the preset path honours "auto" / "always" / "never" identically
			// to the plain path.
			return $renderPaginationNav(
				viewStyle = arguments.viewStyle,
				pg = local.pg,
				showInfo = arguments.showInfo,
				showFirst = $paginationShouldShowAnchor(mode = local.firstMode, side = "first", pg = local.pg, windowSize = arguments.windowSize),
				showPrevious = $paginationShouldShowAnchor(mode = local.previousMode, side = "previous", pg = local.pg, windowSize = arguments.windowSize),
				showNext = $paginationShouldShowAnchor(mode = local.nextMode, side = "next", pg = local.pg, windowSize = arguments.windowSize),
				showLast = $paginationShouldShowAnchor(mode = local.lastMode, side = "last", pg = local.pg, windowSize = arguments.windowSize),
				windowSize = arguments.windowSize,
				subArgs = local.subArgs
			);
		}

		local.sections = [];

		if (arguments.showInfo) {
			ArrayAppend(local.sections, paginationInfo(argumentCollection = local.subArgs));
		}

		if ($paginationShouldShowAnchor(mode = local.firstMode, side = "first", pg = local.pg, windowSize = arguments.windowSize)) {
			local.firstLink = firstPageLink(argumentCollection = local.subArgs);
			if (Len(local.firstLink)) {
				ArrayAppend(local.sections, $paginationWrapAnchor(
					anchor = local.firstLink,
					prependToPage = arguments.prependToPage,
					appendToPage = arguments.appendToPage
				));
			}
		}

		if ($paginationShouldShowAnchor(mode = local.previousMode, side = "previous", pg = local.pg, windowSize = arguments.windowSize)) {
			local.prevLink = previousPageLink(argumentCollection = local.subArgs);
			if (Len(local.prevLink)) {
				ArrayAppend(local.sections, $paginationWrapAnchor(
					anchor = local.prevLink,
					prependToPage = arguments.prependToPage,
					appendToPage = arguments.appendToPage
				));
			}
		}

		local.numberLinks = pageNumberLinks(argumentCollection = local.subArgs, windowSize = arguments.windowSize);
		if (Len(local.numberLinks)) {
			ArrayAppend(local.sections, local.numberLinks);
		}

		if ($paginationShouldShowAnchor(mode = local.nextMode, side = "next", pg = local.pg, windowSize = arguments.windowSize)) {
			local.nextLink = nextPageLink(argumentCollection = local.subArgs);
			if (Len(local.nextLink)) {
				ArrayAppend(local.sections, $paginationWrapAnchor(
					anchor = local.nextLink,
					prependToPage = arguments.prependToPage,
					appendToPage = arguments.appendToPage
				));
			}
		}

		if ($paginationShouldShowAnchor(mode = local.lastMode, side = "last", pg = local.pg, windowSize = arguments.windowSize)) {
			local.lastLink = lastPageLink(argumentCollection = local.subArgs);
			if (Len(local.lastLink)) {
				ArrayAppend(local.sections, $paginationWrapAnchor(
					anchor = local.lastLink,
					prependToPage = arguments.prependToPage,
					appendToPage = arguments.appendToPage
				));
			}
		}

		// `prepend` / `append` are intentionally NOT scrubbed by `$paginationSanitizeWrapper`.
		// They wrap the entire link list (e.g. `<ul class="pagination">` / `</ul>`) and are
		// expected to be developer-authored structural markup, not per-page templates supplied by
		// untrusted authors. `prependToPage` / `appendToPage` get the scrub because they're the
		// extension points a CMS / theme would expose. If a future feature opens up `prepend` /
		// `append` to author-supplied input, route them through `$paginationSanitizeWrapper` too.
		local.content = arguments.prepend & ArrayToList(local.sections, arguments.anchorDivider) & arguments.append;

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
	 * window does not already reach the boundary. Previous/next under "auto" always
	 * delegate to their sub-helper (`previousPageLink()` / `nextPageLink()`), which
	 * renders a disabled `<span class="disabled">` at the boundary by default —
	 * matching the legacy `showPrevious=true` / `showNext=true` behavior so the
	 * boundary indicator is preserved unless the caller opts out with `"never"`.
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
			case "last":
				return arguments.pg.totalPages > (arguments.pg.currentPage + arguments.windowSize);
		}
		return true;
	}

	/**
	 * Internal: wraps a single anchor in prependToPage/appendToPage. Pure concatenation — callers MUST
	 * pre-sanitize `prependToPage` and `appendToPage` via `$paginationSanitizeWrapper()` before passing
	 * them here. Sole caller is `paginationNav()`, which performs that scrub once at its entry so the
	 * four anchor sites (first / previous / next / last) don't each repeat the work. Keeping this helper
	 * pure leaves a single audit surface for the XSS scrub up in `paginationNav()`.
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
	 * Internal: strips event-handler attributes and javascript: URIs from a user-supplied wrapper string,
	 * after first decoding HTML numeric entities so encoded payloads cannot bypass the regex pass.
	 * Centralised here so both prependToPage and appendToPage receive identical treatment, and so the
	 * single audit surface stays in lockstep with the parallel scrub in `paginationLinks()` (links.cfc).
	 */
	public string function $paginationSanitizeWrapper(required string input) {
		if (!Len(arguments.input)) {
			return arguments.input;
		}
		local.rv = $decodeHtmlEntities(arguments.input);
		local.rv = reReplaceNoCase(local.rv, '\s+on\w+\s*=\s*([''"])[^''"]*\1', '', 'all');
		local.rv = reReplaceNoCase(local.rv, '\s+on\w+\s*=\s*[^\s>]+', '', 'all');
		local.rv = reReplaceNoCase(local.rv, 'javascript\s*:', '', 'all');
		return local.rv;
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

	/**
	 * Internal: renders one page entry under a viewStyle preset.
	 * Returns the framework-canonical wrapper (e.g. `<li class="page-item active"><span class="page-link">N</span></li>`)
	 * for the current page, and a wrapped anchor for non-current pages.
	 */
	public string function $renderPaginationPage(
		required numeric pageNumber,
		required boolean isCurrent,
		required string viewStyle,
		required struct linkArgs
	) {
		local.label = NumberFormat(arguments.pageNumber);
		switch (arguments.viewStyle) {
			case "bootstrap5":
				if (arguments.isCurrent) {
					return '<li class="page-item active" aria-current="page"><span class="page-link">' & local.label & '</span></li>';
				}
				arguments.linkArgs.class = "page-link";
				return '<li class="page-item">' & linkTo(argumentCollection = arguments.linkArgs) & '</li>';
			case "bootstrap4":
				if (arguments.isCurrent) {
					return '<li class="page-item active"><span class="page-link">' & local.label & '</span></li>';
				}
				arguments.linkArgs.class = "page-link";
				return '<li class="page-item">' & linkTo(argumentCollection = arguments.linkArgs) & '</li>';
			case "tailwind":
				if (arguments.isCurrent) {
					return '<span class="pagination-current" aria-current="page">' & local.label & '</span>';
				}
				arguments.linkArgs.class = "pagination-link";
				return linkTo(argumentCollection = arguments.linkArgs);
			default:
				Throw(
					type = "Wheels.InvalidViewStyle",
					message = "Unknown viewStyle [#arguments.viewStyle#] passed to pageNumberLinks().",
					detail = "Supported values are ""plain"", ""bootstrap5"", ""bootstrap4"", and ""tailwind""."
				);
		}
	}

	/**
	 * Internal: renders the full paginationNav() output under a viewStyle preset.
	 * Bootstrap presets emit `<nav><ul class="pagination"><li class="page-item">...`.
	 * Each first/previous/next/last item resolves its target page from the pagination
	 * struct directly so we can mark it `disabled` on the wrapper without scraping
	 * the sub-helper output.
	 */
	public string function $renderPaginationNav(
		required string viewStyle,
		required struct pg,
		required boolean showInfo,
		required boolean showFirst,
		required boolean showPrevious,
		required boolean showNext,
		required boolean showLast,
		required numeric windowSize,
		required struct subArgs
	) {
		local.firstDisabled = arguments.pg.currentPage <= 1;
		local.lastDisabled = arguments.pg.currentPage >= arguments.pg.totalPages;

		local.items = "";
		if (arguments.showFirst) {
			local.items &= $renderPaginationNavLink(
				viewStyle = arguments.viewStyle,
				targetPage = 1,
				text = $get(name = "text", functionName = "firstPageLink"),
				isDisabled = local.firstDisabled,
				subArgs = arguments.subArgs
			);
		}
		if (arguments.showPrevious) {
			local.items &= $renderPaginationNavLink(
				viewStyle = arguments.viewStyle,
				targetPage = Max(1, arguments.pg.currentPage - 1),
				text = $get(name = "text", functionName = "previousPageLink"),
				isDisabled = local.firstDisabled,
				subArgs = arguments.subArgs
			);
		}

		// Reuse pageNumberLinks() so the window logic stays in one place.
		// windowSize is excluded from subArgs (see skipArgs in paginationNav), so
		// re-add it here to keep the auto-mode predicate and rendered window aligned.
		local.pageArgs = StructCopy(arguments.subArgs);
		local.pageArgs.viewStyle = arguments.viewStyle;
		local.pageArgs.windowSize = arguments.windowSize;
		local.items &= pageNumberLinks(argumentCollection = local.pageArgs);

		if (arguments.showNext) {
			local.items &= $renderPaginationNavLink(
				viewStyle = arguments.viewStyle,
				targetPage = Min(arguments.pg.totalPages, arguments.pg.currentPage + 1),
				text = $get(name = "text", functionName = "nextPageLink"),
				isDisabled = local.lastDisabled,
				subArgs = arguments.subArgs
			);
		}
		if (arguments.showLast) {
			local.items &= $renderPaginationNavLink(
				viewStyle = arguments.viewStyle,
				targetPage = arguments.pg.totalPages,
				text = $get(name = "text", functionName = "lastPageLink"),
				isDisabled = local.lastDisabled,
				subArgs = arguments.subArgs
			);
		}

		local.infoHtml = "";
		if (arguments.showInfo) {
			local.infoHtml = paginationInfo(argumentCollection = arguments.subArgs) & " ";
		}

		switch (arguments.viewStyle) {
			case "bootstrap5":
			case "bootstrap4":
				return '<nav aria-label="Pagination">' & local.infoHtml
					& '<ul class="pagination">' & local.items & '</ul></nav>';
			case "tailwind":
				return '<nav aria-label="Pagination" class="pagination">' & local.infoHtml & local.items & '</nav>';
			default:
				Throw(
					type = "Wheels.InvalidViewStyle",
					message = "Unknown viewStyle [#arguments.viewStyle#] passed to paginationNav().",
					detail = "Supported values are ""plain"", ""bootstrap5"", ""bootstrap4"", and ""tailwind""."
				);
		}
	}

	/**
	 * Internal: renders a single first/previous/next/last item under a viewStyle preset.
	 */
	public string function $renderPaginationNavLink(
		required string viewStyle,
		required numeric targetPage,
		required string text,
		required boolean isDisabled,
		required struct subArgs
	) {
		local.encode = StructKeyExists(arguments.subArgs, "encode") ? arguments.subArgs.encode : true;
		local.pageName = StructKeyExists(arguments.subArgs, "name") ? arguments.subArgs.name : "page";
		local.pageNumberAsParam = StructKeyExists(arguments.subArgs, "pageNumberAsParam")
			? arguments.subArgs.pageNumberAsParam
			: true;

		local.safeText = (IsBoolean(local.encode) && local.encode)
			? EncodeForHTML(arguments.text)
			: arguments.text;

		switch (arguments.viewStyle) {
			case "bootstrap5":
			case "bootstrap4":
				if (arguments.isDisabled) {
					return '<li class="page-item disabled"><span class="page-link">' & local.safeText & '</span></li>';
				}
				local.linkArgs = $paginationLinkToArgs(
					page = arguments.targetPage,
					text = arguments.text,
					name = local.pageName,
					pageNumberAsParam = local.pageNumberAsParam,
					encode = local.encode,
					args = arguments.subArgs
				);
				local.linkArgs.class = "page-link";
				return '<li class="page-item">' & linkTo(argumentCollection = local.linkArgs) & '</li>';
			case "tailwind":
				if (arguments.isDisabled) {
					return '<span class="pagination-disabled">' & local.safeText & '</span>';
				}
				local.linkArgs = $paginationLinkToArgs(
					page = arguments.targetPage,
					text = arguments.text,
					name = local.pageName,
					pageNumberAsParam = local.pageNumberAsParam,
					encode = local.encode,
					args = arguments.subArgs
				);
				local.linkArgs.class = "pagination-link";
				return linkTo(argumentCollection = local.linkArgs);
			default:
				Throw(
					type = "Wheels.InvalidViewStyle",
					message = "Unknown viewStyle [#arguments.viewStyle#] passed to paginationNav() nav link rendering.",
					detail = "Supported values are ""plain"", ""bootstrap5"", ""bootstrap4"", and ""tailwind""."
				);
		}
	}

}
