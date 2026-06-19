/**
 * Test fixture: ServiceProvider package whose register() always throws.
 * Used by ServiceProviderIsolationSpec to prove a broken provider is logged,
 * recorded in failedPackages, and skipped — without aborting the lifecycle
 * for sibling providers. boot() sets a request flag so specs can assert the
 * boot phase never reaches a provider whose register() failed.
 */
component implements="wheels.ServiceProviderInterface" {

	public any function init() {
		this.version = "1.0.0";
		return this;
	}

	public void function register(required any container) {
		Throw(type = "Tests.SPRegisterBoom", message = "register() failure fixture");
	}

	public void function boot(required struct app) {
		request.$spFailregisterBootCalled = true;
	}

}
