/**
 * Contract for controller rendering and response generation.
 *
 * The default implementation lives in `wheels.controller.rendering` and is mixed
 * into Controller instances at runtime. Compliance is verified by runtime reflection tests.
 *
 * [section: Controller]
 * [category: Interface]
 */
interface {

	/**
	 * Render a view template and return or set it as the response.
	 *
	 * @controller Controller name (default: current controller).
	 * @action Action/view name (default: current action).
	 * @template Path to a specific template file.
	 * @layout Layout to wrap the view in (false to skip layout).
	 * @cache Minutes to cache the rendered output.
	 * @returnAs "string" to return the output instead of setting it as the response.
	 * @hideDebugInformation Suppress debug output.
	 * @status HTTP status code.
	 */
	public any function renderView(
		string controller,
		string action,
		string template,
		any layout,
		any cache,
		string returnAs,
		boolean hideDebugInformation,
		numeric status
	);

	/**
	 * Render a partial template.
	 *
	 * @partial Path to the partial (e.g., "comments/comment").
	 * @cache Minutes to cache.
	 * @layout Layout to wrap the partial in.
	 * @returnAs "string" to return instead of setting as response.
	 * @dataFunction Function name that provides data to the partial.
	 * @status HTTP status code.
	 */
	public any function renderPartial(
		string partial,
		any cache,
		any layout,
		string returnAs,
		any dataFunction,
		numeric status
	);

	/**
	 * Render a plain text string as the response.
	 *
	 * @text The text content.
	 * @status HTTP status code.
	 */
	public void function renderText(string text, any status);

	/**
	 * Render an empty response body.
	 *
	 * @status HTTP status code (default: 200).
	 */
	public void function renderNothing(string status);

	/**
	 * Render data using a format-appropriate template (JSON, XML, etc.).
	 *
	 * @data The data to render (query, struct, array, or object).
	 * @controller Controller name.
	 * @action Action name.
	 * @template Template path.
	 * @layout Layout.
	 * @cache Minutes to cache.
	 * @returnAs "string" to return instead of setting as response.
	 * @hideDebugInformation Suppress debug output.
	 * @status HTTP status code.
	 */
	public any function renderWith(
		any data,
		string controller,
		string action,
		string template,
		any layout,
		any cache,
		string returnAs,
		boolean hideDebugInformation,
		numeric status
	);

	/**
	 * Redirect the client to another URL or route.
	 *
	 * @controller Target controller.
	 * @action Target action.
	 * @route Named route.
	 * @key Primary key value for the route.
	 * @params Additional URL parameters as a struct or string.
	 * @anchor URL fragment anchor.
	 * @onlyPath Whether to generate a relative path (true) or full URL (false).
	 * @host Override host for the URL.
	 * @protocol Override protocol (http/https).
	 * @port Override port.
	 * @statusCode HTTP redirect status code (301, 302, etc.).
	 * @addToken Whether to add session token (CF-specific).
	 * @delay Whether to delay the redirect until after the action completes.
	 * @encode Whether to encode the URL.
	 */
	public void function redirectTo(
		string controller,
		string action,
		string route,
		any key,
		any params,
		string anchor,
		boolean onlyPath,
		string host,
		string protocol,
		numeric port,
		numeric statusCode,
		boolean addToken,
		boolean delay,
		boolean encode
	);

	/**
	 * Return the current response body.
	 */
	public string function response();

	/**
	 * Set the response body directly.
	 *
	 * @content The response content string.
	 */
	public void function setResponse(string content);

}
