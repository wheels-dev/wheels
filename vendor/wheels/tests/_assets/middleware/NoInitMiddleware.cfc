// Test middleware with handle() and no init(): MiddlewareInterface requires
// only handle(), so a string-registered component like this must still load.
component implements="wheels.middleware.MiddlewareInterface" {

	public string function handle(required struct request, required any next) {
		arguments.request.noInit = "handled";
		return arguments.next(arguments.request);
	}

}
