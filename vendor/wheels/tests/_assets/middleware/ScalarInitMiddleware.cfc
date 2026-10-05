// Test middleware whose init() returns a non-object (true): the component
// itself must be what gets cached and run, not the returned value.
component implements="wheels.middleware.MiddlewareInterface" {

	public any function init() {
		variables.initialized = true;
		return true;
	}

	public boolean function wasInitialized() {
		return StructKeyExists(variables, "initialized") && variables.initialized;
	}

	public string function handle(required struct request, required any next) {
		return arguments.next(arguments.request);
	}

}
