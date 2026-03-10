/**
 * Provides declarative service injection for controllers.
 *
 * Use inject() in a controller's config() to declare which DI-registered
 * services should be resolved and attached to each controller instance.
 *
 * Services are declared at class level (config runs once) but resolved
 * at instance level (per-request), which is important for request-scoped services.
 */
component {

	/**
	 * Declare one or more services for injection into this controller.
	 * Call in config(). Services are resolved when the controller instance is created.
	 *
	 * @name Comma-delimited list of registered service names to inject.
	 */
	public void function inject(required string name) {
		local.names = listToArray(arguments.name);
		for (local.serviceName in local.names) {
			local.serviceName = trim(local.serviceName);
			if (len(local.serviceName) && !arrayFind(variables.$class.services, local.serviceName)) {
				arrayAppend(variables.$class.services, local.serviceName);
			}
		}
	}

	/**
	 * Return the list of declared service names for this controller.
	 */
	public array function injectedServices() {
		if (structKeyExists(variables, "$class") && structKeyExists(variables.$class, "services")) {
			return variables.$class.services;
		}
		return [];
	}

	/**
	 * Resolve all declared services from the DI container and attach them
	 * as properties on this controller instance (this.serviceName).
	 * Called automatically during controller instance initialization.
	 */
	public void function $resolveInjectedServices() {
		if (!structKeyExists(variables, "$class") || !structKeyExists(variables.$class, "services")) {
			return;
		}
		if (!isDefined("application.wheelsdi")) {
			return;
		}
		for (local.serviceName in variables.$class.services) {
			if (application.wheelsdi.containsInstance(local.serviceName)) {
				this[local.serviceName] = application.wheelsdi.getInstance(local.serviceName);
			}
		}
	}

}
