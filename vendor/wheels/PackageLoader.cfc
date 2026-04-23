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

		// The same mixin targets as Plugins.cfc
		variables.mixableComponents = "application,dispatch,controller,mapper,model,base,sqlserver,mysql,postgresql,h2,test";

		// Initialize mixin containers
		for (local.target in variables.mixableComponents) {
			variables.mixins[local.target] = {};
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

		if (StructKeyExists(local.manifest, "checksums") && IsStruct(local.manifest.checksums)) {
			local.checksumFailed = false;
			for (local.cfcFile in local.manifest.checksums) {
				local.expectedHash = local.manifest.checksums[local.cfcFile];
				local.cfcFilePath = arguments.pkgDir & "/" & local.cfcFile;
				if (FileExists(local.cfcFilePath)) {
					local.actualHash = Hash(FileRead(local.cfcFilePath), "SHA-256");
					if (CompareNoCase(local.actualHash, local.expectedHash) != 0) {
						try {
							WriteLog(
								text = "[Wheels] SECURITY WARNING: Checksum mismatch for ##local.cfcFile## in package '##arguments.dirName##'. Expected: ##local.expectedHash##, Got: ##local.actualHash##",
								type = "warning",
								file = "wheels_security"
							);
						} catch (any e) {}
						local.checksumFailed = true;
					}
				}
			}
			if (local.checksumFailed) {
				ArrayAppend(variables.failedPackages, {
					name = arguments.dirName,
					error = "Checksum verification failed",
					detail = "One or more CFC files did not match declared checksums in package.json"
				});
				return;
			}
		}

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
			$collectMixins(arguments.dirName, local.pkg, arguments.mixinTargets);
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
	 * Follows the same pattern as Plugins.cfc $processMixins().
	 */
	private void function $collectMixins(
		required string pkgName,
		required any pkg,
		required string mixinTargets
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
					variables.mixins[local.target][local.methodName] = arguments.pkg[local.methodName];
				}
			}
		}
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
