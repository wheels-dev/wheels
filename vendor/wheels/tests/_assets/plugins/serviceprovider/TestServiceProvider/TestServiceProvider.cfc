/**
 * Test plugin that implements ServiceProviderInterface.
 * Used to verify the interface contract is implementable.
 */
component implements="wheels.ServiceProviderInterface" {

	function init() {
		this.version = "3.0";
		this.registerCalled = false;
		this.bootCalled = false;
		this.containerReceived = javacast("null", "");
		this.appReceived = javacast("null", "");
		return this;
	}

	public void function register(required any container) {
		this.registerCalled = true;
		this.containerReceived = arguments.container;
	}

	public void function boot(required struct app) {
		this.bootCalled = true;
		this.appReceived = arguments.app;
	}

	/**
	 * Helper method that would normally be mixed into framework objects.
	 * ServiceProvider plugins should NOT have their methods mixed in.
	 */
	public string function testServiceHelper() {
		return "from-service-provider";
	}

}
