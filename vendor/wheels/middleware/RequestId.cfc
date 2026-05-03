/**
 * Adds a unique request ID to every request for tracing and debugging.
 * Sets `request.wheels.requestId` and adds an `X-Request-Id` response header.
 *
 * [section: Middleware]
 * [category: Built-in]
 */
component implements="wheels.middleware.MiddlewareInterface" output="false" {

	public string function handle(required struct request, required any next) {
		// Generate a unique request ID.
		local.requestId = CreateUUID();
		// The middleware contract: the passed-in `request` struct carries
		// per-request context. Use `arguments.request` rather than bare
		// `request` so Adobe (which shadows the request SCOPE with the
		// function parameter of the same name) writes to the same struct
		// that Lucee/BoxLang see.
		if (!StructKeyExists(arguments.request, "wheels")) {
			arguments.request.wheels = {};
		}
		arguments.request.wheels.requestId = local.requestId;
		// Also mirror to the CFML `request` scope so legacy callers
		// reading `request.wheels.requestId` outside the middleware
		// continue to work. Use `cfset` via tag form so the scope lookup
		// is unambiguous on every engine.
		$writeRequestScopeRequestId(local.requestId);

		// Call the next middleware / controller dispatch.
		local.response = arguments.next(arguments.request);

		// Set response header (safe to call even if headers already sent).
		try {
			cfheader(name = "X-Request-Id", value = local.requestId);
		} catch (any e) {
			// Headers may already be flushed — silently ignore.
		}

		return local.response;
	}

	/**
	 * Helper: write the requestId to the `request` SCOPE. Pulled into a
	 * separate function so bare `request` resolves to the scope (no
	 * parameter named `request` shadows it here), making the assignment
	 * stable on Adobe / Lucee / BoxLang.
	 */
	private void function $writeRequestScopeRequestId(required string requestId) {
		if (!StructKeyExists(request, "wheels")) {
			request.wheels = {};
		}
		request.wheels.requestId = arguments.requestId;
	}

}
