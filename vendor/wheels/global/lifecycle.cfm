<cfscript>
/**
 * wheels.Global include: lifecycle
 * Error callbacks, interface contracts, global-include reload, protected methods.
 *
 * Included from `vendor/wheels/Global.cfc` at component-body scope so
 * these functions compile into the Global component. Children inherit
 * them; there is no per-instance mixin copy. Keep every helper that
 * must mix onto models/controllers `public` and `$`-prefixed
 * (cross-engine invariant 7).
 */


	/**
	 * Restore the application scope modified by the test runner
	 */
	public void function $restoreTestRunnerApplicationScope() {
		if (StructKeyExists(request, "wheels") && StructKeyExists(request.wheels, "testRunnerApplicationScope")) {
			application.wheels = request.wheels.testRunnerApplicationScope;
		}
	}


	/**
	 * Registers a callback function to be invoked when an unhandled error occurs.
	 * Callbacks receive a single argument: the exception struct.
	 * Multiple callbacks are invoked in registration order. A failing callback
	 * is logged and skipped — it will not prevent other callbacks from running.
	 * Should be called during app initialization, not per-request.
	 *
	 * [section: Configuration]
	 * [category: Error Handling]
	 *
	 * @callback A function that accepts an exception struct argument. Must complete quickly — long-running callbacks delay error responses.
	 */
	public void function registerOnError(required function callback) {
		ArrayAppend(application.wheels.onErrorCallbacks, arguments.callback);
	}


	/**
	 * Fires all registered onError callbacks. Each runs in its own try/catch
	 * so a broken callback cannot suppress other callbacks or break error rendering.
	 */
	public void function $fireOnErrorCallbacks(required any exception) {
		if (
			StructKeyExists(application, "wheels")
			&& StructKeyExists(application.wheels, "onErrorCallbacks")
			&& IsArray(application.wheels.onErrorCallbacks)
		) {
			for (var cb in application.wheels.onErrorCallbacks) {
				try {
					cb(arguments.exception);
				} catch (any e) {
					cflog(text = "onError callback failed: #e.message#", type = "error", file = "wheels-errors");
				}
			}
		}
	}


	/**
	 * Verifies that mixin-assembled objects satisfy critical interface contracts.
	 * Runs only in development mode at the end of application bootstrap.
	 * Checks a subset of essential methods — full verification is done by test specs.
	 * Logs warnings instead of throwing to avoid blocking app startup.
	 * Note: the model check is a no-op at startup because models are lazy-loaded
	 * (application.wheels.models is empty until the first model() call).
	 * It activates when called later or from tests.
	 */
	public void function $verifyInterfaceContracts() {
		local.issues = [];

		// Check Model interface (requires at least one model to be loaded)
		try {
			local.modelMethods = [
				"findAll",
				"findOne",
				"findByKey",
				"count",
				"exists",
				"save",
				"valid",
				"update",
				"delete",
				"hasMany",
				"belongsTo",
				"hasOne",
				"validatesPresenceOf"
			];
			if (StructKeyExists(application.wheels, "models") && !StructIsEmpty(application.wheels.models)) {
				local.sampleModelName = StructKeyArray(application.wheels.models)[1];
				local.sampleModel = model(local.sampleModelName);
				for (local.m in local.modelMethods) {
					if (!StructKeyExists(local.sampleModel, local.m)) {
						ArrayAppend(local.issues, "Model(#local.sampleModelName#) missing: #local.m#()");
					}
				}
			}
		} catch (any e) {
			ArrayAppend(local.issues, "Model contract check failed: #e.message#");
		}

		// Check Controller interface
		try {
			local.controllerMethods = [
				"renderView",
				"renderPartial",
				"renderText",
				"redirectTo",
				"linkTo",
				"urlFor",
				"startFormTag",
				"endFormTag",
				"filters",
				"verifies"
			];
			local.params = {controller = "wheels", action = "wheels"};
			local.testController = controller(name = "wheels", params = local.params);
			for (local.m in local.controllerMethods) {
				if (!StructKeyExists(local.testController, local.m)) {
					ArrayAppend(local.issues, "Controller missing: #local.m#()");
				}
			}
		} catch (any e) {
			ArrayAppend(local.issues, "Controller contract check failed: #e.message#");
		}

		// Report issues as warnings
		if (ArrayLen(local.issues)) {
			local.msg = "Interface contract warnings: " & ArrayToList(local.issues, "; ");
			cflog(text = local.msg, type = "warning", file = "wheels-errors");
			if (StructKeyExists(application, "wheels") && application.wheels.showDebugInformation) {
				request.wheels.interfaceWarnings = local.issues;
			}
		}
	}


	/**
	 * Snapshot mtimes of all .cfm files under the app's global include directory.
	 *
	 * Used by the bare `?reload=true` path so a developer adding a helper to
	 * `app/global/*.cfm` does not have to remember the password-gated full reload
	 * (issue ##2792).
	 */
	public struct function $snapshotGlobalIncludes(string directory = ExpandPath("/app/global")) {
		var snapshot = {};
		if (!DirectoryExists(arguments.directory)) {
			return snapshot;
		}
		var files = DirectoryList(arguments.directory, true, "query", "*.cfm");
		for (var row in files) {
			snapshot[row.directory & "/" & row.name] = row.dateLastModified;
		}
		return snapshot;
	}


	/**
	 * Compare a prior `$snapshotGlobalIncludes` result against the current
	 * filesystem state and return true if any tracked .cfm file was added,
	 * removed, or modified.
	 *
	 * Paired with `$snapshotGlobalIncludes` to drive the bare `?reload=true`
	 * soft-reload path in development (issue ##2792).
	 */
	public boolean function $globalIncludesChanged(
		required struct snapshot,
		string directory = ExpandPath("/app/global")
	) {
		var current = $snapshotGlobalIncludes(directory = arguments.directory);
		for (var key in current) {
			if (!StructKeyExists(arguments.snapshot, key)) {
				return true;
			}
			if (DateCompare(arguments.snapshot[key], current[key]) != 0) {
				return true;
			}
		}
		for (var key in arguments.snapshot) {
			if (!StructKeyExists(current, key)) {
				return true;
			}
		}
		return false;
	}


	/**
	 * Build the comma-list of public framework helper names that get mixed onto
	 * every controller (from `wheels.Global` + `wheels.controller.*` +
	 * `wheels.view.*`). Stored on `application.wheels.protectedControllerMethods`
	 * and consumed by `$callAction()` to reject URL dispatch to framework
	 * helpers like `env()`, `model()`, `redirectTo()` (issue ##2844).
	 *
	 * Derived from `getMetaData().functions` on each source component, mirroring
	 * what `$integrateComponents` mixes onto a controller. `$`-prefixed names
	 * are already gated separately and are excluded here.
	 *
	 * Adobe CF's `getMetaData().functions` does not enumerate component-body
	 * includes (#2790), so after the DC7 split (issue ##3241) the public
	 * helpers that live in `vendor/wheels/global/*.cfm` are also harvested
	 * from those files. Lucee typically lists the includes in metadata
	 * already; the extra pass is then a no-op via `ListFindNoCase`.
	 */
	public string function $buildProtectedControllerMethods() {
		var protectedMethods = "";
		var sources = ["wheels.Global"];
		var mixinPaths = ["wheels.controller", "wheels.view"];
		for (var basePath in mixinPaths) {
			var folder = ExpandPath("/" & Replace(basePath, ".", "/", "all"));
			if (!DirectoryExists(folder)) {
				continue;
			}
			var files = DirectoryList(folder, false, "name", "*.cfc");
			for (var fileName in files) {
				ArrayAppend(sources, basePath & "." & Replace(fileName, ".cfc", "", "all"));
			}
		}
		for (var componentPath in sources) {
			var meta = GetMetaData(CreateObject("component", componentPath));
			if (!StructKeyExists(meta, "functions")) {
				continue;
			}
			for (var fn in meta.functions) {
				if (
					StructKeyExists(fn, "access") && fn.access == "public"
					&& Left(fn.name, 1) != "$"
					&& !ListFindNoCase(protectedMethods, fn.name)
				) {
					protectedMethods = ListAppend(protectedMethods, fn.name);
				}
			}
		}
		var includeNames = $publicFunctionNamesFromGlobalIncludes();
		var includeCount = ArrayLen(includeNames);
		for (var includeIndex = 1; includeIndex <= includeCount; includeIndex++) {
			if (!ListFindNoCase(protectedMethods, includeNames[includeIndex])) {
				protectedMethods = ListAppend(protectedMethods, includeNames[includeIndex]);
			}
		}
		return protectedMethods;
	}

	/**
	 * Public (non-`$`) function names declared in `vendor/wheels/global/*.cfm`.
	 * Used by `$buildProtectedControllerMethods()` so Adobe CF still rejects
	 * dispatch to helpers like `env()` / `model()` after those declarations
	 * moved out of `Global.cfc` itself (issue ##3241, #2790).
	 */
	public array function $publicFunctionNamesFromGlobalIncludes() {
		var publicNames = [];
		var allNames = $frameworkGlobalFunctionNames();
		var nameCount = ArrayLen(allNames);
		for (var nameIndex = 1; nameIndex <= nameCount; nameIndex++) {
			if (Left(allNames[nameIndex], 1) != "$") {
				ArrayAppend(publicNames, allNames[nameIndex]);
			}
		}
		return publicNames;
	}

	/**
	 * Every `public function` name declared in `vendor/wheels/global/*.cfm`,
	 * including `$`-prefixed internals. Cached on `application.wheels` so a
	 * reload (which rebuilds that struct) re-reads the files.
	 */
	public array function $frameworkGlobalFunctionNames() {
		if (StructKeyExists(application, "wheels") && StructKeyExists(application.wheels, "frameworkGlobalFunctionNames")) {
			return application.wheels.frameworkGlobalFunctionNames;
		}
		var names = $readGlobalIncludeFunctionNames();
		if (StructKeyExists(application, "wheels")) {
			application.wheels.frameworkGlobalFunctionNames = names;
		}
		return names;
	}

	/**
	 * Line-scan `vendor/wheels/global/*.cfm` for `public ... function name(`.
	 * Comment-only lines are skipped (Anti-Pattern 14 spirit) without a
	 * whole-file comment-strip regex — that shape hangs Lucee 7 on large
	 * sources (see BareCfabortGuardSpec).
	 */
	public array function $readGlobalIncludeFunctionNames() {
		var names = [];
		var seen = {};
		var folder = ExpandPath("/wheels/global");
		if (!DirectoryExists(folder)) {
			return names;
		}
		var files = DirectoryList(folder, false, "path", "*.cfm");
		var fileCount = ArrayLen(files);
		for (var fileIndex = 1; fileIndex <= fileCount; fileIndex++) {
			var content = FileRead(files[fileIndex]);
			var fileLines = ListToArray(content, Chr(10), true);
			for (var rawLine in fileLines) {
				var line = Trim(Replace(rawLine, Chr(13), "", "all"));
				if (!Len(line) || Left(line, 2) == "//" || Left(line, 1) == "*" || Left(line, 2) == "/*") {
					continue;
				}
				if (!REFindNoCase("^public\s+", line)) {
					continue;
				}
				var fnPos = FindNoCase("function ", line);
				if (!fnPos) {
					continue;
				}
				var after = Trim(Mid(line, fnPos + 9, Len(line)));
				var paren = Find("(", after);
				if (paren <= 1) {
					continue;
				}
				var name = Trim(Left(after, paren - 1));
				if (!Len(name) || StructKeyExists(seen, name)) {
					continue;
				}
				ArrayAppend(names, name);
				seen[name] = true;
			}
		}
		return names;
	}


	/**
	 * Convert the comma-list returned by `$buildProtectedControllerMethods()`
	 * into a struct-as-set so `$callAction()` can perform an O(1)
	 * `StructKeyExists` membership test on the per-request dispatch hot path
	 * instead of an O(n) `ListFindNoCase` scan over ~100-250 helper names.
	 * CFML struct keys are case-insensitive by default, preserving the prior
	 * `ListFindNoCase` semantics (an action named `ENV` is still rejected like
	 * `env`). Stored on `application.wheels.protectedControllerMethodsLookup`
	 * alongside the list, which is retained for callers expecting that shape.
	 */
	public struct function $protectedControllerMethodsLookup(required string methods) {
		var lookup = {};
		for (var name in ListToArray(arguments.methods)) {
			lookup[name] = true;
		}
		return lookup;
	}


	/**
	 * Re-evaluate the given global-includes file into `application.wo`'s
	 * variables/this scope. Invoked from the bare `?reload=true` soft-reload
	 * when `$globalIncludesChanged` reports drift (issue ##2792).
	 *
	 * `include` inside a method body adds function declarations to the
	 * method's local scope, not the component's outer scope, so we walk
	 * local for any user-defined functions and copy them onto variables
	 * and this so they remain callable on `application.wo` across requests.
	 */
	public void function $reincludeGlobals(string file = "/app/global/functions.cfm") {
		// Evaluate the file in a throwaway instance and bind the functions it
		// declares onto variables + this. Done via a separate instance (not a
		// bare `include` here) because Adobe CF throws "Routines cannot be
		// declared more than once" when a `?reload=true` re-includes a file
		// whose UDFs are already bound to application.wo — the prior copy in
		// our own scope collides with the re-declaration. A fresh scope per
		// call sidesteps that; rebinding here is a plain struct assignment, so
		// the updated version replaces the old one on every engine.
		var reloaded = new wheels.GlobalIncludeLoader().loadFunctions(arguments.file);
		for (var key in reloaded) {
			variables[key] = reloaded[key];
			this[key] = reloaded[key];
		}
	}


	/**
	 * Copy include-injected user functions from `variables` onto `this` so
	 * they remain enumerable on engines (Adobe CF) where struct-iteration
	 * only reliably surfaces `this`-scope members. Must stay a function: an
	 * inline `local.X` iterator in the pseudo-constructor materializes
	 * `variables.local` and shadows method-local `local` on BoxLang.
	 *
	 * The promote-key list is memoized in application scope because this runs
	 * on EVERY instantiation of every Global-derived component (per model row,
	 * per controller, per Plugins instance) while its input — the function set
	 * injected by the `/app/global/functions.cfm` include above — is constant
	 * for the application lifetime. The memo is keyed per concrete class name
	 * because whether a subclass's own (e.g. private) methods are already
	 * registered in `variables` at this point in the pseudo-constructor is
	 * engine-dependent, so the promotable set is not guaranteed identical
	 * across subclasses. The gate is the cached key itself, never a separate
	 * done-flag (##2800 lesson), and the cache lives inside
	 * `application[$appKey()]`, which `?reload=true` rebuilds as a fresh
	 * struct — so invalidation is structural. When `application` (or the
	 * Wheels struct in it) is unavailable — CLI/test bootstrap, early
	 * application start — we fall back to the full scan without memoizing.
	 */
	public void function $promoteIncludedGlobalsToThis() {
		var promoteCache = "";
		var promoteCacheKey = "";
		if (IsDefined("application")) {
			var promoteAppKey = $appKey();
			if (StructKeyExists(application, promoteAppKey) && IsStruct(application[promoteAppKey])) {
				var classMetadata = GetMetadata(this);
				if (IsStruct(classMetadata) && StructKeyExists(classMetadata, "name") && Len(classMetadata.name)) {
					promoteCacheKey = classMetadata.name;
					if (!StructKeyExists(application[promoteAppKey], "promotedGlobalKeys")) {
						application[promoteAppKey].promotedGlobalKeys = {};
					}
					promoteCache = application[promoteAppKey].promotedGlobalKeys;
				}
			}
		}
		if (IsStruct(promoteCache) && StructKeyExists(promoteCache, promoteCacheKey)) {
			// Memoized path: apply the recorded keys with the same guards the
			// fresh scan uses. Keys that vanished from `variables` are skipped
			// and keys already on `this` are left alone, so a stale entry can
			// never promote something the scan would not have.
			var cachedKeys = promoteCache[promoteCacheKey];
			var cachedKeyCount = ArrayLen(cachedKeys);
			for (var keyIndex = 1; keyIndex <= cachedKeyCount; keyIndex++) {
				var promoteKey = cachedKeys[keyIndex];
				if (StructKeyExists(variables, promoteKey) && !StructKeyExists(this, promoteKey)) {
					this[promoteKey] = variables[promoteKey];
				}
			}
			return;
		}
		var promotedKeys = $scanAndPromoteIncludedGlobals();
		if (IsStruct(promoteCache)) {
			// Concurrent first instantiations may both scan and both assign;
			// the value is deterministic per class, so last-write-wins is safe.
			promoteCache[promoteCacheKey] = promotedKeys;
		}
	}


	/**
	 * The full `variables` scan behind `$promoteIncludedGlobalsToThis()`:
	 * promote every variables-scope custom function that is not already on
	 * `this`, returning the promoted key names. Also serves as the
	 * non-memoizing fallback when application scope is unavailable.
	 */
	public array function $scanAndPromoteIncludedGlobals() {
		var promotedKeys = [];
		for (var promoteKey in variables) {
			if (!isCustomFunction(variables[promoteKey])) {
				continue;
			}
			if (structKeyExists(this, promoteKey)) {
				continue;
			}
			this[promoteKey] = variables[promoteKey];
			ArrayAppend(promotedKeys, promoteKey);
		}
		return promotedKeys;
</cfscript>
