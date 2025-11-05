/**
 * Scaffold a complete resource with model, controller, views, tests, and migration
 * 
 * Examples:
 * wheels scaffold User
 * wheels scaffold Post properties="title:string,content:text,published:boolean"
 * wheels scaffold Product properties="name:string,price:decimal" api=true
 * wheels scaffold Comment belongsTo=Post,User
 */
component aliases="wheels g scaffold" extends="../base" {
    
    property name="scaffoldService" inject="ScaffoldService@wheels-cli";
    property name="detailOutput" inject="DetailOutputService@wheels-cli";
    property name="helpers" inject="helpers@wheels-cli";
    
    /**
     * @name.hint Name of resource to scaffold (singular)
     * @properties.hint Model properties (format: name:type,name2:type2)
     * @belongsTo.hint Parent model relationships (comma-separated)
     * @hasMany.hint Child model relationships (comma-separated)
     * @api.hint Generate API-only scaffold (no views)
     * @tests.hint Generate test files (default: true)
     * @migrate.hint Run migrations after scaffolding
     * @force.hint Overwrite existing files
     */
    function run(
        required string name,
        string properties = "",
        string belongsTo = "",
        string hasMany = "",
        boolean api = false,
        boolean tests = true,
        boolean migrate = false,
        boolean force = false
    ) {
        requireWheelsApp(getCWD());
        arguments = reconstructArgs(argStruct=arguments);

        // Custom validation for properties parameter format (name:type,name2:type2)
        if (len(trim(arguments.properties))) {
            var validTypes = ["biginteger", "binary", "boolean", "date", "datetime", "decimal", "float", "integer", "string", "limit", "text", "time", "timestamp", "uuid"];
            var properties = listToArray(arguments.properties, ",");
            var invalidTypes = [];

            for (var prop in properties) {
                prop = trim(prop);
                if (find(":", prop)) {
                    var propType = trim(listLast(prop, ":"));
                    if (!arrayFindNoCase(validTypes, propType)) {
                        arrayAppend(invalidTypes, propType);
                    }
                } else {
                    // Property without type specification is invalid
                    detailOutput.error("Invalid property format: '#prop#'. Expected format: name:type");
                    setExitCode(1);
                    return;
                }
            }

            if (arrayLen(invalidTypes) > 0) {
                detailOutput.error("Invalid property type(s): #arrayToList(invalidTypes, ', ')#. Valid types are: #arrayToList(validTypes, ', ')#");
                setExitCode(1);
                return;
            }
        }

        // Validate scaffold
        var validation = scaffoldService.validateScaffold(arguments.name, getCWD(), arguments.force);
        if (!validation.valid) {
            detailOutput.error("Cannot scaffold '#arguments.name#':");
            for (var error in validation.errors) {
                print.redLine("   - #error#");
            }
            setExitCode(1);
            return;
        }
        
        // Generate scaffold
        detailOutput.header("", "Scaffolding resource: #arguments.name#");
        
        var result = scaffoldService.generateScaffold(
            name = arguments.name,
            properties = arguments.properties,
            belongsTo = arguments.belongsTo,
            hasMany = arguments.hasMany,
            api = arguments.api,
            tests = arguments.tests,
            force = arguments.force,
            baseDirectory = getCWD()
        );
        
        if (!result.success) {
            detailOutput.error("Scaffolding failed!");
            for (var error in result.errors) {
                print.redLine("   - #error#");
            }
            setExitCode(1);
            return;
        }
        
        // Run migrations if requested
        if (arguments.migrate) {
            detailOutput.invoke("dbmigrate");
            command('wheels dbmigrate up').run();
        } else if (!arguments.api) {
            // Only ask to migrate in interactive mode
            try {
                if (confirm("Would you like to run migrations now? [y/n]")) {
                    detailOutput.invoke("dbmigrate");
                    command('wheels dbmigrate up').run();
                }
            } catch (any e) {
                // Skip if non-interactive
            }
        }
        
        detailOutput.success("Scaffold complete! Your #arguments.name# resource is ready to use.");
        
        var nextSteps = [
            "Start your server: server start",
            "Visit the resource at: /#lCase(helpers.pluralize(arguments.name))#"
        ];
        
        if (!arguments.migrate) {
            arrayPrepend(nextSteps, "Run migrations: wheels dbmigrate up");
        }
        
        detailOutput.nextSteps(nextSteps);
    }
}
