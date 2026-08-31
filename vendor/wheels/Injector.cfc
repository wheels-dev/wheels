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

		// Storage for alias → factory closures (registered via toFactory()).
		// Kept separate from mappings so getMappings() stays string-typed.
		variables.factories = {};

		// Singleton cache: mapping name → instance. Keyed by the same value
		// as variables.singletonFlags so the flag and the cache can never
		// disagree (previously the cache was keyed by component path, so a
		// singleton resolved via a second alias was never cached and two
		// singleton aliases to one path silently shared an instance).
		variables.singletons = {};

		// Track which mappings are singletons
		variables.singletonFlags = {};

		// Memoized init() parameter names per component path. getMetaData +
		// the function scan in $resolveInitArguments run once per component,
		// not on every transient resolution. Only parameter NAMES are cached;
		// they are matched against the live mappings on each resolution.
		variables.initParamCache = {};

		// Unique per-container prefix for the singleton construction lock so
		// separate Injector instances (e.g. tests) never contend with each
		// other or with the application container.
		variables.lockNamePrefix = "wheelsDISingleton_" & CreateUUID() & "_";

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
		// S2: remapping an existing name starts a new lifecycle. Reset
		// singleton / request flags here (not in to()) so
		// map(b).asSingleton().to(...) can flag b after the reset.
		// First bind of a new name is not a rebind — leave request cache
		// and any unrelated flags alone.
		if (structKeyExists(variables.factories, arguments.name)) {
			// Re-mapping over a factory binding changes the construction
			// source, so any cached instance must go too.
			structDelete(variables.factories, arguments.name);
			structDelete(variables.singletons, arguments.name);
			structDelete(variables.singletonFlags, arguments.name);
			structDelete(variables.requestScopedFlags, arguments.name);
			structDelete(request, "$wheelsDICache");
		} else if (structKeyExists(variables.mappings, arguments.name)) {
			// Path re-map: keep the cached singleton for the dev-reload
			// same-path pattern (to() invalidates it on a path CHANGE).
			structDelete(variables.singletonFlags, arguments.name);
			structDelete(variables.requestScopedFlags, arguments.name);
			structDelete(request, "$wheelsDICache");
		}
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
		// A to() after toFactory() replaces the factory binding entirely.
		structDelete(variables.factories, variables.currentMapping);
		// Re-binding an alias to a DIFFERENT component path invalidates any
		// cached singleton instance for that alias — the cache is keyed by
		// alias, so without this the stale instance of the old component
		// would keep being served. Re-registering the same path (the
		// dev-mode reload pattern) keeps the cached instance.
		if (
			structKeyExists(variables.singletons, variables.currentMapping)
			&& structKeyExists(variables.mappings, variables.currentMapping)
			&& variables.mappings[variables.currentMapping] != arguments.componentPath
		) {
			structDelete(variables.singletons, variables.currentMapping);
		}
		variables.mappings[variables.currentMapping] = arguments.componentPath;
		variables.lastMappedName = variables.currentMapping;
		variables.currentMapping = "";
		return this;
	}

	/**
	 * Complete a mapping with a factory closure. The closure receives the
	 * container itself (so it can compose other services via
	 * ctx.getInstance(...)) and its return value is the resolved instance.
	 *
	 * Scope interplay mirrors to(): transient factories run per resolve,
	 * .asSingleton() runs the factory once under the singleton lock, and
	 * .asRequestScoped() once per request. No auto-wiring or onDIcomplete()
	 * runs on the result — the closure owns construction, and initArguments
	 * passed to getInstance() are ignored for factory bindings.
	 *
	 * @factory Closure that builds the instance.
	 */
	public Injector function toFactory(required any factory) {
		if (!len(variables.currentMapping)) {
			throw(type="Wheels.Injector", message="toFactory() called without a preceding map() call.");
		}
		if (!IsClosure(arguments.factory) && !IsCustomFunction(arguments.factory)) {
			throw(
				type = "Wheels.Injector",
				message = "toFactory() requires a closure or function reference."
			);
		}
		// A toFactory() after to() replaces the path binding entirely.
		structDelete(variables.mappings, variables.currentMapping);
		structDelete(variables.singletons, variables.currentMapping);
		variables.factories[variables.currentMapping] = arguments.factory;
		variables.lastMappedName = variables.currentMapping;
		variables.currentMapping = "";
		return this;
	}

	/**
	 * Check whether a mapping is a factory binding.
	 *
	 * @name Alias name to check
	 */
	public boolean function isFactory(required string name) {
		return structKeyExists(variables.factories, arguments.name);
	}

	/**
	 * Mark the in-progress mapping (map then asSingleton then to) or the
	 * most recently completed mapping as a singleton. Throws Wheels.Injector
	 * when neither currentMapping nor lastMappedName is set.
	 */
	public Injector function asSingleton() {
		variables.singletonFlags[$scopeTarget("asSingleton")] = true;
		return this;
	}

	/**
	 * Mark the in-progress mapping (map then asRequestScoped then to) or
	 * the most recently completed mapping as request-scoped. Throws
	 * Wheels.Injector when neither currentMapping nor lastMappedName is set.
	 */
	public Injector function asRequestScoped() {
		variables.requestScopedFlags[$scopeTarget("asRequestScoped")] = true;
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
		// Factory bindings bypass path resolution entirely.
		if (structKeyExists(variables.factories, arguments.name)) {
			// Singleton: the cache is keyed by the mapping name. A
			// double-checked named lock ensures concurrent first resolutions
			// run the factory exactly once.
			if (structKeyExists(variables.singletonFlags, arguments.name)) {
				if (!structKeyExists(variables.singletons, arguments.name)) {
					lock name="#variables.lockNamePrefix##lCase(arguments.name)#" type="exclusive" timeout="30" {
						if (!structKeyExists(variables.singletons, arguments.name)) {
							variables.singletons[arguments.name] = $invokeFactory(arguments.name);
						}
					}
				}
				return variables.singletons[arguments.name];
			}

			// Request-scoped: cached per request in request.$wheelsDICache.
			if (structKeyExists(variables.requestScopedFlags, arguments.name)) {
				local.requestCache = $getRequestCache();
				if (!structKeyExists(local.requestCache, arguments.name)) {
					local.requestCache[arguments.name] = $invokeFactory(arguments.name);
				}
				return local.requestCache[arguments.name];
			}

			// Transient: the factory runs on every resolve.
			return $invokeFactory(arguments.name);
		}

		// Resolve the component path
		local.componentPath = resolveMapping(arguments.name);

		// Singleton: the cache is keyed by the mapping name — the same key
		// the asSingleton() flag uses — so the flag and the cache can never
		// disagree. A double-checked named lock ensures concurrent first
		// resolutions construct exactly once instead of racing and orphaning
		// one of the two constructed instances.
		if (structKeyExists(variables.singletonFlags, arguments.name)) {
			if (!structKeyExists(variables.singletons, arguments.name)) {
				lock name="#variables.lockNamePrefix##lCase(arguments.name)#" type="exclusive" timeout="30" {
					if (!structKeyExists(variables.singletons, arguments.name)) {
						variables.singletons[arguments.name] = $constructInstance(
							arguments.name,
							local.componentPath,
							arguments.initArguments
						);
					}
				}
			}
			return variables.singletons[arguments.name];
		}

		// Request-scoped: cached per request in request.$wheelsDICache. A
		// request runs on a single thread, so no lock is needed here.
		if (structKeyExists(variables.requestScopedFlags, arguments.name)) {
			local.requestCache = $getRequestCache();
			if (!structKeyExists(local.requestCache, arguments.name)) {
				local.requestCache[arguments.name] = $constructInstance(
					arguments.name,
					local.componentPath,
					arguments.initArguments
				);
			}
			return local.requestCache[arguments.name];
		}

		// Transient: a fresh instance per call.
		return $constructInstance(arguments.name, local.componentPath, arguments.initArguments);
	}

	/**
	 * Creates, initializes (with auto-wiring when no explicit initArguments
	 * are passed), and finalizes a component instance. Shared by the
	 * singleton, request-scoped, and transient paths of getInstance().
	 */
	private any function $constructInstance(
		required string name,
		required string componentPath,
		required struct initArguments
	) {
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
			local.instance = createObject("component", arguments.componentPath);

			// Call init() if it exists
			if (structKeyExists(local.instance, "init")) {
				if (!structIsEmpty(arguments.initArguments)) {
					local.instance.init(argumentCollection = arguments.initArguments);
				} else {
					// Auto-wire: resolve init() arguments from container mappings
					local.autoArgs = $resolveInitArguments(local.instance, arguments.componentPath);
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
	 * Invoke a registered factory closure, passing the container so the
	 * factory can compose other services. The closure is hoisted to a local
	 * variable first — a bracket call `variables.factories[name](this)`
	 * crashes the Adobe CF parser (Cross-Engine Invariant 4).
	 */
	private any function $invokeFactory(required string name) {
		var fn = variables.factories[arguments.name];
		return fn(this);
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
		return structKeyExists(variables.mappings, arguments.name) || structKeyExists(variables.factories, arguments.name);
	}

	/**
	 * Return all registered mappings (name → componentPath).
	 */
	public struct function getMappings() {
		// S7: callers get a Duplicate copy. Mutating the return value
		// must not change later getMappings() or the live mappings table.
		return Duplicate(variables.mappings);
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

	/**
	 * Snapshot of mapping tables so a failed ServiceProvider boot() can
	 * unwind bindings written during register().
	 */
	public struct function $snapshotBindings() {
		return {
			mappings = Duplicate(variables.mappings),
			factories = Duplicate(variables.factories),
			singletonFlags = Duplicate(variables.singletonFlags),
			requestScopedFlags = Duplicate(variables.requestScopedFlags)
		};
	}

	/**
	 * Restore mapping tables from $snapshotBindings() and drop singleton
	 * cache entries that are no longer mapped.
	 */
	public void function $restoreBindings(required struct snapshot) {
		variables.mappings = StructKeyExists(arguments.snapshot, "mappings")
			? Duplicate(arguments.snapshot.mappings)
			: {};
		variables.factories = StructKeyExists(arguments.snapshot, "factories")
			? Duplicate(arguments.snapshot.factories)
			: {};
		variables.singletonFlags = StructKeyExists(arguments.snapshot, "singletonFlags")
			? Duplicate(arguments.snapshot.singletonFlags)
			: {};
		variables.requestScopedFlags = StructKeyExists(arguments.snapshot, "requestScopedFlags")
			? Duplicate(arguments.snapshot.requestScopedFlags)
			: {};
		for (local.name in StructKeyArray(variables.singletons)) {
			if (!StructKeyExists(variables.mappings, local.name) && !StructKeyExists(variables.factories, local.name)) {
				StructDelete(variables.singletons, local.name);
			}
		}
	}

	// ---------------------------------------------------------------------------
	// Private helpers
	// ---------------------------------------------------------------------------

	/**
	 * Whether this name carries an explicit mapping or lifecycle flag in the
	 * container — the #3213 model fast path in $createObjectFromRoot must fall
	 * back to the full DI construction path when it does.
	 */
	public boolean function hasExplicitMapping(required string name) {
		return (
			StructKeyExists(variables.mappings, arguments.name)
			|| StructKeyExists(variables.factories, arguments.name)
			|| StructKeyExists(variables.singletonFlags, arguments.name)
			|| StructKeyExists(variables.requestScopedFlags, arguments.name)
		);
	}

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
	 * Name that asSingleton() / asRequestScoped() should flag.
	 * Prefers the in-progress map() name so map(b).asSingleton().to(...)
	 * binds b, not the previous lastMappedName. Empty both sides is
	 * Wheels.Injector — same type as to() without map().
	 */
	private string function $scopeTarget(required string methodName) {
		if (len(variables.currentMapping)) {
			return variables.currentMapping;
		}
		if (len(variables.lastMappedName)) {
			return variables.lastMappedName;
		}
		throw(
			type = "Wheels.Injector",
			message = "#arguments.methodName#() called without a preceding map() or to() call."
		);
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
	 * The init() parameter names are memoized per component path so
	 * getMetaData and the function scan run once per component rather than
	 * on every transient resolution. Only the parameter NAMES are cached —
	 * they are matched against the live mappings on each call, so mappings
	 * registered after a component's first resolution are still honored.
	 *
	 * The scan walks the extends chain so an inherited init() participates
	 * in constructor auto-wiring just like one declared on the component
	 * itself.
	 *
	 * @instance The component instance to inspect
	 * @componentPath The resolved dotted component path (memoization key)
	 */
	private struct function $resolveInitArguments(required any instance, required string componentPath) {
		local.args = {};

		if (!structKeyExists(variables.initParamCache, arguments.componentPath)) {
			variables.initParamCache[arguments.componentPath] = $scanInitParameterNames(getMetaData(arguments.instance));
		}

		// Match parameter names against container mappings
		for (local.paramName in variables.initParamCache[arguments.componentPath]) {
			if (containsInstance(local.paramName)) {
				local.args[local.paramName] = getInstance(local.paramName);
			}
		}

		return local.args;
	}

	/**
	 * Walks component metadata — including the extends chain — for the
	 * first init() declaration and returns its parameter names as an array.
	 * Returns an empty array when no init() (or no parameters) is found.
	 */
	private array function $scanInitParameterNames(required struct meta) {
		local.names = [];
		local.current = arguments.meta;

		while (isStruct(local.current)) {
			if (structKeyExists(local.current, "functions")) {
				for (local.fn in local.current.functions) {
					if (local.fn.name == "init") {
						if (structKeyExists(local.fn, "parameters")) {
							for (local.param in local.fn.parameters) {
								arrayAppend(local.names, local.param.name);
							}
						}
						return local.names;
					}
				}
			}
			if (!structKeyExists(local.current, "extends") || !isStruct(local.current.extends)) {
				break;
			}
			local.current = local.current.extends;
		}

		return local.names;
	}

}
