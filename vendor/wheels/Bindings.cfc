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
			.bind("ModelPersistenceInterface").to("wheels.model.create")
			.bind("ModelValidationInterface").to("wheels.model.validations")
			.bind("ModelErrorInterface").to("wheels.model.errors")
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
			.bind("ViewContentInterface").to("wheels.view.miscellaneous");

		// Routing subsystem
		arguments.injector
			.bind("RouteMapperInterface").to("wheels.Mapper")
			.bind("RouteResolverInterface").to("wheels.Mapper");

		// Events subsystem
		arguments.injector
			.bind("EventHandlerInterface").to("wheels.events.EventMethods");

		// Database adapters (no default — adapter is selected per datasource at runtime)
		// Bind per-project: bind("DatabaseModelAdapterInterface").to("wheels.databaseAdapters.H2.H2Model")

		// Note: there is intentionally NO "InjectorInterface" binding. The live
		// container self-registers at application.wheelsdi during init(), and a
		// path binding here could never resolve (Injector.init() requires a
		// binderPath that no auto-wire mapping supplies) — and if it ever did,
		// the fresh instance would clobber application.wheelsdi.
	}

}
