/**
 * Lightweight dependency injection container for Wheels.
 *
 * Replaces WireBox with only the features Wheels actually uses:
 * - map(name).to(componentPath) fluent bindings
 * - getInstance(name, initArguments) resolution
 * - onDIcomplete() lifecycle callback
 *
 * Self-registers at application.wirebox for backward compatibility.
 */
component {

	/**
	 * Constructor. Accepts a dotted-path to a Bindings CFC that has a configure(injector) method.
	 *
	 * @binderPath Dotted component path to the bindings configuration CFC (e.g. "wheels.Bindings")
	 */
	public Injector function init(required string binderPath) {
		// Storage for alias → component path mappings
		variables.mappings = {};

		// Singleton cache: component path → instance
		variables.singletons = {};

		// Track which mappings are singletons
		variables.singletonFlags = {};

		// Track the current mapping being built (for fluent API)
		variables.currentMapping = "";

		// Register self at application.wirebox for backward compatibility
		application.wirebox = this;

		// Load bindings configuration
		local.binder = createObject("component", arguments.binderPath);
		local.binder.configure(this);

		return this;
	}

	/**
	 * Start a fluent mapping definition. Call .to() next.
	 *
	 * @name The alias name for this mapping (e.g. "global", "Plugins")
	 */
	public Injector function map(required string name) {
		variables.currentMapping = arguments.name;
		return this;
	}

	/**
	 * Complete a mapping by specifying the component path.
	 *
	 * @componentPath Dotted component path (e.g. "wheels.Global")
	 */
	public Injector function to(required string componentPath) {
		if (!len(variables.currentMapping)) {
			throw(type="Wheels.Injector", message="to() called without a preceding map() call.");
		}
		variables.mappings[variables.currentMapping] = arguments.componentPath;
		variables.currentMapping = "";
		return this;
	}

	/**
	 * Mark the current or last mapping as a singleton.
	 * When getInstance() is called for a singleton, the instance is cached.
	 */
	public Injector function asSingleton() {
		// asSingleton can be called after to() — find the last mapping
		local.lastKey = "";
		for (local.key in variables.mappings) {
			local.lastKey = local.key;
		}
		if (len(local.lastKey)) {
			variables.singletonFlags[local.lastKey] = true;
		}
		return this;
	}

	/**
	 * Resolve and return a component instance.
	 *
	 * Resolution order:
	 * 1. Check alias mappings
	 * 2. Treat name as a full dotted component path
	 *
	 * After creation: call init(), then onDIcomplete().
	 *
	 * @name Alias name or dotted component path
	 * @initArguments Struct of arguments to pass to the init() method
	 */
	public any function getInstance(required string name, struct initArguments = {}) {
		// Resolve the component path
		local.componentPath = resolveMapping(arguments.name);

		// Check singleton cache
		if (structKeyExists(variables.singletonFlags, arguments.name) && structKeyExists(variables.singletons, local.componentPath)) {
			return variables.singletons[local.componentPath];
		}

		// Create the component instance
		local.instance = createObject("component", local.componentPath);

		// Call init() if it exists
		if (structKeyExists(local.instance, "init")) {
			if (!structIsEmpty(arguments.initArguments)) {
				local.instance.init(argumentCollection = arguments.initArguments);
			} else {
				local.instance.init();
			}
		}

		// Call onDIcomplete() lifecycle callback if present
		if (structKeyExists(local.instance, "onDIcomplete")) {
			local.instance.onDIcomplete();
		}

		// Cache singletons
		if (structKeyExists(variables.singletonFlags, arguments.name)) {
			variables.singletons[local.componentPath] = local.instance;
		}

		return local.instance;
	}

	/**
	 * Check if a mapping exists for the given name.
	 *
	 * @name Alias name to check
	 */
	public boolean function containsInstance(required string name) {
		return structKeyExists(variables.mappings, arguments.name);
	}

	// ---------------------------------------------------------------------------
	// Private helpers
	// ---------------------------------------------------------------------------

	/**
	 * Resolve an alias to its component path, or return the name as-is if no mapping exists.
	 */
	private string function resolveMapping(required string name) {
		if (structKeyExists(variables.mappings, arguments.name)) {
			return variables.mappings[arguments.name];
		}
		return arguments.name;
	}

}
