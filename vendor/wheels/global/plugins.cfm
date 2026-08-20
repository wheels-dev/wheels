/**
 * wheels.Global include: plugins
 * Plugin/package bootstrap, deprecation, version checks.
 *
 * Included from `vendor/wheels/Global.cfc` at component-body scope so
 * these functions compile into the Global component. Children inherit
 * them; there is no per-instance mixin copy. Keep every helper that
 * must mix onto models/controllers `public` and `$`-prefixed
 * (cross-engine invariant 7).
 */


	/**
	 * Returns a list of the names of all installed plugins.
	 *
	 * [section: Global Helpers]
	 * [category: Miscellaneous Functions]
	 */
	public string function pluginNames() {
		return StructKeyList(application.wheels.plugins);
	}


	/**
	 * Internal function. Returns the application-cached Plugins instance so the
	 * request-lifecycle call sites (onDIcomplete on controllers, models and the
	 * dispatcher, plus $runOnRequestStart) don't construct a throwaway
	 * wheels.Plugins — and its wheels.Global parent pseudo-constructor — per
	 * request / per materialized model row (issue 2897, Stage 3). Falls back to
	 * a fresh instance during bootstrap windows where the cache has not been
	 * populated yet, or where the application scope is undefined (CLI / test
	 * bootstrap). Sharing one instance is safe because $initializeMixins keeps
	 * its scratch state local-scoped.
	 */
	public any function $pluginObj() {
		if (IsDefined("application")) {
			local.appKey = StructKeyExists(application, "$wheels") ? "$wheels" : "wheels";
			if (StructKeyExists(application, local.appKey) && StructKeyExists(application[local.appKey], "PluginObj")) {
				return application[local.appKey].PluginObj;
			}
		}
		return CreateObject("component", "wheels.Plugins");
	}


	/**
	 * Internal function. Records a deprecation warning through a single shared
	 * policy: the first call for a given feature logs a warning to the standard
	 * wheels log and registers the warning in
	 * application[appKey].deprecationWarnings so running apps can surface it
	 * (debug panel, tooling). Subsequent calls for the same feature are no-ops,
	 * making the helper safe to call from per-request code paths. The dedup
	 * check, registration, and log write run atomically under an exclusive
	 * lock so concurrent first callers (e.g. parallel first requests hitting a
	 * deprecated per-request helper) register and log exactly once. If the
	 * Wheels application struct does not exist yet, the helper is a silent
	 * no-op: with no registry to dedup against, logging would fire on every
	 * call, and all framework callers run after the struct is established.
	 *
	 * @feature Stable identifier for the deprecated feature (e.g. "plugins-directory", "paginationLinks").
	 * @message Human-readable message: what is deprecated, what replaces it, and when it goes away.
	 * @docUrl Optional URL of the migration guide, appended to the logged message.
	 */
	public void function $deprecated(required string feature, required string message, string docUrl = "") {
		try {
			local.appKey = $appKey();
			if (StructKeyExists(application, local.appKey)) {
				// One app-wide lock (rather than per-feature) also serializes the lazy
				// creation of the registry array itself; contention is a non-issue at
				// once-per-feature-per-application frequency.
				lock name="wheels_deprecated_registry" type="exclusive" timeout="5" {
					if (!StructKeyExists(application[local.appKey], "deprecationWarnings")) {
						application[local.appKey].deprecationWarnings = [];
					}
					for (local.existing in application[local.appKey].deprecationWarnings) {
						if (local.existing.feature == arguments.feature) {
							return;
						}
					}
					ArrayAppend(application[local.appKey].deprecationWarnings, {
						feature = arguments.feature,
						message = arguments.message,
						url = arguments.docUrl
					});
					// Log if-and-only-if the registration above just succeeded; the
					// registry is what enforces the warn-once policy for the log too.
					try {
						local.text = "[Wheels] Deprecation: " & arguments.message;
						if (Len(arguments.docUrl)) {
							local.text &= " See: " & arguments.docUrl;
						}
						WriteLog(type = "warning", text = local.text, file = "wheels");
					} catch (any e) {
						// Logging is best-effort; the registry entry above already records the warning.
					}
				}
			}
		} catch (any e) {
			// Best-effort by design (including lock timeouts); never let a
			// deprecation notice break the caller.
		}
	}


	// Returns the running framework version. Delegates to BuildInfo.cfc, which
	// is the authoritative version source. The historical box.json-reading
	// implementation (with monorepo / wheels-base-template fallback chain)
	// was retired when BuildInfo became the source of truth — see the BuildInfo
	// header for migration context. Kept as a thin wrapper because callers
	// upstream of onapplicationstart (e.g. PackageLoader, Plugins) and tests
	// reference $readFrameworkVersion by name.
	public string function $readFrameworkVersion() {
		return new wheels.BuildInfo().version();
	}


	public string function $checkMinimumVersion(required string engine, required string version) {
		local.rv = "";
		local.version = Replace(arguments.version, ".", ",", "all");
		local.major = Val(ListGetAt(local.version, 1));
		local.minor = 0;
		local.patch = 0;
		local.build = 0;
		if (ListLen(local.version) > 1) {
			local.minor = Val(ListGetAt(local.version, 2));
		}
		if (ListLen(local.version) > 2) {
			local.patch = Val(ListGetAt(local.version, 3));
		}
		if (ListLen(local.version) > 3) {
			local.build = Val(ListGetAt(local.version, 4));
		}
		if (arguments.engine == "BoxLang") {
			local.minimumMajor = "1";
			local.minimumMinor = "0";
			local.minimumPatch = "0";
			local.maximumMajor = "1";
			local.maximumMinor = "15";
			local.maximumPatch = "999";

			// Check minimum version
			if (
				local.major < local.minimumMajor
				|| (local.major == local.minimumMajor && local.minor < local.minimumMinor)
				|| (local.major == local.minimumMajor && local.minor == local.minimumMinor && local.patch < local.minimumPatch)
			) {
				local.rv = "The Wheels framework requires BoxLang version #local.minimumMajor#.#local.minimumMinor#.#local.minimumPatch# or higher. You are currently running version #arguments.version#.";
			}

			// Check maximum version (optional - for major version compatibility)
			if (
				local.major > local.maximumMajor
				|| (local.major == local.maximumMajor && local.minor > local.maximumMinor)
				|| (local.major == local.maximumMajor && local.minor == local.maximumMinor && local.patch > local.maximumPatch)
			) {
				local.rv = "The Wheels framework has been tested up to BoxLang version #local.maximumMajor#.#local.maximumMinor#.#local.maximumPatch#. You are currently running version #arguments.version#. Please check for framework updates or compatibility issues.";
			}
		} else if (arguments.engine == "Lucee") {
			local.minimumMajor = "5";
			local.minimumMinor = "3";
			local.minimumPatch = "2";
			local.minimumBuild = "77";
			// per-major-release floor consumed by the `StructKeyExists(local, local.major)`
			// check below (keyed by the running engine's major version number)
			local.5 = {minimumMinor = 2, minimumPatch = 1, minimumBuild = 9};
		} else if (arguments.engine == "Adobe ColdFusion") {
			// Adobe ColdFusion 2018 is the oldest supported Adobe engine
			// (CF 11 / 2016 are end-of-life and no longer supported)
			local.minimumMajor = "2018";
			local.minimumMinor = "0";
			local.minimumPatch = "0";
			local.minimumBuild = "";
		} else if (arguments.engine == "RustCFML") {
			// RustCFML is a pre-1.0, rapidly evolving experimental engine that
			// Wheels supports on a best-effort basis. Accept any version (leave
			// local.rv = "") rather than enforcing a minimum; per-version
			// divergences are tracked via the RustCFMLAdapter capabilities.
			local.rv = "";
		} else {
			local.rv = false;
		}
		if (StructKeyExists(local, "minimumMajor")) {
			if (
				local.major < local.minimumMajor
				|| (local.major == local.minimumMajor && local.minor < local.minimumMinor)
				|| (local.major == local.minimumMajor && local.minor == local.minimumMinor && local.patch < local.minimumPatch)
				|| (
					local.major == local.minimumMajor
					&& local.minor == local.minimumMinor
					&& local.patch == local.minimumPatch
					&& Len(local.minimumBuild)
					&& local.build < local.minimumBuild
				)
			) {
				local.rv = local.minimumMajor & "." & local.minimumMinor & "." & local.minimumPatch;
				if (Len(local.minimumBuild)) {
					local.rv &= "." & local.minimumBuild;
				}
			}
			if (StructKeyExists(local, local.major)) {
				// special requirements for having a specific minor or patch version within a major release exists
				if (
					local.minor < local[local.major].minimumMinor
					|| (local.minor == local[local.major].minimumMinor && local.patch < local[local.major].minimumPatch)
				) {
					local.rv = local.major & "." & local[local.major].minimumMinor & "." & local[local.major].minimumPatch;
				}
			}
		}
		return local.rv;
	}


	/**
	 * Internal function. Normalizes mixin-collision records to a single
	 * shared shape: {target, method, firstProvider, secondProvider,
	 * acknowledged, source}. Plugins.cfc emits legacy-shaped records
	 * ({existingPlugin, overridingPlugin}) while PackageLoader.cfc and the
	 * cross-system merge in $loadPackages emit the shared shape directly;
	 * all of them end up in the same application.wheels.mixinCollisions
	 * array, which /wheels/plugins and the development debug footer consume
	 * unconditionally — a mixed-shape array crashes those surfaces with a
	 * "key doesn't exist" error.
	 */
	public array function $normalizeMixinCollisions(required array collisions) {
		local.rv = [];
		for (local.c in arguments.collisions) {
			ArrayAppend(local.rv, {
				target = local.c.target,
				method = local.c.method,
				firstProvider = StructKeyExists(local.c, "firstProvider") ? local.c.firstProvider : local.c.existingPlugin,
				secondProvider = StructKeyExists(local.c, "secondProvider") ? local.c.secondProvider : local.c.overridingPlugin,
				acknowledged = StructKeyExists(local.c, "acknowledged") ? local.c.acknowledged : false,
				source = StructKeyExists(local.c, "source") ? local.c.source : "plugin"
			});
		}
		return local.rv;
	}


	/**
	 * Internal function.
	 */
	public void function $loadPlugins() {
		local.appKey = $appKey();
		local.pluginPath = application[local.appKey].webPath & application[local.appKey].pluginPath;
		application[local.appKey].PluginObj = $createObjectFromRoot(
			path = "wheels",
			fileName = "Plugins",
			method = "$init",
			pluginPath = local.pluginPath,
			deletePluginDirectories = application[local.appKey].deletePluginDirectories,
			overwritePlugins = application[local.appKey].overwritePlugins,
			loadIncompatiblePlugins = application[local.appKey].loadIncompatiblePlugins,
			wheelsEnvironment = application[local.appKey].environment,
			wheelsVersion = application[local.appKey].version
		);
		application[local.appKey].plugins = application[local.appKey].PluginObj.getPlugins();
		application[local.appKey].pluginMeta = application[local.appKey].PluginObj.getPluginMeta();
		application[local.appKey].incompatiblePlugins = application[local.appKey].PluginObj.getIncompatiblePlugins();
		application[local.appKey].dependantPlugins = application[local.appKey].PluginObj.getDependantPlugins();
		application[local.appKey].versionMismatchPlugins = application[local.appKey].PluginObj.getVersionMismatchPlugins();
		// Plugins.cfc emits legacy-shaped collision records ({existingPlugin,
		// overridingPlugin}); normalize them to the shared shape at the merge
		// point so package- and cross-system records (which already use
		// {firstProvider, secondProvider}) can live in the same array without
		// crashing the consumers (/wheels/plugins and the debug footer).
		application[local.appKey].mixinCollisions = $normalizeMixinCollisions(
			application[local.appKey].PluginObj.getMixinCollisions()
		);
		application[local.appKey].mixins = application[local.appKey].PluginObj.getMixins();
		application[local.appKey].pluginMiddleware = application[local.appKey].PluginObj.getPluginMiddleware();
		// Invoke register(container) on ServiceProviderInterface plugins before activation
		if (IsDefined("application.wheelsdi") && ArrayLen(application[local.appKey].PluginObj.getServiceProviders())) {
			application[local.appKey].PluginObj.$invokeServiceProviderRegister(application.wheelsdi);
			// Boot after all register() calls complete — plugins can now resolve services
			application[local.appKey].PluginObj.$invokeServiceProviderBoot(application[local.appKey]);
		}
		// Invoke onPluginActivate lifecycle hook on all plugins now that everything is in the application scope
		application[local.appKey].PluginObj.$invokeOnPluginActivate();
	}


	/**
	 * Discovers and loads packages from the vendor/ directory via PackageLoader.
	 * Merges package mixins into the existing application mixins struct so they
	 * participate in the standard $initializeMixins injection pipeline.
	 */
	public void function $loadPackages() {
		local.appKey = $appKey();
		local.vendorPath = ExpandPath(application[local.appKey].packagePath);

		application[local.appKey].PackageLoaderObj = $createObjectFromRoot(
			path = "wheels",
			fileName = "PackageLoader",
			method = "init",
			vendorPath = local.vendorPath,
			wheelsVersion = application[local.appKey].version,
			wheelsEnvironment = application[local.appKey].environment
		);

		application[local.appKey].packages = application[local.appKey].PackageLoaderObj.getPackages();
		application[local.appKey].packageMeta = application[local.appKey].PackageLoaderObj.getPackageMeta();
		application[local.appKey].failedPackages = application[local.appKey].PackageLoaderObj.getFailedPackages();

		// Ensure mixinCollisions exists (unset when no plugins loaded before packages)
		if (!StructKeyExists(application[local.appKey], "mixinCollisions")) {
			application[local.appKey].mixinCollisions = [];
		}

		// Carry forward any collisions the PackageLoader detected internally
		for (local.c in application[local.appKey].PackageLoaderObj.getMixinCollisions()) {
			ArrayAppend(application[local.appKey].mixinCollisions, local.c);
		}

		// Merge package mixins into the existing mixins struct (plugins loaded first, packages overlay).
		// Detect cross-system collisions — a package method that shadows a plugin method on the
		// same target — before StructAppend silently overwrites.
		local.pkgMixins = application[local.appKey].PackageLoaderObj.getMixins();
		local.pluginProviders = StructKeyExists(application[local.appKey], "PluginObj")
			? application[local.appKey].PluginObj.getMethodProviders()
			: {};
		local.pkgProviders = application[local.appKey].PackageLoaderObj.getMethodProviders();
		for (local.target in local.pkgMixins) {
			if (!StructKeyExists(application[local.appKey].mixins, local.target)) {
				application[local.appKey].mixins[local.target] = {};
			}
			for (local.methodName in local.pkgMixins[local.target]) {
				if (StructKeyExists(application[local.appKey].mixins[local.target], local.methodName)) {
					// Only treat this as a cross-system collision when the existing entry
					// came from a known plugin. Without an attributable plugin provider
					// the prior entry could be framework-internal or pre-seeded, and a
					// "migrate the plugin" recommendation would be misleading.
					local.pluginAttributable = StructKeyExists(local.pluginProviders, local.target)
						&& StructKeyExists(local.pluginProviders[local.target], local.methodName);
					if (!local.pluginAttributable) {
						continue;
					}
					local.pluginName = local.pluginProviders[local.target][local.methodName];
					local.pkgName = StructKeyExists(local.pkgProviders, local.target)
						&& StructKeyExists(local.pkgProviders[local.target], local.methodName)
						? local.pkgProviders[local.target][local.methodName]
						: "(unknown package)";
					ArrayAppend(application[local.appKey].mixinCollisions, {
						target = local.target,
						method = local.methodName,
						firstProvider = local.pluginName,
						secondProvider = local.pkgName,
						acknowledged = false,
						source = "cross"
					});
					WriteLog(
						type = "warning",
						text = "[Wheels] Cross-system mixin collision: method '#local.methodName#' on target '#local.target#' provided by plugin '#local.pluginName#' is being overwritten by package '#local.pkgName#'. Migrate the plugin to a package or remove the duplicate to resolve."
					);
				}
			}
			StructAppend(application[local.appKey].mixins[local.target], local.pkgMixins[local.target]);
		}

		// Merge package middleware into pluginMiddleware (shared pipeline)
		local.pkgMiddleware = application[local.appKey].PackageLoaderObj.getPackageMiddleware();
		for (local.mw in local.pkgMiddleware) {
			ArrayAppend(application[local.appKey].pluginMiddleware, local.mw);
		}

		// Invoke ServiceProvider register/boot if DI container exists. The
		// gate asks the loader (not just getServiceProviders()) because lazy
		// service-hinted packages aren't instantiated yet at this point —
		// $invokeServiceProviderRegister pulls them into the lifecycle, so a
		// vendor tree containing only lazy service packages still needs the
		// lifecycle invoked.
		if (IsDefined("application.wheelsdi") && application[local.appKey].PackageLoaderObj.$hasServiceProviderWork()) {
			application[local.appKey].PackageLoaderObj.$invokeServiceProviderRegister(application.wheelsdi);
			application[local.appKey].PackageLoaderObj.$invokeServiceProviderBoot(application[local.appKey]);
			// Re-sync the application-scope copy so register()/boot() failure
			// records are visible there too. Adobe CF copies arrays by value on
			// assignment, so the copy taken above (pre-invoke) never receives
			// lifecycle-phase entries on those engines — only Lucee/BoxLang share
			// the reference. Re-assigning is harmless on Lucee/BoxLang (same
			// reference) and required on Adobe (fresh copy including new entries).
			application[local.appKey].failedPackages = application[local.appKey].PackageLoaderObj.getFailedPackages();
		}

		// Surface an aggregate summary when any packages failed to load. Without
		// this, PackageLoader records each failure in variables.failedPackages and
		// emits per-package WriteLog calls — but a developer who hits a downstream
		// "No matching function [BASECOATINCLUDES]" error has no obvious place to
		// look. Logging a single high-visibility WARN to wheels.log + a stronger
		// one to wheels-errors.log gives a clear breadcrumb back to the root cause.
		// Runs after the ServiceProvider lifecycle invoke so register()/boot()
		// failures appear in the same summary as load-phase failures.
		if (ArrayLen(application[local.appKey].failedPackages)) {
			local.failNames = "";
			local.failDetail = "";
			for (local.fp in application[local.appKey].failedPackages) {
				local.failNames = ListAppend(local.failNames, local.fp.name);
				local.failDetail &= "  - " & local.fp.name & ": " & local.fp.error & Chr(10);
			}
			try {
				writeLog(
					file = "wheels",
					type = "warning",
					text = "Wheels: " & ArrayLen(application[local.appKey].failedPackages)
						& " package(s) failed to load: " & local.failNames
						& ". Helpers / services these packages provide will be unavailable —"
						& " calling code typically surfaces this as 'No matching function [...]"
						& "' or 'No service registered with the name [...]'."
						& " Per-package detail in wheels-errors.log."
				);
				writeLog(
					file = "wheels-errors",
					type = "error",
					text = "Wheels: " & ArrayLen(application[local.appKey].failedPackages)
						& " package(s) failed to load:" & Chr(10) & local.failDetail
				);
			} catch (any e) {
				// Logging is best-effort during application start.
			}
		}
	}


	/**
	 * NB: url rewriting files need to be removed from here.
	 */
	public string function $buildReleaseZip(
		string version = application.wheels.version,
		string directory = ExpandPath("/")
	) {
		local.name = "wheels-" & LCase(Replace(arguments.version, " ", "-", "all"));
		local.name = Replace(local.name, "alpha-", "alpha.");
		local.name = Replace(local.name, "beta-", "beta.");
		local.name = Replace(local.name, "rc-", "rc.");
		local.path = arguments.directory & local.name & ".zip";

		// directories & files to add to the zip
		local.include = [
			"/config",
			"/app/controllers",
			"/app/events",
			"/app/lib",
			"/app/migrator",
			"files",
			"/app/global",
			"images",
			"javascripts",
			"miscellaneous",
			"/app/models",
			"/plugins",
			"stylesheets",
			"/tests",
			"/app/views",
			"/vendor/wheels",
			"Application.cfc",
			"../wheels.json",
			"../box.json",
			"index.cfm"
		];

		// directories & files to be removed
		local.exclude = ["/wheels/rocketunit_tests", "/wheels/public/build.cfm", "/wheels/tests"];

		// filter out these bad boys
		local.filter = "*.settings, *.classpath, *.project, *.DS_Store";

		// The change log and license are copied to the wheels directory only for the build.
		// FileCopy(ExpandPath("CHANGELOG.md"), ExpandPath("/wheels/CHANGELOG.md"));
		// FileCopy(ExpandPath("LICENSE"), ExpandPath("/wheels/LICENSE"));

		// Entries starting with "/" or ".." → treat as project-root paths (keep original folder structure)
		// Entries without "/" → treat as webroot (/public) paths
		for (local.i in local.include) {
			if (FileExists(ExpandPath(local.i))) {
				if (Left(local.i, 1) neq "/" && Left(local.i, 2) neq "..") {
					$zip(file = local.path, source = ExpandPath(local.i), prefix = "/public");
				} else {
					$zip(file = local.path, source = ExpandPath(local.i));
				}
			} else if (DirectoryExists(ExpandPath(local.i))) {
				if (Left(local.i, 1) neq "/" && Left(local.i, 2) neq "..") {
					$zip(file = local.path, source = ExpandPath(local.i), prefix = "/public/#local.i#");
				} else {
					$zip(file = local.path, source = ExpandPath(local.i), prefix = local.i);
				}
			} else {
				Throw(
					type = "Wheels.Build",
					message = "#ExpandPath(local.i)# not found",
					detail = "All paths specified in local.include must exist"
				);
			}
		};

		for (local.i in local.exclude) {
			$zip(file = local.path, action = "delete", entrypath = local.i);
		};
		$zip(file = local.path, action = "delete", filter = local.filter, recurse = true);

		// Clean up.
		/* Might not need this because the wheels folder is outside the app now */
		// FileDelete(ExpandPath("/wheels/CHANGELOG.md"));
		// FileDelete(ExpandPath("/wheels/LICENSE"));

		return local.path;
	}
