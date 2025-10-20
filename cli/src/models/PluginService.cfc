component {
    
    property name="packageService" inject="PackageService";
    property name="forgebox" inject="ForgeBox";
    property name="fileSystemUtil" inject="FileSystem";
    property name="configService" inject="ConfigService";
    
    
    /**
     * Install a Wheels CLI plugin
     */
    function install(
        required string name,
        boolean dev = false,
        string version = ""
    ) {
        try {
            var boxJsonPath = expandPath("box.json");
            var boxJson = {};
            
            // Read existing box.json
            if (fileExists(boxJsonPath)) {
                boxJson = deserializeJSON(fileRead(boxJsonPath));
            }
            
            // Initialize dependencies if needed
            if (!boxJson.keyExists("dependencies")) {
                boxJson.dependencies = {};
            }
            if (!boxJson.keyExists("devDependencies")) {
                boxJson.devDependencies = {};
            }
            
            // Determine dependency type
            var depType = arguments.dev ? "devDependencies" : "dependencies";
            
            // Check if it's a valid plugin
            var pluginInfo = getPluginInfo(arguments.name);
            if (!pluginInfo.isValid) {
                return {
                    success: false,
                    error: "Plugin '" & arguments.name & "' not found or is not a valid Wheels CLI plugin"
                };
            }
            
            // Add version if specified
            var packageSpec = arguments.name;
            if (len(arguments.version)) {
                packageSpec &= "@" & arguments.version;
            }
            
            // Add to box.json
            boxJson[depType][pluginInfo.slug] = packageSpec;
            
            // Write updated box.json
            fileWrite(boxJsonPath, serializeJSON(boxJson, true));
            
            // Install via CommandBox
            packageService.installPackage(
                ID = packageSpec,
                save = true,
                saveDev = arguments.dev
            );
            
            // Register plugin commands
            registerPluginCommands(pluginInfo);
            
            return {
                success: true,
                plugin: pluginInfo,
                installedVersion: pluginInfo.version
            };
            
        } catch (any e) {
            return {
                success: false,
                error: e.message
            };
        }
    }
    
    /**
     * Remove a Wheels CLI plugin
     */
    function remove(required string name) {
        try {
            var boxJsonPath = resolvePath("box.json");
            var pluginFound = false;

            // Get current working directory
            var currentDir = fileSystemUtil.resolvePath("");

            // Check if plugin exists in box.json
            if (fileExists(boxJsonPath)) {
                var boxJson = deserializeJSON(fileRead(boxJsonPath));

                // Check dependencies
                if (boxJson.keyExists("dependencies") && boxJson.dependencies.keyExists(arguments.name)) {
                    boxJson.dependencies.delete(arguments.name);
                    pluginFound = true;
                }

                // Check devDependencies
                if (boxJson.keyExists("devDependencies") && boxJson.devDependencies.keyExists(arguments.name)) {
                    boxJson.devDependencies.delete(arguments.name);
                    pluginFound = true;
                }

                if (!pluginFound) {
                    // Check if plugin is in /plugins folder (Wheels application plugin)
                    var pluginsDir = fileSystemUtil.resolvePath("plugins");
                    if (directoryExists(pluginsDir)) {
                        var pluginPath = pluginsDir & "/" & arguments.name;
                        if (directoryExists(pluginPath)) {
                            pluginFound = true;
                        }
                    }
                }

                if (!pluginFound) {
                    return {
                        success: false,
                        error: "Plugin '#arguments.name#' is not installed"
                    };
                }

                // Write updated box.json
                fileWrite(boxJsonPath, serializeJSON(boxJson, true));

                // Uninstall via CommandBox
                packageService.uninstallPackage(
                    ID = arguments.name,
                    currentWorkingDirectory = currentDir
                );
            } else {
                return {
                    success: false,
                    error: "No box.json found. Plugin '#arguments.name#' is not installed"
                };
            }

            return {
                success: true,
                pluginName: arguments.name
            };

        } catch (any e) {
            return {
                success: false,
                error: e.message
            };
        }
    }
    
    /**
     * List installed plugins
     */
    function list() {
        var plugins = [];
        var pluginNames = [];
        
        // Check for Wheels application plugins in /plugins folder first (priority)
        var pluginsDir = fileSystemUtil.resolvePath("plugins");
        if (directoryExists(pluginsDir)) {
            // Get all .zip files in plugins directory (Wheels application plugins)
            var pluginZips = directoryList(pluginsDir, false, "query", "*.zip", "name");
            for (var zipFile in pluginZips) {
                var pluginInfo = parseWheelsPluginZip(pluginsDir & "/" & zipFile.name);
                if (pluginInfo.isValid) {
                    arrayAppend(plugins, pluginInfo);
                    arrayAppend(pluginNames, pluginInfo.name);
                }
            }
        }
        
        // Also check box.json for CLI plugins installed locally (avoid duplicates)
        var boxJsonPath = resolvePath("box.json");
        if (fileExists(boxJsonPath)) {
            var boxJson = deserializeJSON(fileRead(boxJsonPath));
            
            // Check dependencies
            if (boxJson.keyExists("dependencies")) {
                for (var dep in boxJson.dependencies) {
                    if (isWheelsPlugin(dep) && !isDuplicatePlugin(dep, pluginNames)) {
                        var pluginInfo = getInstalledPluginInfo(dep, false);
                        arrayAppend(plugins, pluginInfo);
                        arrayAppend(pluginNames, pluginInfo.name);
                    }
                }
            }
            
            // Check devDependencies
            if (boxJson.keyExists("devDependencies")) {
                for (var dep in boxJson.devDependencies) {
                    if (isWheelsPlugin(dep) && !isDuplicatePlugin(dep, pluginNames)) {
                        var pluginInfo = getInstalledPluginInfo(dep, true);
                        arrayAppend(plugins, pluginInfo);
                        arrayAppend(pluginNames, pluginInfo.name);
                    }
                }
            }
        }
        
        return plugins;
    }
    
    /**
     * Search for available plugins
     */
    function search(string query = "", string type = "cfwheels-plugins") {
        try {
            // Search ForgeBox for wheels plugins
            var searchParams = {};
            if (len(arguments.query)) {
                searchParams.searchTerm = arguments.query;
            }
            searchParams.type = arguments.type;
            searchParams.max = 50;
            
            var searchResults = packageService.search(argumentCollection=searchParams);
            
            var plugins = [];
            for (var result in searchResults) {
                arrayAppend(plugins, {
                    name: result.name,
                    slug: result.slug,
                    version: result.version,
                    description: result.summary,
                    author: result.author,
                    downloads: result.downloads
                });
            }
            
            return plugins;
        } catch (any e) {
            return [];
        }
    }
    
    /**
     * Get plugin information
     */
    private function getPluginInfo(pluginName) {
        // Check if it's a URL
        if (findNoCase("http", arguments.pluginName) || findNoCase("github.com", arguments.pluginName)) {
            return {
                isValid: true,
                name: listLast(arguments.pluginName, "/"),
                slug: listLast(arguments.pluginName, "/"),
                version: "latest",
                repository: arguments.pluginName
            };
        }
        
        // Assume package names are valid and let PackageService/ForgeBox handle validation during install
        // This approach is more permissive and mirrors how CommandBox handles package installation
        var slug = lCase(arguments.pluginName);
        
        return {
            isValid: true,
            name: arguments.pluginName,
            slug: slug,
            version: "latest",
            description: "ForgeBox package"
        };
    }
    
    /**
     * Check if a module is a Wheels CLI plugin
     */
    private function isWheelsPlugin(moduleName) {
        // Exclude the core framework and common non-plugin dependencies
        if (listFindNoCase("wheels-core,wirebox,testbox,cfformat", arguments.moduleName)) {
            return false;
        }
        
        // Check for actual Wheels plugin patterns
        return reFindNoCase("^cfwheels-.*-plugin", arguments.moduleName) ||
               reFindNoCase("^wheels-.*-plugin", arguments.moduleName) ||
               reFindNoCase("-wheels-cli$", arguments.moduleName) ||
               reFindNoCase("wheels.*cli", arguments.moduleName);
    }
    
    /**
     * Check if a plugin is already in the list (handles name variations)
     */
    private function isDuplicatePlugin(required string pluginName, required array existingNames) {
        // Direct name match
        if (arrayFindNoCase(arguments.existingNames, arguments.pluginName)) {
            return true;
        }
        
        // Check for common name variations
        var cleanName = reReplace(arguments.pluginName, "^cfwheels-", "");
        cleanName = reReplace(cleanName, "-plugin$", "");
        
        for (var existingName in arguments.existingNames) {
            var cleanExisting = reReplace(existingName, "^cfwheels-", "");
            cleanExisting = reReplace(cleanExisting, "-plugin$", "");
            cleanExisting = reReplace(cleanExisting, "\s+Plugin$", "");
            
            if (compareNoCase(cleanName, cleanExisting) == 0) {
                return true;
            }
        }
        
        return false;
    }
    
    /**
     * Parse information from a Wheels plugin zip file
     */
    private function parseWheelsPluginZip(required string zipPath) {
        var pluginInfo = {
            isValid: false,
            name: "",
            version: "unknown",
            dev: false,
            global: false,
            description: "",
            type: "wheels-plugin"
        };
        
        try {
            // Extract plugin name and version from filename
            var fileName = listLast(arguments.zipPath, "/\\");
            fileName = reReplace(fileName, "\.zip$", "");
            
            // Parse filename pattern: PluginName-Version.zip
            var parts = listToArray(fileName, "-");
            if (arrayLen(parts) >= 2) {
                pluginInfo.name = parts[1];
                pluginInfo.version = parts[arrayLen(parts)];
            } else {
                pluginInfo.name = fileName;
            }
            
            // Try to extract more info from box.json inside the zip
            try {
                cfzip(action="read", file=arguments.zipPath, entryPath="box.json", variable="boxJsonContent");
                if (len(boxJsonContent)) {
                    var boxJsonData = deserializeJSON(boxJsonContent);
                    if (structKeyExists(boxJsonData, "name")) {
                        pluginInfo.name = boxJsonData.name;
                    }
                    if (structKeyExists(boxJsonData, "version")) {
                        pluginInfo.version = boxJsonData.version;
                    }
                    if (structKeyExists(boxJsonData, "shortDescription")) {
                        pluginInfo.description = boxJsonData.shortDescription;
                    } else if (structKeyExists(boxJsonData, "description")) {
                        pluginInfo.description = boxJsonData.description;
                    } else if (structKeyExists(boxJsonData, "summary")) {
                        pluginInfo.description = boxJsonData.summary;
                    }
                }
            } catch (any e) {
                // Ignore errors reading box.json from zip
            }
            
            pluginInfo.isValid = true;
            return pluginInfo;
            
        } catch (any e) {
            return pluginInfo;
        }
    }

    /**
     * Get information about an installed plugin
     */
    private function getInstalledPluginInfo(pluginName, isDev) {
        var info = {
            name: arguments.pluginName,
            version: "unknown",
            dev: arguments.isDev,
            global: false,
            description: ""
        };
        
        // Try to read module info
        var modulePath = resolvePath("modules/" & arguments.pluginName);
        if (directoryExists(modulePath)) {
            var moduleConfigPath = modulePath & "/ModuleConfig.cfc";
            if (fileExists(moduleConfigPath)) {
                try {
                    var moduleConfig = createObject("component", "modules." & arguments.pluginName & ".ModuleConfig");
                    info.version = moduleConfig.version ?: "unknown";
                    info.description = moduleConfig.description ?: "";
                } catch (any e) {
                    // Ignore errors reading module config
                }
            }
        }
        
        return info;
    }


    /**
     * Register plugin commands with CommandBox
     */
    private function registerPluginCommands(pluginInfo) {
        // CommandBox will auto-discover commands in the module
        // This is a placeholder for any additional registration logic
    }
    
    /**
     * Resolve a file path  
     */
    private function resolvePath(path, baseDirectory = "") {
        // Use fileSystemUtil.resolvePath() which is already injected and handles paths correctly
        if (len(arguments.baseDirectory)) {
            return fileSystemUtil.resolvePath(arguments.path, arguments.baseDirectory);
        } else {
            return fileSystemUtil.resolvePath(arguments.path);
        }
    }
}