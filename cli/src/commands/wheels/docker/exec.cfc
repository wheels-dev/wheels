/**
 * Execute commands in deployed containers
 *
 * {code:bash}
 * wheels docker exec "ls -la"
 * wheels docker exec "box repl" --interactive
 * wheels docker exec "mysql -u root -p" service=db --interactive
 * wheels docker exec "tail -f logs/application.log" servers=web1.example.com
 * {code}
 */
component extends="DockerCommand" {

    property name="detailOutput" inject="DetailOutputService@wheels-cli";

    /**
     * @command Command to execute in container
     * @servers Specific servers to execute on (comma-separated list)
     * @service Service to execute in: app or db (default: app)
     * @interactive Run command interactively (default: false)
     */
    function run(
        required string command,
        string servers="",
        string service="app",
        boolean interactive=false
    ) {
        //ensure we are in a Wheels app
        requireWheelsApp(getCWD());
        // Reconstruct arguments for handling --key=value style
        arguments = reconstructArgs(arguments);
        
        // Load servers
        var serverList = [];
        
        // Check for deploy-servers file (text or json) in current directory
        var textConfigPath = fileSystemUtil.resolvePath("deploy-servers.txt");
        var jsonConfigPath = fileSystemUtil.resolvePath("deploy-servers.json");
        var ymlConfigPath = fileSystemUtil.resolvePath("config/deploy.yml");
        var projectName = getProjectName();
        
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
            error("No server configuration found. Use 'wheels docker init' or create deploy-servers.txt.");
        }

        if (arrayLen(serverList) == 0) {
            error("No servers configured for execution");
        }

        // Validate interactive mode with multiple servers
        if (arguments.interactive && arrayLen(serverList) > 1) {
            error("Cannot run interactive commands on multiple servers simultaneously. Please specify a single server using 'servers=host'.");
        }

        detailOutput.header("Wheels Deploy Remote Execution");
        
        for (var serverConfig in serverList) {
            if (arrayLen(serverList) > 1) {
                detailOutput.subHeader("=== Server: #serverConfig.host# ===");
            }
            
            try {
                executeInContainer(serverConfig, arguments.command, arguments.service, arguments.interactive);
            } catch (any e) {
                // Check for UserInterruptException (CommandBox specific) or standard InterruptedException
                if (findNoCase("UserInterruptException", e.message) || findNoCase("InterruptedException", e.message) || (structKeyExists(e, "type") && findNoCase("UserInterruptException", e.type))) {
                    detailOutput.line();
                    detailOutput.statusFailed("Command interrupted by user.");
                    break;
                }
               detailOutput.statusFailed("Failed to execute command on #serverConfig.host#: #e.message#");
            }
        }
    }

    private function executeInContainer(
        struct serverConfig, 
        string command, 
        string service, 
        boolean interactive
    ) {
        var local = {};
        local.host = arguments.serverConfig.host;
        local.user = arguments.serverConfig.user;
        local.port = structKeyExists(arguments.serverConfig, "port") ? arguments.serverConfig.port : 22;
        local.projectName = getProjectName();
        local.imageName = structKeyExists(arguments.serverConfig, "imageName") ? arguments.serverConfig.imageName : local.projectName;

        // 1. Check SSH Connection
        if (!testSSHConnection(local.host, local.user, local.port)) {
            throw("SSH connection failed");
        }

        // 2. Determine Container Name
        var containerName = "";
        
        if (arguments.service == "app") {
            // Logic similar to logs.cfc to find active app container
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
            throw("Could not find running container for service: " & arguments.service);
        }

        // 3. Construct Docker Exec Command
        var execCmd = ["ssh", "-p", local.port];
        
        // If interactive, we need TTY allocation for SSH
        if (arguments.interactive) {
            execCmd.add("-t");
        }
        
        execCmd.addAll(getSSHOptions());
        
        var dockerCmd = "docker exec";
        
        // If interactive, we need interactive mode for Docker
        if (arguments.interactive) {
            dockerCmd &= " -it";
        }
        
        dockerCmd &= " " & containerName & " " & arguments.command;
        
        execCmd.addAll([local.user & "@" & local.host, dockerCmd]);
        
        // 4. Execute
        detailOutput.output("Executing: " & arguments.command);
        detailOutput.output("Container: " & containerName);
        detailOutput.output();
        
        // Use runInteractiveCommand for both interactive and non-interactive
        // For non-interactive, it streams output nicely.
        // For interactive, we pass true to inheritInput.
        var result = runInteractiveCommand(execCmd, arguments.interactive);
        
        if (result.exitCode != 0 && result.exitCode != 130) {
            throw("Command failed with exit code: " & result.exitCode);
        }
    }

}