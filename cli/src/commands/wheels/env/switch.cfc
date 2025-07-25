/**
 * Switch to a different environment
 * Examples:
 * wheels env switch production
 * wheels env switch development
 */
component extends="../base" {
    
    property name="environmentService" inject="EnvironmentService@wheels-cli";
    
    /**
     * @environment.hint Environment name to switch to
     */
    function run(
        required string environment
    ) {
        var projectRoot = resolvePath(".");
        print.line(projectRoot);
        print.yellowLine("Switching to '#arguments.environment#' environment...")
             .line();
        
        var result = environmentService.switch(arguments.environment, projectRoot);
        
        if (result.success) {
            print.greenLine(" #result.message#")
                 .line();
            
            print.yellowLine("Note: You may need to restart your server for all changes to take effect");
        } else {
            print.redLine("Failed to switch environment: #result.error#");
            setExitCode(1);
        }
    }
}