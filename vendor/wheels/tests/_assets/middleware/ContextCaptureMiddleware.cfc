/**
 * Test middleware that captures the request context it receives into a sink
 * struct supplied at construction so specs can assert on the context shape
 * (#3074). By default it short-circuits the pipeline and returns "ok" so
 * dispatch-level specs don't need a routable controller; pass
 * passThrough=true to delegate to next() instead.
 *
 * The sink indirection avoids writing to the `request` scope from inside
 * handle(), where the `request` parameter shadows the scope (see the
 * $writeRequestId comment in wheels.middleware.RequestId).
 */
component implements="wheels.middleware.MiddlewareInterface" {

	public ContextCaptureMiddleware function init(struct sink = {}, boolean passThrough = false) {
		variables.sink = arguments.sink;
		variables.passThrough = arguments.passThrough;
		return this;
	}

	public string function handle(required struct request, required any next) {
		variables.sink.context = arguments.request;
		if (variables.passThrough) {
			return arguments.next(arguments.request);
		}
		return "ok";
	}

}
