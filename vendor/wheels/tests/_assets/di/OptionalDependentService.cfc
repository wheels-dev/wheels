/**
 * A test service with an OPTIONAL init() dependency. Used to verify that the
 * memoized init-parameter metadata is matched against the live mappings on
 * every resolution: a mapping registered after the component's first
 * resolution must still be injected on subsequent resolutions.
 */
component {

	public any function init(any simpleService = "") {
		variables.simpleService = arguments.simpleService;
		return this;
	}

	public boolean function hasDependency() {
		return IsObject(variables.simpleService);
	}

}
