/**
 * Hardener B4 fixture: the only package in this vendor tree. Lazy, implements
 * ServiceProviderInterface, and does NOT hint provides.services. The loader
 * must still detect ServiceProvider work so register()/boot() run.
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
