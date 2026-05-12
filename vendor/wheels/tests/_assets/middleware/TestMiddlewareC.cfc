/**
 * Test middleware for plugin middleware ordering tests.
 * Appends "C" to the request.trace array so tests can verify execution order.
 */
component implements="wheels.middleware.MiddlewareInterface" {

	public TestMiddlewareC function init() {
		return this;
	}

	public string function handle(required struct request, required any next) {
		if (!StructKeyExists(arguments.request, "trace")) {
			arguments.request.trace = [];
		}
		ArrayAppend(arguments.request.trace, "C");
		return next(arguments.request);
	}

}
