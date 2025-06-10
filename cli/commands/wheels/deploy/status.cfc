/**
 * Check deployment status across all servers
 * 
 * {code:bash}
 * wheels deploy:status
 * wheels deploy:status --servers=192.168.1.100
 * wheels deploy:status --detailed
 * {code}
 */
component extends="./base" {

    /**
     * @servers Check specific servers (comma-separated)
     * @detailed Show detailed container information
     * @logs Show recent container logs
     */
    function run(
        string servers="",
        boolean detailed=false,
        boolean logs=false
    ) {
        var deployConfig = loadDeployConfig();
        if (isNull(deployConfig)) {
            return;
        }
        
        print.line();
        print.boldMagentaLine("Wheels Deployment Status");
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
        var serviceName = deployConfig.service;
        
        print.line("Checking #arrayLen(targetServers)# server(s)...");
        print.line();
        
        var allHealthy = true;
        
        // Check each server
        for (var server in targetServers) {
            print.boldLine("Server: #server#");
            print.line("-".repeatString(40));
            
            // Check SSH connectivity
            var sshResult = $execBash("ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no #sshUser#@#server# 'echo OK'");
            
            if (sshResult.exitCode != 0) {
                print.redLine("✗ SSH Connection Failed");
                print.line("  Error: Unable to connect to server");
                print.line();
                allHealthy = false;
                continue;
            }
            
            print.greenLine("✓ SSH Connection OK");
            
            // Check Docker status
            var dockerResult = $execBash("ssh #sshUser#@#server# 'docker --version'");
            if (dockerResult.exitCode != 0) {
                print.redLine("✗ Docker Not Available");
                allHealthy = false;
            } else {
                print.greenLine("✓ Docker Running");
            }
            
            // Check container status
            var containerResult = $execBash("ssh #sshUser#@#server# 'docker ps --filter name=#serviceName# --format ""table {{.Names}}\t{{.Status}}\t{{.Image}}""'");
            
            if (containerResult.exitCode == 0 && len(trim(containerResult.output))) {
                var lines = listToArray(containerResult.output, chr(10));
                var foundContainer = false;
                
                for (var line in lines) {
                    if (line contains serviceName && !line contains "NAMES") {
                        foundContainer = true;
                        var parts = reReplace(line, "\s+", "|", "all");
                        var statusParts = listToArray(parts, "|");
                        
                        if (arrayLen(statusParts) >= 3) {
                            var status = statusParts[2];
                            var image = statusParts[3];
                            
                            if (status contains "Up") {
                                print.greenLine("✓ Container Running");
                                print.line("  Status: #status#");
                                print.line("  Image: #image#");
                            } else {
                                print.redLine("✗ Container Not Healthy");
                                print.line("  Status: #status#");
                                allHealthy = false;
                            }
                        }
                    }
                }
                
                if (!foundContainer) {
                    print.redLine("✗ Container Not Found");
                    allHealthy = false;
                }
            } else {
                print.redLine("✗ Container Not Running");
                allHealthy = false;
            }
            
            // Check health endpoint
            if (structKeyExists(deployConfig, "healthcheck")) {
                var healthUrl = "http://#server#:#deployConfig.healthcheck.port##deployConfig.healthcheck.path#";
                var healthResult = $execBash("ssh #sshUser#@#server# 'curl -f -s -o /dev/null -w ""%{http_code}"" #healthUrl#'");
                
                if (healthResult.exitCode == 0 && trim(healthResult.output) == "200") {
                    print.greenLine("✓ Health Check Passed");
                } else {
                    print.redLine("✗ Health Check Failed");
                    print.line("  HTTP Status: #trim(healthResult.output)#");
                    allHealthy = false;
                }
            }
            
            // Show detailed info if requested
            if (arguments.detailed) {
                print.line();
                print.yellowLine("Container Details:");
                
                var inspectResult = $execBash("ssh #sshUser#@#server# 'docker inspect #serviceName# --format ""Created: {{.Created}}\nState: {{.State.Status}}\nRestartCount: {{.RestartCount}}\nPorts: {{range \$p, \$conf := .NetworkSettings.Ports}}{{if \$conf}}{{(index \$conf 0).HostPort}}->{{trimPrefix \""/tcp\"" \$p}} {{end}}{{end}}""'");
                
                if (inspectResult.exitCode == 0) {
                    print.line(inspectResult.output);
                }
                
                // Check disk usage
                var dfResult = $execBash("ssh #sshUser#@#server# 'df -h /opt/#serviceName# | tail -1'");
                if (dfResult.exitCode == 0) {
                    var dfParts = reReplace(trim(dfResult.output), "\s+", "|", "all");
                    var dfArray = listToArray(dfParts, "|");
                    if (arrayLen(dfArray) >= 5) {
                        print.line("Disk Usage: #dfArray[5]# (#dfArray[3]# available)");
                    }
                }
            }
            
            // Show logs if requested
            if (arguments.logs) {
                print.line();
                print.yellowLine("Recent Logs:");
                
                var logsResult = $execBash("ssh #sshUser#@#server# 'docker logs --tail 20 #serviceName# 2>&1'");
                if (logsResult.exitCode == 0) {
                    print.line("-".repeatString(40));
                    print.line(logsResult.output);
                    print.line("-".repeatString(40));
                }
            }
            
            // Check for database if configured
            if (structKeyExists(deployConfig, "accessories") && structKeyExists(deployConfig.accessories, "db")) {
                print.line();
                print.yellowLine("Database Status:");
                
                var dbResult = $execBash("ssh #sshUser#@#server# 'docker ps --filter name=#serviceName#_db --format ""{{.Status}}""'");
                
                if (dbResult.exitCode == 0 && len(trim(dbResult.output))) {
                    if (dbResult.output contains "Up") {
                        print.greenLine("✓ Database Running");
                        print.line("  Status: #trim(dbResult.output)#");
                    } else {
                        print.redLine("✗ Database Not Healthy");
                        allHealthy = false;
                    }
                } else {
                    print.redLine("✗ Database Not Found");
                    allHealthy = false;
                }
            }
            
            print.line();
        }
        
        // Summary
        print.line("=".repeatString(50));
        if (allHealthy) {
            print.boldGreenLine("Overall Status: ✓ All Systems Healthy");
        } else {
            print.boldRedLine("Overall Status: ✗ Issues Detected");
            print.line();
            print.line("Run 'wheels deploy:push' to redeploy");
            print.line("Run 'wheels deploy:logs' to view detailed logs");
        }
        print.line();
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
                timeout=30
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