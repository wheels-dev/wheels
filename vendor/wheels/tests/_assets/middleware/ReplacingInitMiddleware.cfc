// Test middleware whose init() returns a different object. As before init()
// became optional, what init() returns is what gets cached and run.
component implements="wheels.middleware.MiddlewareInterface" {

	public any function init() {
		return CreateObject("component", "wheels.tests._assets.middleware.NoInitMiddleware");
	}

	public string function handle(required struct request, required any next) {
		return arguments.next(arguments.request);
	}

}
