/**
 * Contract for route resolution (the read side of routing).
 *
 * While `RouteMapperInterface` defines how routes are declared, this interface
 * defines how registered routes can be retrieved. Route matching/dispatch is
 * handled by `Dispatch.cfc` separately.
 *
 * The default implementation lives in `Mapper.cfc`.
 *
 * [section: Routing]
 * [category: Interface]
 */
interface {

	/**
	 * Return all registered routes as an array of structs.
	 *
	 * @return Array of route definition structs.
	 */
	public array function getRoutes();

}
