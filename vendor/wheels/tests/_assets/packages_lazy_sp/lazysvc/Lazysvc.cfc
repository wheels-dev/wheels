/**
 * Test fixture: lazy service-only ServiceProvider package. Declares
 * provides.services in its manifest, so the loader must instantiate it into
 * the ServiceProvider lifecycle at boot — otherwise the services it exists
 * to register would silently never register.
 */
component implements="wheels.ServiceProviderInterface" {

	public any function init() {
		this.version = "1.0.0";
		this.registerCalled = false;
		this.bootCalled = false;
		return this;
	}

	public void function register(required any container) {
		this.registerCalled = true;
	}

	public void function boot(required struct app) {
		this.bootCalled = true;
	}

}
