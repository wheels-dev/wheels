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
		string wheelsEnvironment = "production"
	) {
		variables.vendorPath = arguments.vendorPath;
		variables.wheelsVersion = arguments.wheelsVersion;
		variables.wheelsEnvironment = arguments.wheelsEnvironment;
		variables.packages = {};
		variables.packageMeta = {};
		variables.mixins = {};
		variables.serviceProviders = [];
		variables.packageMiddleware = [];
		variables.failedPackages = [];

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

	// ---------------------------------------------------------------------------
	// Discovery & Loading
	// ---------------------------------------------------------------------------

	/**
	 * Scans vendor/ for directories containing package.json (excluding vendor/wheels/).
	 * Each package loads in its own try/catch for error isolation.
	 */
	private void function $discover() {
		if (!DirectoryExists(variables.vendorPath)) {
			return;
		}

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

			// Load this package with error isolation
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
	 * Loads a single package: validates manifest, instantiates CFC, collects mixins/services/middleware.
	 */
	private void function $loadPackage(
		required string dirName,
		required string pkgDir,
		required string manifestPath
	) {
		// Parse and validate the manifest
		local.manifest = $parseManifest(arguments.manifestPath);

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
		local.componentPath = "vendor.#arguments.dirName#.#local.cfcName#";
		local.pkg = CreateObject("component", local.componentPath).init();
		variables.packages[arguments.dirName] = local.pkg;

		// Check for ServiceProviderInterface
		if ($isServiceProvider(local.pkg)) {
			ArrayAppend(variables.serviceProviders, arguments.dirName);
		}

		// Collect middleware from manifest
		if (StructKeyExists(local.provides, "middleware") && IsArray(local.provides.middleware)) {
			for (local.mw in local.provides.middleware) {
				local.options = StructKeyExists(local.mw, "options") ? local.mw.options : {};
				ArrayAppend(variables.packageMiddleware, {
					middleware = local.mw.component,
					options = local.options,
					packageName = arguments.dirName
				});
			}
		}

		// Collect mixins if targets declared
		if (local.mixinTargets != "none") {
			$collectMixins(arguments.dirName, local.pkg, local.mixinTargets);
		}

		// Log success
		WriteLog(
			text = "[Wheels] Package '#arguments.dirName#' v#variables.packageMeta[arguments.dirName].version# loaded (#local.mixinTargets# mixins)",
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

}
