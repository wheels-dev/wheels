/**
 * Chains middleware components into a pipeline using nested closures.
 * Each middleware calls `next(request)` to pass control to the next one.
 * The final closure in the chain executes the actual controller dispatch.
 *
 * [section: Middleware]
 * [category: Core]
 */
component output="false" {

	/**
	 * Creates a new middleware pipeline.
	 *
	 * @middleware Array of middleware component instances (each implements MiddlewareInterface).
	 */
	public Pipeline function init(array middleware = []) {
		variables.middleware = arguments.middleware;
		return this;
	}

	/**
	 * Run the pipeline, wrapping the given core handler with all registered middleware.
	 *
	 * @request Struct containing route params and request context.
	 * @coreHandler Closure that performs the actual controller dispatch. Signature: `function(request)`.
	 * @return The response string.
	 */
	public string function run(required struct request, required any coreHandler) {
		// Build the chain from inside out: start with the core handler,
		// then wrap each middleware around it in reverse order.
		local.next = arguments.coreHandler;

		// Iterate in reverse so the first middleware in the array runs first.
		for (local.i = ArrayLen(variables.middleware); local.i >= 1; local.i--) {
			local.next = $wrapMiddleware(variables.middleware[local.i], local.next);
		}

		return local.next(arguments.request);
	}

	/**
	 * Returns the current middleware stack (for inspection/testing).
	 */
	public array function getMiddleware() {
		return variables.middleware;
	}

	/**
	 * Create a closure that invokes a single middleware's handle() with the given next function.
	 * Uses a shared struct to avoid CFML closure scoping issues (closures have their own local scope).
	 *
	 * Calls `handle()` positionally so user-defined middleware that still
	 * uses the legacy `required struct request` parameter name continues to
	 * work alongside the framework's built-in middleware (which renamed the
	 * parameter to `req` to avoid CFML reserved-scope shadowing on Adobe CF).
	 */
	private any function $wrapMiddleware(required any mw, required any nextFn) {
		var ctx = {mw = arguments.mw, nextFn = arguments.nextFn};
		return function(required struct request) {
			return ctx.mw.handle(arguments.request, ctx.nextFn);
		};
	}

}
