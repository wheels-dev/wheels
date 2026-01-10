/**
 * Stop deployed containers on servers
 * 
 * {code:bash}
 * wheels deploy:stop
 * wheels deploy:stop --servers=192.168.1.100
 * wheels deploy:stop --remove
 * {code}
 */
component extends="./base" {

    /**
     * @servers Stop on specific servers (comma-separated)
     * @remove Remove containers after stopping
     * @force Skip confirmation prompt
     */
    function run(
        string servers="",
        boolean remove=false,
        boolean force=false
    ) {
        var deployConfig = loadDeployConfig();
        if (isNull(deployConfig)) {
            return;
        }
        
        print.line();
        print.boldMagentaLine("Wheels Deploy Stop");
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
        
        // Confirm action
        if (!arguments.force) {
            print.yellowLine("WARNING: This will stop your application on the following servers:");
            print.line(arrayToList(targetServers, ", "));
            
            if (arguments.remove) {
                print.redLine("Containers will be REMOVED after stopping!");
            }
            
            print.line();
            var confirm = ask("Are you sure you want to continue? (yes/no): ");
            
            if (lCase(trim(confirm)) != "yes") {
                print.line("Operation cancelled.");
                return;
            }
        }
        
        var sshUser = deployConfig.ssh.user ?: "root";
        var serviceName = deployConfig.service;
        
        print.line();
        
        // Stop containers on each server
        for (var server in targetServers) {
            print.boldLine("Server: #server#");
            print.line("-".repeatString(30));
            
            var action = arguments.remove ? "down" : "stop";
            
            print.yellowLine("Stopping containers...");
            var result = $execBash("ssh #sshUser#@#server# 'cd /opt/#serviceName# && docker compose #action#'");
            
            if (result.exitCode == 0) {
                print.greenLine("✓ Containers stopped successfully");
                
                if (arguments.remove) {
                    // Clean up volumes if removing
                    print.yellowLine("Cleaning up volumes...");
                    $execBash("ssh #sshUser#@#server# 'cd /opt/#serviceName# && docker compose down -v'");
                }
            } else {
                print.redLine("✗ Failed to stop containers");
                if (len(result.error)) {
                    print.redLine("Error: #result.error#");
                }
            }
            
            print.line();
        }
        
        print.line();
        print.boldLine("Operation completed.");
        
        if (!arguments.remove) {
            print.line();
            print.line("To restart: wheels deploy:push --no-build");
            print.line("To remove completely: wheels deploy:stop --remove");
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