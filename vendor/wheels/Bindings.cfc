/**
 * DI binding configuration for Wheels.
 * Maps alias names to component paths for the lightweight Injector.
 */
component {

	public void function configure(required any injector) {
		// Core framework components
		arguments.injector
			.map("global").to("wheels.Global")
			.map("eventmethods").to("wheels.events.EventMethods")
			.map("ViewObj").to("wheels.view");

		// Interface → default implementation bindings
		// These enable community drop-in replacements via:
		//   bind("ModelFinderInterface").to("my.CustomFinder")

		// Model subsystem
		arguments.injector
			.bind("ModelFinderInterface").to("wheels.model.read")
			.bind("ModelPersistenceInterface").to("wheels.model.crud")
			.bind("ModelValidationInterface").to("wheels.model.validations")
			.bind("ModelCallbackInterface").to("wheels.model.callbacks")
			.bind("ModelAssociationInterface").to("wheels.model.associations")
			.bind("ModelPropertyInterface").to("wheels.model.properties");

		// Controller subsystem
		arguments.injector
			.bind("ControllerFilterInterface").to("wheels.controller.filters")
			.bind("ControllerRenderingInterface").to("wheels.controller.rendering")
			.bind("ControllerFlashInterface").to("wheels.controller.flash");

		// View subsystem
		arguments.injector
			.bind("ViewFormInterface").to("wheels.view.formsplain")
			.bind("ViewLinkInterface").to("wheels.view.links")
			.bind("ViewContentInterface").to("wheels.view.content");

		// Routing subsystem
		arguments.injector
			.bind("RouteMapperInterface").to("wheels.Mapper")
			.bind("RouteResolverInterface").to("wheels.Mapper");

		// Events subsystem
		arguments.injector
			.bind("EventHandlerInterface").to("wheels.events.EventMethods");

		// Database adapters (no default — adapter is selected per datasource at runtime)
		// Bind per-project: bind("DatabaseModelAdapterInterface").to("wheels.databaseAdapters.H2Model")

		// DI subsystem
		arguments.injector
			.bind("InjectorInterface").to("wheels.Injector");
	}

}
