// Test middleware that adds its own key to the request context, then continues.
component implements="wheels.middleware.MiddlewareInterface" {

	public string function handle(required struct request, required any next) {
		arguments.request.note = "from-middleware";
		return arguments.next(arguments.request);
	}

}
