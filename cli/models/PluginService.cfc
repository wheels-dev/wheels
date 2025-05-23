component {
    
    property name="packageService" inject="PackageService@commandbox-core";
    property name="configService" inject="ConfigService@commandbox-core";
    property name="fileSystemUtil" inject="FileSystem@commandbox-core";
    
    /**
     * Install a Wheels CLI plugin
     */
    function install(
        required string name,
        boolean dev = false,
        boolean global = false,
        string version = ""
    ) {
        try {
            var boxJsonPath = resolvePath("box.json");
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
                    error: "Plugin '#arguments.name#' not found or is not a valid Wheels CLI plugin"
                };
            }
            
            // Add version if specified
            var packageSpec = arguments.name;
            if (len(arguments.version)) {
                packageSpec &= "@" & arguments.version;
            }
            
            // Install the plugin
            if (arguments.global) {
                // Install globally via CommandBox
                packageService.installPackage(
                    ID = packageSpec,
                    save = false,
                    global = true
                );
            } else {
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
            }
            
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
    function remove(required string name, boolean global = false) {
        try {
            var boxJsonPath = resolvePath("box.json");
            
            if (arguments.global) {
                // Uninstall globally
                packageService.uninstallPackage(
                    ID = arguments.name,
                    global = true
                );
            } else {
                // Remove from box.json
                if (fileExists(boxJsonPath)) {
                    var boxJson = deserializeJSON(fileRead(boxJsonPath));
                    
                    // Remove from dependencies
                    if (boxJson.keyExists("dependencies") && boxJson.dependencies.keyExists(arguments.name)) {
                        boxJson.dependencies.delete(arguments.name);
                    }
                    
                    // Remove from devDependencies
                    if (boxJson.keyExists("devDependencies") && boxJson.devDependencies.keyExists(arguments.name)) {
                        boxJson.devDependencies.delete(arguments.name);
                    }
                    
                    // Write updated box.json
                    fileWrite(boxJsonPath, serializeJSON(boxJson, true));
                    
                    // Uninstall via CommandBox
                    packageService.uninstallPackage(ID = arguments.name);
                }
            }
            
            return { success: true };
            
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
    function list(boolean global = false) {
        var plugins = [];
        
        if (arguments.global) {
            // Get global CommandBox modules
            var globalModules = configService.getSetting("modules", {});
            for (var moduleName in globalModules) {
                if (isWheelsPlugin(moduleName)) {
                    arrayAppend(plugins, {
                        name: moduleName,
                        version: globalModules[moduleName].version ?: "unknown",
                        global: true,
                        description: globalModules[moduleName].description ?: ""
                    });
                }
            }
        } else {
            // Get local plugins from box.json
            var boxJsonPath = resolvePath("box.json");
            if (fileExists(boxJsonPath)) {
                var boxJson = deserializeJSON(fileRead(boxJsonPath));
                
                // Check dependencies
                if (boxJson.keyExists("dependencies")) {
                    for (var dep in boxJson.dependencies) {
                        if (isWheelsPlugin(dep)) {
                            arrayAppend(plugins, getInstalledPluginInfo(dep, false));
                        }
                    }
                }
                
                // Check devDependencies
                if (boxJson.keyExists("devDependencies")) {
                    for (var dep in boxJson.devDependencies) {
                        if (isWheelsPlugin(dep)) {
                            arrayAppend(plugins, getInstalledPluginInfo(dep, true));
                        }
                    }
                }
            }
        }
        
        return plugins;
    }
    
    /**
     * Search for available plugins
     */
    function search(string query = "") {
        try {
            // Search ForgeBox for wheels-cli-plugin type packages
            var searchResults = packageService.search(
                searchTerm = arguments.query,
                type = "wheels-cli-plugin"
            );
            
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
        
        // Search ForgeBox
        try {
            var packageInfo = packageService.getPackage(arguments.pluginName);
            return {
                isValid: true,
                name: packageInfo.name,
                slug: packageInfo.slug,
                version: packageInfo.version,
                description: packageInfo.summary
            };
        } catch (any e) {
            return {
                isValid: false
            };
        }
    }
    
    /**
     * Check if a module is a Wheels CLI plugin
     */
    private function isWheelsPlugin(moduleName) {
        // Check module name patterns
        return reFindNoCase("^wheels-", arguments.moduleName) ||
               reFindNoCase("-wheels-cli$", arguments.moduleName) ||
               reFindNoCase("wheels.*cli", arguments.moduleName);
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
        var modulePath = resolvePath("modules/#arguments.pluginName#");
        if (directoryExists(modulePath)) {
            var moduleConfigPath = modulePath & "/ModuleConfig.cfc";
            if (fileExists(moduleConfigPath)) {
                try {
                    var moduleConfig = createObject("component", "modules.#arguments.pluginName#.ModuleConfig");
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
    private function resolvePath(path) {
        return fileSystemUtil.resolvePath(arguments.path);
    }
}