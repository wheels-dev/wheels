component extends="commandbox.system.BaseCommand" {

    property name="configService" inject="ConfigService";
    
    /**
     * Check if current directory is a Wheels project
     */
    function isWheelsProject() {
        return fileExists(resolvePath("box.json")) && 
               (fileExists(resolvePath("Application.cfc")) || 
                fileExists(resolvePath("Application.cfm")));
    }
    
    /**
     * Get Wheels version from box.json
     */
    function getWheelsVersion() {
        var boxPath = resolvePath("box.json");
        if (fileExists(boxPath)) {
            var boxData = deserializeJSON(fileRead(boxPath));
            return boxData.dependencies.keyExists("wheels") ? 
                   boxData.dependencies.wheels : "unknown";
        }
        return "unknown";
    }
    
    /**
     * Display file generation summary
     */
    function displayGenerationSummary(files, options) {
        print.line()
             .greenBoldLine("🎉 Generated #files.len()# files:")
             .line();
        
        files.each(function(file) {
            print.greenLine("  ✓ #file#");
        });
        
        print.line()
             .yellowLine("Next steps:")
             .line("1. Review generated files")
             .line("2. Run tests: wheels test run")
             .line("3. Start server: server start");
    }
    
    /**
     * Run a command and return output
     */
    function runCommand(required string cmd) {
        return command(arguments.cmd).run(returnOutput = true);
    }
    
    /**
     * Open a file path in the default editor
     */
    function openPath(required string path) {
        if (shell.isWindows()) {
            runCommand("start #arguments.path#");
        } else if (shell.isMac()) {
            runCommand("open #arguments.path#");
        } else {
            runCommand("xdg-open #arguments.path#");
        }
    }
    
    /**
     * Check for migration changes in file list
     */
    function hasMigrationChanges(required array changes) {
        return changes.some(function(change) {
            return change.path contains "migrations" || 
                   change.path contains "db/schema";
        });
    }
    
    /**
     * Reload the Wheels framework
     */
    function reloadFramework() {
        var serverInfo = getServerInfo();
        var reloadURL = serverInfo.serverURL & "/?reload=true";
        
        http url=reloadURL timeout=5;
        print.greenLine("✅ Framework reloaded");
    }
    
    /**
     * Get current server information
     */
    function getServerInfo() {
        var serverService = getInstance("ServerService@commandbox-core");
        var serverDetails = serverService.resolveServerDetails(
            serverProps = { webroot = getCWD() }
        );
        
        return {
            host = serverDetails.serverInfo.host,
            port = serverDetails.serverInfo.port,
            serverURL = "http://" & serverDetails.serverInfo.host & ":" & serverDetails.serverInfo.port
        };
    }
}