/**
 * Test plugin that implements ServiceProviderInterface.
 * Used to verify the interface contract is implementable and the full
 * register/boot lifecycle works including service resolution during boot.
 */
component implements="wheels.ServiceProviderInterface" {

	function init() {
		this.version = "3.0";
		this.registerCalled = false;
		this.bootCalled = false;
		this.containerReceived = javacast("null", "");
		this.appReceived = javacast("null", "");
		this.resolvedDuringBoot = javacast("null", "");
		return this;
	}

	public void function register(required any container) {
		this.registerCalled = true;
		this.containerReceived = arguments.container;

		// Register a real service into the container to prove end-to-end wiring.
		// Use mapInstance() instead of map() to avoid collision with Lucee/Adobe
		// built-in struct.map() member function.
		arguments.container.mapInstance("pluginGreeting").to(
			"wheels.tests._assets.plugins.serviceprovider.TestServiceProvider.PluginGreetingService"
		).asSingleton();
	}

	public void function boot(required struct app) {
		this.bootCalled = true;
		this.appReceived = arguments.app;
		// Resolve the service registered during register() to prove DI works at boot time
		if (!IsNull(this.containerReceived) && IsObject(this.containerReceived) && StructKeyExists(this.containerReceived, "containsInstance")) {
			if (this.containerReceived.containsInstance("pluginGreeting")) {
				this.resolvedDuringBoot = this.containerReceived.getInstance("pluginGreeting");
			}
		}
	}

	/**
	 * Helper method that would normally be mixed into framework objects.
	 * ServiceProvider plugins should NOT have their methods mixed in.
	 */
	public string function testServiceHelper() {
		return "from-service-provider";
	}

}
