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
	 * @request Struct containing route params, CGI info, and any data added by prior middleware.
	 * @next Closure that calls the next middleware in the pipeline. Invoke as `next(request)`.
	 * @return The response string from the controller (or from a short-circuiting middleware).
	 */
	public string function handle(required struct request, required any next);

}
