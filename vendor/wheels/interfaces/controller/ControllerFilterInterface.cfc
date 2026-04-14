/**
 * Contract for controller filter chain (before/after action hooks).
 *
 * The default implementation lives in `wheels.controller.filters` and is mixed
 * into Controller instances at runtime. Compliance is verified by runtime reflection tests.
 *
 * Filters are registered in a controller's `config()` method and run before
 * or after the matching action executes.
 *
 * [section: Controller]
 * [category: Interface]
 */
interface {

	/**
	 * Register a filter to run before or after controller actions.
	 *
	 * @through Comma-delimited list of method names to call.
	 * @type Filter type: "before" or "after".
	 * @only Comma-delimited list of actions this filter applies to (whitelist).
	 * @except Comma-delimited list of actions to skip (blacklist).
	 * @placement Where to insert: "prepend" or "append" (default).
	 */
	public void function filters(
		string through,
		string type,
		string only,
		string except,
		string placement
	);

	/**
	 * Return the current filter chain as an array of structs.
	 *
	 * @type Filter type to return: "before", "after", or blank for all.
	 * @return Array of filter configuration structs.
	 */
	public array function filterChain(string type);

	/**
	 * Replace the entire filter chain with the given array.
	 *
	 * @chain Array of filter configuration structs.
	 */
	public void function setFilterChain(array chain);

}
