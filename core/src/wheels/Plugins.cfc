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
			local.temp.name = Replace(local.pluginCfc.name, ".cfc", "");
			local.temp.folderPath = $fullPathToPlugin(local.folders["name"][i]);
			local.temp.componentName = local.folders["name"][i] & "." & Replace(local.pluginCfc.name, ".cfc", "");
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
	 * MIXINS
	 */

	public void function $processMixins() {
		// setup a container for each mixableComponents type
		for (local.iMixableComponents in variables.$class.mixableComponents) {
			variables.$class.mixins[local.iMixableComponents] = {};
		}

		// get a sorted list of plugins so that we run through them the same on
		// every platform
		local.pluginKeys = ListToArray(ListSort(StructKeyList(variables.$class.plugins), "textnocase", variables.sort));

		for (local.iPlugin in local.pluginKeys) {
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

				for (local.iPluginMethods in local.pluginMethods) {
					if (IsCustomFunction(local.plugin[local.iPluginMethods]) && local.iPluginMethods neq "init") {
						local.methodMeta = GetMetadata(local.plugin[local.iPluginMethods]);
						local.methodMixins = local.pluginMixins;
						if (StructKeyExists(local.methodMeta, "mixin")) {
							local.methodMixins = local.methodMeta["mixin"];
						}

						// mixin all methods except those marked as none
						if (local.methodMixins != "none") {
							for (local.iMixableComponent in variables.$class.mixableComponents) {
								if (local.methodMixins == "global" || ListFindNoCase(local.methodMixins, local.iMixableComponent)) {
									// cfformat-ignore-start
									variables.$class.mixins[local.iMixableComponent][local.iPluginMethods] = local.plugin[local.iPluginMethods];
									// cfformat-ignore-end
								}
							}
						}
					}
				}
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
			// BoxLang compatibility: this scope is not available in variables scope
			if (StructKeyExists(variablesScope, "this")) {
				$wheels.metaData = GetMetadata(variablesScope.this);
			} else {
				// Fallback for BoxLang
				try {
					$wheels.metaData = GetMetadata(this);
				} catch (any e) {
					// Last resort - create a minimal metadata structure
					$wheels.metaData = {
						"fullname": "wheels.component",
						"displayName": "component"
					};
				}
			}
			if (StructKeyExists($wheels.metaData, "displayName")) {
				$wheels.className = $wheels.metaData.displayName;
			} else if (findNoCase("controllers", $wheels.metaData.fullname)){
				$wheels.className = "controller";
			} else if (findNoCase("models", $wheels.metaData.fullname)){
				$wheels.className = "model";
			} else {
				$wheels.className = Reverse(SpanExcluding(Reverse($wheels.metaData.name), "."));
			}
			if (StructKeyExists(application[$wheels.appKey].mixins, $wheels.className)) {
				if (!StructKeyExists(variablesScope, "core")) {
					if (application[$wheels.appKey].serverName == "Railo") {
						// this is to work around a railo bug (https://jira.jboss.org/browse/RAILO-936)
						// NB, fixed in Railo 3.2.0, so assume this is fixed in all lucee versions
						variablesScope.core = Duplicate(variablesScope);
					} else {
						variablesScope.core = {};
						StructAppend(variablesScope.core, variablesScope);
						StructDelete(variablesScope.core, "$wheels");
					}
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
		return "#application[$appKey()].pluginComponentPath#.#arguments.folder#.#arguments.file#";
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
