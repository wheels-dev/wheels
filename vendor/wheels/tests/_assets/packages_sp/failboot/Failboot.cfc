/**
 * Test fixture: ServiceProvider package whose register() succeeds but boot()
 * always throws. Used by ServiceProviderIsolationSpec to prove a boot-phase
 * failure is logged, recorded in failedPackages, and skipped without aborting
 * the boot of sibling providers.
 */
component implements="wheels.ServiceProviderInterface" {

	public any function init() {
		this.version = "1.0.0";
		this.registerCalled = false;
		return this;
	}

	public void function register(required any container) {
		this.registerCalled = true;
	}

	public void function boot(required struct app) {
		Throw(type = "Tests.SPBootBoom", message = "boot() failure fixture");
	}

}
