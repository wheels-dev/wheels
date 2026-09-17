/**
 * Hardener S7 fixture: register() writes a DI binding, boot() throws.
 * The loader must unwind the binding so a failed boot leaves no residue.
 */
component implements="wheels.ServiceProviderInterface" {

	public any function init() {
		this.version = "1.0.0";
		this.registerCalled = false;
		return this;
	}

	public void function register(required any container) {
		this.registerCalled = true;
		arguments.container.mapInstance("hardenerBootResidue").to("wheels.tests._assets.packages_hardener_bootresidue.bootresidue.Bootresidue");
	}

	public void function boot(required struct app) {
		Throw(type = "Tests.HardenerBootResidue", message = "boot() residue fixture");
	}

}
