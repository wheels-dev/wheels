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
	 * Returns mixin collision records — cases where a package registered a
	 * method name for a target that another package had already claimed.
	 * Each entry: {target, method, firstProvider, secondProvider, acknowledged}.
	 * An `acknowledged` true means the overwriting package declared the method
	 * in its `provides.overrides` list, which suppresses the warning log.
	 */
	public array function getMixinCollisions() {
		return variables.mixinCollisions;
	}

	/**
	 * Returns the per-target method→package-name mapping built during mixin
	 * collection. Used by $loadPackages to name the package side of a
	 * cross-system collision with a legacy plugin.
	 */
	public struct function $methodProviders() {
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
				file = "application"
			);
		}

		// Log excluded (replaced) packages
		for (local.dirName in local.resolution.excluded) {
			WriteLog(
				text = "[Wheels] Package '#local.dirName#' excluded: #local.resolution.excluded[local.dirName]#",
				type = "information",
				file = "application"
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
					file = "application"
				);
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
					file = "application"
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
				file = "application"
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
			// Store lazy package info — CFC will be instantiated on first access
			variables.lazyPackages[arguments.dirName] = {
				dirName = arguments.dirName,
				pkgDir = arguments.pkgDir,
				mixinTargets = local.mixinTargets,
				manifest = local.manifest
			};
			WriteLog(
				text = "[Wheels] Package '#arguments.dirName#' v#variables.packageMeta[arguments.dirName].version# registered (lazy)",
				type = "information",
				file = "application"
			);
			return;
		}

		try {
			WriteLog(
				text = "[Wheels] Loading package '##arguments.dirName##' from ##arguments.pkgDir##",
				type = "information",
				file = "wheels_security"
			);
		} catch (any e) {}

		// Eager loading: instantiate CFC now
		$instantiatePackage(arguments.dirName, arguments.pkgDir, local.mixinTargets, local.provides);
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
			file = "application"
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
			file = "application"
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
				file = "application"
			);
		} else {
			WriteLog(
				type = "warning",
				text = "[Wheels] Mixin collision: method '#arguments.method#' on target '#arguments.target#' provided by package '#arguments.firstProvider#' is being overwritten by package '#arguments.secondProvider#'. Declare the method in the overwriting package's provides.overrides to acknowledge this.",
				file = "application"
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
	 */
	public void function $invokeServiceProviderRegister(required any container) {
		for (local.pkgKey in variables.serviceProviders) {
			variables.packages[local.pkgKey].register(arguments.container);
		}
	}

	/**
	 * Invokes boot(app) on all packages that implement ServiceProviderInterface.
	 */
	public void function $invokeServiceProviderBoot(required struct app) {
		for (local.pkgKey in variables.serviceProviders) {
			variables.packages[local.pkgKey].boot(arguments.app);
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
	 * @pkgName  Package directory name, used in the error message
	 * @targets  Raw mixin-target declaration from the manifest
	 */
	private void function $validateMixinTargets(required string pkgName, required string targets) {
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
				Throw(
					type = "Wheels.PackageInvalidMixinTarget",
					message = "Package '#arguments.pkgName#' declares unknown mixin target '#local.entry#'. Valid targets: #variables.mixableComponents#."
				);
			}
		}
	}

	// ---------------------------------------------------------------------------
	// wheelsVersion compatibility
	// ---------------------------------------------------------------------------

	/**
	 * Returns the runtime Wheels version normalised for semver comparison.
	 * Dev builds ship the unresolved "@build.version@" token — treat as 0.0.0
	 * so strict constraints don't falsely reject packages during development.
	 */
	private string function $normalizeWheelsVersion() {
		local.raw = SpanExcluding(variables.wheelsVersion, " ");
		return (local.raw == "@build.version@") ? "0.0.0" : local.raw;
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
