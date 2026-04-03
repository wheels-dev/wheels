/**
 * Contract for view URL and link generation helpers.
 *
 * The default implementation lives in `wheels.view.links` and is mixed
 * into view context at runtime. Compliance is verified by runtime reflection tests.
 *
 * [section: View]
 * [category: Interface]
 */
interface {

	/**
	 * Generate an HTML anchor tag.
	 *
	 * @text Link text content.
	 * @route Named route.
	 * @controller Target controller.
	 * @action Target action.
	 * @key Primary key value for the route.
	 * @params Additional URL parameters.
	 * @anchor URL fragment.
	 * @onlyPath Relative path or full URL.
	 * @host Override host.
	 * @protocol Override protocol.
	 * @port Override port.
	 * @href Direct URL (bypasses route generation).
	 * @encode Encode attribute values.
	 */
	public string function linkTo(
		string text,
		string route,
		string controller,
		string action,
		any key,
		any params,
		string anchor,
		boolean onlyPath,
		string host,
		string protocol,
		numeric port,
		string href,
		boolean encode
	);

	/**
	 * Generate a form-based button that submits to a URL (for non-GET actions).
	 *
	 * @text Button text.
	 * @image Image path for an image button.
	 * @route Named route.
	 * @controller Target controller.
	 * @action Target action.
	 * @key Primary key value.
	 * @params Additional URL parameters.
	 * @anchor URL fragment.
	 * @method HTTP method (default: "post").
	 * @onlyPath Relative path or full URL.
	 * @host Override host.
	 * @protocol Override protocol.
	 * @port Override port.
	 * @encode Encode attribute values.
	 */
	public string function buttonTo(
		string text,
		string image,
		string route,
		string controller,
		string action,
		any key,
		any params,
		string anchor,
		string method,
		boolean onlyPath,
		string host,
		string protocol,
		numeric port,
		boolean encode
	);

	/**
	 * Generate a mailto: link.
	 *
	 * @emailAddress The email address.
	 * @name Display text (default: the email address itself).
	 * @encode Encode the email address to deter scrapers.
	 */
	public string function mailTo(string emailAddress, string name, boolean encode);

	/**
	 * Generate pagination links for a paginated query.
	 *
	 * @windowSize Number of page links to show around the current page.
	 * @alwaysShowAnchors Always show first/last page links.
	 * @anchorDivider Separator between anchor links and page numbers.
	 * @linkToCurrentPage Whether the current page number is a link.
	 * @prepend HTML before the pagination.
	 * @append HTML after the pagination.
	 * @prependToPage HTML before each page link.
	 * @addActiveClassToPrependedParent Add active class to prepended parent element.
	 * @prependOnFirst Whether to prepend on the first page link.
	 * @prependOnAnchor Whether to prepend on anchor links.
	 * @appendToPage HTML after each page link.
	 * @appendOnLast Whether to append on the last page link.
	 * @appendOnAnchor Whether to append on anchor links.
	 * @classForCurrent CSS class for the current page link.
	 * @handle Named pagination handle.
	 * @name Route parameter name for the page number.
	 * @showSinglePage Whether to show links when there's only one page.
	 * @pageNumberAsParam Whether page number goes in URL params vs. route.
	 * @encode Encode attribute values (accepts boolean, string, or struct).
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
		string handle,
		string name,
		boolean showSinglePage,
		boolean pageNumberAsParam,
		any encode
	);

	/**
	 * Generate a URL string for the given route or controller/action.
	 *
	 * @route Named route.
	 * @controller Target controller.
	 * @action Target action.
	 * @key Primary key value.
	 * @params Additional URL parameters.
	 * @anchor URL fragment.
	 * @onlyPath Relative path or full URL.
	 * @host Override host.
	 * @protocol Override protocol.
	 * @port Override port.
	 * @encode Encode the URL.
	 */
	public string function urlFor(
		string route,
		string controller,
		string action,
		any key,
		any params,
		string anchor,
		boolean onlyPath,
		string host,
		string protocol,
		numeric port,
		boolean encode
	);

}
