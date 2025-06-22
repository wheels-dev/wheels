/**
 * Configuration Service for Wheels CLI
 * Handles loading and managing configuration from .wheelscli.json files
 * 
 * @singleton
 * @author CFWheels Team
 * @version 3.0.0
 */
component accessors="true" singleton {
    
    // DI Properties
    property name="fileSystem" inject="FileSystem";
    property name="JSONUtil" inject="JSONUtil";
    property name="log" inject="logbox:logger:{this}";
    
    // Service Properties
    property name="settings" type="struct";
    property name="configFilePath" type="string";
    property name="projectConfig" type="struct";
    property name="environmentConfig" type="struct";
    property name="isLoaded" type="boolean" default="false";
    
    /**
     * Constructor
     */
    function init(struct settings = {}) {
        variables.settings = arguments.settings;
        variables.projectConfig = {};
        variables.environmentConfig = {};
        variables.configFilePath = "";
        variables.isLoaded = false;
        
        return this;
    }
    
    /**
     * Load configuration from file system
     */
    function loadConfiguration(string startPath = "") {
        var searchPath = len(arguments.startPath) ? arguments.startPath : shell.pwd();
        
        // Find configuration file
        variables.configFilePath = findConfigFile(searchPath);
        
        if (len(variables.configFilePath)) {
            try {
                // Load project configuration
                var configContent = fileRead(variables.configFilePath);
                variables.projectConfig = deserializeJSON(configContent);
                
                log.info("Loaded configuration from: #variables.configFilePath#");
                
                // Load environment-specific configuration
                loadEnvironmentConfig();
                
                // Merge configurations
                mergeConfigurations();
                
                variables.isLoaded = true;
            } catch (any e) {
                log.error("Failed to load configuration: #e.message#", e);
                variables.projectConfig = {};
            }
        } else {
            log.debug("No configuration file found, using defaults");
            variables.projectConfig = {};
        }
        
        return this;
    }
    
    /**
     * Find configuration file in search paths
     */
    private function findConfigFile(required string startPath) {
        var configFileName = getSetting("configFileName", ".wheelscli.json");
        var searchPaths = getSetting("configSearchPaths", [".", "config", ".wheels"]);
        
        // Check current directory first
        var currentPath = arguments.startPath;
        
        // Walk up the directory tree
        while (len(currentPath) && currentPath != "/" && !findNoCase(":", currentPath)) {
            // Check each search path
            for (var searchPath in searchPaths) {
                var checkPath = currentPath & "/" & searchPath & "/" & configFileName;
                checkPath = replace(checkPath, "//", "/", "all");
                
                if (fileExists(checkPath)) {
                    return checkPath;
                }
            }
            
            // Also check root of current path
            var rootCheck = currentPath & "/" & configFileName;
            if (fileExists(rootCheck)) {
                return rootCheck;
            }
            
            // Move up one directory
            currentPath = getDirectoryFromPath(currentPath);
            currentPath = left(currentPath, len(currentPath) - 1); // Remove trailing slash
        }
        
        return "";
    }
    
    /**
     * Load environment-specific configuration
     */
    private function loadEnvironmentConfig() {
        var environment = getEnvironment();
        
        if (!len(environment)) {
            return;
        }
        
        // Check for environment-specific config file
        var envConfigPath = getDirectoryFromPath(variables.configFilePath) & 
                           ".wheelscli." & environment & ".json";
        
        if (fileExists(envConfigPath)) {
            try {
                var envContent = fileRead(envConfigPath);
                variables.environmentConfig = deserializeJSON(envContent);
                log.info("Loaded environment configuration for: #environment#");
            } catch (any e) {
                log.error("Failed to load environment configuration: #e.message#", e);
                variables.environmentConfig = {};
            }
        }
    }
    
    /**
     * Merge configurations (defaults -> project -> environment)
     */
    private function mergeConfigurations() {
        // Start with defaults from settings
        var merged = duplicate(getSetting("defaults", {}));
        
        // Merge project configuration
        structAppend(merged, variables.projectConfig, true);
        
        // Merge environment configuration (highest priority)
        structAppend(merged, variables.environmentConfig, true);
        
        // Store merged configuration
        variables.projectConfig = merged;
    }
    
    /**
     * Get configuration value
     */
    function get(required string key, any defaultValue = "") {
        // Check if configuration is loaded
        if (!variables.isLoaded) {
            loadConfiguration();
        }
        
        // Handle nested keys (e.g., "database.type")
        if (find(".", arguments.key)) {
            return getNestedValue(variables.projectConfig, arguments.key, arguments.defaultValue);
        }
        
        // Simple key lookup
        if (structKeyExists(variables.projectConfig, arguments.key)) {
            return variables.projectConfig[arguments.key];
        }
        
        // Check settings defaults
        var defaults = getSetting("defaults", {});
        if (structKeyExists(defaults, arguments.key)) {
            return defaults[arguments.key];
        }
        
        return arguments.defaultValue;
    }
    
    /**
     * Set configuration value (runtime only, not persisted)
     */
    function set(required string key, required any value) {
        if (!variables.isLoaded) {
            loadConfiguration();
        }
        
        // Handle nested keys
        if (find(".", arguments.key)) {
            setNestedValue(variables.projectConfig, arguments.key, arguments.value);
        } else {
            variables.projectConfig[arguments.key] = arguments.value;
        }
        
        return this;
    }
    
    /**
     * Check if configuration key exists
     */
    function has(required string key) {
        if (!variables.isLoaded) {
            loadConfiguration();
        }
        
        // Handle nested keys
        if (find(".", arguments.key)) {
            return hasNestedValue(variables.projectConfig, arguments.key);
        }
        
        return structKeyExists(variables.projectConfig, arguments.key);
    }
    
    /**
     * Get all configuration
     */
    function getAll() {
        if (!variables.isLoaded) {
            loadConfiguration();
        }
        
        return duplicate(variables.projectConfig);
    }
    
    /**
     * Save configuration to file
     */
    function save(struct config = variables.projectConfig, string path = variables.configFilePath) {
        if (!len(arguments.path)) {
            arguments.path = shell.pwd() & "/.wheelscli.json";
        }
        
        try {
            var json = getJSONUtil().serialize(
                data = arguments.config,
                sortKeys = true,
                indent = true
            );
            
            fileWrite(arguments.path, json);
            log.info("Saved configuration to: #arguments.path#");
            
            return true;
        } catch (any e) {
            log.error("Failed to save configuration: #e.message#", e);
            return false;
        }
    }
    
    /**
     * Create default configuration file
     */
    function createDefault(string path = "") {
        var configPath = len(arguments.path) ? arguments.path : shell.pwd() & "/.wheelscli.json";
        
        var defaultConfig = {
            "name": getDefaultProjectName(),
            "version": "0.0.1",
            "description": "",
            "author": getSetting("templates.defaults.author", ""),
            "license": getSetting("templates.defaults.license", "MIT"),
            "defaults": {
                "database": getSetting("defaults.database", "sqlite"),
                "template": getSetting("defaults.template", "default"),
                "environment": getSetting("defaults.environment", "development")
            },
            "commands": {},
            "templates": {
                "searchPaths": ["config/templates", ".wheels/templates"]
            }
        };
        
        return save(defaultConfig, configPath);
    }
    
    /**
     * Get current environment
     */
    function getEnvironment() {
        // Priority: CLI arg > env var > config > default
        var env = "";
        
        // Check system environment variable
        if (len(systemSettings.getSystemSetting("WHEELS_ENV", ""))) {
            env = systemSettings.getSystemSetting("WHEELS_ENV", "");
        }
        
        // Check configuration
        if (!len(env) && has("defaults.environment")) {
            env = get("defaults.environment");
        }
        
        // Default
        if (!len(env)) {
            env = getSetting("defaults.environment", "development");
        }
        
        return lCase(env);
    }
    
    /**
     * Get setting from module settings
     */
    private function getSetting(required string key, any defaultValue = "") {
        if (structKeyExists(variables.settings, arguments.key)) {
            return variables.settings[arguments.key];
        }
        return arguments.defaultValue;
    }
    
    /**
     * Get nested value from struct
     */
    private function getNestedValue(required struct data, required string key, any defaultValue = "") {
        var keys = listToArray(arguments.key, ".");
        var current = arguments.data;
        
        for (var k in keys) {
            if (isStruct(current) && structKeyExists(current, k)) {
                current = current[k];
            } else {
                return arguments.defaultValue;
            }
        }
        
        return current;
    }
    
    /**
     * Set nested value in struct
     */
    private function setNestedValue(required struct data, required string key, required any value) {
        var keys = listToArray(arguments.key, ".");
        var current = arguments.data;
        
        for (var i = 1; i < arrayLen(keys); i++) {
            if (!structKeyExists(current, keys[i])) {
                current[keys[i]] = {};
            }
            current = current[keys[i]];
        }
        
        current[keys[arrayLen(keys)]] = arguments.value;
    }
    
    /**
     * Check if nested value exists
     */
    private function hasNestedValue(required struct data, required string key) {
        var keys = listToArray(arguments.key, ".");
        var current = arguments.data;
        
        for (var k in keys) {
            if (isStruct(current) && structKeyExists(current, k)) {
                current = current[k];
            } else {
                return false;
            }
        }
        
        return true;
    }
    
    /**
     * Get default project name from directory
     */
    private function getDefaultProjectName() {
        var currentDir = shell.pwd();
        var dirName = listLast(currentDir, "/\");
        
        // Clean up the name
        dirName = reReplace(dirName, "[^a-zA-Z0-9-]", "-", "all");
        dirName = reReplace(dirName, "-+", "-", "all");
        dirName = reReplace(dirName, "^-|-$", "", "all");
        
        return len(dirName) ? dirName : "my-wheels-app";
    }
}