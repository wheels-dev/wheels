/**
 * View deployment logs from servers
 * 
 * {code:bash}
 * wheels deploy:logs
 * wheels deploy:logs --tail=50 --follow
 * wheels deploy:logs --servers=192.168.1.100 --service=db
 * {code}
 */
component extends="../../base" {

    /**
     * @servers Specific servers to check (comma-separated)
     * @tail Number of lines to show
     * @follow Follow log output
     * @service Service to show logs for (app or db)
     * @since Show logs since timestamp (e.g. 2023-01-01, 1h, 5m)
     */
    function run(
        string servers="",
        numeric tail=100,
        boolean follow=false,
        string service="app",
        string since=""
    ) {
        var deployConfig = loadDeployConfig();
        if (isNull(deployConfig)) {
            return;
        }
        
        print.line();
        print.boldMagentaLine("Wheels Deployment Logs");
        print.line("=".repeatString(50));
        
        // Determine target servers
        var targetServers = [];
        if (len(arguments.servers)) {
            targetServers = listToArray(arguments.servers);
        } else if (structKeyExists(deployConfig, "servers") && structKeyExists(deployConfig.servers, "web")) {
            targetServers = deployConfig.servers.web;
        }
        
        if (arrayIsEmpty(targetServers)) {
            print.redLine("No servers configured!");
            return;
        }
        
        var sshUser = deployConfig.ssh.user ?: "root";
        var containerName = deployConfig.service;
        
        // Determine which container to show logs for
        if (arguments.service == "db") {
            containerName &= "_db";
        }
        
        // Build docker logs command
        var logCmd = "docker logs";
        
        if (arguments.tail > 0 && !arguments.follow) {
            logCmd &= " --tail #arguments.tail#";
        }
        
        if (arguments.follow) {
            logCmd &= " -f";
        }
        
        if (len(arguments.since)) {
            logCmd &= " --since #arguments.since#";
        }
        
        logCmd &= " #containerName# 2>&1";
        
        // Show logs from each server
        for (var i = 1; i <= arrayLen(targetServers); i++) {
            var server = targetServers[i];
            
            if (arrayLen(targetServers) > 1) {
                print.line();
                print.boldLine("=== Server: #server# ===");
                print.line();
            }
            
            if (arguments.follow) {
                print.yellowLine("Following logs (Ctrl+C to stop)...");
                print.line();
                
                // For follow mode, we need to execute interactively
                runCommand(
                    name="ssh",
                    arguments="#sshUser#@#server# '#logCmd#'"
                );
            } else {
                var result = $execBash("ssh #sshUser#@#server# '#logCmd#'");
                
                if (result.exitCode == 0) {
                    print.line(result.output);
                } else {
                    print.redLine("Failed to retrieve logs from #server#");
                    if (len(result.error)) {
                        print.redLine("Error: #result.error#");
                    }
                }
            }
        }
        
        if (!arguments.follow) {
            print.line();
            print.line("Tip: Use --follow to stream logs in real-time");
            print.line("     Use --tail=N to show last N lines");
            print.line("     Use --since=1h to show logs from last hour");
        }
    }
    
    private any function loadDeployConfig() {
        var deployConfigPath = fileSystemUtil.resolvePath("deploy.json");
        
        if (!fileExists(deployConfigPath)) {
            print.redLine("deploy.json not found! Run 'wheels deploy:init' first.");
            return;
        }
        
        try {
            return deserializeJSON(fileRead(deployConfigPath));
        } catch (any e) {
            print.redLine("Error reading deploy.json: #e.message#");
            return;
        }
    }
    
    private struct function $execBash(required string command) {
        try {
            var result = runCommand(
                name="bash",
                arguments="-c ""#arguments.command#""",
                timeout=60
            );
            
            return {
                exitCode: result.status ?: 0,
                output: result.output ?: "",
                error: result.error ?: ""
            };
        } catch (any e) {
            return {
                exitCode: 1,
                output: "",
                error: e.message
            };
        }
    }
}