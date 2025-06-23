/**
 * Display Wheels version and project information
 */
component extends="base" {
    
    /**
     * @help Display Wheels framework and project version information
     */
    function run() {
        if (!isWheelsProject() && !isLegacyWheelsProject()) {
            print.redLine("Not in a Wheels project directory!");
            print.line();
            print.yellowLine("To create a new Wheels project, run:");
            print.indentedLine("wheels create app <name>");
            return;
        }
        
        var wheelsInfo = getWheelsInfo();
        
        print.line();
        print.boldBlueLine("CFWheels Project Information");
        print.line(repeatString("=", 40));
        
        // Framework info
        print.yellowLine("Framework:");
        print.indentedLine("Version: #wheelsInfo.version#");
        
        if (len(wheelsInfo.name)) {
            print.indentedLine("Package: #wheelsInfo.name#");
        }
        if (len(wheelsInfo.author)) {
            print.indentedLine("Author: #wheelsInfo.author#");
        }
        if (len(wheelsInfo.homepage)) {
            print.indentedLine("Homepage: #wheelsInfo.homepage#");
        }
        
        // Project info
        var projectBoxJson = getCWD() & "box.json";
        if (fileExists(projectBoxJson)) {
            try {
                var projectInfo = deserializeJSON(fileRead(projectBoxJson));
                
                print.line();
                print.yellowLine("Project:");
                
                if (structKeyExists(projectInfo, "name")) {
                    print.indentedLine("Name: #projectInfo.name#");
                }
                if (structKeyExists(projectInfo, "version")) {
                    print.indentedLine("Version: #projectInfo.version#");
                }
                if (structKeyExists(projectInfo, "author")) {
                    print.indentedLine("Author: #projectInfo.author#");
                }
                if (structKeyExists(projectInfo, "description")) {
                    print.indentedLine("Description: #projectInfo.description#");
                }
            } catch (any e) {
                // Ignore errors reading project box.json
            }
        }
        
        // Environment info
        print.line();
        print.yellowLine("Environment:");
        print.indentedLine("CommandBox: #shell.getVersion()#");
        
        // Get server info if available
        try {
            var serverInfo = serverService.getServerInfoByWebroot(getCWD());
            if (!structIsEmpty(serverInfo) && serverInfo.status == "running") {
                print.indentedLine("CFML Engine: #serverInfo.engineName# #serverInfo.engineVersion#");
                print.indentedLine("Server: #serverInfo.name# (port #serverInfo.port#)");
            }
        } catch (any e) {
            // Server might not be running
        }
        
        print.indentedLine("Project Root: #getCWD()#");
        
        // CLI info
        print.line();
        print.yellowLine("CLI:");
        print.indentedLine("Wheels CLI: 3.0.0-beta.1");
        
        if (isLegacyWheelsProject()) {
            print.line();
            print.redLine("⚠️  Legacy Project Structure Detected!");
            print.indentedLine("Consider upgrading to Wheels 3.0+ for better CLI support.");
            print.indentedLine("See: https://guides.cfwheels.org/upgrading");
        }
        
        print.line();
    }
}