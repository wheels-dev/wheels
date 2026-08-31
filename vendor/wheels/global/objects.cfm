<cfscript>
/**
 * wheels.Global include: objects
 * Model/controller/service lookup, mixin integration plans, object creation.
 *
 * Included from `vendor/wheels/Global.cfc` at component-body scope so
 * these functions compile into the Global component. Children inherit
 * them; there is no per-instance mixin copy. Keep every helper that
 * must mix onto models/controllers `public` and `$`-prefixed
 * (cross-engine invariant 7).
 */


	// ======================================================================
	// FACTORY FUNCTIONS
	// ======================================================================

	/**
	 * Internal function.
	 */
	public any function $cachedModelClassExists(required string name) {
		local.rv = false;
		if (StructKeyExists(application.wheels.models, arguments.name)) {
			local.rv = application.wheels.models[arguments.name];
		}
		return local.rv;
	}


	/**
	 * Internal function.
	 *
	 * Lock-free warm fast-path lookup used by `model()` to bypass
	 * `$doubleCheckedLock` and its `$invoke` reflective dispatch on cache
	 * hits. The full `StructKeyExists` chain guards early-bootstrap and
	 * post-`?reload=true` windows where `application.wheels.models` may
	 * not yet exist. Returns the cached class on hit, `false` on miss
	 * (callers fall through to the slow path).
	 */
	public any function $cachedModelLookup(required string name) {
		if (
			StructKeyExists(application, "wheels")
			&& StructKeyExists(application.wheels, "models")
			&& StructKeyExists(application.wheels.models, arguments.name)
		) {
			return application.wheels.models[arguments.name];
		}
		return false;
	}


	/**
	 * Internal function.
	 */
	public any function $cachedControllerClassExists(required string name) {
		local.rv = false;
		if (StructKeyExists(application.wheels.controllers, arguments.name)) {
			local.rv = application.wheels.controllers[arguments.name];
		}
		return local.rv;
	}


	/**
	 * Internal function.
	 *
	 * Lock-free warm fast-path lookup used by `controller()`. Same
	 * shape and bootstrap guards as `$cachedModelLookup`.
	 */
	public any function $cachedControllerLookup(required string name) {
		if (
			StructKeyExists(application, "wheels")
			&& StructKeyExists(application.wheels, "controllers")
			&& StructKeyExists(application.wheels.controllers, arguments.name)
		) {
			return application.wheels.controllers[arguments.name];
		}
		return false;
	}


	/**
	 * Internal function.
	 */
	public any function $createObjectFromRoot(required string path, required string fileName, required string method) {
		local.method = arguments.method;
		local.component = ListChangeDelims(arguments.path, ".", "/") & "." & ListChangeDelims(arguments.fileName, ".", "/");
		local.argumentCollection = arguments;
		if (local.method EQ 'init') {
			local.rv = application.wheelsdi.getInstance(name = "#local.component#", initArguments = local.argumentCollection);
		} else {
			local.instance = application.wheelsdi.getInstance(name = "#local.component#");
			local.rv = Invoke(local.instance, local.method, local.argumentCollection);
		}
		return local.rv;
	}


	/**
	 * Internal. Returns a cached "integration plan" for a folder of mixin
	 * components (e.g. `wheels.model`, `wheels.controller`, `wheels.mapper`): an
	 * ordered array of `{instance, methods, fullName}` where `instance` is a
	 * single shared, stateless method-holder component and `methods` is its
	 * `getMetaData().functions` array.
	 *
	 * The directory scan, the per-file `createObject`, and the `getMetaData`
	 * calls are the expensive — and completely invariant — part of
	 * `$integrateComponents`: they produce the same result for every object of a
	 * given type. Before this cache they were re-paid on EVERY model, controller,
	 * and mapper materialization (every `new()` and every finder row goes through
	 * `$createInstance` -> `init()` -> `$integrateComponents`), which dominated
	 * test-suite and request time (issue #3213). Now they run once per path and
	 * the cheap per-instance work (copying function references into the target's
	 * `variables`/`this`) is all that remains on the hot path.
	 *
	 * The plan is cached in `application.wheels.integrationPlans`, so a reload —
	 * which rebuilds `application.wheels` — re-scans, the same lifetime contract
	 * as the schema column cache. The cached method-holder components carry no
	 * instance state (they are never `init()`'d) and CFML methods bind to the
	 * object they are invoked on, so sharing their function references across many
	 * target instances and across concurrent requests is safe.
	 */
	public array function $componentIntegrationPlan(required string path) {
		// During early bootstrap (before application.wheels exists) fall back to
		// an uncached build so behavior is identical to the pre-cache code path.
		if (!StructKeyExists(application, "wheels")) {
			return $buildComponentIntegrationPlan(arguments.path);
		}
		if (!StructKeyExists(application.wheels, "integrationPlans")) {
			lock name="wheels.integrationPlans.#application.applicationName#" type="exclusive" timeout="10" {
				if (!StructKeyExists(application.wheels, "integrationPlans")) {
					application.wheels.integrationPlans = {};
				}
			}
		}
		if (!StructKeyExists(application.wheels.integrationPlans, arguments.path)) {
			local.plan = $buildComponentIntegrationPlan(arguments.path);
			lock name="wheels.integrationPlans.#application.applicationName#" type="exclusive" timeout="10" {
				application.wheels.integrationPlans[arguments.path] = local.plan;
			}
		}
		local.plan = application.wheels.integrationPlans[arguments.path];

		// Once per request (per path), validate the cached plan. On Lucee 7 a
		// cached function reference can come back as Java null (#3457) — e.g.
		// when the plan was first built while the engine was still compiling
		// the mixin component. A null ref is then written into every
		// materialized instance's variables/this scope, and Lucee throws a
		// bare NullPointerException when it later enumerates the component.
		// Rebuild the plan in place when that happens.
		//
		// The flag lives in a request-scope struct rather than a dotted
		// request-scope key: RustCFML resolves dots in request-scope keys as
		// paths (nested writes, missed deletes), so a flat dotted key never
		// round-trips there.
		if (!StructKeyExists(request, "wheelsIntegrationPlanChecks")) {
			request.wheelsIntegrationPlanChecks = {};
		}
		local.planKey = LCase(arguments.path);
		if (!StructKeyExists(request.wheelsIntegrationPlanChecks, local.planKey)) {
			request.wheelsIntegrationPlanChecks[local.planKey] = true;
			if ($integrationPlanHasNullRefs(local.plan)) {
				local.plan = $buildComponentIntegrationPlan(arguments.path);
				lock name="wheels.integrationPlans.#application.applicationName#" type="exclusive" timeout="10" {
					application.wheels.integrationPlans[arguments.path] = local.plan;
				}
				$warnNullIntegrationPlanRefs(arguments.path);
			}
		}
		return local.plan;
	}

	/**
	 * Internal. Whether any entry in an integration plan carries a null (or
	 * missing) function reference — a plan in that state would write null
	 * members into every materialized instance (#3457).
	 */
	public boolean function $integrationPlanHasNullRefs(required array plan) {
		for (local.comp in arguments.plan) {
			for (local.pm in local.comp.publicMethods) {
				if (!StructKeyExists(local.pm, "ref") || IsNull(local.pm.ref)) {
					return true;
				}
			}
		}
		return false;
	}

	/**
	 * Internal. One-time warning when a cached integration plan had to be
	 * rebuilt because it contained null function references (#3457).
	 */
	public void function $warnNullIntegrationPlanRefs(required string path) {
		try {
			if (StructKeyExists(getFunctionList(), "writeLog")) {
				writeLog(
					file = "wheels",
					type = "warning",
					text = "Wheels rebuilt a cached component integration plan for '#arguments.path#' because it contained null function references (see issue ##3457). If this repeats on every request, the engine's class cache may be stale — restart the server."
				);
			}
		} catch (any e) {
			// Logging must never fail the request.
		}
	}


	/**
	 * Internal. Builds (without caching) the integration plan for a path — the
	 * directory scan + per-file createObject + getMetaData that
	 * $componentIntegrationPlan memoizes. The DirectoryList call mirrors the
	 * original $integrateComponents exactly so file (and therefore override)
	 * order is unchanged.
	 */
	public array function $buildComponentIntegrationPlan(required string path) {
		local.folderPath = ExpandPath("/#Replace(arguments.path, ".", "/", "all")#");
		local.fileList = DirectoryList(local.folderPath, false, "name", "*.cfc");
		local.rv = [];
		for (local.fileName in local.fileList) {
			local.componentName = Replace(local.fileName, ".cfc", "", "all");
			local.instance = CreateObject("component", "#arguments.path#.#local.componentName#");
			local.meta = GetMetaData(local.instance);
			local.fns = StructKeyExists(local.meta, "functions") ? local.meta.functions : [];
			// Pre-resolve the PUBLIC method references once. On the hot path
			// (every materialized object) this removes both the per-method
			// `.access` filtering and the `instance[name]` scope lookup; only the
			// reference assignment into the target remains (issue #3213). Function
			// references are late-bound to the object they are invoked on, so the
			// shared, cached reference works correctly on every target instance.
			local.publicMethods = [];
			local.fEnd = ArrayLen(local.fns);
			for (local.f = 1; local.f <= local.fEnd; local.f++) {
				if (local.fns[local.f].access == "public") {
					local.ref = local.instance[local.fns[local.f].name];
					// Guard against engines returning a null function reference
					// while the mixin component is still compiling (#3457) —
					// caching a null ref would write a null member into every
					// materialized instance.
					if (!IsNull(local.ref)) {
						ArrayAppend(local.publicMethods, {
							name = local.fns[local.f].name,
							ref = local.ref
						});
					} else {
						$warnNullIntegrationPlanRefs("#arguments.path#.#local.componentName# (build)");
					}
				}
			}
			ArrayAppend(local.rv, {
				instance = local.instance,
				methods = local.fns,
				publicMethods = local.publicMethods,
				fullName = StructKeyExists(local.meta, "fullName") ? local.meta.fullName : "#arguments.path#.#local.componentName#"
			});
		}
		return local.rv;
	}


	/**
	 * Internal. Returns a struct whose KEYS are the function names that a
	 * registered plugin/package mixin will override for the given component type
	 * (plus the always-checked "global" type). Empty — the common case, no mixins
	 * registered — when there are none. Computed from the app-scoped, reload-stable
	 * application.wheels.mixins so the per-method $willBeOverriddenByMixin function
	 * call can be replaced by an O(1) struct-membership test on the hot path (#3213).
	 */
	public struct function $mixinOverrideSet(required string primaryType) {
		local.rv = {};
		if (
			!StructKeyExists(application, "wheels")
			|| !StructKeyExists(application.wheels, "mixins")
			|| StructIsEmpty(application.wheels.mixins)
		) {
			return local.rv;
		}
		local.types = [arguments.primaryType, "global"];
		for (local.t in local.types) {
			if (StructKeyExists(application.wheels.mixins, local.t) && IsStruct(application.wheels.mixins[local.t])) {
				StructAppend(local.rv, application.wheels.mixins[local.t], false);
			}
		}
		return local.rv;
	}


	/**
	 * Internal function.
	 */
	public void function $debugPoint(required string name) {
		if (!StructKeyExists(request.wheels, "execution")) {
			request.wheels.execution = {};
		}
		local.nameArray = ListToArray(arguments.name);
		local.iEnd = ArrayLen(local.nameArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.item = local.nameArray[local.i];
			if (StructKeyExists(request.wheels.execution, local.item)) {
				request.wheels.execution[local.item] = GetTickCount() - request.wheels.execution[local.item];
			} else {
				request.wheels.execution[local.item] = GetTickCount();
			}
		}
	}


	/**
	 * Internal function.
	 */
	public any function $fileExistsNoCase(required string absolutePath) {
		local.appKey = $appKey();
		// return false by default when the file does not exist in the directory
		local.rv = false;
		// break up the full path string in the path name only and the file name only
		local.path = GetDirectoryFromPath(arguments.absolutePath);
		local.file = Replace(arguments.absolutePath, local.path, "");
		// Skip the directoryFiles memo when cacheFileChecking is off so a
		// new file on disk is visible on the next check.
		local.cacheChecks = StructKeyExists(application[local.appKey], "cacheFileChecking")
		&& application[local.appKey].cacheFileChecking;
		if (local.cacheChecks) {
			local.pathHash = Hash(local.path);
			if (!StructKeyExists(application[local.appKey].directoryFiles, local.pathHash)) {
				local.dirInfo = $directory(directory = local.path);
				application[local.appKey].directoryFiles[local.pathHash] = ValueList(local.dirInfo.name);
			}
			local.fileList = application[local.appKey].directoryFiles[local.pathHash];
		} else {
			local.dirInfo = $directory(directory = local.path);
			local.fileList = ValueList(local.dirInfo.name);
		}
		// loop through the file list and return the file name if exists regardless of case (the == operator is case insensitive)
		local.fileArray = ListToArray(local.fileList);
		local.iEnd = ArrayLen(local.fileArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.foundFile = local.fileArray[local.i];
			if (local.foundFile == local.file) {
				local.rv = local.foundFile;
				break;
			}
		}
		return local.rv;
	}


	/**
	 * Internal function.
	 */
	public string function $objectFileName(required string name, required string objectPath, required string type) {
		// by default we return Model or Controller so that the base component gets loaded
		local.rv = capitalize(arguments.type);

		// we are going to memoize the full controller / model path in the
		// existing / non-existing structs so we can have controllers / models
		// in multiple places (structs give O(1) lookups and atomic writes where
		// the comma lists used previously were O(n) scans per materialized object
		// and lost entries to unlocked concurrent ListAppend calls)
		//
		// The name coming into $objectFileName could have dot notation due to
		// nested controllers so we need to change delims here on the name
		local.fullObjectPath = arguments.objectPath & "/" & ListChangeDelims(arguments.name, '/', '.');

		if (
			!StructKeyExists(application.wheels.existingObjectFiles, local.fullObjectPath)
			&& !StructKeyExists(application.wheels.nonExistingObjectFiles, local.fullObjectPath)
		) {
			// we have not yet checked if this file exists or not so let's do that
			// here (the function below will return the file name with the correct
			// case if it exists, false if not)
			local.file = $fileExistsNoCase(ExpandPath(local.fullObjectPath) & ".cfc");

			if (IsBoolean(local.file) && !local.file) {
				// no file exists, let's store that if caching is on so we don't have to check it again
				if (application.wheels.cacheFileChecking) {
					application.wheels.nonExistingObjectFiles[local.fullObjectPath] = false;
				}
			} else {
				// the file exists, let's store the proper case of the file if caching is turned on
				local.file = SpanExcluding(local.file, ".");
				if (application.wheels.cacheFileChecking) {
					application.wheels.existingObjectFiles[local.fullObjectPath] = local.file;
				}
			}
		}

		// if the file exists we return the file name in its proper case
		if (StructKeyExists(application.wheels.existingObjectFiles, local.fullObjectPath)) {
			local.file = application.wheels.existingObjectFiles[local.fullObjectPath];
		}

		// we've found a file so we'll need to send back the corrected name
		// argument as it could have dot notation in it from the mapper
		if (StructKeyExists(local, "file") and !IsBoolean(local.file)) {
			local.rv = ListSetAt(arguments.name, ListLen(arguments.name, "."), local.file, ".");
		}

		return local.rv;
	}


	/**
	 * Internal function.
	 */
	public any function $createControllerClass(
		required string name,
		string controllerPaths = $get("controllerPath"),
		string type = "controller"
	) {
		// let's allow for multiple controller paths so that plugins can contain controllers
		// the last path is the one we will instantiate the base controller on if the controller is not found on any of the paths
		local.controllerPathsArray = ListToArray(arguments.controllerPaths);
		local.iEnd = ArrayLen(local.controllerPathsArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.controllerPath = local.controllerPathsArray[local.i];
			local.fileName = $objectFileName(name = arguments.name, objectPath = local.controllerPath, type = arguments.type);
			if (local.fileName != "Controller" || local.i == ArrayLen(local.controllerPathsArray)) {
				application.wheels.controllers[arguments.name] = $createObjectFromRoot(
					path = local.controllerPath,
					fileName = local.fileName,
					method = "$initControllerClass",
					name = arguments.name
				);

				local.rv = application.wheels.controllers[arguments.name];
				break;
			}
		}
		return local.rv;
	}


	/**
	 * Internal function.
	 */
	public any function $createModelClass(
		required string name,
		string modelPaths = application.wheels.modelPath,
		string type = "model"
	) {
		// let's allow for multiple model paths so that plugins can contain models
		// the last path is the one we will instantiate the base model on if the model is not found on any of the paths
		local.modelPathsArray = ListToArray(arguments.modelPaths);
		local.iEnd = ArrayLen(local.modelPathsArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.modelPath = local.modelPathsArray[local.i];
			local.fileName = $objectFileName(name = arguments.name, objectPath = local.modelPath, type = arguments.type);
			if (local.fileName != arguments.type || local.i == ArrayLen(local.modelPathsArray)) {
				application.wheels.models[arguments.name] = $createObjectFromRoot(
					path = local.modelPath,
					fileName = local.fileName,
					method = "$initModelClass",
					name = arguments.name
				);
				local.rv = application.wheels.models[arguments.name];
				break;
			}
		}
		return local.rv;
	}


	/**
	 * Internal function.
	 */
	public void function $clearModelInitializationCache() {
		StructClear(application.wheels.models);
	}


	/**
	 * Internal function.
	 */
	public void function $clearControllerInitializationCache() {
		StructClear(application.wheels.controllers);
	}


	/**
	 * Creates and returns a controller object with your own custom name and params.
	 * Used primarily for testing purposes.
	 *
	 * [section: Global Helpers]
	 * [category: Miscellaneous Functions]
	 *
	 * @name Name of the controller to create.
	 * @params The params struct (combination of form and URL variables).
	 */
	public any function controller(required string name, struct params = {}) {
		// Lock-free warm fast path: skip $doubleCheckedLock + $invoke
		// reflective dispatch on cache hits (issue #2897, Stage 1). Returns
		// the cached *class*; the params branch below still creates an
		// instance when params is non-empty.
		local.rv = $cachedControllerLookup(name = arguments.name);
		if (IsBoolean(local.rv) && !local.rv) {
			local.args = {};
			local.args.name = arguments.name;
			local.rv = $doubleCheckedLock(
				condition = "$cachedControllerClassExists",
				conditionArgs = local.args,
				execute = "$createControllerClass",
				executeArgs = local.args,
				name = "controllerLock#application.applicationName#"
			);
		}
		if (!StructIsEmpty(arguments.params)) {
			local.rv = local.rv.$createControllerObject(arguments.params);
		}
		return local.rv;
	}


	/**
	 * Returns a reference to the requested model so that class level methods can be called on it.
	 *
	 * [section: Global Helpers]
	 * [category: Miscellaneous Functions]
	 *
	 * @name Name of the model to get a reference to.
	 */
	public any function model(required string name) {
		// Lock-free warm fast path: skip $doubleCheckedLock + $invoke
		// reflective dispatch on cache hits (issue #2897, Stage 1).
		local.rv = $cachedModelLookup(name = arguments.name);
		if (IsBoolean(local.rv) && !local.rv) {
			return $doubleCheckedLock(
				condition = "$cachedModelClassExists",
				conditionArgs = arguments,
				execute = "$createModelClass",
				executeArgs = arguments,
				name = "modelLock#application.applicationName#"
			);
		}
		return local.rv;
	}


	/**
	 * Resolve a DI-registered service by name.
	 *
	 * [section: Global Helpers]
	 * [category: Miscellaneous Functions]
	 *
	 * @name The registered service name to resolve.
	 */
	public any function service(required string name) {
		if (!IsDefined("application.wheelsdi")) {
			Throw(
				type = "Wheels.DI.NotInitialized",
				message = "The DI container has not been initialized. Ensure your application has started properly."
			);
		}
		if (!application.wheelsdi.containsInstance(arguments.name)) {
			Throw(
				type = "Wheels.DI.ServiceNotFound",
				message = "No service registered with the name '#arguments.name#'. Check your config/services.cfm registrations."
			);
		}
		return application.wheelsdi.getInstance(arguments.name);
	}


	/**
	 * Return a reference to the DI container for direct configuration.
	 *
	 * [section: Global Helpers]
	 * [category: Miscellaneous Functions]
	 */
	public any function injector() {
		if (!IsDefined("application.wheelsdi")) {
			Throw(
				type = "Wheels.DI.NotInitialized",
				message = "The DI container has not been initialized. Ensure your application has started properly."
			);
		}
		return application.wheelsdi;
	}
</cfscript>
