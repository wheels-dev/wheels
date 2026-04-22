/**
 * Test middleware that short-circuits the pipeline (never calls next).
 */
component implements="wheels.middleware.MiddlewareInterface" output="false" {

	public BlockingMiddleware function init(required struct tracker) {
		variables.tracker = arguments.tracker;
		return this;
	}

	public string function handle(required struct request, required any next) {
		ArrayAppend(variables.tracker.order, "blocked");
		return "blocked";
	}

}
