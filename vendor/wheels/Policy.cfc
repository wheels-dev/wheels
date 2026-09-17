/**
 * Base Policy class for the Wheels authorization layer (issue #3156).
 *
 * A policy answers "may this user perform this action on this record?" with one
 * method per action (Pundit-style). This base class is DEFAULT-DENY: every
 * standard action returns `false` and `scope()` returns a no-rows chain, so an
 * app policy must explicitly override a method to grant access.
 *
 * App policies live in `app/policies/<ModelName>Policy.cfc` and extend the
 * app-level `Policy.cfc` stub in the same folder (which extends `wheels.Policy`,
 * mirroring how `app/models/Model.cfc` extends `wheels.Model`). Scaffold one
 * with `wheels generate policy Post`.
 *
 * Usage:
 *   // app/policies/PostPolicy.cfc
 *   component extends="Policy" {
 *     public boolean function update() {
 *       return IsStruct(variables.user)
 *         && StructKeyExists(variables.user, "id")
 *         && variables.user.id == variables.record.authorId;
 *     }
 *     public any function scope(required any collection) {
 *       if (IsStruct(variables.user) && StructKeyExists(variables.user, "id")) {
 *         return arguments.collection.where("authorId", variables.user.id);
 *       }
 *       return super.scope(arguments.collection);
 *     }
 *   }
 *
 * Controllers and views consume policies through the `authorize()`, `can()`,
 * and `policyScope()` helpers mixed in from `wheels.controller.authorization`.
 *
 * [section: Authorization]
 * [category: Core]
 */
component {

	/**
	 * Stores the authenticated identity and the record under evaluation.
	 *
	 * @user The authenticated identity (typically a struct or model instance), or an empty string for a guest.
	 * @record The model instance or model class being authorized, or an empty string for headless policies.
	 */
	public any function init(any user = "", any record = "") {
		variables.user = arguments.user;
		variables.record = arguments.record;
		return this;
	}

	/**
	 * May the user list records? Default-deny — override in your policy to grant.
	 */
	public boolean function index() {
		return false;
	}

	/**
	 * May the user view this record? Default-deny — override in your policy to grant.
	 */
	public boolean function show() {
		return false;
	}

	/**
	 * May the user see the new-record form? Default-deny — override in your policy to grant.
	 */
	public boolean function new() {
		return false;
	}

	/**
	 * May the user create a record? Default-deny — override in your policy to grant.
	 */
	public boolean function create() {
		return false;
	}

	/**
	 * May the user see the edit form for this record? Default-deny — override in your policy to grant.
	 */
	public boolean function edit() {
		return false;
	}

	/**
	 * May the user update this record? Default-deny — override in your policy to grant.
	 */
	public boolean function update() {
		return false;
	}

	/**
	 * May the user delete this record? Default-deny — override in your policy to grant.
	 */
	public boolean function delete() {
		return false;
	}

	/**
	 * Narrows a collection to the records the user may see (used by `policyScope()`
	 * for `index` actions). Default-deny: returns a no-rows chain that does not
	 * call `whereIn` with an empty id list, so an empty resolved-id set cannot
	 * become `IN ()` or match every row. Override in your policy to widen.
	 *
	 * @collection The model class (or chainable query builder / scope chain) to narrow.
	 */
	public any function scope(required any collection) {
		return CreateObject("component", "wheels.Policy").init();
	}

	/**
	 * The identity this policy was initialized with. An empty string is a guest.
	 */
	public any function currentUser() {
		return variables.user;
	}

	/**
	 * No-rows terminal for the default-deny `scope()` chain.
	 */
	public numeric function count() {
		return 0;
	}

	/**
	 * Empty query for the default-deny `scope()` chain.
	 */
	public query function findAll() {
		return QueryNew("id");
	}

	/**
	 * Keeps the default-deny chain empty when callers compose after `scope()`.
	 */
	public any function where() {
		return this;
	}

	/**
	 * Keeps the default-deny chain empty. Does not interpolate an empty `IN ()`.
	 */
	public any function whereIn() {
		return this;
	}

}
