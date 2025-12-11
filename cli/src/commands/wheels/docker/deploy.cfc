/**
 * Unified Docker deployment command for Wheels apps
 *
 * {code:bash}
 * wheels docker deploy --local
 * wheels docker deploy --local --environment=staging
 * wheels docker deploy --remote
 * wheels docker deploy --remote --servers=deploy-servers.txt
 * wheels docker deploy --remote --blue-green
 * {code}
 */
component extends="DockerCommand" {
    
    /**
     * @local Deploy to local Docker environment
     * @remote Deploy to remote server(s)
     * @environment Deployment environment (production, staging) - for local deployment
     * @db Database to use (h2, mysql, postgres, mssql) - for local deployment
     * @cfengine ColdFusion engine to use (lucee, adobe) - for local deployment
     * @optimize Enable production optimizations - for local deployment
     * @servers Server configuration file (deploy-servers.txt or deploy-servers.json) - for remote deployment
     * @skipDockerCheck Skip Docker installation check on remote servers
     * @blueGreen Enable Blue/Green deployment strategy (zero downtime) - for remote deployment
     */
    function run(
        boolean local=false,
        boolean remote=false,
        string environment="production",
        string db="mysql",
        string cfengine="lucee",
        boolean optimize=true,
        string servers="",
        boolean skipDockerCheck=false,
        boolean blueGreen=false
    ) {
        arguments = reconstructArgs(arguments);
        
        // Validate that exactly one deployment type is specified
        if (!arguments.local && !arguments.remote) {
            error("Please specify deployment type: --local or --remote");
        }
        
        if (arguments.local && arguments.remote) {
            error("Cannot specify both --local and --remote. Please choose one.");
        }
        
        // Route to appropriate deployment method
        if (arguments.local) {
            deployLocal(arguments.environment, arguments.db, arguments.cfengine, arguments.optimize);
        } else {
            deployRemote(arguments.servers, arguments.skipDockerCheck, arguments.blueGreen);
        }
    }
    
    // =============================================================================
    // LOCAL DEPLOYMENT
    // =============================================================================
    
    private function deployLocal(
        string environment,
        string db,
        string cfengine,
        boolean optimize
    ) {
        // Welcome message
        print.line();
        print.boldMagentaLine("Wheels Docker Local Deployment");
        print.line();

        // Check for docker-compose file
        local.useCompose = hasDockerComposeFile();
        
        if (local.useCompose) {
            print.greenLine("Found docker-compose file, will use docker-compose").toConsole();
            
            // Check if Docker is installed locally
            if (!isDockerInstalled()) {
                error("Docker is not installed or not accessible. Please ensure Docker Desktop or Docker Engine is running.");
            }
            
            print.yellowLine("Starting services with docker-compose...").toConsole();
            
            try {
                // Stop existing containers
                runLocalCommand(["docker", "compose", "down"]);
            } catch (any e) {
                print.yellowLine("No existing containers to stop").toConsole();
            }
            
            // Start containers with build
            print.yellowLine("Building and starting containers...").toConsole();
            runLocalCommand(["docker", "compose", "up", "-d", "--build"]);
            
            print.line();
            print.boldGreenLine("Docker Compose services started successfully!").toConsole();
            print.line();
            print.yellowLine("Check container status with: docker compose ps").toConsole();
            print.yellowLine("View logs with: docker compose logs -f").toConsole();
            print.line();
            
        } else {
            // Check for Dockerfile
            local.dockerfilePath = getCWD() & "/Dockerfile";
            if (!fileExists(local.dockerfilePath)) {
                error("No Dockerfile or docker-compose.yml found in current directory");
            }
            
            print.greenLine("Found Dockerfile, will use standard docker commands").toConsole();
            
            // Check if Docker is installed locally
            if (!isDockerInstalled()) {
                error("Docker is not installed or not accessible. Please ensure Docker Desktop or Docker Engine is running.");
            }
            
            // Extract port from Dockerfile
            local.exposedPort = getDockerExposedPort();
            if (!len(local.exposedPort)) {
                print.yellowLine("No EXPOSE directive found in Dockerfile, using default port 8080").toConsole();
                local.exposedPort = "8080";
            } else {
                print.greenLine("Found EXPOSE port: " & local.exposedPort).toConsole();
            }
            
            // Get project name for image/container naming
            local.imageName = getProjectName();
            
            print.yellowLine("Building Docker image...").toConsole();
            runLocalCommand(["docker", "build", "-t", local.imageName, "."]);
            
            print.yellowLine("Starting container...").toConsole();
            
            try {
                // Stop and remove existing container
                runLocalCommand(["docker", "stop", local.imageName]);
                runLocalCommand(["docker", "rm", local.imageName]);
            } catch (any e) {
                print.yellowLine("No existing container to remove").toConsole();
            }
            
            // Run new container
            runLocalCommand(["docker", "run", "-d", "--name", local.imageName, "-p", local.exposedPort & ":" & local.exposedPort, local.imageName]);
            
            print.line();
            print.boldGreenLine("Container started successfully!").toConsole();
            print.line();
            print.yellowLine("Container name: " & local.imageName).toConsole();
            print.yellowLine("Access your application at: http://localhost:" & local.exposedPort).toConsole();
            print.line();
            print.yellowLine("Check container status with: docker ps").toConsole();
            print.yellowLine("View logs with: docker logs -f " & local.imageName).toConsole();
            print.line();
        }
    }
    
    /**
     * Check if Docker is installed locally
     */
    private function isDockerInstalled() {
        try {
            var result = runLocalCommand(["docker", "--version"], false);
            return (result.exitCode eq 0);
        } catch (any e) {
            return false;
        }
    }
    
    // =============================================================================
    // REMOTE DEPLOYMENT
    // =============================================================================
    
    private function deployRemote(string serversFile, boolean skipDockerCheck, boolean blueGreen) {
        // Check for deploy-servers file (text or json) in current directory
        var textConfigPath = fileSystemUtil.resolvePath("deploy-servers.txt");
        var jsonConfigPath = fileSystemUtil.resolvePath("deploy-servers.json");
        var servers = [];
        
        // If specific servers file is provided, use that
        if (len(trim(arguments.serversFile))) {
            var customPath = fileSystemUtil.resolvePath(arguments.serversFile);
            if (!fileExists(customPath)) {
                error("Server configuration file not found: #arguments.serversFile#");
            }
            
            if (right(arguments.serversFile, 5) == ".json") {
                servers = loadServersFromConfig(arguments.serversFile);
            } else {
                servers = loadServersFromTextFile(arguments.serversFile);
            }
        } 
        // Otherwise, look for default files
        else if (fileExists(textConfigPath)) {
            print.cyanLine("Found deploy-servers.txt, loading server configuration").toConsole();
            servers = loadServersFromTextFile("deploy-servers.txt");
        } else if (fileExists(jsonConfigPath)) {
            print.cyanLine("Found deploy-servers.json, loading server configuration").toConsole();
            servers = loadServersFromConfig("deploy-servers.json");
        } else {
            error("No server configuration found. Create deploy-servers.txt or deploy-servers.json in your project root." & chr(10) & chr(10) &
                  "Example deploy-servers.txt:" & chr(10) &
                  "192.168.1.100 ubuntu 22" & chr(10) &
                  "production.example.com deploy" & chr(10) & chr(10) &
                  "Or see examples/deploy-servers.example.txt for more details.");
        }

        if (arrayLen(servers) == 0) {
            error("No servers configured for deployment");
        }

        print.line().boldCyanLine("Starting remote deployment to #arrayLen(servers)# server(s)...").toConsole();
        if (arguments.blueGreen) {
            print.boldMagentaLine("Strategy: Blue/Green Deployment (Zero Downtime)").toConsole();
        }

        // Deploy to all servers sequentially
        deployToMultipleServersSequential(servers, arguments.skipDockerCheck, arguments.blueGreen);

        print.line().boldGreenLine("Deployment to all servers completed!").toConsole();
    }

    /**
     * Deploy to multiple servers sequentially
     */
    private function deployToMultipleServersSequential(required array servers, boolean skipDockerCheck, boolean blueGreen) {
        var successCount = 0;
        var failureCount = 0;
        var serverConfig = {};

        for (var i = 1; i <= arrayLen(servers); i++) {
            serverConfig = servers[i];
            print.line().boldCyanLine("---------------------------------------").toConsole();
            print.boldCyanLine("Deploying to server #i# of #arrayLen(servers)#: #serverConfig.host#").toConsole();
            print.line().boldCyanLine("---------------------------------------").toConsole();

            try {
                if (arguments.blueGreen) {
                    deployToSingleServerBlueGreen(serverConfig, arguments.skipDockerCheck);
                } else {
                    deployToSingleServer(serverConfig, arguments.skipDockerCheck);
                }
                successCount++;
                print.greenLine("Server #serverConfig.host# deployed successfully").toConsole();
            } catch (any e) {
                failureCount++;
                print.redLine("Failed to deploy to #serverConfig.host#: #e.message#").toConsole();
            }
        }

        print.line().toConsole();
        print.boldCyanLine("Deployment Summary:").toConsole();
        print.greenLine("   Successful: #successCount#").toConsole();
        if (failureCount > 0) {
            print.redLine("   Failed: #failureCount#").toConsole();
        }
    }

    /**
     * Deploy to a single server (Standard Strategy)
     */
    private function deployToSingleServer(required struct serverConfig, boolean skipDockerCheck) {
        var local = {};
        local.host = arguments.serverConfig.host;
        local.user = arguments.serverConfig.user;
        local.port = structKeyExists(arguments.serverConfig, "port") ? arguments.serverConfig.port : 22;
        local.remoteDir = structKeyExists(arguments.serverConfig, "remoteDir") ? arguments.serverConfig.remoteDir : "/home/#local.user#/#local.user#-app";
        local.imageName = structKeyExists(arguments.serverConfig, "imageName") ? arguments.serverConfig.imageName : "#local.user#-app";

        // Step 1: Check SSH connection
        if (!testSSHConnection(local.host, local.user, local.port)) {
            error("SSH connection failed to #local.host#. Check credentials and access.");
        }
        print.greenLine("SSH connection successful").toConsole();

        // Step 1.5: Check and install Docker if needed (unless skipped)
        if (!arguments.skipDockerCheck) {
            ensureDockerInstalled(local.host, local.user, local.port);
        } else {
            print.yellowLine("Skipping Docker installation check (--skipDockerCheck flag is set)").toConsole();
        }

        // Step 2: Create remote directory
        print.yellowLine("Creating remote directory...").toConsole();
        executeRemoteCommand(local.host, local.user, local.port, "mkdir -p " & local.remoteDir);

        // Step 3: Check for docker-compose file
        local.useCompose = hasDockerComposeFile();
        if (local.useCompose) {
            print.greenLine("Found docker-compose file, will use docker-compose").toConsole();
        } else {
            // Extract port from Dockerfile for standard docker run
            local.exposedPort = getDockerExposedPort();
            if (!len(local.exposedPort)) {
                print.yellowLine(" No EXPOSE directive found in Dockerfile, using default port 8080").toConsole();
                local.exposedPort = "8080";
            } else {
                print.greenLine("Found EXPOSE port: " & local.exposedPort).toConsole();
            }
        }

        // Step 4: Tar and upload project
        local.timestamp = dateFormat(now(), "yyyymmdd") & timeFormat(now(), "HHmmss");
        local.tarFile = getTempFile(getTempDirectory(), "deploysrc_") & ".tar.gz";
        local.remoteTar = "/tmp/deploysrc_" & local.timestamp & ".tar.gz";

        print.yellowLine("Creating source tarball...").toConsole();
        runLocalCommand(["tar", "-czf", local.tarFile, "-C", getCWD(), "."]);

        print.yellowLine(" Uploading to remote server...").toConsole();
        var scpCmd = ["scp", "-P", local.port];
        scpCmd.addAll(getSSHOptions());
        scpCmd.addAll([local.tarFile, local.user & "@" & local.host & ":" & local.remoteTar]);
        runLocalCommand(scpCmd);
        fileDelete(local.tarFile);

        // Step 5: Build and run on remote
        local.deployScript = "";
        local.deployScript &= chr(35) & "!/bin/bash" & chr(10);
        local.deployScript &= "set -e" & chr(10);
        local.deployScript &= "echo 'Extracting source to " & local.remoteDir & " ...'" & chr(10);
        local.deployScript &= "mkdir -p " & local.remoteDir & chr(10);
        local.deployScript &= "tar --overwrite -xzf " & local.remoteTar & " -C " & local.remoteDir & chr(10);
        local.deployScript &= "cd " & local.remoteDir & chr(10);

        if (local.useCompose) {
            // Use docker-compose with proper permissions
            local.deployScript &= "echo 'Starting services with docker-compose...'" & chr(10);
            
            // Check if user is in docker group and can run docker without sudo
            local.deployScript &= "if groups | grep -q docker && [ -w /var/run/docker.sock ]; then" & chr(10);
            local.deployScript &= "  ## User has docker access, run without sudo" & chr(10);
            local.deployScript &= "  docker compose down || true" & chr(10);
            local.deployScript &= "  docker compose up -d --build" & chr(10);
            local.deployScript &= "else" & chr(10);
            local.deployScript &= "  ## User needs sudo for docker" & chr(10);
            local.deployScript &= "  sudo docker compose down || true" & chr(10);
            local.deployScript &= "  sudo docker compose up -d --build" & chr(10);
            local.deployScript &= "fi" & chr(10);
            local.deployScript &= "echo 'Docker Compose services started!'" & chr(10);
        } else {
            // Use standard docker commands with proper permissions
            local.deployScript &= "echo 'Building Docker image...'" & chr(10);
            
            // Check if user is in docker group and can run docker without sudo
            local.deployScript &= "if groups | grep -q docker && [ -w /var/run/docker.sock ]; then" & chr(10);
            local.deployScript &= "  ## User has docker access, run without sudo" & chr(10);
            local.deployScript &= "  docker build -t " & local.imageName & " ." & chr(10);
            local.deployScript &= "  echo 'Starting container...'" & chr(10);
            local.deployScript &= "  docker stop " & local.imageName & " || true" & chr(10);
            local.deployScript &= "  docker rm " & local.imageName & " || true" & chr(10);
            local.deployScript &= "  docker run -d --name " & local.imageName & " -p " & local.exposedPort & ":" & local.exposedPort & " " & local.imageName & chr(10);
            local.deployScript &= "else" & chr(10);
            local.deployScript &= "  ## User needs sudo for docker" & chr(10);
            local.deployScript &= "  sudo docker build -t " & local.imageName & " ." & chr(10);
            local.deployScript &= "  echo 'Starting container...'" & chr(10);
            local.deployScript &= "  sudo docker stop " & local.imageName & " || true" & chr(10);
            local.deployScript &= "  sudo docker rm " & local.imageName & " || true" & chr(10);
            local.deployScript &= "  sudo docker run -d --name " & local.imageName & " -p " & local.exposedPort & ":" & local.exposedPort & " " & local.imageName & chr(10);
            local.deployScript &= "fi" & chr(10);
        }

        local.deployScript &= "echo 'Deployment complete!'" & chr(10);

        // Normalize line endings
        local.deployScript = replace(local.deployScript, chr(13) & chr(10), chr(10), "all");
        local.deployScript = replace(local.deployScript, chr(13), chr(10), "all");

        local.tempFile = getTempFile(getTempDirectory(), "deploy_");
        fileWrite(local.tempFile, local.deployScript);

        print.yellowLine("Uploading deployment script...").toConsole();
        var scpScriptCmd = ["scp", "-P", local.port];
        scpScriptCmd.addAll(getSSHOptions());
        scpScriptCmd.addAll([local.tempFile, local.user & "@" & local.host & ":/tmp/deploy-simple.sh"]);
        runLocalCommand(scpScriptCmd);
        fileDelete(local.tempFile);

        print.yellowLine("Executing deployment script remotely...").toConsole();
        // Use interactive command to prevent hanging and allow Ctrl+C
        var execCmd = ["ssh", "-p", local.port];
        execCmd.addAll(getSSHOptions());
        execCmd.addAll([local.user & "@" & local.host, "chmod +x /tmp/deploy-simple.sh && bash /tmp/deploy-simple.sh"]);
        
        runInteractiveCommand(execCmd);

        print.boldGreenLine("Deployment to #local.host# completed successfully!").toConsole();
    }

    /**
     * Deploy to a single server (Blue/Green Strategy)
     */
    private function deployToSingleServerBlueGreen(required struct serverConfig, boolean skipDockerCheck) {
        var local = {};
        local.host = arguments.serverConfig.host;
        local.user = arguments.serverConfig.user;
        local.port = structKeyExists(arguments.serverConfig, "port") ? arguments.serverConfig.port : 22;
        local.remoteDir = structKeyExists(arguments.serverConfig, "remoteDir") ? arguments.serverConfig.remoteDir : "/home/#local.user#/#local.user#-app";
        local.imageName = structKeyExists(arguments.serverConfig, "imageName") ? arguments.serverConfig.imageName : "#local.user#-app";

        // Step 1: Check SSH connection
        if (!testSSHConnection(local.host, local.user, local.port)) {
            error("SSH connection failed to #local.host#. Check credentials and access.");
        }
        print.greenLine("SSH connection successful").toConsole();

        // Step 1.5: Check and install Docker if needed
        if (!arguments.skipDockerCheck) {
            ensureDockerInstalled(local.host, local.user, local.port);
        }

        // Step 2: Create remote directory
        print.yellowLine("Creating remote directory...").toConsole();
        executeRemoteCommand(local.host, local.user, local.port, "mkdir -p " & local.remoteDir);

        // Step 3: Determine Port
        local.exposedPort = getDockerExposedPort();
        if (!len(local.exposedPort)) {
            print.yellowLine(" No EXPOSE directive found in Dockerfile, using default port 8080").toConsole();
            local.exposedPort = "8080";
        } else {
            print.greenLine("Found EXPOSE port: " & local.exposedPort).toConsole();
        }

        // Step 4: Tar and upload project
        local.timestamp = dateFormat(now(), "yyyymmdd") & timeFormat(now(), "HHmmss");
        local.tarFile = getTempFile(getTempDirectory(), "deploysrc_") & ".tar.gz";
        local.remoteTar = "/tmp/deploysrc_" & local.timestamp & ".tar.gz";

        print.yellowLine("Creating source tarball...").toConsole();
        runLocalCommand(["tar", "-czf", local.tarFile, "-C", getCWD(), "."]);

        print.yellowLine(" Uploading to remote server...").toConsole();
        var scpCmd = ["scp", "-P", local.port];
        scpCmd.addAll(getSSHOptions());
        scpCmd.addAll([local.tarFile, local.user & "@" & local.host & ":" & local.remoteTar]);
        runLocalCommand(scpCmd);
        fileDelete(local.tarFile);

        // Step 5: Generate Blue/Green Deployment Script
        local.deployScript = "";
        local.deployScript &= chr(35) & "!/bin/bash" & chr(10);
        local.deployScript &= "set -e" & chr(10);
        
        // Setup variables
        local.deployScript &= "APP_NAME='" & local.imageName & "'" & chr(10);
        local.deployScript &= "APP_PORT='" & local.exposedPort & "'" & chr(10);
        local.deployScript &= "REMOTE_DIR='" & local.remoteDir & "'" & chr(10);
        local.deployScript &= "REMOTE_TAR='" & local.remoteTar & "'" & chr(10);
        local.deployScript &= "NETWORK_NAME='web'" & chr(10);
        local.deployScript &= "PROXY_NAME='nginx-proxy'" & chr(10);
        
        // Extract source
        local.deployScript &= "echo 'Extracting source to ' $REMOTE_DIR ' ...'" & chr(10);
        local.deployScript &= "mkdir -p $REMOTE_DIR" & chr(10);
        local.deployScript &= "tar --overwrite -xzf $REMOTE_TAR -C $REMOTE_DIR" & chr(10);
        local.deployScript &= "cd $REMOTE_DIR" & chr(10);
        
        // Build Image
        local.deployScript &= "echo 'Building Docker image...'" & chr(10);
        local.deployScript &= "docker build -t $APP_NAME:latest ." & chr(10);
        
        // Ensure Network Exists
        local.deployScript &= "echo 'Ensuring Docker network exists...'" & chr(10);
        local.deployScript &= "docker network create $NETWORK_NAME 2>/dev/null || true" & chr(10);
        
        // Ensure Nginx Proxy Exists
        local.deployScript &= "if [ -z ""$(docker ps -q -f name=$PROXY_NAME)"" ]; then" & chr(10);
        local.deployScript &= "    if [ -n ""$(docker ps -aq -f name=$PROXY_NAME)"" ]; then" & chr(10);
        local.deployScript &= "        echo 'Starting existing nginx-proxy...'" & chr(10);
        local.deployScript &= "        docker start $PROXY_NAME" & chr(10);
        local.deployScript &= "    else" & chr(10);
        local.deployScript &= "        echo 'Creating and starting nginx-proxy...'" & chr(10);
        // Create a simple nginx config for the proxy
        local.deployScript &= "        mkdir -p /etc/nginx/conf.d" & chr(10);
        local.deployScript &= "        docker run -d --name $PROXY_NAME --network $NETWORK_NAME -p 80:80 nginx:alpine" & chr(10);
        local.deployScript &= "    fi" & chr(10);
        local.deployScript &= "fi" & chr(10);

        // Determine Active Color
        local.deployScript &= "IS_BLUE_RUNNING=$(docker ps -q -f name=${APP_NAME}-blue)" & chr(10);
        local.deployScript &= "if [ -n ""$IS_BLUE_RUNNING"" ]; then" & chr(10);
        local.deployScript &= "    TARGET_COLOR='green'" & chr(10);
        local.deployScript &= "    CURRENT_COLOR='blue'" & chr(10);
        local.deployScript &= "else" & chr(10);
        local.deployScript &= "    TARGET_COLOR='blue'" & chr(10);
        local.deployScript &= "    CURRENT_COLOR='green'" & chr(10);
        local.deployScript &= "fi" & chr(10);
        
        local.deployScript &= "TARGET_CONTAINER=${APP_NAME}-${TARGET_COLOR}" & chr(10);
        local.deployScript &= "echo 'Current active color: ' $CURRENT_COLOR" & chr(10);
        local.deployScript &= "echo 'Deploying to: ' $TARGET_COLOR" & chr(10);
        
        // Stop Target if exists (cleanup from failed deploy or old state)
        local.deployScript &= "docker stop $TARGET_CONTAINER 2>/dev/null || true" & chr(10);
        local.deployScript &= "docker rm $TARGET_CONTAINER 2>/dev/null || true" & chr(10);
        
        // Start New Container
        local.deployScript &= "echo 'Starting ' $TARGET_CONTAINER ' ...'" & chr(10);
        local.deployScript &= "docker run -d --name $TARGET_CONTAINER --network $NETWORK_NAME --restart unless-stopped $APP_NAME:latest" & chr(10);
        
        // Wait for container to be ready (simple sleep for now, could be curl loop)
        local.deployScript &= "echo 'Waiting for container to initialize...'" & chr(10);
        local.deployScript &= "sleep 5" & chr(10);
        
        // Update Nginx Configuration
        local.deployScript &= "echo 'Updating Nginx configuration...'" & chr(10);
        local.deployScript &= "cat > nginx.conf <<EOF" & chr(10);
        local.deployScript &= "server {" & chr(10);
        local.deployScript &= "    listen 80;" & chr(10);
        local.deployScript &= "    location / {" & chr(10);
        local.deployScript &= "        proxy_pass http://$TARGET_CONTAINER:$APP_PORT;" & chr(10);
        local.deployScript &= "        proxy_set_header Host \$host;" & chr(10);
        local.deployScript &= "        proxy_set_header X-Real-IP \$remote_addr;" & chr(10);
        local.deployScript &= "    }" & chr(10);
        local.deployScript &= "}" & chr(10);
        local.deployScript &= "EOF" & chr(10);
        
        // Copy config to nginx container and reload
        local.deployScript = replace(local.deployScript, chr(13), chr(10), "all");

        local.tempFile = getTempFile(getTempDirectory(), "deploy_bg_");
        fileWrite(local.tempFile, local.deployScript);

        print.yellowLine("Uploading Blue/Green deployment script...").toConsole();
        var scpScriptCmd = ["scp", "-P", local.port];
        scpScriptCmd.addAll(getSSHOptions());
        scpScriptCmd.addAll([local.tempFile, local.user & "@" & local.host & ":/tmp/deploy-bluegreen.sh"]);
        runLocalCommand(scpScriptCmd);
        fileDelete(local.tempFile);

        print.yellowLine("Executing Blue/Green deployment script remotely...").toConsole();
        // Use interactive command to prevent hanging and allow Ctrl+C
        var execCmd = ["ssh", "-p", local.port];
        execCmd.addAll(getSSHOptions());
        execCmd.addAll([local.user & "@" & local.host, "chmod +x /tmp/deploy-bluegreen.sh && bash /tmp/deploy-bluegreen.sh"]);
        
        runInteractiveCommand(execCmd);

        print.boldGreenLine("Blue/Green Deployment to #local.host# completed successfully!").toConsole();
    }

    // =============================================================================
    // HELPER FUNCTIONS
    // =============================================================================

    /**
     * Check if Docker is installed on remote server and install if needed
     */
    private function ensureDockerInstalled(string host, string user, numeric port) {
        var local = {};
        
        print.yellowLine("Checking Docker installation on remote server...").toConsole();
        
        // Check if Docker is installed
        var checkCmd = ["ssh", "-p", arguments.port];
        checkCmd.addAll(getSSHOptions());
        checkCmd.addAll([arguments.user & "@" & arguments.host, "command -v docker"]);
        
        local.checkResult = runLocalCommand(checkCmd);
        
        if (local.checkResult.exitCode eq 0) {
            print.greenLine("Docker is already installed").toConsole();
            
            // Get Docker version
            var versionCmd = ["ssh", "-p", arguments.port];
            versionCmd.addAll(getSSHOptions());
            versionCmd.addAll([arguments.user & "@" & arguments.host, "docker --version"]);
            
            local.versionResult = runLocalCommand(versionCmd);
            
            if (local.versionResult.exitCode eq 0) {
                print.cyanLine("Docker version: " & trim(local.versionResult.output)).toConsole();
            }
            
            // Check if docker compose is available
            checkDockerCompose(arguments.host, arguments.user, arguments.port);
            
            return true;
        }
        
        print.yellowLine("Docker is not installed. Attempting to install Docker...").toConsole();
        
        // Check if user has passwordless sudo access
        print.yellowLine("Checking sudo access...").toConsole();
        var sudoCheckCmd = ["ssh", "-p", arguments.port];
        sudoCheckCmd.addAll(getSSHOptions());
        sudoCheckCmd.addAll([arguments.user & "@" & arguments.host, "sudo -n true 2>&1"]);
        
        local.sudoCheckResult = runLocalCommand(sudoCheckCmd);
        
        if (local.sudoCheckResult.exitCode neq 0) {
            print.line().toConsole();
            print.boldRedLine("ERROR: User '#arguments.user#' does not have passwordless sudo access on #arguments.host#!").toConsole();
            print.line().toConsole();
            print.yellowLine("To enable passwordless sudo for Docker installation, follow these steps:").toConsole();
            print.line().toConsole();
            print.cyanLine("  1. SSH into the server:").toConsole();
            print.boldWhiteLine("     ssh " & arguments.user & "@" & arguments.host & (arguments.port neq 22 ? " -p " & arguments.port : "")).toConsole();
            print.line().toConsole();
            print.cyanLine("  2. Edit the sudoers file:").toConsole();
            print.boldWhiteLine("     sudo visudo").toConsole();
            print.line().toConsole();
            print.cyanLine("  3. Add this line at the end of the file:").toConsole();
            print.boldWhiteLine("     " & arguments.user & " ALL=(ALL) NOPASSWD:ALL").toConsole();
            print.line().toConsole();
            print.cyanLine("  4. Save and exit:").toConsole();
            print.line("     - Press Ctrl+X").toConsole();
            print.line("     - Press Y to confirm").toConsole();
            print.line("     - Press Enter to save").toConsole();
            print.line().toConsole();
            print.yellowLine("OR, manually install Docker on the remote server:").toConsole();
            print.line().toConsole();
            print.cyanLine("  For Ubuntu/Debian:").toConsole();
            print.line("    curl -fsSL https://get.docker.com -o get-docker.sh").toConsole();
            print.line("    sudo sh get-docker.sh").toConsole();
            print.line("    sudo usermod -aG docker " & arguments.user).toConsole();
            print.line("    newgrp docker").toConsole();
            print.line().toConsole();
            print.cyanLine("  For CentOS/RHEL:").toConsole();
            print.line("    curl -fsSL https://get.docker.com -o get-docker.sh").toConsole();
            print.line("    sudo sh get-docker.sh").toConsole();
            print.line("    sudo usermod -aG docker " & arguments.user).toConsole();
            print.line("    newgrp docker").toConsole();
            print.line().toConsole();
            print.boldYellowLine("After configuring passwordless sudo or installing Docker, run the deployment again.").toConsole();
            print.line().toConsole();
            
            error("Cannot install Docker: User '" & arguments.user & "' requires passwordless sudo access on " & arguments.host);
        }
        
        print.greenLine("User has sudo access").toConsole();
        
        // Detect OS type
        var osCmd = ["ssh", "-p", arguments.port];
        osCmd.addAll(getSSHOptions());
        osCmd.addAll([arguments.user & "@" & arguments.host, "cat /etc/os-release"]);
        
        local.osResult = runLocalCommand(osCmd);
        
        if (local.osResult.exitCode neq 0) {
            error("Failed to detect OS type on remote server");
        }
        
        // Determine installation script based on OS
        local.installScript = "";
        
        if (findNoCase("ubuntu", local.osResult.output) || findNoCase("debian", local.osResult.output)) {
            local.installScript = getDockerInstallScriptDebian();
            print.cyanLine("Detected Debian/Ubuntu system").toConsole();
        } else if (findNoCase("centos", local.osResult.output) || findNoCase("rhel", local.osResult.output) || findNoCase("fedora", local.osResult.output)) {
            local.installScript = getDockerInstallScriptRHEL();
            print.cyanLine("Detected RHEL/CentOS/Fedora system").toConsole();
        } else {
            error("Unsupported OS. Docker installation is only automated for Ubuntu/Debian and RHEL/CentOS/Fedora systems.");
        }
        
        // Create temp file with install script
        local.tempFile = getTempFile(getTempDirectory(), "docker_install_");
        
        // Normalize line endings to Unix format (LF only)
        local.installScript = replace(local.installScript, chr(13) & chr(10), chr(10), "all");
        local.installScript = replace(local.installScript, chr(13), chr(10), "all");
        
        fileWrite(local.tempFile, local.installScript);
        
        // Upload install script
        print.yellowLine("Uploading Docker installation script...").toConsole();
        var scpInstallCmd = ["scp", "-P", arguments.port];
        scpInstallCmd.addAll(getSSHOptions());
        scpInstallCmd.addAll([local.tempFile, arguments.user & "@" & arguments.host & ":/tmp/install-docker.sh"]);
        runLocalCommand(scpInstallCmd);
        fileDelete(local.tempFile);
        
        // Execute install script
        print.yellowLine("Installing Docker (this may take a few minutes)...").toConsole();
        var installCmd = ["ssh", "-p", arguments.port];
        installCmd.addAll(getSSHOptions());
        // Increase timeout for installation
        installCmd.addAll(["-o", "ServerAliveInterval=30", "-o", "ServerAliveCountMax=10"]);
        installCmd.addAll([arguments.user & "@" & arguments.host, "sudo bash /tmp/install-docker.sh"]);
        
        local.installResult = runLocalCommand(installCmd);
        
        if (local.installResult.exitCode neq 0) {
            error("Failed to install Docker on remote server");
        }
        
        print.boldGreenLine("Docker installed successfully!").toConsole();
        
        // Verify installation
        var verifyCmd = ["ssh", "-p", arguments.port];
        verifyCmd.addAll(getSSHOptions());
        verifyCmd.addAll([arguments.user & "@" & arguments.host, "docker --version"]);
        
        local.verifyResult = runLocalCommand(verifyCmd);
        
        if (local.verifyResult.exitCode eq 0) {
            print.greenLine("Docker version: " & trim(local.verifyResult.output)).toConsole();
        }
        
        return true;
    }
    
    /**
     * Check if Docker Compose is available
     */
    private function checkDockerCompose(string host, string user, numeric port) {
        var local = {};
        
        // Check for docker compose (new version)
        var composeCmd = ["ssh", "-p", arguments.port];
        composeCmd.addAll(getSSHOptions());
        composeCmd.addAll([arguments.user & "@" & arguments.host, "docker compose version"]);
        
        local.composeResult = runLocalCommand(composeCmd);
        
        if (local.composeResult.exitCode eq 0) {
            print.greenLine("Docker Compose is available").toConsole();
            print.cyanLine("Compose version: " & trim(local.composeResult.output)).toConsole();
            return true;
        }
        
        // Check for docker-compose (old version)
        var oldComposeCmd = ["ssh", "-p", arguments.port];
        oldComposeCmd.addAll(getSSHOptions());
        oldComposeCmd.addAll([arguments.user & "@" & arguments.host, "docker-compose --version"]);
        
        local.oldComposeResult = runLocalCommand(oldComposeCmd);
        
        if (local.oldComposeResult.exitCode eq 0) {
            print.greenLine("Docker Compose (standalone) is available").toConsole();
            print.cyanLine("Compose version: " & trim(local.oldComposeResult.output)).toConsole();
            return true;
        }
        
        print.yellowLine("Docker Compose is not available, but docker compose plugin should be included in modern Docker installations").toConsole();
        return false;
    }
    
    /**
     * Get Docker installation script for Debian/Ubuntu
     */
    private function getDockerInstallScriptDebian() {
        var script = '##!/bin/bash
set -e

echo "Installing Docker on Debian/Ubuntu..."

## Set non-interactive mode
export DEBIAN_FRONTEND=noninteractive

## Update package index
apt-get update

## Install prerequisites
apt-get install -y ca-certificates curl gnupg lsb-release

## Add Docker GPG key
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

## Set up repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

## Install Docker with automatic yes to all prompts
apt-get update
apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

## Start and enable Docker
systemctl start docker
systemctl enable docker

## Wait for Docker to be ready
sleep 3

## Add current user to docker group (determine actual user if running via sudo)
ACTUAL_USER="${SUDO_USER:-$USER}"
if [ -n "$ACTUAL_USER" ] && [ "$ACTUAL_USER" != "root" ]; then
    usermod -aG docker $ACTUAL_USER
    echo "Added user $ACTUAL_USER to docker group"
fi

## Set proper permissions on docker socket
chmod 666 /var/run/docker.sock

echo "Docker installation completed successfully!"
';
        return script;
    }
    
    /**
     * Get Docker installation script for RHEL/CentOS
     */
    private function getDockerInstallScriptRHEL() {
        var script = '##!/bin/bash
set -e

echo "Installing Docker on RHEL/CentOS/Fedora..."

## Install prerequisites
yum install -y yum-utils

## Add Docker repository
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

## Install Docker
yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

## Start and enable Docker
systemctl start docker
systemctl enable docker

## Wait for Docker to be ready
sleep 3

## Add current user to docker group
ACTUAL_USER="${SUDO_USER:-$USER}"
if [ -n "$ACTUAL_USER" ] && [ "$ACTUAL_USER" != "root" ]; then
    usermod -aG docker $ACTUAL_USER
    echo "Added user $ACTUAL_USER to docker group"
fi

## Set proper permissions on docker socket
chmod 666 /var/run/docker.sock

echo "Docker installation completed successfully!"
';
        return script;
    }

}