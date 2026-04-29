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
component implements="wheels.interfaces.di.InjectorInterface" {

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

		// Track the current mapping being built (for fluent API)
		variables.currentMapping = "";

		// Track the most recently completed mapping name. Used by asSingleton()
		// and asRequestScoped() so they flag the just-mapped key rather than
		// whichever key iterates last in variables.mappings — Lucee's HashMap-backed
		// struct walks keys in hash-bucket order once enough keys are registered to
		// span multiple buckets, so for-in iteration is not insertion-ordered at scale.
		variables.lastMappedName = "";

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
	 * Alias for map() that avoids collision with Lucee/Adobe built-in struct.map().
	 * Use this when calling from plugin ServiceProviders where the container is
	 * passed as a generic `any` argument.
	 */
	public Injector function mapInstance(required string name) {
		return map(argumentCollection = arguments);
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
		variables.lastMappedName = variables.currentMapping;
		variables.currentMapping = "";
		return this;
	}

	/**
	 * Mark the most recently completed mapping as a singleton.
	 * When getInstance() is called for a singleton, the instance is cached.
	 */
	public Injector function asSingleton() {
		if (len(variables.lastMappedName)) {
			variables.singletonFlags[variables.lastMappedName] = true;
		}
		return this;
	}

	/**
	 * Mark the most recently completed mapping as request-scoped.
	 * When getInstance() is called, the instance is cached per-request in request.$wheelsDICache.
	 */
	public Injector function asRequestScoped() {
		if (len(variables.lastMappedName)) {
			variables.requestScopedFlags[variables.lastMappedName] = true;
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

		// Circular dependency guard. The resolving struct is request-scoped —
		// it tracks "what this thread is currently resolving" — so concurrent
		// requests don't trip each other's guard. Application-scoping it (the
		// previous behavior) caused spurious self-loop errors when two
		// requests near-simultaneously hit getInstance for the same controller
		// on a cold framework, before Lucee had compiled the CFC. The chain
		// "X -> X" in the error message was thread A's in-flight entry being
		// observed by thread B before B even started. See issue #2331.
		var resolving = $getResolvingStack();
		if (structKeyExists(resolving, arguments.name)) {
			throw(
				type="Wheels.DI.CircularDependency",
				message="Circular dependency detected while resolving '#arguments.name#'. Resolution chain: #structKeyList(resolving)# -> #arguments.name#"
			);
		}

		resolving[arguments.name] = true;

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
			// Clean up resolving guard. Even on success this runs to keep the
			// per-request stack tidy for subsequent getInstance calls in the
			// same request.
			var resolvingForCleanup = $getResolvingStack();
			structDelete(resolvingForCleanup, arguments.name);
		}

		return local.instance;
	}

	/**
	 * Per-request resolving stack. Tracks which names are currently being
	 * resolved in THIS thread/request, so the circular-dependency guard
	 * doesn't see entries from concurrent requests.
	 *
	 * Lazy-creates request.$wheelsDIResolving on first access.
	 */
	private struct function $getResolvingStack() {
		if (!structKeyExists(request, "$wheelsDIResolving")) {
			request.$wheelsDIResolving = {};
		}
		return request.$wheelsDIResolving;
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
