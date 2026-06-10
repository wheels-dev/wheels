/**
 * Discovers and loads packages from the vendor directory.
 *
 * Packages are optional first-party modules that ship in packages and are activated
 * by copying to vendor. Each package directory must contain a package.json manifest.
 * The framework discovers package.json files in vendor subdirectories on startup
 * with per-package error isolation.
 *
 * PackageLoader runs alongside (not replacing) the existing Plugins.cfc system.
 * Loaded package mixins are merged into the application mixins struct
 * so they participate in the standard initializeMixins injection pipeline.
 *
 * Supports dependency declarations (requires, replaces, suggests), topological
 * load ordering via ModuleGraph.cfc, and lazy loading for service-only packages.
 */
component output="false" {

	/**
	 * Initializes the PackageLoader and discovers all packages in the vendor directory.
	 *
	 * @vendorPath  Expanded filesystem path to the vendor/ directory
	 * @wheelsVersion  Current Wheels version string for compatibility checking
	 * @wheelsEnvironment  Current environment name (development, production, etc.)
	 */
	public PackageLoader function init(
		required string vendorPath,
		string wheelsVersion = "",
		string wheelsEnvironment = "production",
		string componentPrefix = "vendor"
	) {
		variables.vendorPath = arguments.vendorPath;
		variables.wheelsVersion = arguments.wheelsVersion;
		variables.wheelsEnvironment = arguments.wheelsEnvironment;
		variables.componentPrefix = arguments.componentPrefix;
		variables.packages = {};
		variables.packageMeta = {};
		variables.mixins = {};
		variables.serviceProviders = [];
		variables.packageMiddleware = [];
		variables.failedPackages = [];
		variables.excludedPackages = {};
		variables.loadOrder = [];
		variables.lazyPackages = {};
		variables.mixinCollisions = [];
		// Per-package CFML mapping registry: alias → absolute package directory.
		// Populated during load so each installed package gets a static, identifier-
		// safe alias usable in `new <alias>.Sibling()` even when the on-disk dir
		// name contains hyphens (e.g. `wheels-sentry`). See GH#2712.
		variables.packageMappings = {};
		// Tracks which package first claimed each alias so a later collision can
		// be reported instead of silently overwriting.
		variables.$mappingProviders = {};
		// Tracks which package first registered each method per target so a
		// later registration can be flagged as an overwrite. Keyed by target,
		// then by method name, holding the originating package dir name.
		variables.$methodProviders = {};

		// The same mixin targets as Plugins.cfc
		variables.mixableComponents = "application,dispatch,controller,mapper,model,base,sqlserver,mysql,postgresql,h2,test";

		// Initialize mixin containers
		for (local.target in variables.mixableComponents) {
			variables.mixins[local.target] = {};
			variables.$methodProviders[local.target] = {};
		}

		// Run the loading pipeline
		$discover();

		return this;
	}

	// ---------------------------------------------------------------------------
	// Public Getters
	// ---------------------------------------------------------------------------

	public struct function getPackages() {
		return variables.packages;
	}

	public struct function getPackageMeta() {
		return variables.packageMeta;
	}

	public struct function getMixins() {
		return variables.mixins;
	}

	public array function getServiceProviders() {
		return variables.serviceProviders;
	}

	public array function getPackageMiddleware() {
		return variables.packageMiddleware;
	}

	public array function getFailedPackages() {
		return variables.failedPackages;
	}

	public struct function getExcludedPackages() {
		return variables.excludedPackages;
	}

	public array function getLoadOrder() {
		return variables.loadOrder;
	}

	/**
	 * Returns the per-package CFML mapping registry built during load.
	 * Keys are identifier-safe aliases (e.g. `wheelsSentry` derived from
	 * `wheels-sentry`, or an explicit `mapping` value from package.json);
	 * values are absolute paths to the package install directory. See GH#2712.
	 *
	 * Returns a copy: the internal registry is the source of truth, and a
	 * caller mutating the returned struct must not silently corrupt it.
	 */
	public struct function getPackageMappings() {
		return Duplicate(variables.packageMappings);
	}

	/**
	 * Returns mixin collision records — cases where a package registered a
	 * method name for a target that another package had already claimed.
	 * Each entry: {target, method, firstProvider, secondProvider, acknowledged}.
	 * An `acknowledged` true means the overwriting package declared the method
	 * in its `provides.overrides` list, which suppresses the warning log.
	 *
	 * Returns a defensive copy: $rollbackPackage walks the internal array
	 * with ArrayDeleteAt, so a caller mutating the returned reference (e.g.
	 * sorting or appending) would corrupt that walk on a subsequent rollback.
	 */
	public array function getMixinCollisions() {
		return Duplicate(variables.mixinCollisions);
	}

	/**
	 * Returns the per-target method→package-name mapping built during mixin
	 * collection. Used by $loadPackages to name the package side of a
	 * cross-system collision with a legacy plugin.
	 *
	 * Named getMethodProviders (not $methodProviders) to avoid shadowing the
	 * variables.$methodProviders storage struct on Adobe CF, which stores
	 * method declarations in the same `variables` scope keyed by name.
	 */
	public struct function getMethodProviders() {
		return variables.$methodProviders;
	}

	/**
	 * Returns a package instance, triggering lazy instantiation if needed.
	 *
	 * @dirName  Package directory name
	 * @return   Package CFC instance
	 */
	public any function getPackage(required string dirName) {
		if (StructKeyExists(variables.packages, arguments.dirName)) {
			return variables.packages[arguments.dirName];
		}
		// Check if it's a lazy package that hasn't been instantiated
		if (StructKeyExists(variables.lazyPackages, arguments.dirName)) {
			$instantiateLazyPackage(arguments.dirName);
			return variables.packages[arguments.dirName];
		}
		Throw(
			type = "Wheels.PackageNotFound",
			message = "Package '#arguments.dirName#' is not loaded"
		);
	}

	/**
	 * Checks whether a package is loaded (including lazy packages).
	 */
	public boolean function isPackageLoaded(required string dirName) {
		return StructKeyExists(variables.packages, arguments.dirName)
			|| StructKeyExists(variables.lazyPackages, arguments.dirName);
	}

	// ---------------------------------------------------------------------------
	// Discovery & Loading
	// ---------------------------------------------------------------------------

	/**
	 * Scans vendor/ for directories containing package.json (excluding vendor/wheels/).
	 * Builds a dependency graph and loads packages in topological order.
	 */
	private void function $discover() {
		if (!DirectoryExists(variables.vendorPath)) {
			return;
		}

		// Phase 1: Discover all manifests (fast — file reads only, no CFC compilation)
		local.manifests = $discoverManifests();

		if (StructIsEmpty(local.manifests)) {
			return;
		}

		// Phase 2: Resolve dependency graph
		local.graph = new wheels.ModuleGraph();
		local.resolution = local.graph.resolve(local.manifests);

		variables.loadOrder = local.resolution.loadOrder;
		variables.excludedPackages = local.resolution.excluded;

		// Record graph-level errors as failed packages
		for (local.err in local.resolution.errors) {
			ArrayAppend(variables.failedPackages, {
				name = local.err.package,
				error = local.err.message,
				detail = ""
			});
			WriteLog(
				text = "[Wheels] Package '#local.err.package#' failed: #local.err.message#",
				type = "error",
				file = "wheels"
			);
		}

		// Log excluded (replaced) packages
		for (local.dirName in local.resolution.excluded) {
			WriteLog(
				text = "[Wheels] Package '#local.dirName#' excluded: #local.resolution.excluded[local.dirName]#",
				type = "information",
				file = "wheels"
			);
		}

		// Phase 3: Load packages in resolved order
		for (local.dirName in local.resolution.loadOrder) {
			local.pkgDir = variables.vendorPath & "/" & local.dirName;
			local.manifestPath = local.pkgDir & "/package.json";

			try {
				$loadPackage(local.dirName, local.pkgDir, local.manifestPath);
			} catch (any e) {
				ArrayAppend(variables.failedPackages, {
					name = local.dirName,
					error = e.message,
					detail = StructKeyExists(e, "detail") ? e.detail : ""
				});
				WriteLog(
					text = "[Wheels] Package '#local.dirName#' failed to load: #e.message#",
					type = "error",
					file = "wheels"
				);
				// Any partial state from $loadPackage / $instantiatePackage
				// (packageMeta, instantiated CFC, collected mixins/services/
				// middleware) gets cleaned up so failedPackages and the live
				// registries never disagree about which packages loaded.
				$rollbackPackage(local.dirName);
			}
		}
	}

	/**
	 * Scans vendor/ and parses all package.json manifests without instantiating CFCs.
	 * Returns a struct keyed by directory name with parsed manifest structs.
	 */
	private struct function $discoverManifests() {
		local.manifests = {};

		local.dirs = DirectoryList(variables.vendorPath, false, "name");

		for (local.dirName in local.dirs) {
			// Skip the framework core directory
			if (LCase(local.dirName) == "wheels") {
				continue;
			}

			// Skip hidden directories (e.g. .git, .cache, editor metadata).
			// Package conventions never use dot-prefixed names, and loading a
			// stray manifest from one would be surprising and unsafe.
			if (Left(local.dirName, 1) == ".") {
				continue;
			}

			local.pkgDir = variables.vendorPath & "/" & local.dirName;

			// Must be a directory
			if (!DirectoryExists(local.pkgDir)) {
				continue;
			}

			// Must have a package.json manifest
			local.manifestPath = local.pkgDir & "/package.json";
			if (!FileExists(local.manifestPath)) {
				continue;
			}

			// Parse manifest with error isolation
			try {
				local.manifests[local.dirName] = $parseManifest(local.manifestPath);
			} catch (any e) {
				ArrayAppend(variables.failedPackages, {
					name = local.dirName,
					error = e.message,
					detail = StructKeyExists(e, "detail") ? e.detail : ""
				});
				WriteLog(
					text = "[Wheels] Package '#local.dirName#' manifest error: #e.message#",
					type = "error",
					file = "wheels"
				);
			}
		}

		return local.manifests;
	}

	/**
	 * Loads a single package: validates manifest, instantiates CFC, collects mixins/services/middleware.
	 * Supports lazy loading for packages that declare "lazy": true and have no mixins/middleware.
	 */
	private void function $loadPackage(
		required string dirName,
		required string pkgDir,
		required string manifestPath
	) {
		// Parse and validate the manifest
		local.manifest = $parseManifest(arguments.manifestPath);

		// Enforce wheelsVersion constraint before doing any other work so an
		// incompatible package never contributes metadata, mixins, or services.
		if (!$isCompatibleVersion(local.manifest)) {
			local.constraint = Trim(local.manifest.wheelsVersion);
			local.runtime = $normalizeWheelsVersion();
			ArrayAppend(variables.failedPackages, {
				name = arguments.dirName,
				error = "Incompatible wheelsVersion constraint",
				detail = "Package requires '#local.constraint#' but Wheels #local.runtime# is running"
			});
			WriteLog(
				text = "[Wheels] Package '#arguments.dirName#' skipped: requires Wheels #local.constraint#, running #local.runtime#",
				type = "warning",
				file = "wheels"
			);
			return;
		}

		// Store metadata
		variables.packageMeta[arguments.dirName] = {
			name = StructKeyExists(local.manifest, "name") ? local.manifest.name : arguments.dirName,
			version = StructKeyExists(local.manifest, "version") ? local.manifest.version : "0.0.0",
			author = StructKeyExists(local.manifest, "author") ? local.manifest.author : "",
			description = StructKeyExists(local.manifest, "description") ? local.manifest.description : "",
			manifest = local.manifest,
			directory = arguments.pkgDir
		};

		// Resolve the provides block
		local.provides = {};
		if (StructKeyExists(local.manifest, "provides")) {
			local.provides = local.manifest.provides;
		}

		// Determine mixin targets (default: "none" — packages are explicit, unlike legacy plugins)
		local.mixinTargets = "none";
		if (StructKeyExists(local.provides, "mixins") && IsSimpleValue(local.provides.mixins) && Len(Trim(local.provides.mixins))) {
			local.mixinTargets = Trim(local.provides.mixins);
		}
		// Fallback: top-level "mixins" field (for simpler manifests)
		if (local.mixinTargets == "none" && StructKeyExists(local.manifest, "mixins") && IsSimpleValue(local.manifest.mixins) && Len(Trim(local.manifest.mixins))) {
			local.mixinTargets = Trim(local.manifest.mixins);
		}

		// Validate declared mixin targets against the allowlist. Unknown targets
		// (typos, unsupported names like "view") silently produce zero injection
		// under the legacy behavior — reject them up front instead.
		$validateMixinTargets(arguments.dirName, local.mixinTargets);

		// Check for middleware
		local.hasMiddleware = StructKeyExists(local.provides, "middleware")
			&& IsArray(local.provides.middleware)
			&& ArrayLen(local.provides.middleware) > 0;

		// Determine if this package should be lazily loaded
		local.isLazy = StructKeyExists(local.manifest, "lazy") && local.manifest.lazy == true;
		local.canBeLazy = local.isLazy && local.mixinTargets == "none" && !local.hasMiddleware;

		if (local.canBeLazy) {
			// Log the lazy registration attempt before mapping registration so
			// a reader scanning wheels.log on a failed-mapping outcome sees a
			// "Loading package" entry symmetric with the eager path.
			try {
				WriteLog(
					text = "[Wheels] Loading package '#arguments.dirName#' from #arguments.pkgDir# (lazy)",
					type = "information",
					file = "wheels"
				);
			} catch (any e) {}
			// Store lazy package info — CFC will be instantiated on first access
			variables.lazyPackages[arguments.dirName] = {
				dirName = arguments.dirName,
				pkgDir = arguments.pkgDir,
				mixinTargets = local.mixinTargets,
				manifest = local.manifest
			};
			// Register the CFML mapping for a lazy package up front so consumer
			// code can reference siblings via the alias before first access.
			// Return value intentionally discarded on the failure path:
			// $tryRegisterPackageMapping records its own failedPackages entry
			// and calls $rollbackPackage so lazyPackages is cleaned too.
			if (!$tryRegisterPackageMapping(arguments.dirName, local.manifest, arguments.pkgDir)) {
				return;
			}
			WriteLog(
				text = "[Wheels] Package '#arguments.dirName#' v#variables.packageMeta[arguments.dirName].version# registered (lazy)",
				type = "information",
				file = "wheels"
			);
			return;
		}

		try {
			WriteLog(
				text = "[Wheels] Loading package '#arguments.dirName#' from #arguments.pkgDir#",
				type = "information",
				file = "wheels"
			);
		} catch (any e) {}

		// Eager loading: instantiate CFC now
		$instantiatePackage(arguments.dirName, arguments.pkgDir, local.mixinTargets, local.provides);

		// Register the per-package CFML mapping LAST so any earlier failure
		// (validation, instantiation, mixin collection) doesn't leave a stale
		// alias claiming the slot in variables.packageMappings or
		// variables.$mappingProviders. A collision (two packages computing the
		// same alias) is recorded as a failed package and the loaded package
		// is rolled back so its services/mixins don't ship under an alias
		// nobody can resolve. See GH#2712.
		// Return value intentionally discarded: $tryRegisterPackageMapping
		// records its own failedPackages entry and calls $rollbackPackage on
		// the false path.
		$tryRegisterPackageMapping(arguments.dirName, local.manifest, arguments.pkgDir);
	}

	/**
	 * Registers a CFML mapping for a package and returns true on success. On
	 * failure (invalid alias, duplicate alias) the package is rolled back —
	 * packageMeta, the instantiated package, any collected mixins/service
	 * providers/middleware, and the lazy-package entry are all removed — and
	 * the failure is recorded in failedPackages. Centralises the rollback so
	 * eager and lazy load paths share identical cleanup.
	 */
	private boolean function $tryRegisterPackageMapping(
		required string dirName,
		required struct manifest,
		required string pkgDir
	) {
		local.aliasResult = $registerPackageMapping(arguments.dirName, arguments.manifest, arguments.pkgDir);
		if (!local.aliasResult.ok) {
			ArrayAppend(variables.failedPackages, {
				name = arguments.dirName,
				error = local.aliasResult.error,
				detail = local.aliasResult.detail
			});
			WriteLog(
				text = "[Wheels] Package '#arguments.dirName#' failed mapping registration: #local.aliasResult.error#",
				type = "error",
				file = "wheels"
			);
			$rollbackPackage(arguments.dirName);
			return false;
		}

		// Plural `mappings` entries register after the singular alias so the
		// singular slot is always claimed first. A plural failure unwinds any
		// plural entries that did succeed AND the singular alias, then rolls
		// the package back — leaves the mapping registries clean for the next
		// load attempt.
		local.pluralResult = $registerAdditionalMappings(arguments.dirName, arguments.manifest, arguments.pkgDir);
		if (local.pluralResult.ok) {
			return true;
		}

		$unregisterMappings(local.pluralResult.registered);
		// Singular alias used Len() to validate, so it's always present here.
		$unregisterMappings([local.aliasResult.alias]);
		ArrayAppend(variables.failedPackages, {
			name = arguments.dirName,
			error = local.pluralResult.error,
			detail = local.pluralResult.detail
		});
		WriteLog(
			text = "[Wheels] Package '#arguments.dirName#' failed plural mapping registration: #local.pluralResult.error#",
			type = "error",
			file = "wheels"
		);
		$rollbackPackage(arguments.dirName);
		return false;
	}

	/**
	 * Removes the given mapping aliases from the in-process registry and
	 * (best-effort) from `application.mappings`. Used to unwind partial
	 * progress when a multi-entry plural-mapping registration fails midway.
	 * Singular aliases store their identifier-form (e.g. `wheelsSentry`);
	 * plural aliases store their dotted form (e.g. `plugins.sentry`).
	 * `application.mappings` is keyed by slash-form (`/wheelsSentry`,
	 * `/plugins/sentry`) so we translate at the unregister site too.
	 */
	private void function $unregisterMappings(required array aliases) {
		for (local.alias in arguments.aliases) {
			if (!Len(local.alias)) {
				continue;
			}
			StructDelete(variables.packageMappings, local.alias);
			StructDelete(variables.$mappingProviders, local.alias);
			local.slashForm = "/" & Replace(local.alias, ".", "/", "all");
			try {
				if (StructKeyExists(application, "mappings") && IsStruct(application.mappings)) {
					StructDelete(application.mappings, local.slashForm);
				}
			} catch (any e) {
				// Engines without a writable application.mappings reach this
				// path through the same try/catch shape as the register side;
				// the in-process registries above remain authoritative.
			}
		}
	}

	/**
	 * Removes every trace of a package that was partially loaded before a
	 * post-instantiation failure (e.g. mapping collision). Keeps the loader's
	 * public registries internally consistent: a package in failedPackages
	 * never simultaneously appears in packages/packageMeta/lazyPackages or
	 * contributes mixins/services/middleware/mixinCollisions.
	 *
	 * Intentionally does NOT clean variables.packageMappings or
	 * variables.$mappingProviders: callers are responsible for unwinding
	 * those registries before reaching here. From $discover's catch
	 * (pre-mapping exception) nothing was ever written; from
	 * $tryRegisterPackageMapping's false path, $unregisterMappings has
	 * already cleaned both any partial plural entries and the singular
	 * alias. Adding cleanup here would mask a future caller that forgets
	 * to unwind.
	 */
	private void function $rollbackPackage(required string dirName) {
		StructDelete(variables.packageMeta, arguments.dirName);
		StructDelete(variables.packages, arguments.dirName);
		StructDelete(variables.lazyPackages, arguments.dirName);
		// Drop any mixins this package contributed to each target, plus the
		// matching method-provider entries so a later package can register the
		// same method without spurious collision warnings.
		for (local.target in variables.mixableComponents) {
			if (!StructKeyExists(variables.$methodProviders, local.target)) {
				continue;
			}
			local.methodNames = StructKeyArray(variables.$methodProviders[local.target]);
			for (local.methodName in local.methodNames) {
				if (variables.$methodProviders[local.target][local.methodName] == arguments.dirName) {
					StructDelete(variables.$methodProviders[local.target], local.methodName);
					if (StructKeyExists(variables.mixins, local.target)) {
						StructDelete(variables.mixins[local.target], local.methodName);
					}
				}
			}
		}
		// Drop any service-provider registration and middleware entries.
		local.svcIdx = ArrayFind(variables.serviceProviders, arguments.dirName);
		if (local.svcIdx > 0) {
			ArrayDeleteAt(variables.serviceProviders, local.svcIdx);
		}
		for (local.i = ArrayLen(variables.packageMiddleware); local.i >= 1; local.i--) {
			if (variables.packageMiddleware[local.i].packageName == arguments.dirName) {
				ArrayDeleteAt(variables.packageMiddleware, local.i);
			}
		}
		// Drop any mixin-collision diagnostic records that reference this
		// package — getMixinCollisions() is a public API and a stale entry
		// describing a method collision against a package no longer loaded
		// would mislead a consumer reading both getFailedPackages() and
		// getMixinCollisions(). Walk in reverse so ArrayDeleteAt is safe.
		for (local.i = ArrayLen(variables.mixinCollisions); local.i >= 1; local.i--) {
			local.entry = variables.mixinCollisions[local.i];
			if (local.entry.firstProvider == arguments.dirName
				|| local.entry.secondProvider == arguments.dirName) {
				ArrayDeleteAt(variables.mixinCollisions, local.i);
			}
		}
	}

	/**
	 * Instantiates a package CFC and collects its mixins/services/middleware.
	 */
	private void function $instantiatePackage(
		required string dirName,
		required string pkgDir,
		required string mixinTargets,
		required struct provides
	) {
		// Find the main CFC: convention is directory name matches CFC name
		local.cfcName = arguments.dirName;
		local.cfcPath = arguments.pkgDir & "/" & local.cfcName & ".cfc";
		if (!FileExists(local.cfcPath)) {
			// Fallback: find first CFC in directory
			local.cfcFiles = DirectoryList(arguments.pkgDir, false, "name", "*.cfc");
			if (ArrayLen(local.cfcFiles) == 0) {
				Throw(
					type = "Wheels.PackageNoCFC",
					message = "Package '#arguments.dirName#' has no CFC files"
				);
			}
			local.cfcName = Replace(local.cfcFiles[1], ".cfc", "");
		}

		// Instantiate the package CFC
		local.componentPath = "#variables.componentPrefix#.#arguments.dirName#.#local.cfcName#";
		local.pkg = CreateObject("component", local.componentPath).init();
		variables.packages[arguments.dirName] = local.pkg;

		// Check for ServiceProviderInterface
		if ($isServiceProvider(local.pkg)) {
			ArrayAppend(variables.serviceProviders, arguments.dirName);
		}

		// Collect middleware from manifest
		if (StructKeyExists(arguments.provides, "middleware") && IsArray(arguments.provides.middleware)) {
			for (local.mw in arguments.provides.middleware) {
				local.options = StructKeyExists(local.mw, "options") ? local.mw.options : {};
				ArrayAppend(variables.packageMiddleware, {
					middleware = local.mw.component,
					options = local.options,
					packageName = arguments.dirName
				});
			}
		}

		// Collect mixins if targets declared
		if (arguments.mixinTargets != "none") {
			local.overrides = $resolveOverrides(arguments.provides);
			$collectMixins(arguments.dirName, local.pkg, arguments.mixinTargets, local.overrides);
		}

		// Log success
		WriteLog(
			text = "[Wheels] Package '#arguments.dirName#' v#variables.packageMeta[arguments.dirName].version# loaded (#arguments.mixinTargets# mixins)",
			type = "information",
			file = "wheels"
		);
	}

	/**
	 * Instantiates a lazy package on first access.
	 */
	private void function $instantiateLazyPackage(required string dirName) {
		if (!StructKeyExists(variables.lazyPackages, arguments.dirName)) {
			return;
		}

		local.info = variables.lazyPackages[arguments.dirName];

		local.provides = {};
		if (StructKeyExists(local.info.manifest, "provides")) {
			local.provides = local.info.manifest.provides;
		}

		$instantiatePackage(
			dirName = arguments.dirName,
			pkgDir = local.info.pkgDir,
			mixinTargets = local.info.mixinTargets,
			provides = local.provides
		);

		// Remove from lazy registry
		StructDelete(variables.lazyPackages, arguments.dirName);

		WriteLog(
			text = "[Wheels] Lazy package '#arguments.dirName#' instantiated on demand",
			type = "information",
			file = "wheels"
		);
	}

	/**
	 * Collects public methods from a package CFC and assigns them to mixin targets.
	 * Follows the same pattern as Plugins.cfc $processMixins() but also records
	 * collisions when two packages register the same method for the same target.
	 *
	 * @overrides Lowercase-keyed struct of method names the package deliberately
	 *            overrides (from manifest provides.overrides). Suppresses the
	 *            warning log but still records the collision as `acknowledged`.
	 */
	private void function $collectMixins(
		required string pkgName,
		required any pkg,
		required string mixinTargets,
		struct overrides = {}
	) {
		local.methods = StructKeyList(arguments.pkg);
		local.lifecycleHooks = "init,onPluginLoad,onPluginActivate,register,boot";

		// Validation pre-pass: reject per-method mixin metadata with unknown
		// targets BEFORE mutating variables.mixins. Without this, a typo on
		// method N would silently produce zero injection (see #2257) and —
		// worse — methods 1..N-1 would already be registered when we threw
		// mid-loop, leaving the package half-loaded.
		for (local.methodName in local.methods) {
			if (!IsCustomFunction(arguments.pkg[local.methodName])) {
				continue;
			}
			if (ListFindNoCase(local.lifecycleHooks, local.methodName)) {
				continue;
			}
			local.methodMeta = GetMetadata(arguments.pkg[local.methodName]);
			if (StructKeyExists(local.methodMeta, "mixin")) {
				$validateMixinTargets(arguments.pkgName, local.methodMeta.mixin, local.methodName);
			}
		}

		for (local.methodName in local.methods) {
			if (!IsCustomFunction(arguments.pkg[local.methodName])) {
				continue;
			}
			if (ListFindNoCase(local.lifecycleHooks, local.methodName)) {
				continue;
			}

			// Check for per-method mixin override via metadata
			local.methodMeta = GetMetadata(arguments.pkg[local.methodName]);
			local.effectiveTargets = arguments.mixinTargets;
			if (StructKeyExists(local.methodMeta, "mixin")) {
				local.effectiveTargets = local.methodMeta.mixin;
			}

			if (local.effectiveTargets == "none") {
				continue;
			}

			for (local.target in variables.mixableComponents) {
				if (local.effectiveTargets == "global" || ListFindNoCase(local.effectiveTargets, local.target)) {
					// Collision check: another package already registered this method
					// for this target. Record it and keep the later registration
					// (current StructAppend-based merge semantics) so behaviour is
					// unchanged, but make the overwrite visible.
					if (StructKeyExists(variables.$methodProviders[local.target], local.methodName)) {
						local.firstProvider = variables.$methodProviders[local.target][local.methodName];
						local.acknowledged = StructKeyExists(arguments.overrides, LCase(local.methodName));
						$recordCollision(
							target = local.target,
							method = local.methodName,
							firstProvider = local.firstProvider,
							secondProvider = arguments.pkgName,
							acknowledged = local.acknowledged
						);
					}
					variables.mixins[local.target][local.methodName] = arguments.pkg[local.methodName];
					variables.$methodProviders[local.target][local.methodName] = arguments.pkgName;
				}
			}
		}
	}

	/**
	 * Records a mixin collision and emits a warning log unless the overwriting
	 * package explicitly acknowledged the override via provides.overrides.
	 */
	private void function $recordCollision(
		required string target,
		required string method,
		required string firstProvider,
		required string secondProvider,
		required boolean acknowledged
	) {
		ArrayAppend(variables.mixinCollisions, {
			target = arguments.target,
			method = arguments.method,
			firstProvider = arguments.firstProvider,
			secondProvider = arguments.secondProvider,
			acknowledged = arguments.acknowledged,
			source = "package"
		});

		if (arguments.acknowledged) {
			WriteLog(
				type = "information",
				text = "[Wheels] Package '#arguments.secondProvider#' intentionally overrides method '#arguments.method#' on target '#arguments.target#' (previously provided by '#arguments.firstProvider#')",
				file = "wheels"
			);
		} else {
			WriteLog(
				type = "warning",
				text = "[Wheels] Mixin collision: method '#arguments.method#' on target '#arguments.target#' provided by package '#arguments.firstProvider#' is being overwritten by package '#arguments.secondProvider#'. Declare the method in the overwriting package's provides.overrides to acknowledge this.",
				file = "wheels"
			);
		}
	}

	/**
	 * Normalises provides.overrides into a lowercase-keyed struct for O(1) lookup.
	 * Accepts an array of method names; any other shape is ignored.
	 */
	private struct function $resolveOverrides(required struct provides) {
		local.result = {};
		if (!StructKeyExists(arguments.provides, "overrides")) {
			return local.result;
		}
		if (IsArray(arguments.provides.overrides)) {
			for (local.name in arguments.provides.overrides) {
				if (IsSimpleValue(local.name) && Len(Trim(local.name))) {
					local.result[LCase(Trim(local.name))] = true;
				}
			}
		}
		return local.result;
	}

	// ---------------------------------------------------------------------------
	// Manifest Parsing
	// ---------------------------------------------------------------------------

	/**
	 * Parses and validates a package.json manifest.
	 * Throws on invalid JSON or missing required fields.
	 */
	private struct function $parseManifest(required string manifestPath) {
		local.raw = FileRead(arguments.manifestPath);
		local.manifest = DeserializeJSON(local.raw);

		if (!IsStruct(local.manifest)) {
			Throw(type = "Wheels.PackageInvalidManifest", message = "package.json must be a JSON object");
		}

		// Validate required fields
		if (!StructKeyExists(local.manifest, "name") || !Len(Trim(local.manifest.name))) {
			Throw(type = "Wheels.PackageInvalidManifest", message = "package.json missing required field: name");
		}
		if (!StructKeyExists(local.manifest, "version") || !Len(Trim(local.manifest.version))) {
			Throw(type = "Wheels.PackageInvalidManifest", message = "package.json missing required field: version");
		}

		return local.manifest;
	}

	// ---------------------------------------------------------------------------
	// ServiceProvider Support
	// ---------------------------------------------------------------------------

	/**
	 * Checks whether a package implements ServiceProviderInterface.
	 */
	private boolean function $isServiceProvider(required any pkg) {
		local.meta = GetMetadata(arguments.pkg);
		return StructKeyExists(local.meta, "implements")
			&& IsStruct(local.meta.implements)
			&& StructKeyExists(local.meta.implements, "wheels.ServiceProviderInterface");
	}

	/**
	 * Invokes register(container) on all packages that implement ServiceProviderInterface.
	 * Also triggers instantiation of lazy ServiceProvider packages.
	 *
	 * Each provider is invoked with the same per-package error isolation the
	 * loader applies everywhere else: a throwing register() is logged, recorded
	 * in failedPackages, and rolled back via $rollbackPackage — which also
	 * removes the key from variables.serviceProviders so the boot phase skips
	 * it — and the remaining providers still run. Mixins/middleware this
	 * package contributed are unwound from the loader registries by the
	 * rollback, but copies already merged into the application scope by
	 * Global.cfc::$loadPackages are intentionally NOT unwound here: that merge
	 * happens before this lifecycle invoke.
	 */
	public void function $invokeServiceProviderRegister(required any container) {
		// Iterate a snapshot: $rollbackPackage deletes from
		// variables.serviceProviders, and mutating the array mid-iteration
		// would skip the provider after a failing one.
		local.providerKeys = Duplicate(variables.serviceProviders);
		for (local.pkgKey in local.providerKeys) {
			try {
				variables.packages[local.pkgKey].register(arguments.container);
			} catch (any e) {
				WriteLog(
					text = "[Wheels] Package '#local.pkgKey#' ServiceProvider register() failed: #e.message#",
					type = "error",
					file = "wheels"
				);
				ArrayAppend(variables.failedPackages, {
					name = local.pkgKey,
					error = "ServiceProvider register() failed: " & e.message,
					detail = StructKeyExists(e, "detail") ? e.detail : ""
				});
				$rollbackPackage(local.pkgKey);
			}
		}
	}

	/**
	 * Invokes boot(app) on all packages that implement ServiceProviderInterface.
	 *
	 * Same per-provider isolation as $invokeServiceProviderRegister: a throwing
	 * boot() is logged, recorded in failedPackages, and rolled back so the
	 * remaining providers still boot. Services the failing provider already
	 * registered in the DI container during register() cannot be unwound — the
	 * Injector has no per-package tracking.
	 */
	public void function $invokeServiceProviderBoot(required struct app) {
		// Iterate a snapshot: $rollbackPackage deletes from variables.serviceProviders.
		local.providerKeys = Duplicate(variables.serviceProviders);
		for (local.pkgKey in local.providerKeys) {
			try {
				variables.packages[local.pkgKey].boot(arguments.app);
			} catch (any e) {
				WriteLog(
					text = "[Wheels] Package '#local.pkgKey#' ServiceProvider boot() failed: #e.message#",
					type = "error",
					file = "wheels"
				);
				ArrayAppend(variables.failedPackages, {
					name = local.pkgKey,
					error = "ServiceProvider boot() failed: " & e.message,
					detail = StructKeyExists(e, "detail") ? e.detail : ""
				});
				$rollbackPackage(local.pkgKey);
			}
		}
	}

	// ---------------------------------------------------------------------------
	// Mixin target validation
	// ---------------------------------------------------------------------------

	/**
	 * Validates each declared mixin target against the known allowlist.
	 * Accepts the special values "none" (explicit opt-out) and "global" (wildcard);
	 * every other entry must match one of variables.mixableComponents. An unknown
	 * entry (typo like "controler", or an unsupported target like "view") throws
	 * so the package is recorded as failed instead of silently loading with zero
	 * mixin injection.
	 *
	 * @pkgName     Package directory name, used in the error message
	 * @targets     Raw mixin-target declaration from the manifest or per-method metadata
	 * @methodName  Optional method name for per-method overrides; included in the
	 *              error message so callers can locate the offending declaration
	 */
	private void function $validateMixinTargets(
		required string pkgName,
		required string targets,
		string methodName = ""
	) {
		local.normalized = LCase(Trim(arguments.targets));
		if (!Len(local.normalized) || local.normalized == "none" || local.normalized == "global") {
			return;
		}
		for (local.target in local.normalized) {
			local.entry = Trim(local.target);
			if (!Len(local.entry)) {
				continue;
			}
			if (!ListFindNoCase(variables.mixableComponents, local.entry)) {
				local.context = Len(arguments.methodName) ? " method '#arguments.methodName#'" : "";
				Throw(
					type = "Wheels.PackageInvalidMixinTarget",
					message = "Package '#arguments.pkgName#'#local.context# declares unknown mixin target '#local.entry#'. Valid targets: #variables.mixableComponents#."
				);
			}
		}
	}

	// ---------------------------------------------------------------------------
	// Per-package CFML mapping (GH#2712)
	// ---------------------------------------------------------------------------

	/**
	 * Derives a CFML-identifier-safe alias from a package manifest. If the
	 * manifest declares an explicit `mapping` field — even an empty/whitespace
	 * one — that field takes precedence and must satisfy the documented
	 * `[A-Za-z_][A-Za-z0-9_]*` invariant. An empty string or whitespace-only
	 * value is treated as an explicit (invalid) override rather than silently
	 * falling through to `name`-based auto-derivation, matching the field's
	 * documented contract. When `mapping` is absent the alias is built from
	 * the manifest `name` by splitting on hyphens/underscores and
	 * lower-camel-casing the segments (`wheels-sentry` → `wheelsSentry`,
	 * `wheels_legacy_adapter` → `wheelsLegacyAdapter`). Returns an empty
	 * string if no valid alias can be derived — caller treats that as failure.
	 *
	 * @manifest Parsed package.json struct
	 * @dirName  Package directory name. Unreachable defensive fallback when
	 *           $parseManifest's `name`-required check is bypassed (e.g. a
	 *           direct caller of this private helper); kept so $deriveMapping
	 *           never has to crash on a malformed struct in isolation.
	 */
	private string function $deriveMapping(required struct manifest, required string dirName) {
		// Explicit override takes precedence. Presence of the field — even if
		// empty or whitespace — signals the author's intent to set the alias
		// directly, so we validate it against the documented regex and refuse
		// to fall back to name-based auto-derivation on an invalid value.
		if (StructKeyExists(arguments.manifest, "mapping") && IsSimpleValue(arguments.manifest.mapping)) {
			local.override = Trim(arguments.manifest.mapping);
			if (Len(local.override) && REFind("^[A-Za-z_][A-Za-z0-9_]*$", local.override)) {
				return local.override;
			}
			// Invalid override → return empty so caller records the failure
			// with a specific error message.
			return "";
		}

		local.source = StructKeyExists(arguments.manifest, "name") && IsSimpleValue(arguments.manifest.name) && Len(Trim(arguments.manifest.name))
			? Trim(arguments.manifest.name)
			: arguments.dirName;

		local.segments = ListToArray(local.source, "-_");
		if (!ArrayLen(local.segments)) {
			return "";
		}

		local.alias = LCase(local.segments[1]);
		for (local.i = 2; local.i <= ArrayLen(local.segments); local.i++) {
			local.seg = local.segments[local.i];
			if (!Len(local.seg)) {
				continue;
			}
			local.alias &= UCase(Left(local.seg, 1)) & LCase(Mid(local.seg, 2, Len(local.seg)));
		}

		// Strip any character outside [A-Za-z0-9_] that snuck through (e.g.
		// numeric-only segments are fine, but leading digit must be guarded).
		if (!REFind("^[A-Za-z_][A-Za-z0-9_]*$", local.alias)) {
			return "";
		}
		return local.alias;
	}

	/**
	 * Registers a per-package CFML mapping for the given package. Records
	 * the alias → pkgDir entry in `variables.packageMappings`, tracks the
	 * first claimant in `variables.$mappingProviders` for collision detection,
	 * and (best-effort) reflects the entry into `application.mappings` so the
	 * static `new <alias>.Sibling()` form resolves at runtime.
	 *
	 * Returns `{ok: boolean, error: string, detail: string, alias: string}`.
	 * The caller records a failed package when `ok` is false.
	 */
	private struct function $registerPackageMapping(
		required string dirName,
		required struct manifest,
		required string pkgDir
	) {
		local.alias = $deriveMapping(arguments.manifest, arguments.dirName);
		if (!Len(local.alias)) {
			local.declared = StructKeyExists(arguments.manifest, "mapping") && IsSimpleValue(arguments.manifest.mapping)
				? Trim(arguments.manifest.mapping)
				: "";
			return {
				ok = false,
				error = "Invalid package mapping alias",
				detail = "Package '#arguments.dirName#' did not yield a valid CFML identifier from manifest 'mapping' (#local.declared#) or 'name'. Aliases must match [A-Za-z_][A-Za-z0-9_]*.",
				alias = ""
			};
		}

		if (StructKeyExists(variables.$mappingProviders, local.alias)) {
			local.firstProvider = variables.$mappingProviders[local.alias];
			return {
				ok = false,
				error = "Duplicate package mapping alias",
				detail = "Package '#arguments.dirName#' computes alias '#local.alias#' which is already claimed by package '#local.firstProvider#'. Set a unique 'mapping' value in package.json to resolve.",
				alias = local.alias
			};
		}

		variables.packageMappings[local.alias] = arguments.pkgDir;
		variables.$mappingProviders[local.alias] = arguments.dirName;

		// Reflect into application.mappings when available so packages can
		// reference siblings as `new <alias>.Sibling()`. Wrapped defensively:
		// not every embedding context has a writable application scope (e.g.
		// some testing harnesses), and the in-process `packageMappings`
		// registry is the authoritative record either way.
		try {
			if (StructKeyExists(application, "mappings") && IsStruct(application.mappings)) {
				application.mappings["/" & local.alias] = arguments.pkgDir;
			}
		} catch (any e) {
			WriteLog(
				text = "[Wheels] Package '#arguments.dirName#' could not register application mapping '/#local.alias#': #e.message#",
				type = "warning",
				file = "wheels"
			);
		}

		return {ok = true, error = "", detail = "", alias = local.alias};
	}

	/**
	 * Registers the package's plural `mappings` block — a struct of
	 * dotted-CFML-mapping-name → relative-path-from-pkgDir entries. Lets a
	 * package author claim additional namespaces beyond the singular
	 * identifier-form alias (e.g. `plugins.sentry` for legacy compatibility,
	 * or namespaces pointing at internal subdirectories).
	 *
	 * Each key must be a dotted identifier where every segment matches
	 * `[A-Za-z_][A-Za-z0-9_]*` so the resulting `application.mappings`
	 * slash-form (`/plugins/sentry`) is resolvable by `new plugins.sentry.X()`
	 * dotted lookups on every CFML engine.
	 *
	 * Each value is a relative path inside the package directory: `"."` or
	 * `""` means the package root; `"subdir"` resolves to `pkgDir/subdir`.
	 * Absolute paths and `..` traversal are rejected so a package can't
	 * register a mapping pointing outside its own install tree.
	 *
	 * Returns `{ok, error, detail, registered}` where `registered` lists the
	 * mapping names actually written so the caller can unwind on later
	 * failure. The struct shape mirrors `$registerPackageMapping` so both
	 * registration paths plug into the same failedPackages bookkeeping.
	 */
	private struct function $registerAdditionalMappings(
		required string dirName,
		required struct manifest,
		required string pkgDir
	) {
		local.result = {ok = true, error = "", detail = "", registered = []};

		if (!StructKeyExists(arguments.manifest, "mappings")) {
			return local.result;
		}
		if (!IsStruct(arguments.manifest.mappings)) {
			local.result.ok = false;
			local.result.error = "Invalid package mappings block";
			local.result.detail = "Package '#arguments.dirName#' declared a 'mappings' field that is not a struct. Expected a map of dotted mapping name to relative path.";
			return local.result;
		}

		// StructKeyArray returns keys in iteration order; tests assert
		// failure on the *first* invalid entry by author-declared name so a
		// stable iteration is necessary. Lucee/Adobe/BoxLang all preserve
		// insertion order for struct literals parsed from JSON.
		local.entries = StructKeyArray(arguments.manifest.mappings);
		for (local.name in local.entries) {
			local.value = arguments.manifest.mappings[local.name];

			if (!IsSimpleValue(local.value)) {
				local.result.ok = false;
				local.result.error = "Invalid package mapping path";
				local.result.detail = "Package '#arguments.dirName#' mapping '#local.name#' must be a string path relative to the package directory.";
				return local.result;
			}

			local.validation = $validatePluralMappingName(local.name);
			if (!local.validation.ok) {
				local.result.ok = false;
				local.result.error = "Invalid package mapping name";
				local.result.detail = "Package '#arguments.dirName#' mapping '#local.name#': #local.validation.detail#";
				return local.result;
			}

			local.resolution = $resolvePluralMappingPath(arguments.pkgDir, Trim(local.value));
			if (!local.resolution.ok) {
				local.result.ok = false;
				local.result.error = "Invalid package mapping path";
				local.result.detail = "Package '#arguments.dirName#' mapping '#local.name#' → '#local.value#': #local.resolution.detail#";
				return local.result;
			}

			if (StructKeyExists(variables.$mappingProviders, local.name)) {
				local.firstProvider = variables.$mappingProviders[local.name];
				local.result.ok = false;
				local.result.error = "Duplicate package mapping alias";
				local.result.detail = "Package '#arguments.dirName#' mapping '#local.name#' is already claimed by package '#local.firstProvider#'. Choose a unique mapping name in package.json to resolve.";
				return local.result;
			}

			variables.packageMappings[local.name] = local.resolution.path;
			variables.$mappingProviders[local.name] = arguments.dirName;
			ArrayAppend(local.result.registered, local.name);

			local.slashForm = "/" & Replace(local.name, ".", "/", "all");
			try {
				if (StructKeyExists(application, "mappings") && IsStruct(application.mappings)) {
					application.mappings[local.slashForm] = local.resolution.path;
				}
			} catch (any e) {
				WriteLog(
					text = "[Wheels] Package '#arguments.dirName#' could not register application mapping '#local.slashForm#': #e.message#",
					type = "warning",
					file = "wheels"
				);
			}
		}

		return local.result;
	}

	/**
	 * Validates a dotted plural-mapping name. Each segment must match the
	 * CFML identifier regex so the resulting `/seg1/seg2/...` form resolves
	 * cleanly via static-dotted `new` syntax. Leading/trailing dots and
	 * consecutive dots produce empty segments which the segment regex
	 * rejects. Returns `{ok, detail}`.
	 */
	private struct function $validatePluralMappingName(required string name) {
		local.trimmed = Trim(arguments.name);
		if (!Len(local.trimmed)) {
			return {ok = false, detail = "mapping name must not be empty"};
		}
		if (Left(local.trimmed, 1) == "." || Right(local.trimmed, 1) == ".") {
			return {ok = false, detail = "mapping name must not start or end with '.'"};
		}
		local.segments = ListToArray(local.trimmed, ".");
		if (!ArrayLen(local.segments)) {
			return {ok = false, detail = "mapping name produced no segments"};
		}
		for (local.seg in local.segments) {
			if (!Len(local.seg) || !REFind("^[A-Za-z_][A-Za-z0-9_]*$", local.seg)) {
				return {ok = false, detail = "segment '#local.seg#' must match [A-Za-z_][A-Za-z0-9_]*"};
			}
		}
		return {ok = true, detail = ""};
	}

	/**
	 * Resolves a relative mapping path against the package directory.
	 * `"."` and `""` resolve to the package directory itself. Subdirectory
	 * paths are appended with a single separator. Absolute paths (`/foo`,
	 * `C:\foo`) and any `..` traversal segment are rejected so a package
	 * cannot register a mapping pointing outside its install tree.
	 * Returns `{ok, path, detail}`.
	 */
	private struct function $resolvePluralMappingPath(required string pkgDir, required string relPath) {
		local.norm = Replace(arguments.relPath, "\", "/", "all");
		if (!Len(local.norm) || local.norm == ".") {
			return {ok = true, path = arguments.pkgDir, detail = ""};
		}
		if (Left(local.norm, 1) == "/") {
			return {ok = false, path = "", detail = "absolute paths are not allowed"};
		}
		if (REFind("^[A-Za-z]:", local.norm)) {
			return {ok = false, path = "", detail = "absolute paths are not allowed"};
		}
		// Strip a leading "./" before scanning for traversal so authors can
		// write `./subdir` interchangeably with `subdir`. A bare `./` collapses
		// to the package root once the prefix is stripped.
		if (Left(local.norm, 2) == "./") {
			local.norm = Len(local.norm) > 2 ? Mid(local.norm, 3, Len(local.norm) - 2) : "";
			if (!Len(local.norm)) {
				return {ok = true, path = arguments.pkgDir, detail = ""};
			}
		}
		local.segments = ListToArray(local.norm, "/");
		for (local.seg in local.segments) {
			if (local.seg == "..") {
				return {ok = false, path = "", detail = "'..' traversal is not allowed"};
			}
		}
		return {ok = true, path = arguments.pkgDir & "/" & local.norm, detail = ""};
	}

	// ---------------------------------------------------------------------------
	// wheelsVersion compatibility
	// ---------------------------------------------------------------------------

	/**
	 * Returns the runtime Wheels version normalised for semver comparison.
	 * Dev builds surface as "0.0.0-dev" via BuildInfo. The legacy
	 * "@build.version@" check is kept as a defensive guard for any path that
	 * still feeds the raw placeholder in. Both normalise to "0.0.0" so strict
	 * version constraints don't falsely reject packages during development.
	 */
	private string function $normalizeWheelsVersion() {
		local.raw = SpanExcluding(variables.wheelsVersion, " ");
		if (local.raw == "@build.version@" || local.raw == "0.0.0-dev") {
			return "0.0.0";
		}
		return local.raw;
	}

	/**
	 * Validates a package manifest's wheelsVersion constraint against the
	 * running Wheels version. Packages that omit the field, use "*", or are
	 * evaluated against a dev-stamp runtime always pass — a strict constraint
	 * in that case would break `wheels test run` on unbuilt checkouts.
	 *
	 * @manifest Parsed package.json struct
	 * @return True if the package is compatible with the running Wheels version
	 */
	private boolean function $isCompatibleVersion(required struct manifest) {
		if (!StructKeyExists(arguments.manifest, "wheelsVersion")
			|| !IsSimpleValue(arguments.manifest.wheelsVersion)) {
			return true;
		}
		local.constraint = Trim(arguments.manifest.wheelsVersion);
		if (!Len(local.constraint) || local.constraint == "*") {
			return true;
		}
		local.runtime = $normalizeWheelsVersion();
		// Unstamped dev build or caller that didn't pass a runtime version:
		// skip enforcement so local dev and embedding callers don't break.
		if (!Len(local.runtime) || local.runtime == "0.0.0") {
			return true;
		}
		local.semver = CreateObject("component", "wheels.SemVer");
		return local.semver.satisfiesAll(local.runtime, local.constraint);
	}

}
