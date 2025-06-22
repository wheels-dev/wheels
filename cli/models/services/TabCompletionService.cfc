/**
 * Tab Completion Service for Wheels CLI
 * Provides common tab completion functions for commands
 * 
 * @singleton
 * @author CFWheels Team
 * @version 3.0.0
 */
component accessors="true" singleton {
    
    // DI Properties
    property name="fileSystem" inject="FileSystem";
    property name="log" inject="logbox:logger:{this}";
    property name="projectService" inject="ProjectService@wheelscli";
    property name="wheelsService" inject="WheelsService@wheelscli";
    property name="templateService" inject="TemplateService@wheelscli";
    property name="migrationService" inject="MigrationService@wheelscli";
    property name="configService" inject="ConfigService@wheelscli";
    
    /**
     * Constructor
     */
    function init() {
        return this;
    }
    
    /**
     * Get model names for tab completion
     */
    function getModelNames(string paramSoFar = "", struct context = {}) {
        var projectPath = structKeyExists(arguments.context, "projectPath") ? arguments.context.projectPath : shell.pwd();
        var models = [];
        
        try {
            var modelsPath = projectPath & "/app/models";
            if (directoryExists(modelsPath)) {
                var files = directoryList(modelsPath, false, "name", "*.cfc");
                
                for (var file in files) {
                    var modelName = listFirst(file, ".");
                    // Skip base classes
                    if (!listFindNoCase("Model,Base,Abstract", modelName)) {
                        arrayAppend(models, modelName);
                    }
                }
            }
        } catch (any e) {
            log.debug("Error getting model names for completion: #e.message#");
        }
        
        return filterCompletions(models, arguments.paramSoFar);
    }
    
    /**
     * Get controller names for tab completion
     */
    function getControllerNames(string paramSoFar = "", struct context = {}) {
        var projectPath = structKeyExists(arguments.context, "projectPath") ? arguments.context.projectPath : shell.pwd();
        var controllers = [];
        
        try {
            var controllersPath = projectPath & "/app/controllers";
            if (directoryExists(controllersPath)) {
                var files = directoryList(controllersPath, false, "name", "*.cfc");
                
                for (var file in files) {
                    var controllerName = listFirst(file, ".");
                    // Skip base classes
                    if (!listFindNoCase("Controller,Base,Abstract,Application", controllerName)) {
                        arrayAppend(controllers, controllerName);
                    }
                }
            }
        } catch (any e) {
            log.debug("Error getting controller names for completion: #e.message#");
        }
        
        return filterCompletions(controllers, arguments.paramSoFar);
    }
    
    /**
     * Get migration names for tab completion
     */
    function getMigrationNames(string paramSoFar = "", struct context = {}) {
        var projectPath = structKeyExists(arguments.context, "projectPath") ? arguments.context.projectPath : shell.pwd();
        var migrations = [];
        
        try {
            var migrationFiles = getMigrationService().getMigrationFiles(projectPath);
            
            for (var migration in migrationFiles) {
                arrayAppend(migrations, migration.name);
            }
        } catch (any e) {
            log.debug("Error getting migration names for completion: #e.message#");
        }
        
        return filterCompletions(migrations, arguments.paramSoFar);
    }
    
    /**
     * Get migration versions for tab completion
     */
    function getMigrationVersions(string paramSoFar = "", struct context = {}) {
        var projectPath = structKeyExists(arguments.context, "projectPath") ? arguments.context.projectPath : shell.pwd();
        var versions = [];
        
        try {
            var migrationFiles = getMigrationService().getMigrationFiles(projectPath);
            
            for (var migration in migrationFiles) {
                arrayAppend(versions, migration.version);
            }
        } catch (any e) {
            log.debug("Error getting migration versions for completion: #e.message#");
        }
        
        return filterCompletions(versions, arguments.paramSoFar);
    }
    
    /**
     * Get environment names for tab completion
     */
    function getEnvironments(string paramSoFar = "", struct context = {}) {
        var environments = ["development", "testing", "production", "maintenance"];
        
        // Check for custom environments in config
        var customEnvs = getConfigService().get("environments", []);
        for (var env in customEnvs) {
            if (!arrayFindNoCase(environments, env)) {
                arrayAppend(environments, env);
            }
        }
        
        return filterCompletions(environments, arguments.paramSoFar);
    }
    
    /**
     * Get database types for tab completion
     */
    function getDatabaseTypes(string paramSoFar = "", struct context = {}) {
        var databases = ["sqlite", "mysql", "postgresql", "sqlserver"];
        return filterCompletions(databases, arguments.paramSoFar);
    }
    
    /**
     * Get template names for tab completion
     */
    function getSnippetNames(string paramSoFar = "", struct context = {}) {
        var templateType = structKeyExists(arguments.context, "type") ? arguments.context.type : "";
        var templates = [];
        
        try {
            var availableTemplates = getTemplateService().listTemplates(templateType);
            
            // Add built-in templates
            if (structKeyExists(availableTemplates.builtin, templateType)) {
                for (var template in availableTemplates.builtin[templateType]) {
                    arrayAppend(templates, template);
                }
            }
            
            // Add custom templates
            if (structKeyExists(availableTemplates.custom, templateType)) {
                for (var template in availableTemplates.custom[templateType]) {
                    if (!arrayFindNoCase(templates, template)) {
                        arrayAppend(templates, template & " (custom)");
                    }
                }
            }
        } catch (any e) {
            log.debug("Error getting template names for completion: #e.message#");
        }
        
        return filterCompletions(templates, arguments.paramSoFar);
    }
    
    /**
     * Get template types for tab completion
     */
    function getSnippetTypes(string paramSoFar = "", struct context = {}) {
        var types = ["model", "controller", "view", "migration", "test"];
        return filterCompletions(types, arguments.paramSoFar);
    }
    
    /**
     * Get test types for tab completion
     */
    function getTestTypes(string paramSoFar = "", struct context = {}) {
        var types = ["model", "controller", "integration", "unit", "helper"];
        return filterCompletions(types, arguments.paramSoFar);
    }
    
    /**
     * Get property types for tab completion
     */
    function getPropertyTypes(string paramSoFar = "", struct context = {}) {
        var types = [
            "string",
            "integer", 
            "numeric",
            "boolean",
            "date",
            "datetime",
            "time",
            "text",
            "uuid",
            "binary",
            "decimal",
            "float"
        ];
        return filterCompletions(types, arguments.paramSoFar);
    }
    
    /**
     * Get property options for tab completion
     */
    function getPropertyOptions(string paramSoFar = "", struct context = {}) {
        var options = [
            "required",
            "unique", 
            "email",
            "default",
            "null",
            "index",
            "references"
        ];
        return filterCompletions(options, arguments.paramSoFar);
    }
    
    /**
     * Get server names for tab completion
     */
    function getServerNames(string paramSoFar = "", struct context = {}) {
        var servers = [];
        
        try {
            // Get server list from CommandBox
            var serverList = command("server list --json").run(returnOutput=true);
            if (isJSON(serverList)) {
                var serverData = deserializeJSON(serverList);
                for (var serverName in serverData) {
                    arrayAppend(servers, serverName);
                }
            }
        } catch (any e) {
            log.debug("Error getting server names for completion: #e.message#");
        }
        
        return filterCompletions(servers, arguments.paramSoFar);
    }
    
    /**
     * Get port numbers for tab completion
     */
    function getPortNumbers(string paramSoFar = "", struct context = {}) {
        var ports = [];
        
        // Common development ports
        var commonPorts = [
            "3000", "3001", "3002",
            "4000", "4001", "4002", 
            "5000", "5001", "5002",
            "8000", "8001", "8002",
            "8080", "8081", "8082",
            "8888", "9000", "9001"
        ];
        
        // Add current server ports
        try {
            var serverList = command("server list --json").run(returnOutput=true);
            if (isJSON(serverList)) {
                var serverData = deserializeJSON(serverList);
                for (var server in serverData) {
                    if (structKeyExists(server, "port") && !arrayFindNoCase(commonPorts, server.port)) {
                        arrayAppend(commonPorts, server.port);
                    }
                }
            }
        } catch (any e) {
            // Ignore
        }
        
        return filterCompletions(commonPorts, arguments.paramSoFar);
    }
    
    /**
     * Get file paths for tab completion
     */
    function getFilePaths(string paramSoFar = "", struct context = {}) {
        var basePath = structKeyExists(arguments.context, "basePath") ? arguments.context.basePath : shell.pwd();
        var extension = structKeyExists(arguments.context, "extension") ? arguments.context.extension : "*";
        var paths = [];
        
        try {
            var currentPath = arguments.paramSoFar;
            var directory = basePath;
            
            // Handle relative paths
            if (len(currentPath)) {
                if (directoryExists(basePath & "/" & currentPath)) {
                    directory = basePath & "/" & currentPath;
                    currentPath = "";
                } else if (find("/", currentPath)) {
                    directory = basePath & "/" & getDirectoryFromPath(currentPath);
                    currentPath = getFileFromPath(currentPath);
                }
            }
            
            if (directoryExists(directory)) {
                var items = directoryList(directory, false, "query");
                
                for (var item in items) {
                    if (item.type == "Dir") {
                        arrayAppend(paths, item.name & "/");
                    } else if (extension == "*" || listFindNoCase(extension, listLast(item.name, "."))) {
                        arrayAppend(paths, item.name);
                    }
                }
            }
        } catch (any e) {
            log.debug("Error getting file paths for completion: #e.message#");
        }
        
        return filterCompletions(paths, currentPath);
    }
    
    /**
     * Get action names for controllers
     */
    function getActionNames(string paramSoFar = "", struct context = {}) {
        var actions = [];
        
        // Common RESTful actions
        var restfulActions = ["index", "show", "new", "create", "edit", "update", "delete"];
        
        // Add any controller-specific actions if controller is specified
        if (structKeyExists(arguments.context, "controller")) {
            var controllerPath = shell.pwd() & "/app/controllers/" & arguments.context.controller & ".cfc";
            
            if (fileExists(controllerPath)) {
                try {
                    var content = fileRead(controllerPath);
                    var functionPattern = 'function\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(';
                    var matches = reMatchNoCase(functionPattern, content);
                    
                    for (var match in matches) {
                        var functionName = reReplaceNoCase(match, functionPattern, "\1");
                        if (!listFindNoCase("init,config,$", left(functionName, 1))) {
                            arrayAppend(actions, functionName);
                        }
                    }
                } catch (any e) {
                    // Ignore
                }
            }
        }
        
        // Combine and deduplicate
        for (var action in restfulActions) {
            if (!arrayFindNoCase(actions, action)) {
                arrayAppend(actions, action);
            }
        }
        
        return filterCompletions(actions, arguments.paramSoFar);
    }
    
    /**
     * Get format types for tab completion
     */
    function getFormatTypes(string paramSoFar = "", struct context = {}) {
        var formats = ["text", "json", "xml", "table", "csv"];
        return filterCompletions(formats, arguments.paramSoFar);
    }
    
    /**
     * Filter completions based on partial input
     */
    private function filterCompletions(required array options, string partial = "") {
        if (!len(arguments.partial)) {
            return arguments.options;
        }
        
        var filtered = [];
        var lowerPartial = lCase(arguments.partial);
        
        for (var option in arguments.options) {
            if (findNoCase(lowerPartial, option) == 1) {
                arrayAppend(filtered, option);
            }
        }
        
        // If no prefix matches, try contains
        if (!arrayLen(filtered)) {
            for (var option in arguments.options) {
                if (findNoCase(lowerPartial, option)) {
                    arrayAppend(filtered, option);
                }
            }
        }
        
        // Sort results
        arraySort(filtered, "textnocase");
        
        return filtered;
    }
    
    /**
     * Get boolean options
     */
    function getBooleanOptions(string paramSoFar = "", struct context = {}) {
        return filterCompletions(["true", "false"], arguments.paramSoFar);
    }
    
    /**
     * Get yes/no options
     */
    function getYesNoOptions(string paramSoFar = "", struct context = {}) {
        return filterCompletions(["yes", "no"], arguments.paramSoFar);
    }
}