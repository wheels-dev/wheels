/**
 * Contract for route matching and dispatch (the read side of routing).
 *
 * While `RouteMapperInterface` defines how routes are declared, this interface
 * defines how the framework resolves an incoming request to a matching route.
 *
 * The default implementation lives in `Mapper.cfc`. The `$` prefix on
 * `$findMatchingRoute` is a Wheels naming convention meaning "framework-internal"
 * — it is NOT a CFML access modifier. Community implementors must implement it.
 *
 * [section: Routing]
 * [category: Interface]
 */
interface {

	/**
	 * Find the route that matches the given request path and HTTP method.
	 *
	 * @path The URL path to match (e.g., "/users/42").
	 * @method The HTTP method (e.g., "GET", "POST").
	 * @routes Optional array of routes to search (default: all registered routes).
	 * @return Struct containing matched route details (controller, action, params, etc.).
	 *         Throws `Wheels.RouteNotFound` if no match.
	 */
	public struct function $findMatchingRoute(required string path, required string method, array routes);

	/**
	 * Return all registered routes as an array of structs.
	 *
	 * @return Array of route definition structs.
	 */
	public array function getRoutes();

}
