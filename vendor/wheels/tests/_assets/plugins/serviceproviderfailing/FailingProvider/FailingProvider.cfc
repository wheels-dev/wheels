/**
 * Test fixture: legacy plugin implementing ServiceProviderInterface whose
 * register() always throws. Used by pluginsModernSpec to prove a broken
 * provider is logged and skipped without aborting the lifecycle for sibling
 * providers. boot() sets a request flag so specs can assert the boot phase
 * never reaches a plugin whose register() failed.
 */
component implements="wheels.ServiceProviderInterface" {

	function init() {
		this.version = "3.0";
		return this;
	}

	public void function register(required any container) {
		Throw(type = "Tests.PluginSPRegisterBoom", message = "plugin register() failure fixture");
	}

	public void function boot(required struct app) {
		request.$spPluginFailingBootCalled = true;
	}

}
