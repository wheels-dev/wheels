component {
    
    property name="codeGenerationService" inject="CodeGenerationService@wheels-cli";
    property name="migrationService" inject="MigrationService@wheels-cli";
    property name="helpers" inject="helpers@wheels-cli";
    
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
                belongsTo = arguments.belongsTo,
                hasMany = arguments.hasMany,
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
                var migrationPath = createMigrationWithProperties(
                    name = arguments.name,
                    properties = parseProperties(arguments.properties),
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
                var parsedProperties = parseProperties(arguments.properties);
                
                for (var action in viewActions) {
                    var viewResult = codeGenerationService.generateView(
                        name = variables.helpers.pluralize(arguments.name),
                        action = action,
                        force = arguments.force,
                        baseDirectory = arguments.baseDirectory,
                        properties = parsedProperties
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
     * Create migration with properties
     */
    public function createMigrationWithProperties(
        required string name,
        required array properties,
        string baseDirectory = ""
    ) {
        var timestamp = dateFormat(now(), "yyyymmdd") & timeFormat(now(), "HHmmss");
        var tableName = variables.helpers.pluralize(lCase(arguments.name));
        var className = "create_#tableName#_table";
        var fileName = timestamp & "_" & className & ".cfc";
        var migrationDir = resolvePath("app/migrator/migrations", arguments.baseDirectory);
        
        // Create migrations directory if it doesn't exist
        if (!directoryExists(migrationDir)) {
            directoryCreate(migrationDir, true);
        }
        
        var migrationPath = migrationDir & "/" & fileName;
        
        // Generate migration content with properties
        var content = generateMigrationContentWithProperties(
            className = className,
            tableName = tableName,
            properties = arguments.properties
        );
        
        // Write migration file
        fileWrite(migrationPath, content);
        
        return "app/migrator/migrations/" & fileName;
    }
    
    /**
     * Generate migration content with properties
     */
    private function generateMigrationContentWithProperties(
        required string className,
        required string tableName,
        required array properties
    ) {
        var content = '/*' & chr(10);
        content &= '  |----------------------------------------------------------------------------------------------|' & chr(10);
        content &= '	| Parameter  | Required | Type    | Default | Description                                      |' & chr(10);
        content &= '  |----------------------------------------------------------------------------------------------|' & chr(10);
        content &= '	| name       | Yes      | string  |         | table name, in pluralized form                   |' & chr(10);
        content &= '	| force      | No       | boolean | false   | drop existing table of same name before creating |' & chr(10);
        content &= '	| id         | No       | boolean | true    | if false, defines a table with no primary key    |' & chr(10);
        content &= '	| primaryKey | No       | string  | id      | overrides default primary key name               |' & chr(10);
        content &= '  |----------------------------------------------------------------------------------------------|' & chr(10);
        content &= chr(10);
        content &= '    EXAMPLE:' & chr(10);
        content &= '      t = createTable(name=''employees'', force=false, id=true, primaryKey=''empId'');' & chr(10);
        content &= '			t.string(columnNames=''firstName,lastName'', default='''', null=true, limit=''255'');' & chr(10);
        content &= '			t.text(columnNames=''bio'', default='''', null=true);' & chr(10);
        content &= '			t.timestamps();' & chr(10);
        content &= '			t.create();' & chr(10);
        content &= '*/' & chr(10);
        content &= 'component extends="wheels.migrator.Migration" hint="Migration: #arguments.className#" {' & chr(10);
        content &= chr(10);
        content &= '	function up() {' & chr(10);
        content &= '		transaction {' & chr(10);
        content &= '			try {' & chr(10);
        content &= '				t = createTable(name = ''#arguments.tableName#'', force=''false'', id=''true'', primaryKey=''id'');' & chr(10);
        
        // Add properties
        for (var prop in arguments.properties) {
            var cfType = mapToCFWheelsType(prop.type);
            var params = 'columnNames=''#prop.name#''';
            
            if (structKeyExists(prop, "default") && prop.default != "") {
                params &= ', default=''#prop.default#''';
            } else {
                params &= ', default=''''';
            }
            
            params &= ', null=' & (structKeyExists(prop, "required") && prop.required ? 'false' : 'true');
            
            // Add type-specific parameters
            switch (cfType) {
                case "string":
                    params &= ', limit=''255''';
                    break;
                case "decimal":
                    params &= ', precision=''10'', scale=''2''';
                    break;
                case "integer":
                    params &= ', limit=''11''';
                    break;
            }
            
            content &= '				t.#cfType#(#params#);' & chr(10);
        }
        
        content &= '				t.timestamps();' & chr(10);
        content &= '				t.create();' & chr(10);
        content &= '			} catch (any e) {' & chr(10);
        content &= '				local.exception = e;' & chr(10);
        content &= '			}' & chr(10);
        content &= chr(10);
        content &= '			if (StructKeyExists(local, "exception")) {' & chr(10);
        content &= '				transaction action="rollback";' & chr(10);
        content &= '				Throw(errorCode = "1", detail = local.exception.detail, message = local.exception.message, type = "any");' & chr(10);
        content &= '			} else {' & chr(10);
        content &= '				transaction action="commit";' & chr(10);
        content &= '			}' & chr(10);
        content &= '		}' & chr(10);
        content &= '	}' & chr(10);
        content &= chr(10);
        content &= '	function down() {' & chr(10);
        content &= '		transaction {' & chr(10);
        content &= '			try {' & chr(10);
        content &= '				dropTable(''#arguments.tableName#'');' & chr(10);
        content &= '			} catch (any e) {' & chr(10);
        content &= '				local.exception = e;' & chr(10);
        content &= '			}' & chr(10);
        content &= chr(10);
        content &= '			if (StructKeyExists(local, "exception")) {' & chr(10);
        content &= '				transaction action="rollback";' & chr(10);
        content &= '				Throw(errorCode = "1", detail = local.exception.detail, message = local.exception.message, type = "any");' & chr(10);
        content &= '			} else {' & chr(10);
        content &= '				transaction action="commit";' & chr(10);
        content &= '			}' & chr(10);
        content &= '		}' & chr(10);
        content &= '	}' & chr(10);
        content &= chr(10);
        content &= '}' & chr(10);
        
        return content;
    }
    
    /**
     * Map property type to CFWheels migration type
     */
    private function mapToCFWheelsType(required string type) {
        switch (lCase(arguments.type)) {
            case "string":
                return "string";
            case "text":
                return "text";
            case "integer":
            case "int":
                return "integer";
            case "biginteger":
            case "bigint":
                return "biginteger";
            case "float":
            case "double":
                return "float";
            case "decimal":
            case "numeric":
                return "decimal";
            case "boolean":
            case "bool":
                return "boolean";
            case "date":
                return "date";
            case "datetime":
            case "timestamp":
                return "datetime";
            case "time":
                return "time";
            case "binary":
            case "blob":
                return "binary";
            case "uuid":
                return "uniqueidentifier";
            default:
                return "string";
        }
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
     * Resolve path relative to base directory
     */
    private function resolvePath(required string path, string baseDirectory = "") {
        if (len(arguments.baseDirectory)) {
            return arguments.baseDirectory & "/" & arguments.path;
        }
        return arguments.path;
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