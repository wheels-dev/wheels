/**
 * Interface that all middleware components must implement.
 * Middleware runs at the dispatch level, before controller instantiation.
 *
 * [section: Middleware]
 * [category: Core]
 */
interface {

	/**
	 * Handle the incoming request.
	 *
	 * @req Struct containing route params, CGI info, and any data added by prior middleware. Parameter is named `req` rather than `request` so impls can write to the request scope (`request.X = ...`) without the param shadowing the CFML reserved scope name on Adobe CF.
	 * @next Closure that calls the next middleware in the pipeline. Invoke as `next(req)`.
	 * @return The response string from the controller (or from a short-circuiting middleware).
	 */
	public string function handle(required struct req, required any next);

}
