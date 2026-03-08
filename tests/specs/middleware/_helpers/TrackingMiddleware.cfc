/**
 * Test middleware that records before/after execution order.
 */
component implements="wheels.middleware.MiddlewareInterface" output="false" {

	public TrackingMiddleware function init(required string id, required struct tracker) {
		variables.id = arguments.id;
		variables.tracker = arguments.tracker;
		return this;
	}

	public string function handle(required struct request, required any next) {
		ArrayAppend(variables.tracker.order, "before:#variables.id#");
		local.response = arguments.next(arguments.request);
		ArrayAppend(variables.tracker.order, "after:#variables.id#");
		return local.response;
	}

}
