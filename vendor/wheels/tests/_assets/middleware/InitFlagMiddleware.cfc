// Test middleware whose init() records that it ran, so a spec can check that a
// string-registered middleware with an init() still gets it called.
component implements="wheels.middleware.MiddlewareInterface" {

	public any function init() {
		variables.initialized = true;
		return this;
	}

	public boolean function wasInitialized() {
		return StructKeyExists(variables, "initialized") && variables.initialized;
	}

	public string function handle(required struct request, required any next) {
		return arguments.next(arguments.request);
	}

}
