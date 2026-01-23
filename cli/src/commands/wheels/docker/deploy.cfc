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

    property name="detailOutput" inject="DetailOutputService@wheels-cli";
    
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
     * @image Deprecated. Use unique project name in box.json instead.
     * @tag Custom tag to use (default: latest). Always treated as suffix to project name.
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
        boolean blueGreen=false,
        string image="",
        string tag=""
    ) {
        //ensure we are in a Wheels app
        requireWheelsApp(getCWD());
        // Reconstruct arguments for handling --key=value style
        arguments = reconstructArgs(arguments);
        
        var projectName = getProjectName();
        
        // Interactive Tag Selection logic
        // Only trigger if no tag is specified and we are running?
        // Actually, if tag is empty, we usually default to 'latest'.
        // But user requested: "check the images available with different tags and then ask the user to select"
        
        if (!len(arguments.tag)) {
            try {
                // List images for project with a safe delimiter
                var imageCheck = runLocalCommand(["docker", "images", "--format", "{{.Repository}}:::{{.Tag}}"], false);
                
                if (imageCheck.exitCode == 0) {
                    var candidates = [];
                    var lines = listToArray(imageCheck.output, chr(10));
                    
                    for (var img in lines) {
                        // Split by our custom delimiter
                        var parts = listToArray(img, ":::");
                        if (arrayLen(parts) >= 2) {
                            var repo = trim(parts[1]);
                            var t = trim(parts[2]);
                            
                            // Check for exact match on project name
                            if (repo == projectName) {
                                arrayAppend(candidates, t);
                            }
                        }
                    }
                    
                    // Deduplicate candidates just in case
                    // (CFML doesn't have a native Set, so we can use a struct key trick or just leave it if docker output is unique enough)
                    
                    if (arrayLen(candidates) > 1) {
                        detailOutput.line();
                        detailOutput.output("Select a tag to deploy for project '#projectName#':");
                        
                        for (var i=1; i<=arrayLen(candidates); i++) {
                            detailOutput.output("   #i#. " & candidates[i]);
                        }
                        detailOutput.line();
                        
                        var selection = ask("Enter number to select, or press Enter for 'latest': ");
                        
                        if (len(trim(selection)) && isNumeric(selection) && selection > 0 && selection <= arrayLen(candidates)) {
                            arguments.tag = candidates[selection];
                            detailOutput.statusSuccess("Selected tag: " & arguments.tag);
                        } else if (len(trim(selection))) {
                            // Treat as custom tag input if they typed a string not in the list? 
                            // Or just fallback to what they typed
                            arguments.tag = selection;
                            detailOutput.statusSuccess("Using custom tag: " & arguments.tag);
                        } else {
                            // Empty selection matches 'latest' default logic later, or we can explicit set it
                            detailOutput.statusInfo("No selection made, defaulting to 'latest'");
                        }
                    }
                }
            } catch (any e) {
                // Determine if we should show error or just fail silently to defaults
                // print.redLine("Warning: Failed to list local images: " & e.message).toConsole();
            }
        }
        
        // set local as default if neither specified
        if (!arguments.local && !arguments.remote) {
            arguments.local=true;
        }
        
        if (arguments.local && arguments.remote) {
            error("Cannot specify both --local and --remote. Please choose one.");
        }
        
        // Route to appropriate deployment method
        if (arguments.local) {
            deployLocal(arguments.environment, arguments.db, arguments.cfengine, arguments.optimize, arguments.tag);
        } else {
            deployRemote(arguments.servers, arguments.skipDockerCheck, arguments.blueGreen, arguments.tag);
        }
    }
    
    // =============================================================================
    // LOCAL DEPLOYMENT
    // =============================================================================
    
    private function deployLocal(
        string environment,
        string db,
        string cfengine,
        boolean optimize,
        string tag=""
    ) {
        // Welcome message
        detailOutput.header("Wheels Docker Local Deployment");

        // Check for docker-compose file
        local.useCompose = hasDockerComposeFile();
        
        if (local.useCompose) {
            detailOutput.statusSuccess("Found docker-compose file, will use docker-compose");
            
            // Just run docker-compose up
            if (len(arguments.tag)) {
                detailOutput.statusInfo("Note: --tag argument is ignored when using docker-compose.");
            }
            
            detailOutput.statusInfo("Starting services...");
            runLocalCommand(["docker-compose", "up", "-d", "--build"]);
            
            detailOutput.line();
            detailOutput.statusSuccess("Services started successfully!");
            detailOutput.line();
            detailOutput.output("View logs with: docker-compose logs -f");
            detailOutput.line();
            
        } else {
            // Check for Dockerfile
            local.dockerfilePath = getCWD() & "/Dockerfile";
            if (!fileExists(local.dockerfilePath)) {
                error("No Dockerfile or docker-compose.yml found in current directory");
            }
            
            detailOutput.statusSuccess("Found Dockerfile, will use standard docker commands");
            
            // Check if Docker is installed locally
            if (!isDockerInstalled()) {
                error("Docker is not installed or not accessible. Please ensure Docker Desktop or Docker Engine is running.");
            }
            
            // Extract port from Dockerfile
            local.exposedPort = getDockerExposedPort();
            if (!len(local.exposedPort)) {
                detailOutput.statusInfo("No EXPOSE directive found in Dockerfile, using default port 8080");
                local.exposedPort = "8080";
            } else {
                detailOutput.statusSuccess("Found EXPOSE port: " & local.exposedPort);
            }
            
            // Get project name for image/container naming
            local.projectName = getProjectName();
            local.deployConfig = getDeployConfig();
            
            // Strict Tag Strategy: projectName:tag
            local.tag = len(arguments.tag) ? arguments.tag : "latest";
            
            // Smart Tag Logic: Check if tag contains colon (full image name)
            if (find(":", local.tag)) {
                local.imageName = local.tag;
            } else if (structKeyExists(local.deployConfig, "image") && len(trim(local.deployConfig.image))) {
                local.imageName = local.deployConfig.image & ":" & local.tag;
            } else {
                local.imageName = local.projectName & ":" & local.tag;
            }
            
            // Container Name: Always use project name for consistency
            local.containerName = local.projectName;
            
            detailOutput.statusInfo("Building Docker image (" & local.imageName & ")...");
            runLocalCommand(["docker", "build", "-t", local.imageName, "."]);
            
            detailOutput.statusInfo("Starting container...");
            
            try {
                // Stop and remove existing container
                runLocalCommand(["docker", "stop", local.containerName]);
                runLocalCommand(["docker", "rm", local.containerName]);
            } catch (any e) {
                detailOutput.output("No existing container to remove");
            }
            
            // Run new container
            runLocalCommand(["docker", "run", "-d", "--name", local.containerName, "-p", local.exposedPort & ":" & local.exposedPort, local.imageName]);
            
            detailOutput.line();
            detailOutput.statusSuccess("Container started successfully!");
            detailOutput.line();
            detailOutput.create("Image: " & local.imageName);
            detailOutput.create("Container: " & local.containerName);
            detailOutput.statusInfo("Access your application at: http://localhost:" & local.exposedPort);
            detailOutput.line();
            detailOutput.output("Check container status with: docker ps");
            detailOutput.output("View logs with: wheels docker logs --local");
            detailOutput.line();
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
    
    private function deployRemote(string serversFile, boolean skipDockerCheck, boolean blueGreen, string tag="") {
        // Check for deploy-servers file (text or json) in current directory
        var textConfigPath = fileSystemUtil.resolvePath("deploy-servers.txt");
        var jsonConfigPath = fileSystemUtil.resolvePath("deploy-servers.json");
        var ymlConfigPath = fileSystemUtil.resolvePath("config/deploy.yml");
        var servers = [];
        var projectName = getProjectName();
        
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
        // 1. Look for config/deploy.yml first
        else if (fileExists(ymlConfigPath)) {
            var deployConfig = getDeployConfig();
            if (arrayLen(deployConfig.servers)) {
                 detailOutput.identical("Found config/deploy.yml, loading server configuration");
                servers = deployConfig.servers;
                
                // Add defaults for missing fields
                for (var s in servers) {
                    if (!structKeyExists(s, "remoteDir")) {
                        s.remoteDir = "/home/#s.user#/#projectName#";
                    }
                    if (!structKeyExists(s, "port")) {
                        s.port = 22;
                    }
                }
            }
        }
        // 2. Otherwise, look for default files
        else if (fileExists(textConfigPath)) {
           detailOutput.identical("Found deploy-servers.txt, loading server configuration");
            servers = loadServersFromTextFile("deploy-servers.txt");
        } else if (fileExists(jsonConfigPath)) {
           detailOutput.identical("Found deploy-servers.json, loading server configuration");
            servers = loadServersFromConfig("deploy-servers.json");
        } else {
            error("No server configuration found. Use 'wheels docker init' or create deploy-servers.txt.");
        }

        if (arrayLen(servers) == 0) {
            error("No servers configured for deployment");
        }

        detailOutput.statusInfo("Starting remote deployment to #arrayLen(servers)# server(s)...");
        if (arguments.blueGreen) {
        detailOutput.output("Strategy: Blue/Green Deployment (Zero Downtime)");
        }

        // Deploy to all servers sequentially
        deployToMultipleServersSequential(servers, arguments.skipDockerCheck, arguments.blueGreen, arguments.tag);

        detailOutput.line();
        detailOutput.success("Deployment to all servers completed!");
    }

    /**
     * Deploy to multiple servers sequentially
     */
    private function deployToMultipleServersSequential(required array servers, boolean skipDockerCheck, boolean blueGreen, string tag="") {
        var successCount = 0;
        var failureCount = 0;
        var serverConfig = {};

        for (var i = 1; i <= arrayLen(servers); i++) {
            serverConfig = servers[i];
            
            // Override tag if provided via CLI argument
            if (len(arguments.tag)) {
                serverConfig.tag = arguments.tag;
            } else if (!structKeyExists(serverConfig, "tag")) {
                 // Default tag is latest if not specified in server config either
                 serverConfig.tag = "latest";
            }
            
            detailOutput.header("Deploying to server #i# of #arrayLen(servers)#: #serverConfig.host#");

            try {
                if (arguments.blueGreen) {
                    deployToSingleServerBlueGreen(serverConfig, arguments.skipDockerCheck);
                } else {
                    deployToSingleServer(serverConfig, arguments.skipDockerCheck);
                }
                successCount++;
                detailOutput.statusSuccess("Server #serverConfig.host# deployed successfully");
            } catch (any e) {
                failureCount++;
                detailOutput.statusFailed("Failed to deploy to #serverConfig.host#: #e.message#");
            }
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
        local.projectName = getProjectName(); // Use unique project name
        
        // Use standard directory based on Project Name
        local.remoteDir = structKeyExists(arguments.serverConfig, "remoteDir") ? arguments.serverConfig.remoteDir : "/home/#local.user#/#local.projectName#";
        
        local.tag = structKeyExists(arguments.serverConfig, "tag") ? arguments.serverConfig.tag : "latest";
        local.deployConfig = getDeployConfig();
        
        // Smart Tag Logic
        if (find(":", local.tag)) {
            local.imageName = local.tag;
        } else if (structKeyExists(local.deployConfig, "image") && len(trim(local.deployConfig.image))) {
            local.imageName = local.deployConfig.image & ":" & local.tag;
        } else {
            local.imageName = local.projectName & ":" & local.tag;
        }
        local.containerName = local.projectName;

        // Step 1: Check SSH connection
        if (!testSSHConnection(local.host, local.user, local.port)) {
            error("SSH connection failed to #local.host#. Check credentials and access.");
        }
        detailOutput.statusSuccess("SSH connection successful");

        // Step 1.5: Check and install Docker if needed (unless skipped)
        if (!arguments.skipDockerCheck) {
            ensureDockerInstalled(local.host, local.user, local.port);
        } else {
            detailOutput.skip("Skipping Docker installation check (--skipDockerCheck flag is set)");
        }

        // Step 2: Create remote directory
        detailOutput.statusInfo("Creating remote directory...");
        executeRemoteCommand(local.host, local.user, local.port, "mkdir -p " & local.remoteDir);

        // Step 3: Check for docker-compose file
        local.useCompose = hasDockerComposeFile();
        if (local.useCompose) {
            detailOutput.statusSuccess("Found docker-compose file, will use docker-compose");
        } else {
            // Extract port from Dockerfile for standard docker run
            local.exposedPort = getDockerExposedPort();
            if (!len(local.exposedPort)) {
                detailOutput.statusInfo(" No EXPOSE directive found in Dockerfile, using default port 8080");
                local.exposedPort = "8080";
            } else {
                detailOutput.statusSuccess("Found EXPOSE port: " & local.exposedPort);
            }
        }

        // Step 4: Tar and upload project
        local.timestamp = dateFormat(now(), "yyyymmdd") & timeFormat(now(), "HHmmss");
        local.tarFile = getTempFile(getTempDirectory(), "deploysrc_") & ".tar.gz";
        local.remoteTar = "/tmp/deploysrc_" & local.timestamp & ".tar.gz";

        detailOutput.statusInfo("Creating source tarball...");
        runLocalCommand(["tar", "-czf", local.tarFile, "-C", getCWD(), "."]);

        detailOutput.statusInfo(" Uploading to remote server...");
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
            // Use docker-compose
            local.deployScript &= "if groups | grep -q docker && [ -w /var/run/docker.sock ]; then" & chr(10);
            local.deployScript &= "  docker compose down || true" & chr(10);
            local.deployScript &= "  docker compose up -d --build" & chr(10);
            local.deployScript &= "else" & chr(10);
            local.deployScript &= "  sudo docker compose down || true" & chr(10);
            local.deployScript &= "  sudo docker compose up -d --build" & chr(10);
            local.deployScript &= "fi" & chr(10);
        } else {
            // Use standard docker commands
            local.deployScript &= "echo 'Building Docker image...'" & chr(10);
            
            // Check if user is in docker group
            local.deployScript &= "if groups | grep -q docker && [ -w /var/run/docker.sock ]; then" & chr(10);
            local.deployScript &= "  docker build -t " & local.imageName & " ." & chr(10);
            local.deployScript &= "  echo 'Starting container...'" & chr(10);
            local.deployScript &= "  docker stop " & local.containerName & " || true" & chr(10);
            local.deployScript &= "  docker rm " & local.containerName & " || true" & chr(10);
            local.deployScript &= "  docker run -d --name " & local.containerName & " -p " & local.exposedPort & ":" & local.exposedPort & " " & local.imageName & chr(10);
            local.deployScript &= "else" & chr(10);
            local.deployScript &= "  sudo docker build -t " & local.imageName & " ." & chr(10);
            local.deployScript &= "  echo 'Starting container...'" & chr(10);
            local.deployScript &= "  sudo docker stop " & local.containerName & " || true" & chr(10);
            local.deployScript &= "  sudo docker rm " & local.containerName & " || true" & chr(10);
            local.deployScript &= "  sudo docker run -d --name " & local.containerName & " -p " & local.exposedPort & ":" & local.exposedPort & " " & local.imageName & chr(10);
            local.deployScript &= "fi" & chr(10);
        }

        local.deployScript &= "echo 'Deployment complete!'" & chr(10);

        // Normalize
        local.deployScript = replace(local.deployScript, chr(13) & chr(10), chr(10), "all");
        local.deployScript = replace(local.deployScript, chr(13), chr(10), "all");

        local.tempFile = getTempFile(getTempDirectory(), "deploy_");
        fileWrite(local.tempFile, local.deployScript);

        detailOutput.statusInfo("Uploading deployment script...");
        var scpScriptCmd = ["scp", "-P", local.port];
        scpScriptCmd.addAll(getSSHOptions());
        scpScriptCmd.addAll([local.tempFile, local.user & "@" & local.host & ":/tmp/deploy-simple.sh"]);
        runLocalCommand(scpScriptCmd);
        fileDelete(local.tempFile);

        detailOutput.statusInfo("Executing deployment script remotely...");
        // Use interactive command
        var execCmd = ["ssh", "-p", local.port];
        execCmd.addAll(getSSHOptions());
        execCmd.addAll([local.user & "@" & local.host, "chmod +x /tmp/deploy-simple.sh && bash /tmp/deploy-simple.sh"]);
        
        runInteractiveCommand(execCmd);

        detailOutput.success("Deployment to #local.host# completed successfully!");
    }

    /**
     * Deploy to a single server (Blue/Green Strategy)
     */
    private function deployToSingleServerBlueGreen(required struct serverConfig, boolean skipDockerCheck) {
        var local = {};
        local.host = arguments.serverConfig.host;
        local.user = arguments.serverConfig.user;
        local.port = structKeyExists(arguments.serverConfig, "port") ? arguments.serverConfig.port : 22;
        local.projectName = getProjectName();
        local.remoteDir = structKeyExists(arguments.serverConfig, "remoteDir") ? arguments.serverConfig.remoteDir : "/home/#local.user#/#local.projectName#";
        
        local.tag = structKeyExists(arguments.serverConfig, "tag") ? arguments.serverConfig.tag : "latest";
        local.imageName = local.projectName; // Just project name, tag is separate variable in B/G script

        // Step 1: Check SSH connection
        if (!testSSHConnection(local.host, local.user, local.port)) {
            error("SSH connection failed to #local.host#. Check credentials and access.");
        }
        detailOutput.statusSuccess("SSH connection successful");

        // Step 1.5: Check and install Docker
        if (!arguments.skipDockerCheck) {
            ensureDockerInstalled(local.host, local.user, local.port);
        }

        // Step 2: Create remote directory
        detailOutput.statusInfo("Creating remote directory...");
        executeRemoteCommand(local.host, local.user, local.port, "mkdir -p " & local.remoteDir);

        // Step 3: Determine Port
        local.exposedPort = getDockerExposedPort();
        if (!len(local.exposedPort)) {
            detailOutput.statusInfo(" No EXPOSE directive found in Dockerfile, using default port 8080");
            local.exposedPort = "8080";
        } else {
            detailOutput.statusSuccess("Found EXPOSE port: " & local.exposedPort);
        }

        // Step 4: Tar and upload project
        local.timestamp = dateFormat(now(), "yyyymmdd") & timeFormat(now(), "HHmmss");
        local.tarFile = getTempFile(getTempDirectory(), "deploysrc_") & ".tar.gz";
        local.remoteTar = "/tmp/deploysrc_" & local.timestamp & ".tar.gz";

        detailOutput.statusInfo("Creating source tarball...");
        runLocalCommand(["tar", "-czf", local.tarFile, "-C", getCWD(), "."]);

        detailOutput.statusInfo(" Uploading to remote server...");
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
        local.deployScript &= "TAG='" & local.tag & "'" & chr(10);
        
        // Extract source
        local.deployScript &= "echo 'Extracting source to ' $REMOTE_DIR ' ...'" & chr(10);
        local.deployScript &= "mkdir -p $REMOTE_DIR" & chr(10);
        local.deployScript &= "tar --overwrite -xzf $REMOTE_TAR -C $REMOTE_DIR" & chr(10);
        local.deployScript &= "cd $REMOTE_DIR" & chr(10);
        
        // Build Image
        local.deployScript &= "echo 'Building Docker image...'" & chr(10);
        local.deployScript &= "docker build -t $APP_NAME:$TAG ." & chr(10);
        
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
        
        // Stop Target if exists
        local.deployScript &= "docker stop $TARGET_CONTAINER 2>/dev/null || true" & chr(10);
        local.deployScript &= "docker rm $TARGET_CONTAINER 2>/dev/null || true" & chr(10);
        
        // Start New Container
        local.deployScript &= "echo 'Starting ' $TARGET_CONTAINER ' ...'" & chr(10);
        local.deployScript &= "docker run -d --name $TARGET_CONTAINER --network $NETWORK_NAME --restart unless-stopped $APP_NAME:$TAG" & chr(10);
        
        // Wait for container
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
        
        local.deployScript = replace(local.deployScript, chr(13), chr(10), "all");

        local.tempFile = getTempFile(getTempDirectory(), "deploy_bg_");
        fileWrite(local.tempFile, local.deployScript);

        detailOutput.statusInfo("Uploading Blue/Green deployment script...");
        var scpScriptCmd = ["scp", "-P", local.port];
        scpScriptCmd.addAll(getSSHOptions());
        scpScriptCmd.addAll([local.tempFile, local.user & "@" & local.host & ":/tmp/deploy-bluegreen.sh"]);
        runLocalCommand(scpScriptCmd);
        fileDelete(local.tempFile);

        detailOutput.statusInfo("Executing Blue/Green deployment script remotely...");
        var execCmd = ["ssh", "-p", local.port];
        execCmd.addAll(getSSHOptions());
        execCmd.addAll([local.user & "@" & local.host, "chmod +x /tmp/deploy-bluegreen.sh && bash /tmp/deploy-bluegreen.sh"]);
        
        runInteractiveCommand(execCmd);

        detailOutput.success("Blue/Green Deployment to #local.host# completed successfully!");
    }
    
    /**
     * Check if Docker is installed on remote server and install if needed
     */
    private function ensureDockerInstalled(string host, string user, numeric port) {
        var local = {};
        
        detailOutput.statusInfo("Checking Docker installation on remote server...");
        
        // Check if Docker is installed
        var checkCmd = ["ssh", "-p", arguments.port];
        checkCmd.addAll(getSSHOptions());
        checkCmd.addAll([arguments.user & "@" & arguments.host, "command -v docker"]);
        
        local.checkResult = runLocalCommand(checkCmd);
        
        if (local.checkResult.exitCode eq 0) {
            detailOutput.statusSuccess("Docker is already installed");
            
            // Get Docker version
            var versionCmd = ["ssh", "-p", arguments.port];
            versionCmd.addAll(getSSHOptions());
            versionCmd.addAll([arguments.user & "@" & arguments.host, "docker --version"]);
            
            local.versionResult = runLocalCommand(versionCmd);
            
            if (local.versionResult.exitCode eq 0) {
                detailOutput.statusInfo("Docker version: " & trim(local.versionResult.output));
            }
            
            // Check if docker compose is available
            checkDockerCompose(arguments.host, arguments.user, arguments.port);
            
            return true;
        }
        
        detailOutput.statusInfo("Docker is not installed. Attempting to install Docker...");
        
        // Check if user has passwordless sudo access
        detailOutput.statusInfo("Checking sudo access...");
        var sudoCheckCmd = ["ssh", "-p", arguments.port];
        sudoCheckCmd.addAll(getSSHOptions());
        sudoCheckCmd.addAll([arguments.user & "@" & arguments.host, "sudo -n true 2>&1"]);
        
        local.sudoCheckResult = runLocalCommand(sudoCheckCmd);
        
        if (local.sudoCheckResult.exitCode neq 0) {
            detailOutput.line();
            detailOutput.statusFailed("ERROR: User '#arguments.user#' does not have passwordless sudo access on #arguments.host#!");
            error("Cannot install Docker: User '" & arguments.user & "' requires passwordless sudo access on " & arguments.host);
        }
        
        detailOutput.statusSuccess("User has sudo access");
        
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
            detailOutput.identical("Detected Debian/Ubuntu system");
        } else if (findNoCase("centos", local.osResult.output) || findNoCase("rhel", local.osResult.output) || findNoCase("fedora", local.osResult.output)) {
            local.installScript = getDockerInstallScriptRHEL();
            detailOutput.identical("Detected RHEL/CentOS/Fedora system");
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
        detailOutput.statusInfo("Uploading Docker installation script...");
        var scpInstallCmd = ["scp", "-P", arguments.port];
        scpInstallCmd.addAll(getSSHOptions());
        scpInstallCmd.addAll([local.tempFile, arguments.user & "@" & arguments.host & ":/tmp/install-docker.sh"]);
        runLocalCommand(scpInstallCmd);
        fileDelete(local.tempFile);
        
        // Execute install script
        detailOutput.statusInfo("Installing Docker...");
        var installCmd = ["ssh", "-p", arguments.port];
        installCmd.addAll(getSSHOptions());
        installCmd.addAll(["-o", "ServerAliveInterval=30", "-o", "ServerAliveCountMax=10"]);
        installCmd.addAll([arguments.user & "@" & arguments.host, "sudo bash /tmp/install-docker.sh"]);
        
        local.installResult = runLocalCommand(installCmd);
        
        if (local.installResult.exitCode neq 0) {
            error("Failed to install Docker on remote server");
        }
        
        detailOutput.statusSuccess("Docker installed successfully!");
        
        // Verify installation
        var verifyCmd = ["ssh", "-p", arguments.port];
        verifyCmd.addAll(getSSHOptions());
        verifyCmd.addAll([arguments.user & "@" & arguments.host, "docker --version"]);
        
        local.verifyResult = runLocalCommand(verifyCmd);
        
        if (local.verifyResult.exitCode eq 0) {
            detailOutput.statusSuccess("Docker version: " & trim(local.verifyResult.output));
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
            detailOutput.statusSuccess("Docker Compose is available");
            detailOutput.statusInfo("Compose version: " & trim(local.composeResult.output));
            return true;
        }
        
        // Check for docker-compose (old version)
        var oldComposeCmd = ["ssh", "-p", arguments.port];
        oldComposeCmd.addAll(getSSHOptions());
        oldComposeCmd.addAll([arguments.user & "@" & arguments.host, "docker-compose --version"]);
        
        local.oldComposeResult = runLocalCommand(oldComposeCmd);
        
        if (local.oldComposeResult.exitCode eq 0) {
            detailOutput.statusSuccess("Docker Compose (standalone) is available");
            detailOutput.statusInfo("Compose version: " & trim(local.oldComposeResult.output));
            return true;
        }
        
        detailOutput.output("Docker Compose is not available, but docker compose plugin should be included in modern Docker installations");
        return false;
    }
    
    /**
     * Get Docker installation script for Debian/Ubuntu
     */
    private function getDockerInstallScriptDebian() {
        var script = '##!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl start docker
systemctl enable docker
sleep 3
ACTUAL_USER="${SUDO_USER:-$USER}"
if [ -n "$ACTUAL_USER" ] && [ "$ACTUAL_USER" != "root" ]; then
    usermod -aG docker $ACTUAL_USER
fi
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
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl start docker
systemctl enable docker
sleep 3
ACTUAL_USER="${SUDO_USER:-$USER}"
if [ -n "$ACTUAL_USER" ] && [ "$ACTUAL_USER" != "root" ]; then
    usermod -aG docker $ACTUAL_USER
fi
chmod 666 /var/run/docker.sock
echo "Docker installation completed successfully!"
';
        return script;
    }
}