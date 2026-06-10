/**
 * Test fixture: lazy ServiceProvider package with NO provides.services hint.
 * It stays lazy through the boot lifecycle; when getPackage() instantiates it
 * after boot, the loader must invoke register()/boot() late so its services
 * are not silently missing.
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
