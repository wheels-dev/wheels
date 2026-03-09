/**
 * View deployment logs from servers
 *
 * {code:bash}
 * wheels docker logs
 * wheels docker logs --follow
 * wheels docker logs tail=50 servers=web1.example.com
 * wheels docker logs service=db
 * wheels docker logs since=1h
 * wheels docker logs --remote
 * {code}
 */
component extends="DockerCommand" {

    property name="detailOutput" inject="DetailOutputService@wheels-cli";

    /**
     * @local Fetch logs from local Docker environment
     * @remote Fetch logs from remote server(s)
     * @servers Specific servers to check (comma-separated list)
     * @tail Number of lines to show (default: 100)
     * @follow Follow log output in real-time (default: false)
     * @service Service to show logs for: app or db (default: app)
     * @since Show logs since timestamp (e.g., "2023-01-01", "1h", "5m")
     */
    function run(
        boolean local=false,
        boolean remote=false,
        string servers="",
        string tail="100",
        boolean follow=false,
        string service="app",
        string since=""
    ) {
        //ensure we are in a Wheels app
        requireWheelsApp(getCWD());

        // Reconstruct arguments for handling --key=value style
        arguments = reconstructArgs(arguments);

        if (arguments.local && arguments.remote) {
            detailOutput.error("Cannot specify both --local and --remote. Please choose one.");
            return;
        }

        if (!arguments.local && !arguments.remote) {
            arguments.local = true;
        }

        if (len(arguments.tail) && !isNumeric(arguments.tail)) {
            detailOutput.error("Invalid value for tail. It must be a number.");
            return;
        }
        
        if (arguments.remote == false) {
            fetchLocalLogs(arguments.tail, arguments.follow, arguments.service, arguments.since);
            return;
        }
        
        // Load servers
        var serverList = [];
        
        // Resolve config using centralized config resolution
        var config = resolveConfig({});
        var projectName = config.name;
        
        // Check for deploy-servers file (text or json) in current directory
        var textConfigPath = fileSystemUtil.resolvePath("deploy-servers.txt");
        var jsonConfigPath = fileSystemUtil.resolvePath("deploy-servers.json");
        var ymlConfigPath = fileSystemUtil.resolvePath("config/deploy.yml");
        
        // If specific servers argument is provided
        if (len(trim(arguments.servers))) {
            // Check if it's a file
            if (fileExists(fileSystemUtil.resolvePath(arguments.servers))) {
                if (right(arguments.servers, 5) == ".json") {
                    serverList = loadServersFromConfig(arguments.servers);
                } else {
                    serverList = loadServersFromTextFile(arguments.servers);
                }
            } else {
                // Treat as comma-separated list of hosts
                var hosts = listToArray(arguments.servers, ",");
                for (var host in hosts) {
                    arrayAppend(serverList, {
                        "host": trim(host),
                        "user": "deploy", 
                        "port": 22,
                        "remoteDir": "/home/deploy/#projectName#", 
                        "imageName": projectName 
                    });
                }
            }
        } 
        // 1. Look for config/deploy.yml first
        else if (fileExists(ymlConfigPath)) {
            var deployConfig = getDeployConfig();
            if (arrayLen(deployConfig.servers)) {
                detailOutput.identical("Found config/deploy.yml, loading server configuration");
                serverList = deployConfig.servers;
                
                // Add defaults for missing fields
                for (var s in serverList) {
                    if (!structKeyExists(s, "remoteDir")) {
                        s.remoteDir = "/home/#s.user#/#projectName#";
                    }
                    if (!structKeyExists(s, "port")) {
                        s.port = 22;
                    }
                    if (!structKeyExists(s, "imageName")) {
                        s.imageName = projectName;
                    }
                }
            }
        }
        // 2. Otherwise, look for default files
        else if (fileExists(textConfigPath)) {
            detailOutput.identical("Found deploy-servers.txt, loading server configuration");
            serverList = loadServersFromTextFile("deploy-servers.txt");
        } else if (fileExists(jsonConfigPath)) {
            detailOutput.identical("Found deploy-servers.json, loading server configuration");
            serverList = loadServersFromConfig("deploy-servers.json");
        } else {
            detailOutput.error("No server configuration found. Use 'wheels docker init' or create deploy-servers.txt.");
            return;
        }

        if (arrayLen(serverList) == 0) {
            detailOutput.error("No servers configured for logs");
            return;
        }

        // Validate follow mode with multiple servers
        if (arguments.follow && arrayLen(serverList) > 1) {
            detailOutput.error("Cannot follow logs from multiple servers simultaneously. Please specify a single server using 'servers=host'.");
            return;
        }

        detailOutput.header("Wheels Deployment Logs");
        
        for (var serverConfig in serverList) {
            if (arrayLen(serverList) > 1) {
                detailOutput.subHeader("=== Server: #serverConfig.host# ===");
            }
            
            try {
                fetchLogs(serverConfig, arguments.tail, arguments.follow, arguments.service, arguments.since);
            } catch (any e) {
                // Check for UserInterruptException (CommandBox specific) or standard InterruptedException
                if (findNoCase("UserInterruptException", e.message) || findNoCase("InterruptedException", e.message) || (structKeyExists(e, "type") && findNoCase("UserInterruptException", e.type))) {
                    detailOutput.line();
                    detailOutput.error("Command interrupted by user.");
                    break;
                }
                detailOutput.statusFailed("Failed to fetch logs from #serverConfig.host#: #e.message#");
            }
        }
    }

    private function fetchLogs(
        struct serverConfig, 
        string tail, 
        boolean follow, 
        string service, 
        string since
    ) {
        var local = {};
        local.host = arguments.serverConfig.host;
        local.user = arguments.serverConfig.user;
        local.port = structKeyExists(arguments.serverConfig, "port") ? arguments.serverConfig.port : 22;
        local.projectName = getProjectName();
        local.imageName = structKeyExists(arguments.serverConfig, "imageName") ? arguments.serverConfig.imageName : local.projectName;

        // 1. Check SSH Connection (skip if following to save time/output noise?)
        // Better to check to avoid hanging on bad connection
        if (!testSSHConnection(local.host, local.user, local.port)) {
            detailOutput.error("SSH connection failed");
            return;
        }

        // 2. Determine Container Name
        var containerName = "";
        
        if (arguments.service == "app") {
            // Logic similar to status.cfc to find active app container
            var findCmd = ["ssh", "-p", local.port];
            findCmd.addAll(getSSHOptions());
            // Filter by name (including blue/green variants)
            findCmd.addAll([local.user & "@" & local.host, "docker ps --format '{{.Names}}' --filter name=" & local.imageName]);
            
            var findResult = runLocalCommand(findCmd, false);
            var runningContainers = listToArray(trim(findResult.output), chr(10));
            
            if (arrayLen(runningContainers) > 0) {
                // Default to first found
                containerName = runningContainers[1];
                
                // Try to find exact match or blue/green
                for (var container in runningContainers) {
                    if (container == local.imageName || container == local.imageName & "-blue" || container == local.imageName & "-green") {
                        containerName = container;
                        break;
                    }
                }
            }
        } else {
            // Attempt to find service container (e.g. db)
            // Try common patterns: [project]-[service], [service]
            var patterns = [
                local.imageName & "-" & arguments.service,
                arguments.service
            ];
            
            for (var pattern in patterns) {
                var findServiceCmd = ["ssh", "-p", local.port];
                findServiceCmd.addAll(getSSHOptions());
                findServiceCmd.addAll([local.user & "@" & local.host, "docker ps --format '{{.Names}}' --filter name=" & pattern]);
                
                var serviceResult = runLocalCommand(findServiceCmd, false);
                if (serviceResult.exitCode == 0 && len(trim(serviceResult.output))) {
                    containerName = listFirst(trim(serviceResult.output), chr(10));
                    break;
                }
            }
        }

        if (!len(containerName)) {
            detailOutput.error("Could not find running container for service: " & arguments.service);
            return;
        }

        // 3. Construct Docker Logs Command
        var logsCmd = ["ssh", "-p", local.port];
        // If following, we need TTY allocation? ssh -t? 
        // Actually, for streaming output, standard ssh works, but we might need -t if we want to send Ctrl+C correctly?
        // Let's stick to standard for now.
        logsCmd.addAll(getSSHOptions());
        
        var dockerCmd = "docker logs";
        
        if (len(arguments.tail)) {
            dockerCmd &= " --tail " & arguments.tail;
        }
        
        if (len(arguments.since)) {
            dockerCmd &= " --since " & arguments.since;
        }
        
        if (arguments.follow) {
            dockerCmd &= " -f";
        }
        
        dockerCmd &= " " & containerName;
        
        logsCmd.addAll([local.user & "@" & local.host, dockerCmd]);

        detailOutput.statusInfo("Executing: " & dockerCmd);
        
        // 4. Execute
        // If following, we want to print output as it comes. runLocalCommand does this.
        // However, runLocalCommand waits for completion. For -f, it will run indefinitely until user interrupts.
        // This is fine for CLI usage.
        
        detailOutput.statusInfo("Fetching logs from container: " & containerName);
        // Optional improvement
        if (len(arguments.since)) {
            detailOutput.statusInfo("Filtering logs since: " & arguments.since);
        }
        if (arguments.follow) {
           detailOutput.statusInfo("Following logs... (Press Ctrl+C to stop)");
        }
        detailOutput.line("----------------------------------------");
        
        var result = runInteractiveCommand(logsCmd);
        
        if (result.exitCode != 0 && result.exitCode != 130) {
            detailOutput.error("Command failed with exit code: " & result.exitCode);
            return;
        }
    }

    private function fetchLocalLogs(
        string tail, 
        boolean follow, 
        string service, 
        string since
    ) {
        // Resolve config using centralized config resolution
        var config = resolveConfig({});
        var projectName = config.name;
        var containerName = "";
        
        if (arguments.service == "app") {
            // Find app container
            // Filter by name (including blue/green variants)
            var findCmd = ["docker", "ps", "--format", "{{.Names}}", "--filter", "name=" & projectName];
            
            var findResult = runLocalCommand(findCmd, false);
            var runningContainers = listToArray(trim(findResult.output), chr(10));
            
            if (arrayLen(runningContainers) > 0) {
                // Default to first found
                containerName = runningContainers[1];
                
                // Try to find exact match or blue/green
                for (var container in runningContainers) {
                    if (container == projectName || container == projectName & "-blue" || container == projectName & "-green") {
                        containerName = container;
                        break;
                    }
                }
            }
        } else {
            // Attempt to find service container (e.g. db)
            // Try common patterns: [project]-[service], [service]
            var patterns = [
                projectName & "-" & arguments.service,
                arguments.service
            ];
            
            for (var pattern in patterns) {
                var findServiceCmd = ["docker", "ps", "--format", "{{.Names}}", "--filter", "name=" & pattern];
                
                var serviceResult = runLocalCommand(findServiceCmd, false);
                if (serviceResult.exitCode == 0 && len(trim(serviceResult.output))) {
                    containerName = listFirst(trim(serviceResult.output), chr(10));
                    break;
                }
            }
        }

        if (!len(containerName)) {
            if(arguments.service == "app") {
                detailOutput.error("Could not find running container for service: " & projectName);
            } else {
                detailOutput.error("Could not find running container for service: " & arguments.service);
            }
            return;
        }

        detailOutput.header("Wheels Deployment Logs (Local)");
        detailOutput.statusInfo("Fetching logs from local container: " & containerName);

        // Optional improvement
        if (len(arguments.since)) {
            detailOutput.statusInfo("Filtering logs since: " & arguments.since);
        }

        if (arguments.follow) {
            detailOutput.statusInfo("Following logs... (Press Ctrl+C to stop)");
        }
        detailOutput.output("----------------------------------------");
        
        // Construct Docker Logs Command
        var dockerCmd = ["docker", "logs"];
        
        if (len(arguments.tail)) {
            dockerCmd.addAll(["--tail", arguments.tail]);
        }
        
        if (len(arguments.since)) {
            dockerCmd.addAll(["--since", arguments.since]);
        }
        
        if (arguments.follow) {
            dockerCmd.add("-f");
        }
        
        dockerCmd.add(containerName);

        detailOutput.statusInfo("Executing: " & arrayToList(dockerCmd, " "));
        
        var result = runInteractiveCommand(dockerCmd);
        
        if (result.exitCode != 0 && result.exitCode != 130) {
            detailOutput.error("Command failed with exit code: " & result.exitCode);
            return;
        }
    }

}