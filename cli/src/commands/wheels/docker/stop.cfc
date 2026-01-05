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
        print.line();
        print.boldMagentaLine("Wheels Docker Local Stop");
        print.line();

        // Check if Docker is installed locally
        if (!isDockerInstalled()) {
            error("Docker is not installed or not accessible. Please ensure Docker Desktop or Docker Engine is running.");
        }

        // Check for docker-compose file
        local.useCompose = hasDockerComposeFile();
        
        if (local.useCompose) {
            print.greenLine("Found docker-compose file, will stop docker-compose services").toConsole();
            
            print.yellowLine("Stopping services with docker-compose...").toConsole();
            
            try {
                runLocalCommand(["docker", "compose", "down"]);
                print.boldGreenLine("Docker Compose services stopped successfully!").toConsole();
            } catch (any e) {
                print.yellowLine("Services might not be running").toConsole();
            }
            
        } else {
            print.greenLine("No docker-compose file found, will use standard docker commands").toConsole();
            
            // Get project name for container naming
            local.containerName = getProjectName();
            
            print.yellowLine("Stopping Docker container '" & local.containerName & "'...").toConsole();
            
            try {
                runLocalCommand(["docker", "stop", local.containerName]);
                print.greenLine("Container stopped successfully").toConsole();
                
                if (arguments.removeContainer) {
                    print.yellowLine("Removing Docker container '" & local.containerName & "'...").toConsole();
                    runLocalCommand(["docker", "rm", local.containerName]);
                    print.greenLine("Container removed successfully").toConsole();
                }
                
                print.boldGreenLine("Container operations completed!").toConsole();
            } catch (any e) {
                print.yellowLine("Container might not be running: " & e.message).toConsole();
            }
        }
        
        print.line();
        print.yellowLine("Check container status with: docker ps -a").toConsole();
        print.line();
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
                print.cyanLine("Found config/deploy.yml, loading server configuration").toConsole();
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
                print.cyanLine("Found deploy-servers.txt, loading server configuration").toConsole();
                allServers = loadServersFromTextFile("deploy-servers.txt");
                serversToStop = filterServers(allServers, arguments.serverNumbers);
            } else if (fileExists(jsonConfigPath)) {
                print.cyanLine("Found deploy-servers.json, loading server configuration").toConsole();
                allServers = loadServersFromConfig("deploy-servers.json");
                serversToStop = filterServers(allServers, arguments.serverNumbers);
            } else {
                error("No server configuration found. Use 'wheels docker init' or create deploy-servers.txt.");
            }
        }

        if (arrayLen(serversToStop) == 0) {
            error("No servers configured to stop containers");
        }

        print.line().boldCyanLine("Stopping containers on #arrayLen(serversToStop)# server(s)...").toConsole();

        // Stop containers on all selected servers
        stopContainersOnServers(serversToStop, arguments.removeContainer);

        print.line().boldGreenLine("Container stop operations completed!").toConsole();
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
                print.yellowLine("Skipping invalid server number: " & numStr).toConsole();
            }
        }

        if (arrayLen(selectedServers) == 0) {
            print.yellowLine("No valid servers selected, using all servers").toConsole();
            return arguments.allServers;
        }

        print.greenLine("Selected #arrayLen(selectedServers)# of #arrayLen(arguments.allServers)# server(s)").toConsole();
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
            print.line().boldCyanLine("---------------------------------------").toConsole();
            print.boldCyanLine("Stopping container on server #i# of #arrayLen(servers)#: #serverConfig.host#").toConsole();
            print.line().boldCyanLine("---------------------------------------").toConsole();

            try {
                stopContainerOnServer(serverConfig, arguments.removeContainer);
                successCount++;
                print.greenLine("Container on #serverConfig.host# stopped successfully").toConsole();
            } catch (any e) {
                failureCount++;
                print.redLine("Failed to stop container on #serverConfig.host#: #e.message#").toConsole();
            }
        }

        print.line().toConsole();
        print.boldCyanLine("Stop Operations Summary:").toConsole();
        print.greenLine("   Successful: #successCount#").toConsole();
        if (failureCount > 0) {
            print.redLine("   Failed: #failureCount#").toConsole();
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
        print.greenLine("SSH connection successful").toConsole();

        // Check if docker-compose is being used on the remote server
        local.checkComposeCmd = "test -f " & local.remoteDir & "/docker-compose.yml || test -f " & local.remoteDir & "/docker-compose.yaml";
        local.useCompose = false;

        try {
            executeRemoteCommand(local.host, local.user, local.port, local.checkComposeCmd);
            local.useCompose = true;
            print.greenLine("Found docker-compose file on remote server").toConsole();
        } catch (any e) {
            print.yellowLine("No docker-compose file found, using standard docker commands").toConsole();
        }

        if (local.useCompose) {
            // Stop using docker-compose
            print.yellowLine("Stopping services with docker-compose...").toConsole();
            
            // Check if user can run docker without sudo
            local.stopCmd = "cd " & local.remoteDir & " && ";
            local.stopCmd &= "if groups | grep -q docker && [ -w /var/run/docker.sock ]; then ";
            local.stopCmd &= "docker compose down; ";
            local.stopCmd &= "else sudo docker compose down; fi";

            try {
                executeRemoteCommand(local.host, local.user, local.port, local.stopCmd);
                print.greenLine("Docker Compose services stopped").toConsole();
            } catch (any e) {
                print.yellowLine("Services might not be running: " & e.message).toConsole();
            }
        } else {
            // Stop the container using standard docker commands
            print.yellowLine("Stopping Docker container '" & local.imageName & "'...").toConsole();
            
            // Check if user can run docker without sudo
            local.stopCmd = "if groups | grep -q docker && [ -w /var/run/docker.sock ]; then ";
            local.stopCmd &= "docker stop " & local.imageName & "; ";
            local.stopCmd &= "else sudo docker stop " & local.imageName & "; fi";

            try {
                executeRemoteCommand(local.host, local.user, local.port, local.stopCmd);
                print.greenLine("Container stopped").toConsole();
            } catch (any e) {
                print.yellowLine("Container might not be running: " & e.message).toConsole();
            }

            // Remove container if requested
            if (arguments.removeContainer) {
                print.yellowLine("Removing Docker container '" & local.imageName & "'...").toConsole();
                
                // Check if user can run docker without sudo
                local.removeCmd = "if groups | grep -q docker && [ -w /var/run/docker.sock ]; then ";
                local.removeCmd &= "docker rm " & local.imageName & "; ";
                local.removeCmd &= "else sudo docker rm " & local.imageName & "; fi";

                try {
                    executeRemoteCommand(local.host, local.user, local.port, local.removeCmd);
                    print.greenLine("Container removed").toConsole();
                } catch (any e) {
                    print.yellowLine("Container might not exist: " & e.message).toConsole();
                }
            }
        }

        print.boldGreenLine("Operations on #local.host# completed!").toConsole();
    }


}