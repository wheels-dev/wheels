/**
 * Extends DependentService WITHOUT declaring its own init() so the container
 * must walk the extends chain in the metadata to find the inherited
 * init(simpleService) signature for constructor auto-wiring.
 */
component extends="wheels.tests._assets.di.DependentService" {

	public string function shout() {
		return UCase(delegateGreet());
	}

}
