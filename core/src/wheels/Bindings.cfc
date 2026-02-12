/**
 * DI binding configuration for Wheels.
 * Maps alias names to component paths for the lightweight Injector.
 */
component {

	public void function configure(required any injector) {
		arguments.injector
			.map("global").to("wheels.Global")
			.map("eventmethods").to("wheels.events.EventMethods")
			.map("ViewObj").to("wheels.view");
	}

}
