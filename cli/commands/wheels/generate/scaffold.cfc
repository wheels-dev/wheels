/**
 * Scaffold a complete resource with model, controller, views, tests, and migration
 * 
 * Examples:
 * wheels scaffold User
 * wheels scaffold Post --properties="title:string,content:text,published:boolean"
 * wheels scaffold Product --properties="name:string,price:decimal" --api
 * wheels scaffold Comment --belongs-to=Post,User
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
        // Validate scaffold
        var validation = scaffoldService.validateScaffold(arguments.name, getCWD());
        if (!validation.valid) {
            detailOutput.error("Cannot scaffold '#arguments.name#':");
            for (var error in validation.errors) {
                detailOutput.getPrint().redLine("   • #error#");
            }
            setExitCode(1);
            return;
        }
        
        // Generate scaffold
        detailOutput.header("🏗️", "Scaffolding resource: #arguments.name#");
        
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
                detailOutput.getPrint().redLine("   • #error#");
            }
            setExitCode(1);
            return;
        }
        
        // Run migrations if requested
        if (arguments.migrate) {
            detailOutput.invoke("dbmigrate");
            command('wheels dbmigrate up').run();
        } else {
            // Ask to migrate
            if (confirm("Would you like to run migrations now? [y/n]")) {
                detailOutput.invoke("dbmigrate");
                command('wheels dbmigrate up').run();
            }
        }
        
        detailOutput.success("Scaffold complete! Your #arguments.name# resource is ready to use.");
        
        var nextSteps = [
            "Start your server: server start",
            "Visit the resource at: /#lCase(helpers.pluralize(arguments.name))#"
        ];
        
        if (!arguments.migrate && !confirm("Would you like to run migrations now? [y/n]")) {
            arrayPrepend(nextSteps, "Run migrations: wheels dbmigrate up");
        }
        
        detailOutput.nextSteps(nextSteps);
    }
}
