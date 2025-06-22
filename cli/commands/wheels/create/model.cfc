/**
 * Create a new Wheels model
 */
component extends="commands.wheels.BaseCommand" {
    
    /**
     * Create a new Wheels model
     * 
     * @name.hint Name of the model (singular, e.g., User, Post)
     * @properties.hint Comma-delimited list of properties (name:type:options)
     *             Examples: firstName:string,email:string:unique,age:integer
     * @properties.optionsUDF completePropertyHelp
     * @migration.hint Create a migration file for this model
     * @migration.options true,false
     * @controller.hint Create a matching controller
     * @controller.options true,false
     * @resource.hint Create a resourceful controller with CRUD actions
     * @resource.options true,false
     * @tests.hint Create test files for the model
     * @tests.options true,false
     * @api.hint Create API controller instead of regular controller
     * @api.options true,false
     * @template.hint Model snippet to use
     * @template.optionsUDF completeModelSnippets
     * @force.hint Overwrite existing files
     * @force.options true,false
     * @format.hint Output format
     * @format.optionsUDF completeFormatTypes
     * @help Generate a model file with optional migration, controller, and tests
     */
    function run(
        required string name,
        string properties = "",
        boolean migration = false,
        boolean controller = false,
        boolean resource = false,
        boolean tests = false,
        boolean api = false,
        string template = "",
        boolean force = false,
        string format = "text"
    ) {
        return runCommand(function() {
            ensureWheelsProject();
            
            // Validate model name
            if (!reFind("^[A-Z][a-zA-Z0-9]*$", arguments.name)) {
                error("Invalid model name. Model names must start with a capital letter and contain only letters and numbers.");
            }
            
            var result = {
                success = true,
                modelName = arguments.name,
                filesCreated = [],
                errors = []
            };
            
            // Show header
            if (variables.commandMetadata.outputFormat == "text") {
                printHeader("Creating model: #arguments.name#");
            }
            
            // Parse properties
            var props = parseProperties(arguments.properties);
            
            // Select appropriate snippet
            var snippetName = len(arguments.template) ? arguments.template : selectModelSnippet(props);
            
            if (!fileExists(getDirectoryFromPath(getCurrentTemplatePath()) & "../../../snippets/model/#snippetName#.cfc")) {
                error("Snippet not found: #snippetName#");
            }
            
            var snippet = getSnippet("model", snippetName);
            
            // Check if using custom snippet
            if (isUsingCustomSnippet("model/#snippetName#.cfc")) {
                printInfo("Using custom model snippet: #snippetName#");
            }
            
            // Generate model file
            runWithSpinner("Generating model file", function() {
                var modelContent = renderModelContent(arguments.name, props, snippet);
                var modelsPath = getAppPath("models");
                var modelFile = modelsPath & "/" & arguments.name & ".cfc";
                
                // Ensure models directory exists
                if (!directoryExists(modelsPath)) {
                    directoryCreate(modelsPath, true);
                }
                
                if (fileExists(modelFile) && !arguments.force) {
                    if (!confirm("Model '#arguments.name#' already exists. Overwrite?")) {
                        result.success = false;
                        arrayAppend(result.errors, "Model creation cancelled by user");
                        return;
                    }
                }
                
                fileWrite(modelFile, modelContent);
                arrayAppend(result.filesCreated, "app/models/#arguments.name#.cfc");
            });
            
            if (!result.success) {
                output(result, arguments.format);
                return;
            }
            
            printSuccess("Created model: app/models/#arguments.name#.cfc");
            
            // Generate migration if requested
            if (arguments.migration) {
                printSection("Creating migration");
                command("wheels create migration")
                    .params(
                        name = "Create#pluralize(arguments.name)#Table",
                        model = arguments.name,
                        properties = arguments.properties,
                        format = "text"
                    )
                    .run();
                arrayAppend(result.filesCreated, "db/migrate/[timestamp]_Create#pluralize(arguments.name)#Table.cfc");
            }
            
            // Generate controller if requested
            if (arguments.controller || arguments.resource) {
                printSection("Creating controller");
                command("wheels create controller")
                    .params(
                        name = pluralize(arguments.name),
                        model = arguments.name,
                        resource = arguments.resource,
                        api = arguments.api,
                        force = arguments.force,
                        format = "text"
                    )
                    .run();
                arrayAppend(result.filesCreated, "app/controllers/#pluralize(arguments.name)#.cfc");
            }
            
            // Generate tests if requested
            if (arguments.tests) {
                printSection("Creating tests");
                command("wheels create test")
                    .params(
                        type = "model",
                        name = arguments.name,
                        force = arguments.force,
                        format = "text"
                    )
                    .run();
                arrayAppend(result.filesCreated, "tests/models/#arguments.name#Test.cfc");
                    
                if (arguments.controller || arguments.resource) {
                    command("wheels create test")
                        .params(
                            type = "controller",
                            name = pluralize(arguments.name),
                            force = arguments.force,
                            format = "text"
                        )
                        .run();
                    arrayAppend(result.filesCreated, "tests/controllers/#pluralize(arguments.name)#Test.cfc");
                }
            }
            
            // Show next steps
            if (variables.commandMetadata.outputFormat == "text") {
                printSection("Next steps");
                
                var stepNumber = 1;
                
                if (arguments.migration) {
                    print.indentedLine("#stepNumber#. Review and modify the migration file in db/migrate/");
                    stepNumber++;
                    print.indentedLine("#stepNumber#. Run 'wheels db migrate' to create the database table");
                    stepNumber++;
                }
                
                print.indentedLine("#stepNumber#. Add validations and associations to your model");
                stepNumber++;
                
                if (arguments.controller || arguments.resource) {
                    print.indentedLine("#stepNumber#. Implement controller actions in app/controllers/#pluralize(arguments.name)#.cfc");
                    stepNumber++;
                    print.indentedLine("#stepNumber#. Create views for your controller actions");
                    stepNumber++;
                }
                
                if (!arguments.controller && !arguments.resource) {
                    print.line();
                    printInfo("Tip: Generate a controller with 'wheels create controller #pluralize(arguments.name)# --resource'");
                }
            }
            
            // Output result
            output(result, arguments.format);
        }, argumentCollection=arguments);
    }
    
    /**
     * Parse property string into struct
     */
    private array function parseProperties(required string properties) {
        var props = [];
        
        if (!len(trim(arguments.properties))) {
            return props;
        }
        
        var propList = listToArray(arguments.properties);
        
        for (var prop in propList) {
            var parts = listToArray(prop, ":");
            var property = {
                name = trim(parts[1]),
                type = arrayLen(parts) > 1 ? trim(parts[2]) : "string",
                options = {}
            };
            
            // Validate property name
            if (!reFind("^[a-zA-Z][a-zA-Z0-9_]*$", property.name)) {
                error("Invalid property name '#property.name#'. Property names must start with a letter and contain only letters, numbers, and underscores.");
            }
            
            // Map common type aliases
            switch(property.type) {
                case "str":
                    property.type = "string";
                    break;
                case "int":
                    property.type = "integer";
                    break;
                case "bool":
                    property.type = "boolean";
                    break;
                case "datetime":
                case "timestamp":
                    property.type = "datetime";
                    break;
                case "decimal":
                case "float":
                case "double":
                    property.type = "numeric";
                    break;
                case "blob":
                case "longtext":
                    property.type = "text";
                    break;
            }
            
            // Parse additional options
            if (arrayLen(parts) > 2) {
                for (var i = 3; i <= arrayLen(parts); i++) {
                    var option = trim(parts[i]);
                    property.options[option] = true;
                }
            }
            
            arrayAppend(props, property);
        }
        
        return props;
    }
    
    /**
     * Select appropriate model snippet based on properties and configuration
     */
    private string function selectModelSnippet(required array properties) {
        var hasValidations = false;
        for (var prop in arguments.properties) {
            if (structKeyExists(prop.options, "required") || 
                structKeyExists(prop.options, "unique") ||
                structKeyExists(prop.options, "email")) {
                hasValidations = true;
                break;
            }
        }
        
        var includeAuditFields = getConfigService().get("snippets.model.includeAuditFields", false);
        var includeSoftDeletes = getConfigService().get("snippets.model.includeSoftDeletes", false);
        
        // Select snippet based on features needed
        if (includeAuditFields && includeSoftDeletes && hasValidations) {
            return "ModelComplete";
        } else if (includeAuditFields || includeSoftDeletes) {
            return "ModelWithAudit";
        } else if (hasValidations) {
            return "ModelWithValidation";
        } else {
            return "Model";
        }
    }
    
    /**
     * Generate model content using snippet
     */
    private string function renderModelContent(
        required string name,
        required array properties,
        required string snippet
    ) {
        var data = {
            modelName = arguments.name,
            tableName = pluralize(lCase(arguments.name)),
            properties = arguments.properties,
            timestamp = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss"),
            author = getConfigService().get("author", ""),
            generatedBy = "Wheels CLI v3.0.0"
        };
        
        // Add computed values
        data.singularLowerName = lCase(arguments.name);
        data.pluralLowerName = lCase(pluralize(arguments.name));
        data.pluralName = pluralize(arguments.name);
        
        // Add validations
        var validations = [];
        for (var prop in arguments.properties) {
            if (structKeyExists(prop.options, "required")) {
                arrayAppend(validations, {
                    type = "Presence",
                    property = prop.name,
                    options = ""
                });
            }
            if (structKeyExists(prop.options, "unique")) {
                arrayAppend(validations, {
                    type = "Uniqueness",
                    property = prop.name,
                    options = ""
                });
            }
            if (structKeyExists(prop.options, "email") || prop.name == "email") {
                arrayAppend(validations, {
                    type = "Format",
                    property = prop.name,
                    options = ', pattern="^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"'
                });
            }
        }
        data.validations = validations;
        
        return renderSnippet(arguments.snippet, data);
    }
    
    /**
     * Tab completion for model snippets
     */
    function completeModelSnippets(string paramSoFar = "", struct passedNamedParameters = {}) {
        return getTabCompletionService().getTemplateNames(arguments.paramSoFar, {type = "model"});
    }
    
    /**
     * Tab completion for property help
     */
    function completePropertyHelp(string paramSoFar = "", struct passedNamedParameters = {}) {
        // Provide helpful examples
        return [
            "name:string",
            "email:string:unique",
            "password:string:required",
            "age:integer",
            "price:numeric",
            "isActive:boolean",
            "birthDate:date",
            "createdAt:datetime",
            "description:text",
            "userId:integer:references"
        ];
    }
}