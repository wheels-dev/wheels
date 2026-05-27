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
		$writeRequestId(local.requestId);

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
	 * Store the request ID on the `request` scope so it's available request-wide
	 * for tracing. Kept in a helper with no `request` parameter on purpose:
	 * inside `handle()` the `required struct request` parameter shadows the
	 * `request` scope on Adobe CF, so a bare `request.wheels.requestId = …`
	 * there writes to the passed struct instead of the scope (CLAUDE.md
	 * cross-engine anti-pattern ##11). Here `request` is unambiguously the scope.
	 */
	private void function $writeRequestId(required string requestId) {
		if (!StructKeyExists(request, "wheels")) {
			request.wheels = {};
		}
		request.wheels.requestId = arguments.requestId;
	}

}
