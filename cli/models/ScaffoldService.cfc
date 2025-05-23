component {
    
    property name="codeGenerationService" inject="CodeGenerationService@wheels-cli";
    property name="migrationService" inject="MigrationService@wheels-cli";
    property name="fileSystemUtil" inject="FileSystem@commandbox-core";
    
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
        boolean force = false
    ) {
        var results = {
            success: true,
            generated: [],
            errors: [],
            rollback: []
        };
        
        try {
            // Start transaction-like operation
            print.boldLine("🏗️  Scaffolding #arguments.name#...")
                 .line();
            
            // 1. Generate Model
            print.yellowLine("📦 Creating model...");
            var modelResult = codeGenerationService.generateModel(
                name = arguments.name,
                properties = parseProperties(arguments.properties),
                force = arguments.force
            );
            
            if (modelResult.success) {
                arrayAppend(results.generated, {
                    type: "model",
                    path: modelResult.path
                });
                arrayAppend(results.rollback, modelResult.path);
                print.greenLine("   ✅ Model created");
            } else {
                throw(type="ScaffoldError", message="Failed to create model: #modelResult.error#");
            }
            
            // 2. Generate Migration
            print.yellowLine("📄 Creating migration...");
            var migrationResult = migrationService.createMigration(
                name = "create_#helpers.toPlural(lCase(arguments.name))#_table",
                table = helpers.toPlural(lCase(arguments.name)),
                model = arguments.name,
                type = "create"
            );
            
            if (migrationResult.success) {
                arrayAppend(results.generated, {
                    type: "migration",
                    path: migrationResult.path
                });
                arrayAppend(results.rollback, migrationResult.path);
                print.greenLine("   ✅ Migration created");
            } else {
                throw(type="ScaffoldError", message="Failed to create migration: #migrationResult.error#");
            }
            
            // 3. Generate Controller
            print.yellowLine("🎮 Creating controller...");
            var controllerResult = codeGenerationService.generateController(
                name = helpers.toPlural(arguments.name),
                rest = true,
                force = arguments.force
            );
            
            if (controllerResult.success) {
                arrayAppend(results.generated, {
                    type: "controller",
                    path: controllerResult.path
                });
                arrayAppend(results.rollback, controllerResult.path);
                print.greenLine("   ✅ Controller created");
            } else {
                throw(type="ScaffoldError", message="Failed to create controller: #controllerResult.error#");
            }
            
            // 4. Generate Views (unless API-only)
            if (!arguments.api) {
                print.yellowLine("📝 Creating views...");
                var viewActions = ["index", "show", "new", "edit", "_form"];
                var viewsCreated = 0;
                
                for (var action in viewActions) {
                    var viewResult = codeGenerationService.generateView(
                        name = helpers.toPlural(arguments.name),
                        action = action,
                        force = arguments.force
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
                print.greenLine("   ✅ #viewsCreated# views created");
            }
            
            // 5. Generate Tests
            if (arguments.tests) {
                print.yellowLine("🧪 Creating tests...");
                
                // Model test
                var modelTestResult = codeGenerationService.generateTest(
                    type = "model",
                    name = arguments.name
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
                    name = helpers.toPlural(arguments.name)
                );
                if (controllerTestResult.success) {
                    arrayAppend(results.generated, {
                        type: "test",
                        path: controllerTestResult.path
                    });
                    arrayAppend(results.rollback, controllerTestResult.path);
                }
                
                print.greenLine("   ✅ Tests created");
            }
            
            // 6. Update routes
            var routesUpdated = updateRoutes(arguments.name);
            if (routesUpdated) {
                print.greenLine("📍 Routes updated");
            }
            
            // Success summary
            print.line()
                 .greenBoldLine("✅ Scaffold completed successfully!")
                 .line()
                 .yellowLine("📋 Generated files:")
                 .line();
            
            for (var item in results.generated) {
                print.line("   • #item.type#: #item.path#");
            }
            
            // Next steps
            print.line()
                 .yellowLine("📋 Next steps:")
                 .line("1. Run migrations: wheels dbmigrate up")
                 .line("2. Start server: box server start")
                 .line("3. Visit: http://localhost:8080/#lCase(helpers.toPlural(arguments.name))#");
            
        } catch (any e) {
            // Rollback on error
            results.success = false;
            arrayAppend(results.errors, e.message);
            
            if (e.type == "ScaffoldError") {
                print.redBoldLine("❌ Scaffold failed: #e.message#");
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
    private function updateRoutes(required string name) {
        try {
            var routesPath = fileSystemUtil.resolvePath("config/routes.cfm");
            if (!fileExists(routesPath)) {
                routesPath = fileSystemUtil.resolvePath("app/config/routes.cfm");
            }
            
            if (fileExists(routesPath)) {
                var content = fileRead(routesPath);
                var resourceName = lCase(helpers.toPlural(arguments.name));
                var resourceLine = 'resources(name="#resourceName#");';
                
                // Check if resource already exists
                if (!findNoCase(resourceName, content)) {
                    // Find a good place to insert (before end() if exists)
                    if (findNoCase("end()", content)) {
                        content = replaceNoCase(content, "end()", resourceLine & chr(10) & chr(10) & "end()", "one");
                    } else {
                        // Just append
                        content &= chr(10) & chr(10) & resourceLine;
                    }
                    
                    fileWrite(routesPath, content);
                    return true;
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
            print.line()
                 .yellowLine("🔄 Rolling back created files...");
            
            for (var file in arguments.files) {
                if (fileExists(file)) {
                    try {
                        fileDelete(file);
                        print.line("   • Removed: #file#");
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
    function validateScaffold(required string name) {
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
        var modelPath = fileSystemUtil.resolvePath("models/#helpers.capitalize(arguments.name)#.cfc");
        if (fileExists(modelPath)) {
            arrayAppend(errors, "Model already exists: #modelPath#");
        }
        
        var controllerPath = fileSystemUtil.resolvePath("controllers/#helpers.toPlural(helpers.capitalize(arguments.name))#.cfc");
        if (fileExists(controllerPath)) {
            arrayAppend(errors, "Controller already exists: #controllerPath#");
        }
        
        return {
            valid: arrayLen(errors) == 0,
            errors: errors
        };
    }
}