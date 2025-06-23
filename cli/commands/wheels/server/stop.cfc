/**
 * Stop the development server
 */
component extends="../base" {
    
    property name="serverService" inject="ServerService@commandbox";
    
    /**
     * Stop the Wheels development server
     * 
     * @force Force stop the server
     * @all Stop all running servers
     * @help Stop the running development server
     */
    function run(
        boolean force = false,
        boolean all = false
    ) {
        if (arguments.all) {
            print.line();
            print.boldBlueLine("Stopping all servers");
            
            command("server stop")
                .params(all = true, force = arguments.force)
                .run();
                
            return;
        }
        
        ensureWheelsProject();
        
        print.line();
        print.boldBlueLine("Stopping Wheels development server");
        
        // Get server info
        var serverInfo = serverService.getServerInfoByWebroot(getCWD());
        
        if (structIsEmpty(serverInfo) || serverInfo.status != "running") {
            print.yellowLine("No server is running for this project.");
            return;
        }
        
        print.yellowLine("Stopping server on port #serverInfo.port#...");
        
        try {
            command("server stop")
                .params(
                    directory = getCWD(),
                    force = arguments.force
                )
                .run();
                
            print.greenBoldLine("✅ Server stopped successfully!");
            
        } catch (any e) {
            print.redLine("Failed to stop server: #e.message#");
            
            if (!arguments.force) {
                print.line();
                print.yellowLine("Try forcing the stop:");
                print.indentedLine("wheels server stop --force");
            }
        }
    }
}