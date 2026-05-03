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
		// Adobe CF doesn't auto-vivify the parent struct on nested
		// assignment; ensure `request.wheels` exists before writing so
		// the middleware works outside the normal Wheels dispatch context
		// (e.g. in pipeline-only test harnesses).
		if (!StructKeyExists(request, "wheels")) {
			request.wheels = {};
		}
		request.wheels.requestId = local.requestId;

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

}
