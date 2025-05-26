/**
 * Scaffold a complete resource with model, controller, views, tests, and migration
 * 
 * Examples:
 * wheels scaffold User
 * wheels scaffold Post --properties="title:string,content:text,published:boolean"
 * wheels scaffold Product --properties="name:string,price:decimal" --api
 * wheels scaffold Comment --belongs-to=Post,User
 */
component extends="base" {
    
    property name="scaffoldService" inject="ScaffoldService@wheels-cli";
    
    /**
     * @name.hint Name of resource to scaffold (singular)
     * @properties.hint Model properties (format: name:type,name2:type2)
     * @belongs-to.hint Parent model relationships (comma-separated)
     * @has-many.hint Child model relationships (comma-separated)
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
            print.redBoldLine("❌ Cannot scaffold '#arguments.name#':")
                 .line();
            for (var error in validation.errors) {
                print.redLine("   • #error#");
            }
            setExitCode(1);
            return;
        }
        
        // Generate scaffold
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
            print.line()
                 .redBoldLine("❌ Scaffolding failed!")
                 .line();
            for (var error in result.errors) {
                print.redLine("   • #error#");
            }
            setExitCode(1);
            return;
        }
        
        // Run migrations if requested
        if (arguments.migrate) {
            print.line()
                 .yellowLine("🗄️  Running migrations...");
            
            command('wheels dbmigrate up').run();
        } else {
            // Ask to migrate
            if (confirm("Would you like to run migrations now? [y/n]")) {
                command('wheels dbmigrate up').run();
            }
        }
        
        print.line()
             .greenBoldLine("🎉 Scaffold complete! Your #arguments.name# resource is ready to use.");
    }
}
