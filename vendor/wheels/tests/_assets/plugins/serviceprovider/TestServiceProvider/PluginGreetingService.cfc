/**
 * Simple service registered by TestServiceProvider during register().
 * Used to verify that ServiceProvider plugins can register real services
 * into the DI container.
 */
component {

	public PluginGreetingService function init() {
		return this;
	}

	public string function greet(required string name) {
		return "Hello from plugin, #arguments.name#!";
	}

}
