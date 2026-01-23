/**
 * Unified Docker stop command for Wheels apps
 *
 * {code:bash}
 * wheels docker stop --local
 * wheels docker stop --local --removeContainer
 * wheels docker stop --remote
 * wheels docker stop --remote --servers=1,3
 * wheels docker stop --remote --removeContainer
 * {code}
 */
component extends="DockerCommand" {
    
    property name="detailOutput" inject="DetailOutputService@wheels-cli";

    /**
     * @local Stop containers on local machine
     * @remote Stop containers on remote server(s)
     * @servers Comma-separated list of server numbers to stop (e.g., "1,3,5") - for remote only
     * @removeContainer Also remove the container after stopping (default: false)
     */
    function run(
        boolean local=false,
        boolean remote=false,
        string servers="",
        boolean removeContainer=false
    ) {
        //ensure we are in a Wheels app
        requireWheelsApp(getCWD());
        // Reconstruct arguments for handling --key=value style
        arguments = reconstructArgs(arguments);

        // set local as default if neither specified
        if (!arguments.local && !arguments.remote) {
            arguments.local=true;
        }
        
        if (arguments.local && arguments.remote) {
            error("Cannot specify both --local and --remote. Please choose one.");
        }
        
        // Route to appropriate stop method
        if (arguments.local) {
            stopLocal(arguments.removeContainer);
        } else {
            stopRemote(arguments.servers, arguments.removeContainer);
        }
    }
    
    // =============================================================================
    // LOCAL STOP
    // =============================================================================
    
    private function stopLocal(boolean removeContainer) {
        detailOutput.header("Wheels Docker Local Stop");

        // Check if Docker is installed locally
        if (!isDockerInstalled()) {
            error("Docker is not installed or not accessible. Please ensure Docker Desktop or Docker Engine is running.");
        }

        // Check for docker-compose file
        local.useCompose = hasDockerComposeFile();
        
        if (local.useCompose) {
            detailOutput.statusSuccess("Found docker-compose file, will stop docker-compose services"); 
            detailOutput.statusInfo("Stopping services with docker-compose...");
            
            try {
                runLocalCommand(["docker", "compose", "down"]);
                detailOutput.success("Docker Compose services stopped successfully!");
            } catch (any e) {
                detailOutput.statusFailed("Services might not be running");
            }
            
        } else {
            detailOutput.statusInfo("No docker-compose file found, will use standard docker commands");
            
            // Get project name for container naming
            local.containerName = getProjectName();
            
            detailOutput.statusInfo("Stopping Docker container '" & local.containerName & "'...");
            
            try {
                 runLocalCommand(["docker", "stop", local.containerName]);
                detailOutput.statusSuccess("Container stopped successfully");
                
                if (arguments.removeContainer) {
                    detailOutput.statusInfo("Removing Docker container '" & local.containerName & "'...");
                    runLocalCommand(["docker", "rm", local.containerName]);
                    detailOutput.statusSuccess("Container removed successfully").toConsole();
                }
                
                detailOutput.statusSuccess("Container operations completed!");
            } catch (any e) {
                detailOutput.statusFailed("Container might not be running: " & e.message);
            }
        }
        
        detailOutput.line();
        detailOutput.output("Check container status with: docker ps -a");
        detailOutput.line();
    }
    
    // =============================================================================
    // REMOTE STOP
    // =============================================================================
    
    private function stopRemote(string serverNumbers, boolean removeContainer) {
        // Check for deploy-servers file (text or json) in current directory
        var textConfigPath = fileSystemUtil.resolvePath("deploy-servers.txt");
        var jsonConfigPath = fileSystemUtil.resolvePath("deploy-servers.json");
        var ymlConfigPath = fileSystemUtil.resolvePath("config/deploy.yml");
        var allServers = [];
        var serversToStop = [];
        var projectName = getProjectName();

        if (len(trim(arguments.serverNumbers)) == 0 && fileExists(ymlConfigPath)) {
            var deployConfig = getDeployConfig();
            if (arrayLen(deployConfig.servers)) {
                detailOutput.identical("Found config/deploy.yml, loading server configuration");
                allServers = deployConfig.servers;
                
                // Add defaults
                for (var s in allServers) {
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
                serversToStop = allServers;
            }
        } 
        
        if (arrayLen(serversToStop) == 0) {
            if (fileExists(textConfigPath)) {
                detailOutput.identical("Found deploy-servers.txt, loading server configuration");
                allServers = loadServersFromTextFile("deploy-servers.txt");
                serversToStop = filterServers(allServers, arguments.serverNumbers);
            } else if (fileExists(jsonConfigPath)) {
                detailOutput.identical("Found deploy-servers.json, loading server configuration");
                allServers = loadServersFromConfig("deploy-servers.json");
                serversToStop = filterServers(allServers, arguments.serverNumbers);
            } else {
                error("No server configuration found. Use 'wheels docker init' or create deploy-servers.txt.");
            }
        }

        if (arrayLen(serversToStop) == 0) {
            error("No servers configured to stop containers");
        }

        detailOutput.line();
        detailOutput.statusInfo("Stopping containers on #arrayLen(serversToStop)# server(s)...");

        // Stop containers on all selected servers
        stopContainersOnServers(serversToStop, arguments.removeContainer);

        detailOutput.line();
        detailOutput.statusSuccess("Container stop operations completed!");
    }

    /**
     * Filter servers based on comma-separated list of server numbers
     */
    private function filterServers(required array allServers, string serverNumbers="") {
        // If no specific servers requested, return all
        if (!len(trim(arguments.serverNumbers))) {
            return arguments.allServers;
        }

        var selectedServers = [];
        var numbers = listToArray(arguments.serverNumbers);

        for (var numStr in numbers) {
            var num = val(trim(numStr));
            if (num > 0 && num <= arrayLen(arguments.allServers)) {
                arrayAppend(selectedServers, arguments.allServers[num]);
            } else {
                detailOutput.skip("Skipping invalid server number: " & numStr);
            }
        }

        if (arrayLen(selectedServers) == 0) {
            detailOutput.output("No valid servers selected, using all servers");
            return arguments.allServers;
        }

        detailOutput.statusSuccess("Selected #arrayLen(selectedServers)# of #arrayLen(arguments.allServers)# server(s)");
        return selectedServers;
    }

    /**
     * Stop containers on multiple servers sequentially
     */
    private function stopContainersOnServers(required array servers, required boolean removeContainer) {
        var successCount = 0;
        var failureCount = 0;
        var serverConfig = {};

        for (var i = 1; i <= arrayLen(servers); i++) {
            serverConfig = servers[i];
            detailOutput.header("Stopping container on server #i# of #arrayLen(servers)#: #serverConfig.host#");
           
            try {
                stopContainerOnServer(serverConfig, arguments.removeContainer);
                successCount++;
                detailOutput.statusSuccess("Container on #serverConfig.host# stopped successfully");
            } catch (any e) {
                failureCount++;
                detailOutput.statusFailed("Failed to stop container on #serverConfig.host#: #e.message#");
            }
        }

        detailOutput.line();
        detailOutput.statusInfo("Stop Operations Summary:");
        detailOutput.statusSuccess("   Successful: #successCount#");
        if (failureCount > 0) {   
            detailOutput.statusFailed("   Failed: #failureCount#");
        }
    }

    /**
     * Stop container on a single server
     */
    private function stopContainerOnServer(required struct serverConfig, required boolean removeContainer) {
        var local = {};
        local.host = arguments.serverConfig.host;
        local.user = arguments.serverConfig.user;
        local.port = structKeyExists(arguments.serverConfig, "port") ? arguments.serverConfig.port : 22;
        local.projectName = getProjectName();
        local.imageName = structKeyExists(arguments.serverConfig, "imageName") ? arguments.serverConfig.imageName : local.projectName;
        local.remoteDir = structKeyExists(arguments.serverConfig, "remoteDir") ? arguments.serverConfig.remoteDir : "/home/#local.user#/#local.projectName#";

        // Check SSH connection
        if (!testSSHConnection(local.host, local.user, local.port)) {
            error("SSH connection failed to #local.host#. Check credentials and access.");
        }
        detailOutput.statusSuccess("SSH connection successful");

        // Check if docker-compose is being used on the remote server
        local.checkComposeCmd = "test -f " & local.remoteDir & "/docker-compose.yml || test -f " & local.remoteDir & "/docker-compose.yaml";
        local.useCompose = false;

        try {
            executeRemoteCommand(local.host, local.user, local.port, local.checkComposeCmd);
            local.useCompose = true;
            detailOutput.statusInfo("Found docker-compose file on remote server");
        } catch (any e) {
            detailOutput.statusInfo("No docker-compose file found, using standard docker commands");
        }

        if (local.useCompose) {
            // Stop using docker-compose
            detailOutput.statusInfo("Stopping services with docker-compose...").toConsole();
            
            // Check if user can run docker without sudo
            local.stopCmd = "cd " & local.remoteDir & " && ";
            local.stopCmd &= "if groups | grep -q docker && [ -w /var/run/docker.sock ]; then ";
            local.stopCmd &= "docker compose down; ";
            local.stopCmd &= "else sudo docker compose down; fi";

            try {
                executeRemoteCommand(local.host, local.user, local.port, local.stopCmd);
                detailOutput.statusSuccess("Docker Compose services stopped");
            } catch (any e) {
                detailOutput.statusWarning("Services might not be running: " & e.message);
            }
        } else {
            // Stop the container using standard docker commands
            detailOutput.statusInfo("Stopping Docker container '" & local.imageName & "'...");
            
            // Check if user can run docker without sudo
            local.stopCmd = "if groups | grep -q docker && [ -w /var/run/docker.sock ]; then ";
            local.stopCmd &= "docker stop " & local.imageName & "; ";
            local.stopCmd &= "else sudo docker stop " & local.imageName & "; fi";

            try {
                executeRemoteCommand(local.host, local.user, local.port, local.stopCmd);
                detailOutput.statusSuccess("Container stopped");
            } catch (any e) {
                detailOutput.statusWarning("Container might not be running: " & e.message);
            }

            // Remove container if requested
            if (arguments.removeContainer) {
                
                detailOutput.statusInfo("Removing Docker container '" & local.imageName & "'...");

                // Check if user can run docker without sudo
                local.removeCmd = "if groups | grep -q docker && [ -w /var/run/docker.sock ]; then ";
                local.removeCmd &= "docker rm " & local.imageName & "; ";
                local.removeCmd &= "else sudo docker rm " & local.imageName & "; fi";

                try {
                    executeRemoteCommand(local.host, local.user, local.port, local.removeCmd);
                    detailOutput.statusSuccess("Container removed");
                } catch (any e) {
                    detailOutput.statusWarning("Container might not exist: " & e.message);
                }
            }
        }

        detailOutput.success("Operations on #local.host# completed!");
    }

}