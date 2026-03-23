/**
 * Test middleware for plugin middleware integration tests.
 * Appends "A" to the request.trace array so tests can verify execution order.
 */
component implements="wheels.middleware.MiddlewareInterface" {

	public TestMiddlewareA function init() {
		return this;
	}

	public string function handle(required struct request, required any next) {
		if (!StructKeyExists(arguments.request, "trace")) {
			arguments.request.trace = [];
		}
		ArrayAppend(arguments.request.trace, "A");
		return next(arguments.request);
	}

}
