<cfscript>
/**
 * wheels.Global include: pagination
 * Pagination store helpers used by finders and views.
 *
 * Included from `vendor/wheels/Global.cfc` at component-body scope so
 * these functions compile into the Global component. Children inherit
 * them; there is no per-instance mixin copy. Keep every helper that
 * must mix onto models/controllers `public` and `$`-prefixed
 * (cross-engine invariant 7).
 */


	/**
	 * Returns a struct with information about the specified paginated query.
	 * The keys that will be included in the struct are `currentPage`, `totalPages` and `totalRecords`.
	 *
	 * [section: Controller]
	 * [category: Pagination Functions]
	 *
	 * @handle The handle given to the query to return pagination information for.
	 */
	public struct function pagination(string handle = "query") {
		local.store = $ensurePaginationStore();
		if ($get("showErrorInformation")) {
			if (!StructKeyExists(local.store, arguments.handle)) {
				Throw(
					type = "Wheels.QueryHandleNotFound",
					message = "Wheels couldn't find a query with the handle of `#arguments.handle#`.",
					extendedInfo = "Make sure your `findAll` call has the `page` argument specified and matching `handle` argument if specified."
				);
			}
		}
		return local.store[arguments.handle];
	}


	/**
	 * Internal function.
	 * Creates the reserved per-request pagination namespace if it doesn't exist yet.
	 *
	 * Pagination handles are caller-supplied names, so storing them directly in `request.wheels`
	 * put arbitrary user input in the same case-insensitive keyspace as framework-owned request
	 * state. A handle matching a framework key overwrote it, and — because `pagination()` only
	 * validates the handle when `showErrorInformation` is on — production reads of an unknown
	 * handle returned whatever framework struct happened to occupy that key. Both directions are
	 * closed by confining handles to their own sub-struct (#3339, same fix shape as #3336).
	 *
	 * Returns the namespace struct so callers can work through the returned reference instead of
	 * calling this as a bare statement — Adobe CF 2025's parser rejects a bare dotted call like
	 * `application.wo.$ensurePaginationStore()` in a script statement position (see the cross-engine
	 * note in CLAUDE.md).
	 */
	public struct function $ensurePaginationStore() {
		if (!StructKeyExists(request, "wheels")) {
			request.wheels = {};
		}
		if (!StructKeyExists(request.wheels, "$pagination")) {
			request.wheels["$pagination"] = {};
		}
		return request.wheels["$pagination"];
	}


	/**
	 * Allows you to set a pagination handle for a custom query so you can perform pagination on it in your view with `paginationLinks`.
	 *
	 * [section: Controller]
	 * [category: Pagination Functions]
	 *
	 * @totalRecords Total count of records that should be represented by the paginated links.
	 * @currentPage Page number that should be represented by the data being fetched and the paginated links.
	 * @perPage Number of records that should be represented on each page of data.
	 * @handle Name of handle to reference in `paginationLinks`.
	 */
	public void function setPagination(
		required numeric totalRecords,
		numeric currentPage = 1,
		numeric perPage = 25,
		string handle = "query"
	) {
		// NOTE: this should be documented as a controller function but needs to be placed here because the findAll() method calls it.

		// All numeric values must be integers.
		arguments.totalRecords = Fix(arguments.totalRecords);
		arguments.currentPage = Fix(arguments.currentPage);
		arguments.perPage = Fix(arguments.perPage);

		// The totalRecords argument cannot be negative.
		if (arguments.totalRecords < 0) {
			arguments.totalRecords = 0;
		}

		// Default perPage to 25 if it's less then zero.
		if (arguments.perPage <= 0) {
			arguments.perPage = 25;
		}

		// Calculate the total pages the query will have.
		arguments.totalPages = Ceiling(arguments.totalRecords / arguments.perPage);

		// The currentPage argument shouldn't be less then 1 or greater then the number of pages.
		if (arguments.currentPage >= arguments.totalPages) {
			arguments.currentPage = arguments.totalPages;
		}
		if (arguments.currentPage < 1) {
			arguments.currentPage = 1;
		}

		// As a convenience for cfquery and cfloop when doing oldschool type pagination.
		// Set startrow for cfquery and cfloop.
		arguments.startRow = (arguments.currentPage * arguments.perPage) - arguments.perPage + 1;

		// Set maxrows for cfquery.
		arguments.maxRows = arguments.perPage;

		// Set endrow for cfloop.
		arguments.endRow = (arguments.startRow - 1) + arguments.perPage;

		// The endRow argument shouldn't be greater then the totalRecords or less than startRow.
		if (arguments.endRow >= arguments.totalRecords) {
			arguments.endRow = arguments.totalRecords;
		}
		if (arguments.endRow < arguments.startRow) {
			arguments.endRow = arguments.startRow;
		}

		local.args = Duplicate(arguments);
		StructDelete(local.args, "handle");
		local.store = $ensurePaginationStore();
		local.store[arguments.handle] = local.args;
	}
</cfscript>
