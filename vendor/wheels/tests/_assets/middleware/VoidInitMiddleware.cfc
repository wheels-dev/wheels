// Test middleware whose init() returns nothing: the component itself is what
// gets cached and run.
component implements="wheels.middleware.MiddlewareInterface" {

	public void function init() {
		variables.initialized = true;
	}

	public boolean function wasInitialized() {
		return StructKeyExists(variables, "initialized") && variables.initialized;
	}

	public string function handle(required struct request, required any next) {
		return arguments.next(arguments.request);
	}

}
