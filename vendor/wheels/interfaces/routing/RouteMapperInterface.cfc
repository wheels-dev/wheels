/**
 * Contract for the route definition DSL used in `config/routes.cfm`.
 *
 * The default implementation is spread across `wheels.mapper.resources`,
 * `matching`, `scoping`, and `mapping` — all mixed into `Mapper.cfc` at
 * runtime via `$integrateComponents()`. Because of this mixin pattern,
 * Mapper cannot use `implements=` at compile time.
 *
 * An alternative router must implement ALL 28 methods below for existing
 * `config/routes.cfm` files in the wild to work without modification.
 *
 * [section: Routing]
 * [category: Interface]
 */
interface {

	/* ── Resource Definition (resources.cfc) ─────────────────── */

	/**
	 * Define RESTful resource routes (index, show, new, create, edit, update, delete).
	 *
	 * @name Resource name (determines controller and URL segment).
	 * @nested Whether to begin a nested scope (requires `end()` to close).
	 * @path Override the URL segment (default: `name`).
	 * @controller Override the controller name.
	 * @singular Override the singular form of the resource name.
	 * @plural Override the plural form.
	 * @only Comma-delimited list of actions to generate (whitelist).
	 * @except Comma-delimited list of actions to skip (blacklist).
	 * @shallow Whether nested resources use shallow URLs.
	 * @shallowPath URL prefix for shallow routes.
	 * @shallowName Route name prefix for shallow routes.
	 * @constraints Struct of regex constraints for route variables.
	 * @callback Closure receiving the mapper for nested resource definitions.
	 * @binding Route model binding: true, false, or a model name string.
	 */
	public struct function resources(
		required string name,
		boolean nested,
		string path,
		string controller,
		string singular,
		string plural,
		string only,
		string except,
		boolean shallow,
		string shallowPath,
		string shallowName,
		struct constraints,
		any callback,
		any binding
	);

	/**
	 * Define a singular resource (show, new, create, edit, update, delete — no index).
	 * Same parameters as `resources()`.
	 */
	public struct function resource(
		required string name,
		boolean nested,
		string path,
		string controller,
		string singular,
		string plural,
		string only,
		string except,
		boolean shallow,
		string shallowPath,
		string shallowName,
		struct constraints,
		any callback,
		any binding
	);

	/**
	 * Open a member scope (routes that act on a specific resource instance, e.g., `/users/:key/activate`).
	 */
	public struct function member();

	/**
	 * Open a collection scope (routes that act on the collection, e.g., `/users/search`).
	 */
	public struct function collection();

	/* ── HTTP Method Matching (matching.cfc) ──────────────────── */

	/**
	 * Define a GET route.
	 *
	 * @name Route name (for URL generation via `urlFor(route="name")`).
	 * @pattern URL pattern with variables (e.g., "/users/:id").
	 * @to Controller##action shorthand (e.g., "users##show").
	 * @controller Target controller.
	 * @action Target action.
	 * @package Controller package/subfolder.
	 * @on Member or collection context: "member" or "collection".
	 * @redirect URL to redirect to (301).
	 */
	public struct function get(
		string name,
		string pattern,
		string to,
		string controller,
		string action,
		string package,
		string on,
		string redirect
	);

	/** Define a POST route. Same parameters as `get()`. */
	public struct function post(string name, string pattern, string to, string controller, string action, string package, string on, string redirect);

	/** Define a PUT route. Same parameters as `get()`. */
	public struct function put(string name, string pattern, string to, string controller, string action, string package, string on, string redirect);

	/** Define a PATCH route. Same parameters as `get()`. */
	public struct function patch(string name, string pattern, string to, string controller, string action, string package, string on, string redirect);

	/** Define a DELETE route. Same parameters as `get()`. */
	public struct function delete(string name, string pattern, string to, string controller, string action, string package, string on, string redirect);

	/**
	 * Define the root route (homepage).
	 *
	 * @to Controller##action (e.g., "home##index").
	 * @mapFormat Whether to append format matching.
	 */
	public struct function root(string to, boolean mapFormat);

	/**
	 * Define a wildcard catch-all route. Must be declared last.
	 *
	 * @method HTTP method to match (default: all).
	 * @action Default action name.
	 * @mapKey Whether to map :key from the URL.
	 * @mapFormat Whether to map the format extension.
	 */
	public struct function wildcard(string method, string action, boolean mapKey, boolean mapFormat);

	/**
	 * Define a health check endpoint.
	 *
	 * @to Controller##action for the health check.
	 * @path URL path (default: "/health").
	 * @name Route name.
	 */
	public struct function health(string to, string path, string name);

	/* ── Route Constraints (matching.cfc) ────────────────────── */

	/** Constrain a route variable to numeric values only. */
	public struct function whereNumber(required string variableName);

	/** Constrain a route variable to alphabetic values only. */
	public struct function whereAlpha(required string variableName);

	/** Constrain a route variable to alphanumeric values. */
	public struct function whereAlphaNumeric(required string variableName);

	/** Constrain a route variable to UUID format. */
	public struct function whereUuid(required string variableName);

	/** Constrain a route variable to URL-safe slug format. */
	public struct function whereSlug(required string variableName);

	/** Constrain a route variable to a set of allowed values. */
	public struct function whereIn(required string variableName, required string values);

	/** Constrain a route variable to match a custom regex pattern. */
	public struct function whereMatch(required string variableName, required string pattern);

	/* ── Scoping (scoping.cfc) ───────────────────────────────── */

	/**
	 * Open a scope that applies shared settings to all nested routes.
	 *
	 * @name Scope name (used in route name prefixing).
	 * @path URL path prefix.
	 * @package Controller package/subfolder.
	 * @controller Default controller for nested routes.
	 * @shallow Enable shallow nesting.
	 * @shallowPath URL prefix for shallow routes.
	 * @shallowName Route name prefix for shallow routes.
	 * @constraints Struct of regex constraints.
	 * @middleware Array of middleware to apply to nested routes.
	 * @binding Route model binding for nested resources.
	 */
	public struct function scope(
		string name,
		string path,
		string package,
		string controller,
		boolean shallow,
		string shallowPath,
		string shallowName,
		struct constraints,
		any middleware,
		any binding
	);

	/**
	 * Open a namespace scope (URL prefix + controller subfolder).
	 *
	 * @name Namespace name.
	 * @package Controller package override.
	 * @path URL path override.
	 */
	public struct function namespace(required string name, string package, string path);

	/**
	 * Open a package scope (controller subfolder, no URL prefix).
	 *
	 * @name Package/subfolder name.
	 * @package Package path override.
	 */
	public struct function package(required string name, string package);

	/**
	 * Scope routes to a specific controller.
	 *
	 * @controller Controller name.
	 * @name Route name prefix.
	 * @path URL path prefix.
	 */
	public struct function controller(required string controller, string name, string path);

	/**
	 * Return the current route constraints in scope.
	 */
	public struct function constraints();

	/**
	 * Open a named group scope (combines path prefix and optional constraints).
	 *
	 * @name Group name.
	 * @path URL path prefix.
	 * @constraints Struct of regex constraints.
	 * @callback Closure for defining nested routes.
	 */
	public struct function group(string name, string path, struct constraints, any callback);

	/**
	 * Open an API scope (JSON-first, no format extension).
	 *
	 * @path URL path prefix (default: "/api").
	 * @name Route name prefix.
	 * @constraints Struct of regex constraints.
	 * @callback Closure for nested routes.
	 */
	public struct function api(string path, string name, struct constraints, any callback);

	/**
	 * Open a versioned scope (e.g., `/v1/...`).
	 *
	 * @number Version number.
	 * @path URL path prefix (default: "/v{number}").
	 * @name Route name prefix.
	 * @callback Closure for nested routes.
	 */
	public struct function version(required numeric number, string path, string name, any callback);

	/* ── Lifecycle (mapping.cfc) ─────────────────────────────── */

	/**
	 * Close the current scope, namespace, resource, or mapper block.
	 */
	public struct function end();

}
