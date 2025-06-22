/**
 * Display help for Wheels CLI commands
 */
component extends="commands.wheels.BaseCommand" {
    
    /**
     * @command Command to get help for (optional)
     * @help Display help information for Wheels CLI commands
     */
    function run(string command = "") {
        if (len(arguments.command)) {
            // Show help for specific command
            command("help")
                .params("command" = "wheels " & arguments.command)
                .run();
        } else {
            // Show general Wheels CLI help
            print.line();
            print.boldBlueLine("CFWheels CLI - Next Generation");
            print.line("Version: 3.0.0-beta.1");
            print.line();
            print.yellowLine("Usage:");
            print.indentedLine("wheels <command> [options]");
            print.line();
            
            print.yellowLine("Available Commands:");
            print.line();
            
            // Application Commands
            print.greenLine("  Application:");
            print.indentedLine("create app <name>        Create a new Wheels application");
            print.indentedLine("version                  Display version information");
            print.line();
            
            // Generator Commands
            print.greenLine("  Generators:");
            print.indentedLine("create model <name>      Generate a model file");
            print.indentedLine("create controller <name> Generate a controller file");
            print.indentedLine("create view <name>       Generate view files");
            print.indentedLine("create migration <name>  Generate a migration file");
            print.indentedLine("create test <type>       Generate test files");
            print.line();
            
            // Database Commands
            print.greenLine("  Database:");
            print.indentedLine("db create                Create the database");
            print.indentedLine("db drop                  Drop the database");
            print.indentedLine("db migrate               Run pending migrations");
            print.indentedLine("db rollback              Rollback migrations");
            print.indentedLine("db seed                  Seed the database");
            print.indentedLine("db setup                 Create, migrate, and seed");
            print.indentedLine("db status                Show migration status");
            print.line();
            
            // Server Commands
            print.greenLine("  Server:");
            print.indentedLine("server start             Start the development server");
            print.indentedLine("server stop              Stop the development server");
            print.indentedLine("server restart           Restart the development server");
            print.line();
            
            // Template Commands
            print.greenLine("  Templates:");
            print.indentedLine("templates copy           Copy templates for customization");
            print.indentedLine("templates list           List available templates");
            print.line();
            
            // Test Commands
            print.greenLine("  Testing:");
            print.indentedLine("test all                 Run all tests");
            print.indentedLine("test unit                Run unit tests");
            print.indentedLine("test integration         Run integration tests");
            print.line();
            
            // Other Commands
            print.greenLine("  Other:");
            print.indentedLine("console                  Open an interactive console");
            print.indentedLine("routes                   Display application routes");
            print.line();
            
            print.yellowLine("Examples:");
            print.indentedLine("# Create a new blog application");
            print.indentedLine("wheels create app blog");
            print.line();
            print.indentedLine("# Generate a Post model with migration");
            print.indentedLine("wheels create model Post title:string content:text --migration");
            print.line();
            print.indentedLine("# Generate a RESTful controller");
            print.indentedLine("wheels create controller Posts --resource");
            print.line();
            print.indentedLine("# Run database migrations");
            print.indentedLine("wheels db migrate");
            print.line();
            
            print.yellowLine("For more help on a specific command:");
            print.indentedLine("wheels help <command>");
            print.indentedLine("wheels <command> --help");
            print.line();
            
            print.yellowLine("Documentation:");
            print.indentedLine("https://guides.cfwheels.org/cli");
            print.line();
        }
    }
}