/**
 * Dependency injection container for Wheels.
 *
 * Provides DI features for Wheels applications:
 * - map(name).to(componentPath) fluent bindings
 * - getInstance(name, initArguments) resolution
 * - onDIcomplete() lifecycle callback
 * - Singleton and request-scoped lifecycles
 * - Auto-wiring of init() arguments
 * - bind() for interface-style aliasing
 *
 * Self-registers at application.wheelsdi for framework-wide access.
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

		// Track which mappings are request-scoped
		variables.requestScopedFlags = {};

		// Circular dependency guard during resolution
		variables.resolving = {};

		// Track the current mapping being built (for fluent API)
		variables.currentMapping = "";

		// Register self at application.wheelsdi for framework-wide access
		application.wheelsdi = this;

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
		local.lastKey = $findLastMappingKey();
		if (len(local.lastKey)) {
			variables.singletonFlags[local.lastKey] = true;
		}
		return this;
	}

	/**
	 * Mark the current or last mapping as request-scoped.
	 * When getInstance() is called, the instance is cached per-request in request.$wheelsDICache.
	 */
	public Injector function asRequestScoped() {
		local.lastKey = $findLastMappingKey();
		if (len(local.lastKey)) {
			variables.requestScopedFlags[local.lastKey] = true;
		}
		return this;
	}

	/**
	 * Alias for map() with interface-binding semantics.
	 * Use bind("InterfaceName").to("concrete.Path") for clarity when mapping abstractions.
	 *
	 * @name The interface or abstract name to bind
	 */
	public Injector function bind(required string name) {
		return map(arguments.name);
	}

	/**
	 * Resolve and return a component instance.
	 *
	 * Resolution order:
	 * 1. Check alias mappings
	 * 2. Treat name as a full dotted component path
	 *
	 * After creation: call init() (with auto-wiring if no initArguments), then onDIcomplete().
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

		// Check request-scope cache
		if (structKeyExists(variables.requestScopedFlags, arguments.name)) {
			local.requestCache = $getRequestCache();
			if (structKeyExists(local.requestCache, arguments.name)) {
				return local.requestCache[arguments.name];
			}
		}

		// Circular dependency guard
		if (structKeyExists(variables.resolving, arguments.name)) {
			throw(
				type="Wheels.DI.CircularDependency",
				message="Circular dependency detected while resolving '#arguments.name#'. Resolution chain: #structKeyList(variables.resolving)# -> #arguments.name#"
			);
		}

		variables.resolving[arguments.name] = true;

		try {
			// Create the component instance
			local.instance = createObject("component", local.componentPath);

			// Call init() if it exists
			if (structKeyExists(local.instance, "init")) {
				if (!structIsEmpty(arguments.initArguments)) {
					local.instance.init(argumentCollection = arguments.initArguments);
				} else {
					// Auto-wire: resolve init() arguments from container mappings
					local.autoArgs = $resolveInitArguments(local.instance);
					if (!structIsEmpty(local.autoArgs)) {
						local.instance.init(argumentCollection = local.autoArgs);
					} else {
						local.instance.init();
					}
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

			// Cache in request scope
			if (structKeyExists(variables.requestScopedFlags, arguments.name)) {
				local.requestCache = $getRequestCache();
				local.requestCache[arguments.name] = local.instance;
			}
		} finally {
			// Clean up resolving guard
			structDelete(variables.resolving, arguments.name);
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

	/**
	 * Return all registered mappings (name → componentPath).
	 */
	public struct function getMappings() {
		return variables.mappings;
	}

	/**
	 * Check if a mapping is request-scoped.
	 *
	 * @name Alias name to check
	 */
	public boolean function isRequestScoped(required string name) {
		return structKeyExists(variables.requestScopedFlags, arguments.name);
	}

	/**
	 * Check if a mapping is a singleton.
	 *
	 * @name Alias name to check
	 */
	public boolean function isSingleton(required string name) {
		return structKeyExists(variables.singletonFlags, arguments.name);
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

	/**
	 * Find the last key added to the mappings struct (used by asSingleton/asRequestScoped).
	 */
	private string function $findLastMappingKey() {
		local.lastKey = "";
		for (local.key in variables.mappings) {
			local.lastKey = local.key;
		}
		return local.lastKey;
	}

	/**
	 * Return the per-request DI cache struct, creating it if needed.
	 */
	private struct function $getRequestCache() {
		if (!structKeyExists(request, "$wheelsDICache")) {
			request["$wheelsDICache"] = {};
		}
		return request["$wheelsDICache"];
	}

	/**
	 * Inspect the init() method of an instance and auto-resolve parameters
	 * whose names match registered container mappings.
	 *
	 * @instance The component instance to inspect
	 */
	private struct function $resolveInitArguments(required any instance) {
		local.args = {};
		local.meta = getMetaData(arguments.instance);

		// Find the init() function in the metadata
		if (!structKeyExists(local.meta, "functions")) {
			return local.args;
		}

		local.initMeta = {};
		for (local.fn in local.meta.functions) {
			if (local.fn.name == "init") {
				local.initMeta = local.fn;
				break;
			}
		}

		// No init() or no parameters
		if (structIsEmpty(local.initMeta) || !structKeyExists(local.initMeta, "parameters")) {
			return local.args;
		}

		// Match parameter names against container mappings
		for (local.param in local.initMeta.parameters) {
			if (containsInstance(local.param.name)) {
				local.args[local.param.name] = getInstance(local.param.name);
			}
		}

		return local.args;
	}

}
