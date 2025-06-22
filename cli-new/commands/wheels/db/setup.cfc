/**
 * Setup the database (create, migrate, and seed)
 */
component extends="commands.wheels.BaseCommand" {
    
    /**
     * Setup the database by running create, migrate, and seed
     * 
     * @environment Environment to setup database for (development, testing, production)
     * @seed Run database seeds after migration
     * @force Force recreate if database exists
     * @help Create database, run migrations, and optionally seed data
     */
    function run(
        string environment = "development",
        boolean seed = true,
        boolean force = false
    ) {
        ensureWheelsProject();
        
        print.line();
        print.boldBlueLine("Setting up database for #arguments.environment# environment");
        print.line();
        
        // Step 1: Create database
        print.yellowLine("Step 1: Creating database...");
        command("wheels db create")
            .params(
                environment = arguments.environment,
                force = arguments.force
            )
            .run();
        
        print.line();
        
        // Step 2: Run migrations
        print.yellowLine("Step 2: Running migrations...");
        command("wheels db migrate")
            .params(environment = arguments.environment)
            .run();
        
        print.line();
        
        // Step 3: Seed database (if requested)
        if (arguments.seed) {
            print.yellowLine("Step 3: Seeding database...");
            
            var seedPath = getCWD() & "/db/seeds/";
            if (directoryExists(seedPath) && 
                arrayLen(directoryList(seedPath, false, "path", "*.cfc"))) {
                
                command("wheels db seed")
                    .params(environment = arguments.environment)
                    .run();
            } else {
                print.line("No seed files found. Skipping seeding.");
            }
            
            print.line();
        }
        
        print.greenBoldLine("✅ Database setup complete!");
        print.line();
        print.boldLine("Your database is ready to use!");
        print.line();
        print.yellowLine("Next steps:");
        print.indentedLine("• Start the server: wheels server start");
        print.indentedLine("• Create a model: wheels create model User name:string email:string:unique");
        print.indentedLine("• Create a controller: wheels create controller Users --resource");
    }
}