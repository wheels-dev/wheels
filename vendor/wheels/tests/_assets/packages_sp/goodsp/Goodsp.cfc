/**
 * Test fixture: healthy ServiceProvider package. Records register()/boot()
 * invocations so ServiceProviderIsolationSpec can assert the lifecycle still
 * reaches it when a sibling provider throws.
 */
component implements="wheels.ServiceProviderInterface" {

	public any function init() {
		this.version = "1.0.0";
		this.registerCalled = false;
		this.bootCalled = false;
		this.containerReceived = JavaCast("null", "");
		return this;
	}

	public void function register(required any container) {
		this.registerCalled = true;
		this.containerReceived = arguments.container;
	}

	public void function boot(required struct app) {
		this.bootCalled = true;
	}

}
