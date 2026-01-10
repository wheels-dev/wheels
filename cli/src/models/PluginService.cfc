component {
    
    property name="packageService" inject="PackageService";
    property name="forgebox" inject="ForgeBox";
    property name="fileSystemUtil" inject="FileSystem";
    property name="configService" inject="ConfigService";
    
    
    /**
     * Install a Wheels plugin (cfwheels-plugins type only)
     * Plugins are automatically installed to /plugins folder
     */
    function install(
        required string name,
        boolean dev = false,
        string version = ""
    ) {
        try {
            // Ensure plugins directory exists
            var pluginsDir = fileSystemUtil.resolvePath("plugins");
            if (!directoryExists(pluginsDir)) {
                directoryCreate(pluginsDir);
            }

            // Check if it's a valid cfwheels-plugins package
            var pluginInfo = getPluginInfo(arguments.name);
            if (!pluginInfo.isValid) {
                return {
                    success: false,
                    error: "Plugin '" & arguments.name & "' not found or is not a valid Wheels plugin"
                };
            }

            // Verify it's a cfwheels-plugins type
            if (pluginInfo.type != "cfwheels-plugins") {
                return {
                    success: false,
                    error: "Package '" & arguments.name & "' is not a cfwheels-plugins type. Only cfwheels-plugins can be installed."
                };
            }

            // Build package spec with version
            var packageSpec = arguments.name;
            if (len(arguments.version)) {
                packageSpec &= "@" & arguments.version;
            }

            // Get the slug for directory name
            var pluginSlug = pluginInfo.slug;
            var targetPath = pluginsDir & "/" & pluginSlug;

            // Install via CommandBox with proper parameters
            var result = packageService.installPackage(
                ID = packageSpec,
                currentWorkingDirectory = fileSystemUtil.resolvePath(""),
                save = false,
                production = true,
                verbose = false
            );

            // If package didn't install to /plugins, move it there
            if (directoryExists(targetPath)) {
                // Already in correct location
            } else {
                // Check common installation locations and move if needed
                var possiblePaths = [
                    fileSystemUtil.resolvePath("modules/" & pluginSlug),
                    fileSystemUtil.resolvePath(pluginSlug)
                ];

                for (var possiblePath in possiblePaths) {
                    if (directoryExists(possiblePath)) {
                        // Move to plugins directory
                        directoryRename(possiblePath, targetPath);
                        break;
                    }
                }
            }

            return {
                success: true,
                plugin: pluginInfo,
                installedVersion: arguments.version ?: pluginInfo.version
            };

        } catch (any e) {
            return {
                success: false,
                error: e.message
            };
        }
    }
    
    /**
     * Remove a Wheels plugin from /plugins folder
     */
    function remove(required string name) {
        try {
            var pluginsDir = fileSystemUtil.resolvePath("plugins");

            // Check if plugins directory exists
            if (!directoryExists(pluginsDir)) {
                return {
                    success: false,
                    error: "Plugins directory not found. Plugin '#arguments.name#' is not installed"
                };
            }

            // Find plugin by folder name, slug, or actual name
            var foundPlugin = findPluginByName(pluginsDir, arguments.name);

            if (!foundPlugin.found) {
                return {
                    success: false,
                    error: "Plugin '#arguments.name#' is not installed in plugins folder"
                };
            }

            // Delete the plugin directory
            directoryDelete(foundPlugin.path, true);

            return {
                success: true,
                pluginName: foundPlugin.folderName
            };

        } catch (any e) {
            return {
                success: false,
                error: e.message
            };
        }
    }
    
    /**
     * List installed plugins from /plugins folder only
     */
    function list() {
        var plugins = [];

        // Check for cfwheels-plugins in /plugins folder
        var pluginsDir = fileSystemUtil.resolvePath("plugins");
        if (!directoryExists(pluginsDir)) {
            return plugins; // Return empty array if plugins folder doesn't exist
        }

        // Get all directories in plugins folder
        var pluginDirs = directoryList(pluginsDir, false, "query", "*", "name", "directory");

        for (var pluginDir in pluginDirs) {
            var pluginPath = pluginsDir & "/" & pluginDir.name;
            var pluginInfo = getPluginInfoFromFolder(pluginPath, pluginDir.name);

            if (pluginInfo.isValid) {
                arrayAppend(plugins, pluginInfo);
            }
        }

        return plugins;
    }

    /**
     * Get plugin information from ForgeBox
     * Validates that it's a cfwheels-plugins type
     */
    private function getPluginInfo(pluginName) {
        try {
            // Check if it's a URL
            if (findNoCase("http", arguments.pluginName) || findNoCase("github.com", arguments.pluginName)) {
                return {
                    isValid: false,
                    error: "URL installations are not supported for cfwheels-plugins. Use package name from ForgeBox."
                };
            }

            // Try to get package info from ForgeBox using forgebox service
            try {
                var forgeboxData = forgebox.getEntry(arguments.pluginName);

                // Check if it's a cfwheels-plugins type
                if (structKeyExists(forgeboxData, "typeslug") && forgeboxData.typeslug == "cfwheels-plugins") {
                    return {
                        isValid: true,
                        name: forgeboxData.title ?: arguments.pluginName,
                        slug: arguments.pluginName,
                        version: forgeboxData.version ?: "latest",
                        type: forgeboxData.typeslug,
                        description: forgeboxData.summary ?: ""
                    };
                } else {
                    return {
                        isValid: false,
                        error: "Package '#arguments.pluginName#' is not a cfwheels-plugins type"
                    };
                }
            } catch (any e) {
                return {
                    isValid: false,
                    error: "Package '#arguments.pluginName#' not found on ForgeBox"
                };
            }

        } catch (any e) {
            return {
                isValid: false,
                error: e.message
            };
        }
    }

    /**
     * Get plugin information from installed folder
     */
    function getPluginInfoFromFolder(required string pluginPath, required string folderName) {
        var pluginInfo = {
            isValid: false,
            name: arguments.folderName,
            slug: arguments.folderName,
            folderName: arguments.folderName,
            version: "unknown",
            description: "",
            type: "cfwheels-plugins"
        };

        try {
            // Check for box.json in plugin folder
            var boxJsonPath = arguments.pluginPath & "/box.json";
            if (fileExists(boxJsonPath)) {
                var boxJson = deserializeJSON(fileRead(boxJsonPath));

                pluginInfo.isValid = true;
                if (structKeyExists(boxJson, "name")) {
                    pluginInfo.name = boxJson.name;
                }
                if (structKeyExists(boxJson, "slug")) {
                    pluginInfo.slug = boxJson.slug;
                }
                if (structKeyExists(boxJson, "version")) {
                    pluginInfo.version = boxJson.version;
                }
                if (structKeyExists(boxJson, "shortDescription")) {
                    pluginInfo.description = boxJson.shortDescription;
                } else if (structKeyExists(boxJson, "description")) {
                    pluginInfo.description = boxJson.description;
                }
                if (structKeyExists(boxJson, "type")) {
                    pluginInfo.type = boxJson.type;
                }
            } else {
                // No box.json, but folder exists - mark as valid with folder name
                pluginInfo.isValid = true;
            }

        } catch (any e) {
            pluginInfo.isValid = false;
        }

        return pluginInfo;
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
     * Find plugin in /plugins folder by folder name, slug, or actual name
     * Algorithm searches all plugin folders and matches against:
     * 1. Folder name (exact match, case insensitive)
     * 2. Plugin slug from box.json (exact match, case insensitive)
     * 3. Plugin name from box.json (exact match, case insensitive)
     * 4. Normalized variations (removes cfwheels-, wheels- prefixes)
     */
    function findPluginByName(required string pluginsDir, required string searchTerm) {
        var result = {
            found: false,
            path: "",
            folderName: ""
        };

        // Normalize search term for comparison
        var normalizedSearch = normalizePluginName(arguments.searchTerm);

        // Get all directories in plugins folder
        var pluginDirs = directoryList(arguments.pluginsDir, false, "query", "*", "name", "directory");

        for (var pluginDir in pluginDirs) {
            var folderName = pluginDir.name;
            var pluginPath = arguments.pluginsDir & "/" & folderName;

            // Check 1: Direct folder name match (case insensitive)
            if (compareNoCase(folderName, arguments.searchTerm) == 0) {
                result.found = true;
                result.path = pluginPath;
                result.folderName = folderName;
                return result;
            }

            // Check 2 & 3: Check against slug and name in box.json
            var boxJsonPath = pluginPath & "/box.json";
            if (fileExists(boxJsonPath)) {
                try {
                    var boxJson = deserializeJSON(fileRead(boxJsonPath));

                    // Check slug (case insensitive)
                    if (structKeyExists(boxJson, "slug") && compareNoCase(boxJson.slug, arguments.searchTerm) == 0) {
                        result.found = true;
                        result.path = pluginPath;
                        result.folderName = folderName;
                        return result;
                    }

                    // Check actual name (case insensitive)
                    if (structKeyExists(boxJson, "name") && compareNoCase(boxJson.name, arguments.searchTerm) == 0) {
                        result.found = true;
                        result.path = pluginPath;
                        result.folderName = folderName;
                        return result;
                    }

                    // Check 4: Normalized comparison (removes prefixes like cfwheels-, wheels-)
                    var normalizedSlug = normalizePluginName(structKeyExists(boxJson, "slug") ? boxJson.slug : "");
                    var normalizedName = normalizePluginName(structKeyExists(boxJson, "name") ? boxJson.name : "");
                    var normalizedFolder = normalizePluginName(folderName);

                    if ((len(normalizedSlug) && compareNoCase(normalizedSlug, normalizedSearch) == 0) ||
                        (len(normalizedName) && compareNoCase(normalizedName, normalizedSearch) == 0) ||
                        (len(normalizedFolder) && compareNoCase(normalizedFolder, normalizedSearch) == 0)) {
                        result.found = true;
                        result.path = pluginPath;
                        result.folderName = folderName;
                        return result;
                    }

                } catch (any e) {
                    // Continue checking other folders
                }
            } else {
                // No box.json, check normalized folder name
                var normalizedFolder = normalizePluginName(folderName);
                if (compareNoCase(normalizedFolder, normalizedSearch) == 0) {
                    result.found = true;
                    result.path = pluginPath;
                    result.folderName = folderName;
                    return result;
                }
            }
        }

        return result;
    }

    /**
     * Normalize plugin name by removing common prefixes
     * Examples:
     * - "cfwheels-bcrypt" -> "bcrypt"
     * - "CFWheels Bcrypt" -> "bcrypt"
     * - "wheels-bcrypt" -> "bcrypt"
     * - "bcrypt" -> "bcrypt"
     */
    private function normalizePluginName(required string pluginName) {
        var normalized = trim(arguments.pluginName);

        // Remove common prefixes (case insensitive)
        normalized = reReplaceNoCase(normalized, "^cfwheels[\s-]+", "");
        normalized = reReplaceNoCase(normalized, "^wheels[\s-]+", "");

        // Remove trailing -plugin suffix
        normalized = reReplaceNoCase(normalized, "[\s-]+plugin$", "");

        // Convert to lowercase and remove extra spaces
        normalized = lCase(trim(normalized));

        return normalized;
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