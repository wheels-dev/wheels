/**
 * Test middleware for plugin middleware integration tests.
 * Appends "B" to the request.trace array so tests can verify execution order.
 */
component implements="wheels.middleware.MiddlewareInterface" {

	public TestMiddlewareB function init() {
		return this;
	}

	public string function handle(required struct request, required any next) {
		if (!StructKeyExists(arguments.request, "trace")) {
			arguments.request.trace = [];
		}
		ArrayAppend(arguments.request.trace, "B");
		return next(arguments.request);
	}

}
