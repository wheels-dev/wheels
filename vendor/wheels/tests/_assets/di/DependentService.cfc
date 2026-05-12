/**
 * A test service that depends on SimpleService via init() parameter.
 * Used to test auto-wiring of init() arguments.
 */
component {

	public DependentService function init(required any simpleService) {
		variables.simpleService = arguments.simpleService;
		return this;
	}

	public any function getSimpleService() {
		return variables.simpleService;
	}

	public string function delegateGreet() {
		return variables.simpleService.greet();
	}

}
