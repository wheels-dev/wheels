/**
 * Start the development server
 */
component extends="../base" {
    
    property name="serverService" inject="ServerService@commandbox";
    
    /**
     * Start the Wheels development server
     * 
     * @port Port number to use
     * @host Host/IP to bind to
     * @environment Environment to run in (development, testing, production)
     * @openbrowser Open browser after starting
     * @rewritesEnable Enable URL rewriting
     * @heapSize JVM heap size (e.g., 512m, 1024m)
     * @debug Enable debug output
     * @help Start the development server for your Wheels application
     */
    function run(
        numeric port = 0,
        string host = "127.0.0.1",
        string environment = "development",
        boolean openbrowser = true,
        boolean rewritesEnable = true,
        string heapSize = "",
        boolean debug = false
    ) {
        ensureWheelsProject();
        
        print.line();
        print.boldBlueLine("Starting Wheels development server");
        
        // Check if server is already running
        var serverInfo = serverService.getServerInfoByWebroot(getCWD());
        
        if (!structIsEmpty(serverInfo) && serverInfo.status == "running") {
            print.yellowLine("Server is already running on port #serverInfo.port#");
            
            if (arguments.openbrowser) {
                print.line("Opening browser...");
                openBrowser("http://#serverInfo.host#:#serverInfo.port#");
            }
            
            return;
        }
        
        // Build server start parameters
        var params = {
            openbrowser = arguments.openbrowser,
            directory = getCWD(),
            rewritesEnable = arguments.rewritesEnable
        };
        
        // Set environment
        params.env = {
            WHEELS_ENV = arguments.environment,
            WHEELS_ENVIRONMENT = arguments.environment
        };
        
        // Set port if specified
        if (arguments.port > 0) {
            params.port = arguments.port;
        }
        
        // Set host
        params.host = arguments.host;
        
        // Set heap size if specified
        if (len(arguments.heapSize)) {
            params.heapSize = arguments.heapSize;
        }
        
        // Enable debug if requested
        if (arguments.debug) {
            params.debug = true;
            params.trace = true;
        }
        
        print.yellowLine("Environment: #arguments.environment#");
        
        if (arguments.port > 0) {
            print.yellowLine("Port: #arguments.port#");
        } else {
            print.yellowLine("Port: Auto-assigned");
        }
        
        print.yellowLine("Host: #arguments.host#");
        print.yellowLine("URL Rewriting: #arguments.rewritesEnable ? 'Enabled' : 'Disabled'#");
        
        if (len(arguments.heapSize)) {
            print.yellowLine("Heap Size: #arguments.heapSize#");
        }
        
        print.line();
        
        // Start the server
        try {
            command("server start")
                .params(argumentCollection = params)
                .run();
                
            print.line();
            print.greenBoldLine("✅ Server started successfully!");
            
            // Get actual server info after start
            serverInfo = serverService.getServerInfoByWebroot(getCWD());
            
            if (!structIsEmpty(serverInfo)) {
                print.line();
                print.yellowLine("Server Details:");
                print.indentedLine("URL: http://#serverInfo.host#:#serverInfo.port#");
                print.indentedLine("PID: #serverInfo.pid#");
                print.indentedLine("Engine: #serverInfo.engineName# #serverInfo.engineVersion#");
            }
            
            print.line();
            print.yellowLine("Server Commands:");
            print.indentedLine("• Stop server: wheels server stop");
            print.indentedLine("• Restart server: wheels server restart");
            print.indentedLine("• View logs: server log");
            
        } catch (any e) {
            print.redLine("Failed to start server: #e.message#");
            
            if (findNoCase("port", e.message)) {
                print.line();
                print.yellowLine("The port may already be in use. Try a different port:");
                print.indentedLine("wheels server start --port=8081");
            }
        }
    }
}