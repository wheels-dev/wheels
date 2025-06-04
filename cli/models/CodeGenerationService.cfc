component {
    
    property name="templateService" inject="TemplateService@wheels-cli";
    property name="helpers" inject="helpers@wheels-cli";
    
    /**
     * Initialize the service
     */
    public function init() {
        return this;
    }
    
    /**
     * Local capitalize function to avoid injection timing issues
     */
    private function capitalize(required string str) {
        if (structKeyExists(variables, "helpers") && isObject(variables.helpers)) {
            return variables.helpers.capitalize(arguments.str);
        }
        // Fallback implementation
        return uCase(left(arguments.str, 1)) & mid(arguments.str, 2, len(arguments.str)-1);
    }
    
    /**
     * Local pluralize function to avoid injection timing issues
     */
    private function pluralize(required string word) {
        if (structKeyExists(variables, "helpers") && isObject(variables.helpers)) {
            return variables.helpers.pluralize(arguments.word);
        }
        // Simple fallback - just add 's'
        return arguments.word & "s";
    }
    
    /**
     * Local singularize function to avoid injection timing issues
     */
    private function singularize(required string word) {
        if (structKeyExists(variables, "helpers") && isObject(variables.helpers)) {
            return variables.helpers.singularize(arguments.word);
        }
        // Simple fallback - remove trailing 's' if present
        if (right(arguments.word, 1) == "s") {
            return left(arguments.word, len(arguments.word) - 1);
        }
        return arguments.word;
    }
    
    /**
     * Generate a model file
     */
    function generateModel(
        required string name,
        string extends = "",
        string description = "",
        boolean force = false,
        array properties = [],
        string baseDirectory = "",
        string belongsTo = "",
        string hasMany = "",
        string hasOne = "",
        string primaryKey = "",
        string tableName = ""
    ) {
        var modelName = capitalize(arguments.name);
        var fileName = modelName & ".cfc";
        var filePath = resolvePath("models/#fileName#", arguments.baseDirectory);
        
        // Check if file exists
        if (fileExists(filePath) && !arguments.force) {
            return {
                success: false,
                error: "Model file already exists. Use --force to overwrite.",
                path: filePath
            };
        }
        
        // Prepare template context
        var context = {
            modelName: modelName,
            tableName: len(arguments.tableName) ? arguments.tableName : pluralize(lCase(modelName)),
            extends: len(arguments.extends) ? arguments.extends : "Model",
            description: arguments.description,
            properties: arguments.properties,
            timestamp: dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss"),
            belongsTo: arguments.belongsTo,
            hasMany: arguments.hasMany,
            hasOne: arguments.hasOne,
            primaryKey: arguments.primaryKey
        };
        
        // Process associations from properties
        context.associations = extractAssociations(arguments.properties);
        
        // Generate from template
        try {
            var generatedPath = templateService.generateFromTemplate(
                template = "ModelContent.txt",
                destination = "models/#fileName#",
                context = context,
                baseDirectory = arguments.baseDirectory
            );
            
            return {
                success: true,
                path: generatedPath,
                message: "Model generated successfully"
            };
        } catch (any e) {
            return {
                success: false,
                error: e.message
            };
        }
    }
    
    /**
     * Generate a controller file
     */
    function generateController(
        required string name,
        string extends = "",
        string description = "",
        boolean rest = false,
        boolean force = false,
        array actions = [],
        string baseDirectory = ""
    ) {
        var controllerName = capitalize(arguments.name);
        var fileName = controllerName & ".cfc";
        var filePath = resolvePath("controllers/#fileName#", arguments.baseDirectory);
        
        // Check if file exists
        if (fileExists(filePath) && !arguments.force) {
            return {
                success: false,
                error: "Controller file already exists. Use --force to overwrite.",
                path: filePath
            };
        }
        
        // Default actions based on type
        if (arrayLen(arguments.actions) == 0) {
            if (arguments.rest) {
                arguments.actions = ["index", "show", "new", "create", "edit", "update", "delete"];
            } else {
                arguments.actions = ["index"];
            }
        }
        
        // Prepare template context
        var context = {
            controllerName: controllerName,
            modelName: singularize(controllerName),
            extends: len(arguments.extends) ? arguments.extends : "Controller",
            description: arguments.description,
            actions: arguments.actions,
            rest: arguments.rest,
            timestamp: dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss")
        };
        
        // Generate from template
        try {
            var template = arguments.rest ? "CRUDContent.txt" : "ControllerContent.txt";
            var generatedPath = templateService.generateFromTemplate(
                template = template,
                destination = "controllers/#fileName#",
                context = context,
                baseDirectory = arguments.baseDirectory
            );
            
            return {
                success: true,
                path: generatedPath,
                message: "Controller generated successfully"
            };
        } catch (any e) {
            return {
                success: false,
                error: e.message
            };
        }
    }
    
    /**
     * Generate view files
     */
    function generateView(
        required string name,
        required string action,
        string template = "",
        boolean force = false,
        string baseDirectory = "",
        array properties = []
    ) {
        var controllerName = capitalize(arguments.name);
        var viewDir = resolvePath("views/#lCase(controllerName)#", arguments.baseDirectory);
        var fileName = arguments.action & ".cfm";
        var filePath = viewDir & "/" & fileName;
        
        // Check if file exists
        if (fileExists(filePath) && !arguments.force) {
            return {
                success: false,
                error: "View file already exists. Use --force to overwrite.",
                path: filePath
            };
        }
        
        // Create view directory if needed
        if (!directoryExists(viewDir)) {
            directoryCreate(viewDir);
        }
        
        // Determine template to use
        if (!len(arguments.template)) {
            // Auto-detect template based on action name
            switch (arguments.action) {
                case "index":
                    arguments.template = "crud/index.txt";
                    break;
                case "show":
                    arguments.template = "crud/show.txt";
                    break;
                case "new":
                    arguments.template = "crud/new.txt";
                    break;
                case "edit":
                    arguments.template = "crud/edit.txt";
                    break;
                case "_form":
                    arguments.template = "crud/_form.txt";
                    break;
                default:
                    arguments.template = "ViewContent.txt";
            }
        }
        
        // Prepare template context
        var context = {
            controllerName: controllerName,
            modelName: singularize(controllerName),
            action: arguments.action,
            timestamp: dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss"),
            properties: arguments.properties
        };
        
        // Generate from template
        try {
            var generatedPath = templateService.generateFromTemplate(
                template = arguments.template,
                destination = "views/#lCase(controllerName)#/#fileName#",
                context = context,
                baseDirectory = arguments.baseDirectory
            );
            
            return {
                success: true,
                path: generatedPath,
                message: "View generated successfully"
            };
        } catch (any e) {
            return {
                success: false,
                error: e.message
            };
        }
    }
    
    /**
     * Generate a complete resource (model, controller, views)
     */
    function generateResource(
        required string name,
        boolean api = false,
        array properties = [],
        boolean force = false
    ) {
        var results = {
            success: true,
            generated: [],
            errors: []
        };
        
        // Generate model
        var modelResult = generateModel(
            name = arguments.name,
            properties = arguments.properties,
            force = arguments.force
        );
        
        if (modelResult.success) {
            arrayAppend(results.generated, {
                type: "model",
                path: modelResult.path
            });
        } else {
            arrayAppend(results.errors, modelResult.error);
            results.success = false;
        }
        
        // Generate controller
        var controllerResult = generateController(
            name = pluralize(arguments.name),
            rest = true,
            force = arguments.force
        );
        
        if (controllerResult.success) {
            arrayAppend(results.generated, {
                type: "controller",
                path: controllerResult.path
            });
        } else {
            arrayAppend(results.errors, controllerResult.error);
            results.success = false;
        }
        
        // Generate views (unless API-only)
        if (!arguments.api) {
            var viewActions = ["index", "show", "new", "edit"];
            for (var action in viewActions) {
                var viewResult = generateView(
                    name = pluralize(arguments.name),
                    action = action,
                    force = arguments.force
                );
                
                if (viewResult.success) {
                    arrayAppend(results.generated, {
                        type: "view",
                        path: viewResult.path
                    });
                } else {
                    arrayAppend(results.errors, viewResult.error);
                }
            }
        }
        
        return results;
    }
    
    /**
     * Generate a test file
     */
    function generateTest(
        required string type,
        required string name,
        boolean unit = false,
        boolean integration = false,
        array methods = [],
        string baseDirectory = ""
    ) {
        var testName = arguments.name;
        if (!reFindNoCase("Test$", testName)) {
            testName &= "Test";
        }
        
        var testDir = "tests/";
        switch (arguments.type) {
            case "model":
                testDir &= "models/";
                break;
            case "controller":
                testDir &= "controllers/";
                break;
            case "view":
                testDir &= "views/";
                break;
            default:
                if (arguments.unit) {
                    testDir &= "unit/";
                } else if (arguments.integration) {
                    testDir &= "integration/";
                }
        }
        
        var fileName = testName & ".cfc";
        var filePath = resolvePath(testDir & fileName, arguments.baseDirectory);
        
        // Create directory if needed
        var dir = resolvePath(testDir, arguments.baseDirectory);
        if (!directoryExists(dir)) {
            directoryCreate(dir, true);
        }
        
        // Prepare template context
        var context = {
            testName: testName,
            targetName: replaceNoCase(testName, "Test", ""),
            type: arguments.type,
            methods: arguments.methods,
            timestamp: dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss")
        };
        
        // Generate from template
        try {
            var template = "tests/#arguments.type#.txt";
            var generatedPath = templateService.generateFromTemplate(
                template = template,
                destination = testDir & fileName,
                context = context,
                baseDirectory = arguments.baseDirectory
            );
            
            return {
                success: true,
                path: generatedPath,
                message: "Test generated successfully"
            };
        } catch (any e) {
            return {
                success: false,
                error: e.message
            };
        }
    }
    
    /**
     * Extract associations from properties
     */
    private function extractAssociations(required array properties) {
        var associations = {
            belongsTo: [],
            hasMany: [],
            hasOne: []
        };
        
        for (var prop in arguments.properties) {
            if (prop.keyExists("association")) {
                switch (prop.association) {
                    case "belongsTo":
                        arrayAppend(associations.belongsTo, {
                            name: prop.name,
                            class: prop.keyExists("class") ? prop.class : capitalize(prop.name)
                        });
                        break;
                    case "hasMany":
                        arrayAppend(associations.hasMany, {
                            name: prop.name,
                            class: prop.keyExists("class") ? prop.class : capitalize(singularize(prop.name))
                        });
                        break;
                    case "hasOne":
                        arrayAppend(associations.hasOne, {
                            name: prop.name,
                            class: prop.keyExists("class") ? prop.class : capitalize(prop.name)
                        });
                        break;
                }
            }
        }
        
        return associations;
    }
    
    /**
     * Validate name for code generation
     */
    function validateName(required string name, required string type) {
        var errors = [];
        
        // Check for empty name
        if (!len(trim(arguments.name))) {
            arrayAppend(errors, "Name cannot be empty");
        }
        
        // Check for valid characters
        if (!reFindNoCase("^[a-zA-Z][a-zA-Z0-9_]*$", arguments.name)) {
            arrayAppend(errors, "Name must start with a letter and contain only letters, numbers, and underscores");
        }
        
        // Check for reserved words
        var reservedWords = ["application", "session", "request", "server", "form", "url", "cgi", "cookie"];
        if (arrayFindNoCase(reservedWords, arguments.name)) {
            arrayAppend(errors, "Name '#arguments.name#' is a reserved word");
        }
        
        // Type-specific validation
        switch (arguments.type) {
            case "model":
                if (reFindNoCase("(Controller|Test|Service)$", arguments.name)) {
                    arrayAppend(errors, "Model name should not end with 'Controller', 'Test', or 'Service'");
                }
                break;
            case "controller":
                if (reFindNoCase("(Model|Test|Service)$", arguments.name)) {
                    arrayAppend(errors, "Controller name should not end with 'Model', 'Test', or 'Service'");
                }
                break;
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