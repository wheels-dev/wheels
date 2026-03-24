component output="false" extends="wheels.Global"{

	public any function $init(
		required string pluginPath,
		boolean deletePluginDirectories = application.wheels.deletePluginDirectories,
		boolean overwritePlugins = application.wheels.overwritePlugins,
		boolean loadIncompatiblePlugins = application.wheels.loadIncompatiblePlugins,
		string wheelsEnvironment = application.wheels.environment,
		string wheelsVersion = application.wheels.version
	) {
		variables.$class = {};
		variables.$class.plugins = {};
		variables.$class.pluginMeta = {};
		variables.$class.mixins = {};
		variables.$class.mixableComponents = "application,dispatch,controller,mapper,model,base,sqlserver,mysql,postgresql,h2,test";
		variables.$class.incompatiblePlugins = "";
		variables.$class.dependantPlugins = "";
		variables.$class.mixinCollisions = [];
		variables.$class.pluginMiddleware = [];
		variables.$class.serviceProviders = [];
		variables.$class.deprecationWarnings = [];
		variables.$class.versionMismatchPlugins = "";
		StructAppend(variables.$class, arguments);
		/* handle pathing for different operating systems */
		variables.$class.pluginPathFull = ReplaceNoCase(ExpandPath(variables.$class.pluginPath), "\", "/", "all");
		/* sort direction */
		variables.sort = "ASC";
		/* extract out plugins */
		$pluginsExtract();
		/* remove orphan plugin directories */
		if (variables.$class.deletePluginDirectories) {
			$pluginDelete();
		}
		/* process plugins */
		$pluginsProcess();
		/* get versions */
		$pluginMetaData();
		/* process mixins */
		$processMixins();
		/* dependencies */
		$determineDependency();
		return this;
	}

	public struct function $pluginFolders() {
		local.plugins = {};
		local.folders = $folders();
		// Within plugin folders, grab info about each plugin and package up into a struct.
		for (local.i = 1; i <= local.folders.recordCount; i++) {
			// For *nix, we need a case-sensitive name for the plugin component, so we must reference its CFC file name.
			local.subfolder = DirectoryList("#local.folders["directory"][i]#/#local.folders["name"][i]#", false, "query");
			local.pluginCfc = $query(
				dbtype = "query",
				query = local.subfolder,
				sql = "SELECT name FROM query WHERE LOWER(name) = '#LCase(local.folders["name"][i])#.cfc'"
			);
			local.temp = {};
			if (local.pluginCfc.recordCount > 0) {
				// Exact match: CFC name matches directory name (conventional plugins)
				local.temp.name = Replace(local.pluginCfc.name, ".cfc", "");
			} else {
				// Directory-based plugin discovery: the CFC name may not match the
				// directory name (e.g. git-cloned or symlinked plugins). Fall back
				// to the first CFC file found in the directory (GH#1978).
				local.cfcFiles = $query(
					dbtype = "query",
					query = local.subfolder,
					sql = "SELECT name FROM query WHERE LOWER(name) LIKE '%.cfc' ORDER BY name"
				);
				if (local.cfcFiles.recordCount > 0) {
					local.temp.name = Replace(local.cfcFiles.name, ".cfc", "");
				} else {
					// No CFC files found — not a valid plugin directory, skip it
					continue;
				}
			}
			local.temp.folderPath = $fullPathToPlugin(local.folders["name"][i]);
			local.temp.componentName = local.folders["name"][i] & "." & local.temp.name;
			local.plugins[local.folders["name"][i]] = local.temp;
		}
		return local.plugins;
	}

	public struct function $pluginFiles() {
		// get all plugin zip files
		local.plugins = {};
		local.files = $files();
		for (local.i = 1; i <= local.files.recordCount; i++) {
			local.name = ListFirst(local.files["name"][i], "-");
			local.temp = {};
			local.temp.file = $fullPathToPlugin(local.files["name"][i]);
			local.temp.name = local.files["name"][i];
			local.temp.folderPath = $fullPathToPlugin(LCase(local.name));
			if (StructKeyExists(server, "boxlang") && !local.temp.folderPath.startsWith("/")) {
				local.temp.folderPath = "/" & local.temp.folderPath;
			}
			local.temp.folderExists = DirectoryExists(local.temp.folderPath);
			local.plugins[local.name] = local.temp;
		};
		return local.plugins;
	}

	public void function $pluginsExtract() {
		// get all plugin zip files
		local.plugins = $pluginFiles();
		for (local.p in local.plugins) {
			local.plugin = local.plugins[local.p];
			if (!local.plugin.folderExists || (local.plugin.folderExists && variables.$class.overwritePlugins)) {
				if (!local.plugin.folderExists) {
					try {
						DirectoryCreate(local.plugin.folderPath);
					} catch (any e) {
						//
					}
				}
				$zip(action = "unzip", destination = local.plugin.folderPath, file = local.plugin.file, overwrite = true);
			}
		};
	}

	public void function $pluginDelete() {
		local.folders = $pluginFolders();
		// put zip files into a list
		local.files = $pluginFiles();
		local.fileList = StructKeyList(local.files);
		// loop through the plugin folders
		for (local.iFolder in local.folders) {
			local.folder = local.folders[local.iFolder];
			// Skip directories without a matching zip file — they may be
			// directory-based plugins (git-cloned, symlinked, or manually
			// installed) rather than orphaned zip extractions (GH#1978).
			if (!ListContainsNoCase(local.fileList, local.folder.name)) {
				continue;
			}
		};
	}

	public void function $pluginsProcess() {
		local.plugins = $pluginFolders();
		local.pluginKeys = ListSort(StructKeyList(local.plugins), "textnocase", variables.sort);
		if (SpanExcluding(variables.$class.wheelsVersion, " ") == "@build.version@") {
			local.wheelsVersion = "0.0.0";
		} else {
			local.wheelsVersion = SpanExcluding(variables.$class.wheelsVersion, " ");
		}
		for (local.pluginKey in local.pluginKeys) {
			local.pluginValue = local.plugins[local.pluginKey];
			local.plugin = CreateObject("component", $componentPathToPlugin(local.pluginKey, local.pluginValue.name)).init();
			if (
				!StructKeyExists(local.plugin, "version")
				|| ListFind(local.plugin.version, local.wheelsVersion)
				|| variables.$class.loadIncompatiblePlugins
			) {
				variables.$class.plugins[local.pluginKey] = local.plugin;
				// Call onPluginLoad lifecycle hook if defined
				if (StructKeyExists(local.plugin, "onPluginLoad") && IsCustomFunction(local.plugin.onPluginLoad)) {
					// Build a context struct (not the application scope itself) so that
					// registerMiddleware works on Adobe CF where application scope doesn't
					// support function members.
					local.loadContext = Duplicate(application);
					$installPluginLoadAPI(local.pluginKey, local.loadContext);
					local.plugin.onPluginLoad(local.loadContext);
					// Sync all non-function keys back to application scope.
					// The Duplicate creates a deep copy so unchanged structs are
					// written back identically (harmless). Closures injected by
					// $installPluginLoadAPI are skipped to keep application clean.
					for (local.contextKey in local.loadContext) {
						if (!IsCustomFunction(local.loadContext[local.contextKey])) {
							application[local.contextKey] = local.loadContext[local.contextKey];
						}
					}
				}
				// Track plugins that implement ServiceProviderInterface
				if ($isServiceProvider(local.plugin)) {
					ArrayAppend(variables.$class.serviceProviders, local.pluginKey);
				}
				// In development mode, warn about mixin-only plugins that lack modern manifests
				if (
					variables.$class.wheelsEnvironment == "development"
					&& !$isServiceProvider(local.plugin)
					&& !$hasPluginManifest(local.pluginKey)
				) {
					local.warning = 'Plugin "#local.pluginKey#" uses legacy mixin injection without a plugin.json manifest or ServiceProvider.cfc. Mixin-only plugins will be deprecated in Wheels 4.0. See: https://guides.cfwheels.org/docs/migrating-plugins-to-service-providers';
					ArrayAppend(variables.$class.deprecationWarnings, {
						plugin = local.pluginKey,
						message = local.warning
					});
					WriteLog(type="warning", text="[Wheels] #local.warning#");
				}
				// If plugin author has specified compatibility version as 2.0, only check against that major version
				// If they've specified 2.0.1, then be more specific
				if (StructKeyExists(local.plugin, "version")) {
					if (
						(ListLen(local.plugin.version, ".") > 2 && !ListFind(local.plugin.version, local.wheelsVersion))
						|| (
							ListLen(local.plugin.version, ".") == 2
							&& !ListFind(local.plugin.version, ListDeleteAt(local.wheelsVersion, 3, "."))
						)
					) {
						variables.$class.incompatiblePlugins = ListAppend(variables.$class.incompatiblePlugins, local.pluginKey);
					}
				}
			}
		};
	}

	/**
	 * Attempt to extract version numbers from box.json and/or corresponding .zip files.
	 * Also reads and validates plugin.json manifests when present.
	 * Storing box.json and manifest data for use by the plugin system.
	 */
	public void function $pluginMetaData() {
		for (local.plugin in variables.$class.plugins) {
			variables.$class.pluginMeta[local.plugin] = {"version" = "", "boxjson" = {}, "manifest" = {}, "dependencies" = {}};
			local.boxJsonLocation = $fullPathToPlugin(local.plugin & "/" & 'box.json');
			if (FileExists(local.boxJsonLocation)) {
				local.boxJson = DeserializeJSON(FileRead(local.boxJsonLocation));
				variables.$class.pluginMeta[local.plugin]["boxjson"] = local.boxJson;
				if (StructKeyExists(local.boxJson, "version")) {
					variables.$class.pluginMeta[local.plugin]["version"] = local.boxJson.version;
				}
				// box.json dependencies as fallback source for semver resolution
				if (StructKeyExists(local.boxJson, "dependencies") && IsStruct(local.boxJson.dependencies)) {
					StructAppend(variables.$class.pluginMeta[local.plugin]["dependencies"], local.boxJson.dependencies);
				}
			}
			// Read plugin.json manifest if present (takes precedence over box.json for version)
			local.manifestLocation = $fullPathToPlugin(local.plugin & "/" & "plugin.json");
			if (FileExists(local.manifestLocation)) {
				local.parsed = $parsePluginManifest(local.manifestLocation);
				if (local.parsed.valid) {
					variables.$class.pluginMeta[local.plugin]["manifest"] = local.parsed.manifest;
					// plugin.json version takes precedence over box.json version
					if (StructKeyExists(local.parsed.manifest, "version") && Len(local.parsed.manifest.version)) {
						variables.$class.pluginMeta[local.plugin]["version"] = local.parsed.manifest.version;
					}
					// plugin.json dependencies override box.json dependencies for semver resolution
					if (StructKeyExists(local.parsed.manifest, "dependencies")) {
						if (IsStruct(local.parsed.manifest.dependencies)) {
							variables.$class.pluginMeta[local.plugin]["dependencies"] = local.parsed.manifest.dependencies;
						} else if (IsArray(local.parsed.manifest.dependencies)) {
							// Convert array form ["PluginA","PluginB"] to struct form {"PluginA":"","PluginB":""}
							local.depStruct = {};
							for (local.depItem in local.parsed.manifest.dependencies) {
								local.depStruct[Trim(local.depItem)] = "";
							}
							variables.$class.pluginMeta[local.plugin]["dependencies"] = local.depStruct;
						}
					}
				} else {
					WriteLog(
						type = "warning",
						text = "Wheels plugin '#local.plugin#' has an invalid plugin.json: #ArrayToList(local.parsed.errors, '; ')#"
					);
				}
			}
		}
	}

	/**
	 * Parses a plugin.json manifest file and validates it against the schema.
	 *
	 * @manifestPath Full filesystem path to the plugin.json file
	 * @return Struct with keys: valid (boolean), manifest (struct), errors (array of strings)
	 */
	public struct function $parsePluginManifest(required string manifestPath) {
		local.result = {valid = false, manifest = {}, errors = []};

		// Read and parse JSON
		try {
			local.raw = FileRead(arguments.manifestPath);
			local.manifest = DeserializeJSON(local.raw);
		} catch (any e) {
			ArrayAppend(local.result.errors, "Failed to parse plugin.json: " & e.message);
			return local.result;
		}

		if (!IsStruct(local.manifest)) {
			ArrayAppend(local.result.errors, "plugin.json must be a JSON object");
			return local.result;
		}

		// Validate against schema
		local.result.errors = $validatePluginManifest(local.manifest);
		local.result.valid = ArrayLen(local.result.errors) == 0;
		if (local.result.valid) {
			local.result.manifest = local.manifest;
		}

		return local.result;
	}

	/**
	 * Validates a parsed plugin.json manifest struct against the expected schema.
	 *
	 * Schema:
	 *   name         (string, required)  - Plugin display name
	 *   version      (string, required)  - Semver-compatible version
	 *   author       (string, optional)  - Plugin author
	 *   description  (string, optional)  - Short description
	 *   dependencies (array|struct, optional) - Array of plugin names or struct of name→semver constraints
	 *   mixins       (string, optional)  - Mixin target: "global","controller","model","none", or comma-delimited list
	 *   middleware    (array, optional)   - Array of middleware declaration structs
	 *   wheelsVersion(string, optional)  - Compatible Wheels version(s), comma-delimited
	 *
	 * @manifest The deserialized plugin.json struct
	 * @return Array of validation error strings (empty if valid)
	 */
	public array function $validatePluginManifest(required struct manifest) {
		local.errors = [];

		// Required fields
		if (!StructKeyExists(arguments.manifest, "name")) {
			ArrayAppend(local.errors, "Missing required field: name");
		} else if (!IsSimpleValue(arguments.manifest.name)) {
			ArrayAppend(local.errors, "Field 'name' must be a string");
		} else if (!Len(Trim(arguments.manifest.name))) {
			ArrayAppend(local.errors, "Missing required field: name");
		}

		if (!StructKeyExists(arguments.manifest, "version")) {
			ArrayAppend(local.errors, "Missing required field: version");
		} else if (!IsSimpleValue(arguments.manifest.version)) {
			ArrayAppend(local.errors, "Field 'version' must be a string");
		} else if (!Len(Trim(arguments.manifest.version))) {
			ArrayAppend(local.errors, "Missing required field: version");
		}

		// Optional string fields
		local.optionalStrings = ListToArray("author,description,mixins,wheelsVersion");
		for (local.field in local.optionalStrings) {
			local.field = Trim(local.field);
			if (StructKeyExists(arguments.manifest, local.field) && !IsSimpleValue(arguments.manifest[local.field])) {
				ArrayAppend(local.errors, "Field '#local.field#' must be a string");
			}
		}

		// Validate mixins value if present
		if (StructKeyExists(arguments.manifest, "mixins") && IsSimpleValue(arguments.manifest.mixins) && Len(Trim(arguments.manifest.mixins))) {
			local.validMixins = "global,none,application,dispatch,controller,model,base,test,sqlserver,mysql,postgresql,h2";
			for (local.mixin in ListToArray(arguments.manifest.mixins)) {
				local.mixin = Trim(local.mixin);
				if (!ListFindNoCase(local.validMixins, local.mixin)) {
					ArrayAppend(local.errors, "Invalid mixin target: '#local.mixin#'");
				}
			}
		}

		// Validate dependencies: array of strings (presence-only) or struct of version constraints
		if (StructKeyExists(arguments.manifest, "dependencies")) {
			if (IsArray(arguments.manifest.dependencies)) {
				for (local.dep in arguments.manifest.dependencies) {
					if (!IsSimpleValue(local.dep) || !Len(Trim(local.dep))) {
						ArrayAppend(local.errors, "Each dependency must be a non-empty string");
						break;
					}
				}
			} else if (IsStruct(arguments.manifest.dependencies)) {
				// Struct form: {"pluginName": ">=1.0.0 <2.0.0"} for semver constraints
				for (local.depKey in arguments.manifest.dependencies) {
					if (!IsSimpleValue(arguments.manifest.dependencies[local.depKey])) {
						ArrayAppend(local.errors, "Dependency constraint for '#local.depKey#' must be a string");
						break;
					}
				}
			} else {
				ArrayAppend(local.errors, "Field 'dependencies' must be an array or struct");
			}
		}

		// Validate middleware (must be array)
		if (StructKeyExists(arguments.manifest, "middleware")) {
			if (!IsArray(arguments.manifest.middleware)) {
				ArrayAppend(local.errors, "Field 'middleware' must be an array");
			} else {
				for (local.mw in arguments.manifest.middleware) {
					if (!IsStruct(local.mw)) {
						ArrayAppend(local.errors, "Each middleware entry must be an object");
						break;
					}
					if (!StructKeyExists(local.mw, "component")) {
						ArrayAppend(local.errors, "Each middleware entry must have a 'component' field");
						break;
					}
				}
			}
		}

		return local.errors;
	}

	/**
	 * Returns the plugin.json schema definition as a struct.
	 * Useful for documentation and tooling.
	 */
	public struct function $pluginManifestSchema() {
		return {
			"name" = {"type" = "string", "required" = true, "description" = "Plugin display name"},
			"version" = {"type" = "string", "required" = true, "description" = "Semver-compatible version string"},
			"author" = {"type" = "string", "required" = false, "description" = "Plugin author name or email"},
			"description" = {"type" = "string", "required" = false, "description" = "Short description of the plugin"},
			"dependencies" = {"type" = "array|struct", "required" = false, "description" = "Array of plugin names or struct of name-to-semver-constraint pairs"},
			"mixins" = {"type" = "string", "required" = false, "description" = "Mixin target: global, controller, model, none, or comma-delimited list"},
			"middleware" = {"type" = "array", "required" = false, "description" = "Array of middleware declaration objects with 'component' field"},
			"wheelsVersion" = {"type" = "string", "required" = false, "description" = "Compatible Wheels version(s), comma-delimited"}
		};
	}

	/**
	 * Resolves plugin dependencies with semver-aware version constraint checking.
	 *
	 * Two dependency sources (checked in order):
	 * 1. plugin.json / box.json "dependencies" struct (semver constraints, e.g., {"authPlugin": ">=1.0.0 <2.0.0"})
	 * 2. CFC metadata "dependency" attribute (legacy presence-only check, e.g., dependency="PluginA,PluginB")
	 *
	 * Missing plugins are reported in dependantPlugins (existing behavior).
	 * Version mismatches are reported in versionMismatchPlugins (new).
	 * In non-production environments, a version mismatch throws to surface problems early.
	 */
	public void function $determineDependency() {
		local.semver = CreateObject("component", "wheels.SemVer");
		for (local.pluginName in variables.$class.plugins) {
			local.meta = variables.$class.pluginMeta[local.pluginName];
			local.deps = local.meta.dependencies;
			// Source 1: Versioned dependencies from plugin.json or box.json
			if (IsStruct(local.deps) && !StructIsEmpty(local.deps)) {
				for (local.depName in local.deps) {
					local.constraint = Trim(local.deps[local.depName]);
					if (!StructKeyExists(variables.$class.plugins, local.depName)) {
						variables.$class.dependantPlugins = ListAppend(
							variables.$class.dependantPlugins,
							local.pluginName & "|" & local.depName
						);
					} else if (Len(local.constraint)) {
						local.depVersion = "";
						if (StructKeyExists(variables.$class.pluginMeta, local.depName)) {
							local.depVersion = variables.$class.pluginMeta[local.depName].version;
						}
						if (Len(local.depVersion)) {
							if (!local.semver.satisfiesAll(local.depVersion, local.constraint)) {
								local.msg = "Plugin '#local.pluginName#' requires '#local.depName#' #local.constraint# but version #local.depVersion# is loaded";
								variables.$class.versionMismatchPlugins = ListAppend(
									variables.$class.versionMismatchPlugins,
									local.pluginName & "|" & local.depName & "|" & local.constraint & "|" & local.depVersion
								);
								if (variables.$class.wheelsEnvironment != "production") {
									Throw(type="Wheels.PluginVersionMismatch", message=local.msg);
								}
							}
						} else {
							WriteLog(
								type="warning",
								text="Wheels: Plugin '#local.pluginName#' requires '#local.depName#' #local.constraint# but no version metadata found for '#local.depName#'"
							);
						}
					}
				}
			}
			// Source 2: Legacy CFC metadata dependency attribute (presence-only)
			local.cfcMeta = GetMetadata(variables.$class.plugins[local.pluginName]);
			if (StructKeyExists(local.cfcMeta, "dependency")) {
				for (local.iDependency in local.cfcMeta.dependency) {
					local.iDependency = Trim(local.iDependency);
					if (!StructKeyExists(variables.$class.plugins, local.iDependency)) {
						local.entry = local.pluginName & "|" & local.iDependency;
						if (!ListFind(variables.$class.dependantPlugins, local.entry)) {
							variables.$class.dependantPlugins = ListAppend(
								variables.$class.dependantPlugins,
								Reverse(SpanExcluding(Reverse(local.cfcMeta.name), ".")) & "|" & local.iDependency
							);
						}
					}
				}
			}
		}
	}

	/**
	 * Invokes the onPluginActivate lifecycle hook on all loaded plugins.
	 * Called after all plugins are loaded, mixins processed, and data stored in the application scope.
	 */
	public void function $invokeOnPluginActivate() {
		local.pluginKeys = ListToArray(ListSort(StructKeyList(variables.$class.plugins), "textnocase", variables.sort));
		for (local.iPlugin in local.pluginKeys) {
			local.plugin = variables.$class.plugins[local.iPlugin];
			if (StructKeyExists(local.plugin, "onPluginActivate") && IsCustomFunction(local.plugin.onPluginActivate)) {
				local.plugin.onPluginActivate(application);
			}
		}
	}

	/**
	 * Invokes register(container) on all plugins that implement ServiceProviderInterface.
	 * Called after all plugins are loaded, passing the DI Injector so plugins can register services.
	 *
	 * @container The Wheels DI container (Injector instance)
	 */
	public void function $invokeServiceProviderRegister(required any container) {
		for (local.pluginKey in variables.$class.serviceProviders) {
			variables.$class.plugins[local.pluginKey].register(arguments.container);
		}
	}

	/**
	 * Invokes boot(app) on all plugins that implement ServiceProviderInterface.
	 * Called after ALL register() methods have completed and user services.cfm has been loaded,
	 * so plugins can safely resolve services from the container.
	 *
	 * @app The Wheels application configuration struct (application.wheels or application.$wheels during init)
	 */
	public void function $invokeServiceProviderBoot(required struct app) {
		for (local.pluginKey in variables.$class.serviceProviders) {
			variables.$class.plugins[local.pluginKey].boot(arguments.app);
		}
	}

	/**
	 * Checks whether a plugin implements ServiceProviderInterface via component metadata.
	 *
	 * @plugin The plugin instance to check
	 */
	private boolean function $isServiceProvider(required any plugin) {
		local.meta = GetMetadata(arguments.plugin);
		return StructKeyExists(local.meta, "implements")
			&& IsStruct(local.meta.implements)
			&& StructKeyExists(local.meta.implements, "wheels.ServiceProviderInterface");
	}

	/**
	 * Checks whether a plugin folder contains a plugin.json manifest file.
	 *
	 * @pluginName The plugin folder name
	 */
	private boolean function $hasPluginManifest(required string pluginName) {
		return FileExists($fullPathToPlugin(arguments.pluginName) & "/plugin.json");
	}

	/**
	 * Temporarily installs the registerMiddleware() API on the application scope
	 * so plugins can call app.registerMiddleware() during onPluginLoad.
	 * Removed after each plugin's onPluginLoad returns via $removePluginLoadAPI().
	 */
	private void function $installPluginLoadAPI(required string pluginName, required struct context) {
		// Use variables.$class (a struct) as the anchor — struct references are
		// by-ref on both Lucee and Adobe CF. Direct array assignment into a struct
		// literal copies the array on Adobe CF, so appending would modify the copy.
		var ctx = {
			owner = variables.$class,
			pluginName = arguments.pluginName
		};
		arguments.context.registerMiddleware = function(required any middleware, struct options = {}) {
			ArrayAppend(ctx.owner.pluginMiddleware, {
				middleware = arguments.middleware,
				options = arguments.options,
				pluginName = ctx.pluginName
			});
		};
	}

	/**
	 * MIXINS
	 */

	public void function $processMixins() {
		// setup a container for each mixableComponents type
		for (local.iMixableComponents in variables.$class.mixableComponents) {
			variables.$class.mixins[local.iMixableComponents] = {};
		}

		// track which plugin provided each method per mixin target for collision detection
		local.methodProviders = {};
		for (local.iMixableComponents in variables.$class.mixableComponents) {
			local.methodProviders[local.iMixableComponents] = {};
		}

		// get a sorted list of plugins so that we run through them the same on
		// every platform
		local.pluginKeys = ListToArray(ListSort(StructKeyList(variables.$class.plugins), "textnocase", variables.sort));

		for (local.iPlugin in local.pluginKeys) {
			// Skip ServiceProvider plugins — they use the DI container lifecycle
			// (register/boot) instead of mixin injection
			if (ArrayFind(variables.$class.serviceProviders, local.iPlugin)) {
				continue;
			}

			// reference the plugin
			local.plugin = variables.$class.plugins[local.iPlugin];
			// grab meta data of the plugin
			local.pluginMeta = GetMetadata(local.plugin);
			if (
				!StructKeyExists(local.pluginMeta, "environment")
				|| ListFindNoCase(local.pluginMeta.environment, variables.$class.wheelsEnvironment)
			) {
				// by default and for backwards compatibility, we inject all methods
				// into all objects
				local.pluginMixins = "global";

				// if the component has a default mixin value, assign that value
				if (StructKeyExists(local.pluginMeta, "mixin")) {
					local.pluginMixins = local.pluginMeta["mixin"];
				}

				// loop through all plugin methods and enter injection info accordingly
				// (based on the mixin value on the method or the default one set on the
				// entire component)
				local.pluginMethods = StructKeyList(local.plugin);

				// lifecycle hooks that should not be injected as mixins
				local.lifecycleHooks = "init,onPluginLoad,onPluginActivate,register,boot";

				for (local.iPluginMethods in local.pluginMethods) {
					if (IsCustomFunction(local.plugin[local.iPluginMethods]) && !ListFindNoCase(local.lifecycleHooks, local.iPluginMethods)) {
						local.methodMeta = GetMetadata(local.plugin[local.iPluginMethods]);
						local.methodMixins = local.pluginMixins;
						if (StructKeyExists(local.methodMeta, "mixin")) {
							local.methodMixins = local.methodMeta["mixin"];
						}

						// mixin all methods except those marked as none
						if (local.methodMixins != "none") {
							for (local.iMixableComponent in variables.$class.mixableComponents) {
								if (local.methodMixins == "global" || ListFindNoCase(local.methodMixins, local.iMixableComponent)) {
									// detect collision: another plugin already provided this method for this target
									if (StructKeyExists(local.methodProviders[local.iMixableComponent], local.iPluginMethods)) {
										local.existingPlugin = local.methodProviders[local.iMixableComponent][local.iPluginMethods];
										ArrayAppend(variables.$class.mixinCollisions, {
											method = local.iPluginMethods,
											target = local.iMixableComponent,
											existingPlugin = local.existingPlugin,
											overridingPlugin = local.iPlugin
										});
									}
									// cfformat-ignore-start
									variables.$class.mixins[local.iMixableComponent][local.iPluginMethods] = local.plugin[local.iPluginMethods];
									local.methodProviders[local.iMixableComponent][local.iPluginMethods] = local.iPlugin;
									// cfformat-ignore-end
								}
							}
						}
					}
				}
			}
		}

		// log any detected collisions
		if (ArrayLen(variables.$class.mixinCollisions)) {
			for (local.collision in variables.$class.mixinCollisions) {
				WriteLog(
					type = "warning",
					text = "Wheels plugin mixin collision: method '#local.collision.method#' on '#local.collision.target#' provided by '#local.collision.existingPlugin#' is overridden by '#local.collision.overridingPlugin#'"
				);
			}
		}
	}

	/**
   * Applies mixins to a component based on application configurations.
   */
  public any function $initializeMixins(required struct variablesScope) {
		// We use $wheels here since these variables get placed in the variables scope of all objects.
		// This way we sure they don't clash with other Wheels variables or any variables the developer may set.
		if (IsDefined("application") && StructKeyExists(application, "$wheels")) {
			$wheels.appKey = "$wheels";
		} else {
			$wheels.appKey = "wheels";
		}

		if (IsDefined("application") && !StructIsEmpty(application[$wheels.appKey].mixins)) {
			$wheels.metaData = GetMetadata(variablesScope.this);
			if (StructKeyExists($wheels.metaData, "displayName")) {
				$wheels.className = $wheels.metaData.displayName;
			} else if (findNoCase("controllers", $wheels.metaData.fullname)){
				$wheels.className = "controller";
			} else if (findNoCase("models", $wheels.metaData.fullname)){
				$wheels.className = "model";
			} else if (findNoCase("tests", $wheels.metaData.fullname)){
				$wheels.className = "test";
			} else {
				$wheels.className = Reverse(SpanExcluding(Reverse($wheels.metaData.name), "."));
			}
			if (StructKeyExists(application[$wheels.appKey].mixins, $wheels.className)) {
				if (!StructKeyExists(variablesScope, "core")) {
					variablesScope.core = {};
					StructAppend(variablesScope.core, variablesScope);
					StructDelete(variablesScope.core, "$wheels");
				}
				StructAppend(variablesScope, application[$wheels.appKey].mixins[$wheels.className], true);

				if (StructKeyExists(variablesScope, "this")) {
					StructAppend(variablesScope.this, application[$wheels.appKey].mixins[$wheels.className], true);
				}

				if (StructKeyExists(variablesScope.core, "this")) {
					StructAppend(variablesScope.core.this, application[$wheels.appKey].mixins[$wheels.className], true);
				}
			}

			// Get rid of any extra data created in the variables scope.
			if (StructKeyExists(variablesScope, "$wheels")) {
				StructDelete(variablesScope, "$wheels");
			}
		}
		return variablesScope;
	}

	/**
	 * GETTERS
	 */

	public any function getPlugins() {
		return variables.$class.plugins;
	}

	public any function getPluginMeta() {
		return variables.$class.pluginMeta;
	}

	public any function getIncompatiblePlugins() {
		return variables.$class.incompatiblePlugins;
	}

	public any function getDependantPlugins() {
		return variables.$class.dependantPlugins;
	}

	public any function getVersionMismatchPlugins() {
		return variables.$class.versionMismatchPlugins;
	}

	public any function getMixins() {
		return variables.$class.mixins;
	}

	public any function getMixinCollisions() {
		return variables.$class.mixinCollisions;
	}

	public array function getPluginMiddleware() {
		return variables.$class.pluginMiddleware;
	}

	public array function getServiceProviders() {
		return variables.$class.serviceProviders;
	}

	public array function getDeprecationWarnings() {
		return variables.$class.deprecationWarnings;
	}

	public any function getMixableComponents() {
		return variables.$class.mixableComponents;
	}

	public any function inspect() {
		return variables;
	}

	/**
	 * PRIVATE
	 */

	public string function $fullPathToPlugin(required string folder) {
		return ListAppend(variables.$class.pluginPathFull, arguments.folder, "/");
	}

	public string function $componentPathToPlugin(required string folder, required string file) {
		// BoxLang compatibility: Handle component path construction more carefully
		if (structKeyExists(server, "boxlang")) {
			local.basePath = application[$appKey()].pluginComponentPath;
			local.fileName = Len(Trim(arguments.file)) ? arguments.file : arguments.folder;
			if (Find("/", local.basePath)) {
				local.basePath = Replace(local.basePath, "/", ".", "all");
				local.basePath = REReplace(local.basePath, "^\.+", "", "all");
			}
			
			local.componentPath = "#local.basePath#.#arguments.folder#.#local.fileName#";
			local.componentPath = REReplaceNoCase(local.componentPath, "\.+$", "", "all");

			return local.componentPath;
		} else {
			return "#application[$appKey()].pluginComponentPath#.#arguments.folder#.#arguments.file#";
		}
	}

	public query function $folders() {
		local.query = $directory(
			action = "list",
			directory = variables.$class.pluginPathFull,
			type = "dir",
			sort = "name #variables.sort#"
		);
		return $query(
			dbtype = "query",
			query = local.query,
			sql = "select * from query where name not like '.%' ORDER BY name #variables.sort#"
		);
	}

	public query function $files() {
		local.query = $directory(
			action = "list",
			directory = variables.$class.pluginPathFull,
			filter = "*.zip",
			type = "file",
			sort = "name #variables.sort#"
		);
		return $query(
			dbtype = "query",
			query = local.query,
			sql = "select * from query where name not like '.%' ORDER BY name #variables.sort#"
		);
	}

}
