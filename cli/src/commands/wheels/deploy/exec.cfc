/**
 * Execute commands in deployed containers
 * 
 * {code:bash}
 * wheels deploy:exec "ls -la"
 * wheels deploy:exec "box repl" --interactive
 * wheels deploy:exec "mysql -u root -p" --service=db --interactive
 * {code}
 */
component extends="./base" {

    /**
     * @command Command to execute in container
     * @servers Execute on specific servers (comma-separated)
     * @service Service to execute in (app or db)
     * @interactive Run command interactively
     */
    function run(
        required string command,
        string servers="",
        string service="app",
        boolean interactive=false
    ) {
        var deployConfig = loadDeployConfig();
        if (isNull(deployConfig)) {
            return;
        }
        
        print.line();
        print.boldMagentaLine("Wheels Deploy Remote Execution");
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
        
        // Determine which container to execute in
        if (arguments.service == "db") {
            containerName &= "_db";
        }
        
        print.line("Executing: #arguments.command#");
        print.line("Container: #containerName#");
        print.line();
        
        // Execute on each server
        for (var server in targetServers) {
            if (arrayLen(targetServers) > 1) {
                print.boldLine("Server: #server#");
                print.line("-".repeatString(30));
            }
            
            var execCmd = "docker exec";
            
            if (arguments.interactive) {
                execCmd &= " -it";
            }
            
            execCmd &= " #containerName# #arguments.command#";
            
            if (arguments.interactive) {
                // For interactive mode, use native SSH
                runCommand(
                    name="ssh",
                    arguments="-t #sshUser#@#server# '#execCmd#'"
                );
            } else {
                var result = $execBash("ssh #sshUser#@#server# '#execCmd#'");
                
                if (result.exitCode == 0) {
                    if (len(trim(result.output))) {
                        print.line(result.output);
                    }
                } else {
                    print.redLine("Failed to execute command on #server#");
                    if (len(result.error)) {
                        print.redLine("Error: #result.error#");
                    }
                }
            }
            
            if (arrayLen(targetServers) > 1) {
                print.line();
            }
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
                timeout=300
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