/**
 * Test fixture: healthy legacy plugin implementing ServiceProviderInterface.
 * Sorted plugin order loads FailingProvider first, so this plugin proves the
 * lifecycle continues past a throwing sibling provider.
 */
component implements="wheels.ServiceProviderInterface" {

	function init() {
		this.version = "3.0";
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
