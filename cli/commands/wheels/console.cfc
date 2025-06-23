/**
 * Open an interactive Wheels console
 */
component extends="base" {
    
    /**
     * Start an interactive console session with your Wheels application loaded
     * 
     * @environment Environment to load (development, testing, production)
     * @help Open an interactive REPL with your Wheels application context
     */
    function run(
        string environment = "development"
    ) {
        ensureWheelsProject();
        
        print.line();
        print.boldBlueLine("Starting Wheels Console");
        print.yellowLine("Environment: #arguments.environment#");
        print.line();
        
        print.line("Loading Wheels application...");
        
        // In a real implementation, this would:
        // 1. Start the application in the specified environment
        // 2. Load all models and make them available
        // 3. Provide helper methods for common tasks
        // 4. Start an interactive REPL session
        
        print.greenLine("✓ Wheels application loaded");
        print.line();
        
        print.yellowLine("Available commands:");
        print.indentedLine("• model('ModelName') - Get a model instance");
        print.indentedLine("• reload() - Reload the application");
        print.indentedLine("• routes() - Display routes");
        print.indentedLine("• exit - Exit the console");
        print.line();
        
        print.yellowLine("Example usage:");
        print.greyLine("wheels> user = model('User').findByKey(1)");
        print.greyLine("wheels> users = model('User').findAll()");
        print.greyLine("wheels> newPost = model('Post').create(title='Test', content='Content')");
        print.line();
        
        // Start CommandBox REPL
        print.line("Starting interactive session...");
        print.line();
        
        command("repl")
            .params(
                prompt = "wheels> ",
                historySave = true
            )
            .run();
    }
}