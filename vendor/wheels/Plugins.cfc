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
			if (structKeyExists(server, "boxlang")) {
				// BoxLang compatibility: Handle case where query returns no results
				if (local.pluginCfc.recordCount > 0) {
					local.temp.name = Replace(local.pluginCfc.name, ".cfc", "");
				} else {
					local.cfcFiles = $query(
						dbtype = "query",
						query = local.subfolder,
						sql = "SELECT name FROM query WHERE LOWER(name) LIKE '%.cfc' ORDER BY name"
					);
					if (local.cfcFiles.recordCount > 0) {
						local.temp.name = Replace(local.cfcFiles.name, ".cfc", "");
					} else {
						local.folderPattern = local.folders["name"][i];
						local.possibleFiles = $query(
							dbtype = "query", 
							query = local.subfolder,
							sql = "SELECT name FROM query WHERE LOWER(name) LIKE '%#LCase(local.folderPattern)#%.cfc'"
						);
						if (local.possibleFiles.recordCount > 0) {
							local.temp.name = Replace(local.possibleFiles.name, ".cfc", "");
						} else {
							local.temp.name = local.folders["name"][i];
						}
					}
				}
				local.temp.folderPath = $fullPathToPlugin(local.folders["name"][i]);
				local.temp.componentName = local.folders["name"][i] & "." & local.temp.name;
			} else {
				local.temp.name = Replace(local.pluginCfc.name, ".cfc", "");
				local.temp.folderPath = $fullPathToPlugin(local.folders["name"][i]);
				local.temp.componentName = local.folders["name"][i] & "." & Replace(local.pluginCfc.name, ".cfc", "");
			}
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
		local.files = StructKeyList(local.files);
		// loop through the plugins folders
		for (local.iFolder in $pluginFolders()) {
			local.folder = local.folders[local.iFolder];
			// see if a folder is in the list of plugin files
			if (!ListContainsNoCase(local.files, local.folder.name)) {
				if (StructKeyExists(server, "boxlang") && !local.folder.folderPath.startsWith("/")) {
					local.folder.folderPath = "/" & local.folder.folderPath;
				}
				DirectoryDelete(local.folder.folderPath, true);
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
					try {
						local.plugin.onPluginLoad(local.loadContext);
					} finally {
						// No cleanup needed — loadContext is discarded
					}
				}
				// Track plugins that implement ServiceProviderInterface
				if ($isServiceProvider(local.plugin)) {
					ArrayAppend(variables.$class.serviceProviders, local.pluginKey);
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
	 * Attempt to extract version numbers from box.json and/or corresponding .zip files
	 * Storing box.json data too as this may be useful later
	 */
	public void function $pluginMetaData() {
		for (local.plugin in variables.$class.plugins) {
			variables.$class.pluginMeta[local.plugin] = {"version" = "", "boxjson" = {}};
			local.boxJsonLocation = $fullPathToPlugin(local.plugin & "/" & 'box.json');
			if (FileExists(local.boxJsonLocation)) {
				local.boxJson = DeserializeJSON(FileRead(local.boxJsonLocation));
				variables.$class.pluginMeta[local.plugin]["boxjson"] = local.boxJson;
				if (StructKeyExists(local.boxJson, "version")) {
					variables.$class.pluginMeta[local.plugin]["version"] = local.boxJson.version;
				}
			}
		}
	}

	public void function $determineDependency() {
		for (local.iPlugins in variables.$class.plugins) {
			local.pluginMeta = GetMetadata(variables.$class.plugins[local.iPlugins]);
			if (StructKeyExists(local.pluginMeta, "dependency")) {
				for (local.iDependency in local.pluginMeta.dependency) {
					local.iDependency = Trim(local.iDependency);
					if (!StructKeyExists(variables.$class.plugins, local.iDependency)) {
						variables.$class.dependantPlugins = ListAppend(
							variables.$class.dependantPlugins,
							Reverse(SpanExcluding(Reverse(local.pluginMeta.name), ".")) & "|" & local.iDependency
						);
					}
				};
			}
		};
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
	 * Temporarily installs the registerMiddleware() API on the application scope
	 * so plugins can call app.registerMiddleware() during onPluginLoad.
	 * Removed after each plugin's onPluginLoad returns via $removePluginLoadAPI().
	 */
	private void function $installPluginLoadAPI(required string pluginName, required struct context) {
		var ctx = {
			pluginMiddleware = variables.$class.pluginMiddleware,
			pluginName = arguments.pluginName
		};
		arguments.context.registerMiddleware = function(required any middleware, struct options = {}) {
			ArrayAppend(ctx.pluginMiddleware, {
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
