component {
    
    property name="codeGenerationService" inject="CodeGenerationService@wheels-cli";
    property name="migrationService" inject="MigrationService@wheels-cli";
    property name="helpers" inject="helpers@wheels";
    
    /**
     * Generate a complete scaffold (model, controller, views, migration)
     */
    function generateScaffold(
        required string name,
        string properties = "",
        string belongsTo = "",
        string hasMany = "",
        boolean api = false,
        boolean tests = true,
        boolean force = false,
        string baseDirectory = ""
    ) {
        var results = {
            success: true,
            generated: [],
            errors: [],
            rollback: []
        };
        
        try {
            // Start transaction-like operation
            
            // 1. Generate Model
            var modelResult = codeGenerationService.generateModel(
                name = arguments.name,
                properties = parseProperties(arguments.properties),
                force = arguments.force,
                baseDirectory = arguments.baseDirectory
            );
            
            if (modelResult.success) {
                arrayAppend(results.generated, {
                    type: "model",
                    path: modelResult.path
                });
                arrayAppend(results.rollback, modelResult.path);
                // Model created successfully
            } else {
                throw(type="ScaffoldError", message="Failed to create model: #modelResult.error#");
            }
            
            // 2. Generate Migration
            try {
                var migrationPath = migrationService.createMigration(
                    name = "create_#variables.helpers.pluralize(lCase(arguments.name))#_table",
                    table = variables.helpers.pluralize(lCase(arguments.name)),
                    model = arguments.name,
                    type = "create",
                    baseDirectory = arguments.baseDirectory
                );
                
                arrayAppend(results.generated, {
                    type: "migration",
                    path: migrationPath
                });
                arrayAppend(results.rollback, migrationPath);
            } catch (any e) {
                throw(type="ScaffoldError", message="Failed to create migration: #e.message#");
            }
            
            // 3. Generate Controller
            var controllerResult = codeGenerationService.generateController(
                name = variables.helpers.pluralize(arguments.name),
                rest = true,
                force = arguments.force,
                baseDirectory = arguments.baseDirectory
            );
            
            if (controllerResult.success) {
                arrayAppend(results.generated, {
                    type: "controller",
                    path: controllerResult.path
                });
                arrayAppend(results.rollback, controllerResult.path);
                // Controller created successfully
            } else {
                throw(type="ScaffoldError", message="Failed to create controller: #controllerResult.error#");
            }
            
            // 4. Generate Views (unless API-only)
            if (!arguments.api) {
                // Creating views...
                var viewActions = ["index", "show", "new", "edit", "_form"];
                var viewsCreated = 0;
                
                for (var action in viewActions) {
                    var viewResult = codeGenerationService.generateView(
                        name = variables.helpers.pluralize(arguments.name),
                        action = action,
                        force = arguments.force,
                        baseDirectory = arguments.baseDirectory
                    );
                    
                    if (viewResult.success) {
                        arrayAppend(results.generated, {
                            type: "view",
                            path: viewResult.path
                        });
                        arrayAppend(results.rollback, viewResult.path);
                        viewsCreated++;
                    }
                }
                // Views created successfully
            }
            
            // 5. Generate Tests
            if (arguments.tests) {
                // Creating tests...
                
                // Model test
                var modelTestResult = codeGenerationService.generateTest(
                    type = "model",
                    name = arguments.name,
                    baseDirectory = arguments.baseDirectory
                );
                if (modelTestResult.success) {
                    arrayAppend(results.generated, {
                        type: "test",
                        path: modelTestResult.path
                    });
                    arrayAppend(results.rollback, modelTestResult.path);
                }
                
                // Controller test
                var controllerTestResult = codeGenerationService.generateTest(
                    type = "controller",
                    name = variables.helpers.pluralize(arguments.name),
                    baseDirectory = arguments.baseDirectory
                );
                if (controllerTestResult.success) {
                    arrayAppend(results.generated, {
                        type: "test",
                        path: controllerTestResult.path
                    });
                    arrayAppend(results.rollback, controllerTestResult.path);
                }
                
                // Tests created successfully
            }
            
            // 6. Update routes
            var routesUpdated = updateRoutes(arguments.name, arguments.baseDirectory);
            if (routesUpdated) {
                // Routes updated successfully
            }
            
            // Success - scaffold completed
            
        } catch (any e) {
            // Rollback on error
            results.success = false;
            arrayAppend(results.errors, e.message);
            
            if (e.type == "ScaffoldError") {
                // Scaffold failed
                rollbackScaffold(results.rollback);
            } else {
                rethrow;
            }
        }
        
        return results;
    }
    
    /**
     * Parse properties string into structured array
     */
    private function parseProperties(required string propertiesString) {
        var properties = [];
        
        if (len(arguments.propertiesString)) {
            var propList = listToArray(arguments.propertiesString);
            
            for (var prop in propList) {
                var parts = listToArray(prop, ":");
                if (arrayLen(parts) >= 2) {
                    var property = {
                        name: trim(parts[1]),
                        type: trim(parts[2]),
                        required: false,
                        unique: false,
                        default: ""
                    };
                    
                    // Check for modifiers
                    if (arrayLen(parts) > 2) {
                        for (var i = 3; i <= arrayLen(parts); i++) {
                            var modifier = trim(parts[i]);
                            switch (modifier) {
                                case "required":
                                    property.required = true;
                                    break;
                                case "unique":
                                    property.unique = true;
                                    break;
                                default:
                                    if (findNoCase("default=", modifier)) {
                                        property.default = replaceNoCase(modifier, "default=", "");
                                    }
                            }
                        }
                    }
                    
                    arrayAppend(properties, property);
                }
            }
        }
        
        return properties;
    }
    
    /**
     * Update routes file to include resource
     */
    private function updateRoutes(required string name, string baseDirectory = "") {
        try {
            var routesPath = resolvePath("config/routes.cfm", arguments.baseDirectory);
            if (!fileExists(routesPath)) {
                routesPath = resolvePath("app/config/routes.cfm", arguments.baseDirectory);
            }
            
            if (fileExists(routesPath)) {
                var content = fileRead(routesPath);
                var resourceName = lCase(variables.helpers.pluralize(arguments.name));
                var resourceRoute = '.resources("' & resourceName & '")';
                
                // Check if resource already exists
                if (!findNoCase(resourceRoute, content)) {
                    // Find the CLI-Appends-Here marker and add route there
                    var markerPattern = '// CLI-Appends-Here';
                    var indent = '';
                    
                    // Try to find marker with various indentation levels
                    if (find(chr(9) & chr(9) & chr(9) & markerPattern, content)) {
                        indent = chr(9) & chr(9) & chr(9);
                    } else if (find(chr(9) & chr(9) & markerPattern, content)) {
                        indent = chr(9) & chr(9);
                    } else if (find(chr(9) & markerPattern, content)) {
                        indent = chr(9);
                    }
                    
                    var fullMarkerPattern = indent & markerPattern;
                    var inject = indent & resourceRoute;
                    
                    if (find(fullMarkerPattern, content)) {
                        // Replace the marker with the new route followed by the marker on a new line
                        content = replace(content, fullMarkerPattern, inject & chr(10) & fullMarkerPattern, 'all');
                        fileWrite(routesPath, content);
                        return true;
                    } else {
                        // If no marker found, try to add before .end()
                        if (find('.end()', content)) {
                            content = replace(content, '.end()', resourceRoute & chr(10) & chr(9) & chr(9) & chr(9) & '.end()', 'all');
                            fileWrite(routesPath, content);
                            return true;
                        }
                    }
                }
            }
        } catch (any e) {
            // Silent fail - routes update is not critical
        }
        
        return false;
    }
    
    /**
     * Rollback created files on error
     */
    private function rollbackScaffold(required array files) {
        if (arrayLen(arguments.files)) {
            for (var file in arguments.files) {
                if (fileExists(file)) {
                    try {
                        fileDelete(file);
                        // File removed
                    } catch (any e) {
                        // Silent fail
                    }
                }
            }
        }
    }
    
    /**
     * Validate scaffold requirements
     */
    function validateScaffold(required string name, string baseDirectory = "") {
        var errors = [];
        
        // Check name
        if (!len(trim(arguments.name))) {
            arrayAppend(errors, "Resource name is required");
        }
        
        // Check for valid name format
        if (!reFindNoCase("^[a-zA-Z][a-zA-Z0-9_]*$", arguments.name)) {
            arrayAppend(errors, "Resource name must start with a letter and contain only letters, numbers, and underscores");
        }
        
        // Check if already exists
        var modelPath = resolvePath("models/#variables.helpers.capitalize(arguments.name)#.cfc", arguments.baseDirectory);
        if (fileExists(modelPath)) {
            arrayAppend(errors, "Model already exists: #modelPath#");
        }
        
        var controllerPath = resolvePath("controllers/#variables.helpers.pluralize(variables.helpers.capitalize(arguments.name))#.cfc", arguments.baseDirectory);
        if (fileExists(controllerPath)) {
            arrayAppend(errors, "Controller already exists: #controllerPath#");
        }
        
        return {
            valid: arrayLen(errors) == 0,
            errors: errors
        };
    }
    
    /**
     * Resolve a file path  
     */
    private function resolvePath(path, baseDirectory = "") {
        // Prepend app/ to common paths if not already present
        var appPath = arguments.path;
        if (!findNoCase("app/", appPath) && !findNoCase("tests/", appPath)) {
            // Common app directories
            if (reFind("^(controllers|models|views|migrator)/", appPath)) {
                appPath = "app/" & appPath;
            }
        }
        
        // If path is already absolute, return it
        if (left(appPath, 1) == "/" || mid(appPath, 2, 1) == ":") {
            return appPath;
        }
        
        // Build absolute path from current working directory
        // Use provided base directory or fall back to expandPath
        var baseDir = len(arguments.baseDirectory) ? arguments.baseDirectory : expandPath(".");
        
        // Ensure we have a trailing slash
        if (right(baseDir, 1) != "/") {
            baseDir &= "/";
        }
        
        return baseDir & appPath;
    }
}