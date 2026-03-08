/**
 * Test middleware that adds data to the request struct.
 */
component implements="wheels.middleware.MiddlewareInterface" output="false" {

	public EnrichingMiddleware function init() {
		return this;
	}

	public string function handle(required struct request, required any next) {
		arguments.request.enriched = true;
		return arguments.next(arguments.request);
	}

}
