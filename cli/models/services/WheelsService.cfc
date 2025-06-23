/**
 * Wheels Service for CLI
 * Handles Wheels framework-specific operations
 * 
 * @singleton
 * @author CFWheels Team
 * @version 3.0.0
 */
component accessors="true" singleton {
    
    // DI Properties
    property name="fileSystem" inject="FileSystem";
    property name="log" inject="logbox:logger:{this}";
    property name="configService" inject="ConfigService@wheels-cli-next";
    property name="projectService" inject="ProjectService@wheels-cli-next";
    
    // Service Properties
    property name="wheelsVersion" type="string";
    property name="wheelsPath" type="string";
    property name="cacheTimeout" type="numeric" default="300"; // 5 minutes
    property name="lastCheck" type="date";
    
    /**
     * Constructor
     */
    function init() {
        variables.wheelsVersion = "";
        variables.wheelsPath = "";
        variables.lastCheck = dateAdd("n", -10, now()); // Force initial check
        return this;
    }
    
    /**
     * Get Wheels version from project
     */
    function getVersion(string projectPath = "") {
        var path = len(arguments.projectPath) ? arguments.projectPath : shell.pwd();
        
        // Check cache
        if (len(variables.wheelsVersion) && dateDiff("s", variables.lastCheck, now()) < variables.cacheTimeout) {
            return variables.wheelsVersion;
        }
        
        // Detect version
        var projectInfo = getProjectService().detectProject(path);
        
        if (projectInfo.isWheelsProject && len(projectInfo.version)) {
            variables.wheelsVersion = projectInfo.version;
            variables.wheelsPath = path & "/vendor/wheels";
            variables.lastCheck = now();
            return variables.wheelsVersion;
        }
        
        return "Unknown";
    }
    
    /**
     * Check if minimum version requirement is met
     */
    function meetsMinimumVersion(required string minimumVersion, string projectPath = "") {
        var currentVersion = getVersion(arguments.projectPath);
        
        if (currentVersion == "Unknown") {
            return false;
        }
        
        return compareVersions(currentVersion, arguments.minimumVersion) >= 0;
    }
    
    /**
     * Compare two version numbers
     */
    function compareVersions(required string version1, required string version2) {
        var v1Parts = listToArray(arguments.version1, ".");
        var v2Parts = listToArray(arguments.version2, ".");
        
        // Pad arrays to same length
        var maxLength = max(arrayLen(v1Parts), arrayLen(v2Parts));
        
        for (var i = arrayLen(v1Parts) + 1; i <= maxLength; i++) {
            arrayAppend(v1Parts, "0");
        }
        
        for (var i = arrayLen(v2Parts) + 1; i <= maxLength; i++) {
            arrayAppend(v2Parts, "0");
        }
        
        // Compare each part
        for (var i = 1; i <= maxLength; i++) {
            var part1 = val(v1Parts[i]);
            var part2 = val(v2Parts[i]);
            
            if (part1 > part2) {
                return 1;
            } else if (part1 < part2) {
                return -1;
            }
        }
        
        return 0;
    }
    
    /**
     * Get available Wheels versions from package registry
     */
    function getAvailableVersions() {
        try {
            // This would query ForgeBox or other package registry
            log.debug("Fetching available Wheels versions");
            
            // For now, return mock data
            return [
                "3.0.0",
                "2.5.0", 
                "2.4.1",
                "2.4.0",
                "2.3.0"
            ];
        } catch (any e) {
            log.error("Failed to fetch available versions: #e.message#", e);
            return [];
        }
    }
    
    /**
     * Check for updates
     */
    function checkForUpdates(string projectPath = "") {
        var currentVersion = getVersion(arguments.projectPath);
        var availableVersions = getAvailableVersions();
        
        if (currentVersion == "Unknown" || !arrayLen(availableVersions)) {
            return {
                updateAvailable = false,
                currentVersion = currentVersion,
                latestVersion = "",
                message = "Unable to check for updates"
            };
        }
        
        var latestVersion = availableVersions[1];
        var updateAvailable = compareVersions(latestVersion, currentVersion) > 0;
        
        return {
            updateAvailable = updateAvailable,
            currentVersion = currentVersion,
            latestVersion = latestVersion,
            availableVersions = availableVersions,
            message = updateAvailable ? "Update available: #latestVersion#" : "You have the latest version"
        };
    }
    
    /**
     * Get Wheels configuration
     */
    function getWheelsConfig(string projectPath = "") {
        var path = len(arguments.projectPath) ? arguments.projectPath : shell.pwd();
        var config = {};
        
        // Check for config files
        var configPaths = [
            path & "/config/settings.cfm",
            path & "/config/development.cfm",
            path & "/config/production.cfm",
            path & "/config/testing.cfm"
        ];
        
        for (var configPath in configPaths) {
            if (fileExists(configPath)) {
                config[getFileFromPath(configPath)] = {
                    exists = true,
                    path = configPath,
                    size = getFileInfo(configPath).size,
                    lastModified = getFileInfo(configPath).lastModified
                };
            }
        }
        
        return config;
    }
    
    /**
     * Get Wheels routes
     */
    function getRoutes(string projectPath = "") {
        var path = len(arguments.projectPath) ? arguments.projectPath : shell.pwd();
        var routesFile = path & "/config/routes.cfm";
        
        if (!fileExists(routesFile)) {
            log.debug("Routes file not found: #routesFile#");
            return [];
        }
        
        // This is a simplified version - actual implementation would parse the routes
        return parseRoutesFile(routesFile);
    }
    
    /**
     * Parse routes file
     */
    private function parseRoutesFile(required string filePath) {
        var routes = [];
        
        try {
            var content = fileRead(arguments.filePath);
            
            // Look for common route patterns
            var patterns = [
                'resources\s*\(\s*["'']([^"'']+)["'']',
                'resource\s*\(\s*["'']([^"'']+)["'']',
                'get\s*\(\s*["'']([^"'']+)["'']',
                'post\s*\(\s*["'']([^"'']+)["'']',
                'put\s*\(\s*["'']([^"'']+)["'']',
                'patch\s*\(\s*["'']([^"'']+)["'']',
                'delete\s*\(\s*["'']([^"'']+)["'']',
                'root\s*\(\s*to\s*=\s*["'']([^"'']+)["'']'
            ];
            
            for (var pattern in patterns) {
                var matches = reMatchNoCase(pattern, content);
                for (var match in matches) {
                    arrayAppend(routes, {
                        pattern = match,
                        type = listFirst(pattern, "\s*("),
                        parsed = true
                    });
                }
            }
            
        } catch (any e) {
            log.error("Failed to parse routes file: #e.message#", e);
        }
        
        return routes;
    }
    
    /**
     * Get Wheels plugins
     */
    function getPlugins(string projectPath = "") {
        var path = len(arguments.projectPath) ? arguments.projectPath : shell.pwd();
        var pluginsPath = path & "/plugins";
        var plugins = [];
        
        if (!directoryExists(pluginsPath)) {
            return plugins;
        }
        
        try {
            var dirs = directoryList(pluginsPath, false, "query");
            
            for (var dir in dirs) {
                if (dir.type == "Dir") {
                    var pluginInfo = getPluginInfo(pluginsPath & "/" & dir.name);
                    if (structCount(pluginInfo)) {
                        arrayAppend(plugins, pluginInfo);
                    }
                }
            }
        } catch (any e) {
            log.error("Failed to get plugins: #e.message#", e);
        }
        
        return plugins;
    }
    
    /**
     * Get plugin information
     */
    private function getPluginInfo(required string pluginPath) {
        var info = {
            name = getFileFromPath(arguments.pluginPath),
            path = arguments.pluginPath,
            version = "Unknown",
            enabled = true
        };
        
        // Check for plugin config file
        var configFiles = [
            arguments.pluginPath & "/config.json",
            arguments.pluginPath & "/box.json",
            arguments.pluginPath & "/plugin.json"
        ];
        
        for (var configFile in configFiles) {
            if (fileExists(configFile)) {
                try {
                    var config = deserializeJSON(fileRead(configFile));
                    if (structKeyExists(config, "version")) {
                        info.version = config.version;
                    }
                    if (structKeyExists(config, "name")) {
                        info.displayName = config.name;
                    }
                    if (structKeyExists(config, "description")) {
                        info.description = config.description;
                    }
                    break;
                } catch (any e) {
                    // Ignore parse errors
                }
            }
        }
        
        return info;
    }
    
    /**
     * Reload Wheels application
     */
    function reloadApplication(string projectPath = "", string password = "") {
        var path = len(arguments.projectPath) ? arguments.projectPath : shell.pwd();
        
        // This would typically make an HTTP request to reload the app
        // For CLI purposes, we might clear caches or restart the server
        
        log.info("Reloading Wheels application at: #path#");
        
        return {
            success = true,
            message = "Application reload requested"
        };
    }
    
    /**
     * Get Wheels environment
     */
    function getEnvironment(string projectPath = "") {
        var path = len(arguments.projectPath) ? arguments.projectPath : shell.pwd();
        
        // Check for environment indicators
        var env = getConfigService().getEnvironment();
        
        // Validate against available environments
        var envFile = path & "/config/environment.cfm";
        if (fileExists(envFile)) {
            // Parse environment file for validation
            log.debug("Found environment file: #envFile#");
        }
        
        return env;
    }
    
    /**
     * Set Wheels environment
     */
    function setEnvironment(required string environment, string projectPath = "") {
        var path = len(arguments.projectPath) ? arguments.projectPath : shell.pwd();
        
        // This would typically update configuration files or environment variables
        log.info("Setting Wheels environment to: #arguments.environment#");
        
        return {
            success = true,
            previousEnvironment = getEnvironment(path),
            newEnvironment = arguments.environment
        };
    }
    
    /**
     * Get models list
     */
    function getModels(string projectPath = "") {
        var path = len(arguments.projectPath) ? arguments.projectPath : shell.pwd();
        var modelsPath = path & "/app/models";
        var models = [];
        
        if (!directoryExists(modelsPath)) {
            return models;
        }
        
        try {
            var files = directoryList(modelsPath, true, "query", "*.cfc");
            
            for (var file in files) {
                var modelName = listFirst(file.name, ".");
                var relativePath = replace(file.directory, modelsPath, "");
                relativePath = replace(relativePath, "\", "/", "all");
                
                arrayAppend(models, {
                    name = modelName,
                    file = file.name,
                    path = file.directory & "/" & file.name,
                    relativePath = relativePath,
                    size = file.size,
                    lastModified = file.dateLastModified
                });
            }
        } catch (any e) {
            log.error("Failed to get models: #e.message#", e);
        }
        
        return models;
    }
    
    /**
     * Get controllers list
     */
    function getControllers(string projectPath = "") {
        var path = len(arguments.projectPath) ? arguments.projectPath : shell.pwd();
        var controllersPath = path & "/app/controllers";
        var controllers = [];
        
        if (!directoryExists(controllersPath)) {
            return controllers;
        }
        
        try {
            var files = directoryList(controllersPath, true, "query", "*.cfc");
            
            for (var file in files) {
                var controllerName = listFirst(file.name, ".");
                var relativePath = replace(file.directory, controllersPath, "");
                relativePath = replace(relativePath, "\", "/", "all");
                
                arrayAppend(controllers, {
                    name = controllerName,
                    file = file.name,
                    path = file.directory & "/" & file.name,
                    relativePath = relativePath,
                    size = file.size,
                    lastModified = file.dateLastModified
                });
            }
        } catch (any e) {
            log.error("Failed to get controllers: #e.message#", e);
        }
        
        return controllers;
    }
    
    /**
     * Clear Wheels caches
     */
    function clearCaches(string projectPath = "") {
        var path = len(arguments.projectPath) ? arguments.projectPath : shell.pwd();
        var results = {
            success = true,
            cleared = [],
            errors = []
        };
        
        // Common cache directories
        var cacheDirs = [
            path & "/tmp",
            path & "/cache",
            path & "/.cache"
        ];
        
        for (var cacheDir in cacheDirs) {
            if (directoryExists(cacheDir)) {
                try {
                    directoryDelete(cacheDir, true);
                    directoryCreate(cacheDir);
                    arrayAppend(results.cleared, cacheDir);
                    log.info("Cleared cache directory: #cacheDir#");
                } catch (any e) {
                    arrayAppend(results.errors, {
                        path = cacheDir,
                        error = e.message
                    });
                    log.error("Failed to clear cache: #cacheDir# - #e.message#", e);
                }
            }
        }
        
        return results;
    }
}