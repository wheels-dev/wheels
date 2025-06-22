/**
 * Restart the development server
 */
component extends="commands.wheels.BaseCommand" {
    
    property name="serverService" inject="ServerService";
    
    /**
     * Restart the Wheels development server
     * 
     * @environment Environment to run in after restart
     * @openbrowser Open browser after restarting
     * @debug Enable debug output
     * @help Restart the development server
     */
    function run(
        string environment = "",
        boolean openbrowser = false,
        boolean debug = false
    ) {
        ensureWheelsProject();
        
        print.line();
        print.boldBlueLine("Restarting Wheels development server");
        
        // Get current server info
        var serverInfo = serverService.getServerInfoByWebroot(getCWD());
        
        if (structIsEmpty(serverInfo) || serverInfo.status != "running") {
            print.yellowLine("No server is running. Starting a new server instead...");
            
            var startParams = {
                openbrowser = arguments.openbrowser,
                debug = arguments.debug
            };
            
            if (len(arguments.environment)) {
                startParams.environment = arguments.environment;
            }
            
            command("wheels server start")
                .params(argumentCollection = startParams)
                .run();
                
            return;
        }
        
        // Store current server settings
        var currentPort = serverInfo.port;
        var currentHost = serverInfo.host;
        
        print.yellowLine("Current server on port #currentPort#");
        
        // Stop the server
        print.yellowLine("Stopping server...");
        
        command("server stop")
            .params(directory = getCWD())
            .run();
            
        // Wait a moment for server to fully stop
        sleep(1000);
        
        // Start the server with same or new settings
        print.yellowLine("Starting server...");
        
        var startParams = {
            port = currentPort,
            host = currentHost,
            openbrowser = arguments.openbrowser,
            debug = arguments.debug
        };
        
        if (len(arguments.environment)) {
            startParams.environment = arguments.environment;
            print.yellowLine("Switching to #arguments.environment# environment");
        }
        
        command("wheels server start")
            .params(argumentCollection = startParams)
            .run();
            
        print.line();
        print.greenBoldLine("✅ Server restarted successfully!");
    }
}