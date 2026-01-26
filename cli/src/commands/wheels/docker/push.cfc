/**
 * Push Docker images to container registries
 *
 * {code:bash}
 * wheels docker push --local --registry=dockerhub --username=myuser
 * wheels docker push --local --registry=dockerhub --username=myuser --tag=v1.0.0
 * wheels docker push --local --registry=ecr --image=123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
 * wheels docker push --local --registry=dockerhub --username=myuser --build
 * wheels docker push --remote --registry=dockerhub --username=myuser
 * {code}
 */
component extends="DockerCommand" {

    property name="detailOutput" inject="DetailOutputService@wheels-cli";
    
    /**
     * @local Push image from local machine
     * @remote Push image from remote server(s)
     * @servers Comma-separated list of server numbers to push from (e.g., "1,3,5") - for remote only
     * @registry Registry type: dockerhub, ecr, gcr, acr, ghcr, private (default: dockerhub)
     * @image Full image name with registry path (optional - auto-detected from project if not specified)
     * @username Registry username (for dockerhub, ghcr, private registries)
     * @password Registry password or token (leave empty to prompt)
     * @tag Tag/version to apply (e.g., v1.0.0, latest). If specified, creates: username/projectname:tag
     * @build Build the image before pushing (default: false)
     * @namespace Registry namespace/username prefix (e.g., for dockerhub: myusername)
     */
    function run(
        boolean local=false,
        boolean remote=false,
        string servers="",
        string registry="",
        string image="",
        string username="",
        string password="",
        string tag="latest",
        boolean build=false,
        string namespace=""
    ) {
        //ensure we are in a Wheels app
        requireWheelsApp(getCWD());
        // Reconstruct arguments for handling --key=value style
        arguments = reconstructArgs(arguments);

        // Load defaults from config if available (prioritize deploy.yml)
        var ymlConfigPath = fileSystemUtil.resolvePath("config/deploy.yml");
        var configPath = fileSystemUtil.resolvePath("docker-config.json");
        var projectName = getProjectName();

        if (fileExists(ymlConfigPath)) {
            var deployConfig = getDeployConfig();
            if (structKeyExists(deployConfig, "image") && len(trim(deployConfig.image))) {
                arguments.image = deployConfig.image;
            }
        }
        
        if (fileExists(configPath)) {
            try {
                var config = deserializeJSON(fileRead(configPath));
                
                if (!len(trim(arguments.registry)) && structKeyExists(config, "registry")) {
                    arguments.registry = config.registry;
                    detailOutput.statusInfo("Using registry from session: #arguments.registry#");
                }
                
                if (!len(trim(arguments.username)) && structKeyExists(config, "username")) {
                    arguments.username = config.username;
                    detailOutput.statusInfo("Using username from session: #arguments.username#");
                }

                if (!len(trim(arguments.namespace)) && structKeyExists(config, "namespace")) {
                    arguments.namespace = config.namespace;
                    if (len(trim(arguments.namespace))) {
                        detailOutput.statusInfo("Using namespace from session: #arguments.namespace#");
                    }
                }

                if (!len(trim(arguments.image)) && structKeyExists(config, "image")) {
                    arguments.image = config.image;
                    if (len(trim(arguments.image))) {
                        detailOutput.statusInfo("Using image from session: #arguments.image#");
                    }
                }
            } catch (any e) {}
        }

        // Smart Tagging logic
        if (len(trim(arguments.tag)) && find(":", arguments.tag)) {
            arguments.image = arguments.tag;
        }

        // Default registry to dockerhub if still empty
        if (!len(trim(arguments.registry))) {
            arguments.registry = "dockerhub";
        }
        
        // set local as default if neither specified
        if (!arguments.local && !arguments.remote) {
            arguments.local=true;
        }
        
        if (arguments.local && arguments.remote) {
            error("Cannot specify both --local and --remote. Please choose one.");
        }
        
        // Validate registry type
        local.supportedRegistries = ["dockerhub", "ecr", "gcr", "acr", "ghcr", "private"];
        if (!arrayContains(local.supportedRegistries, lCase(arguments.registry))) {
            error("Unsupported registry: #arguments.registry#. Supported: #arrayToList(local.supportedRegistries)#");
        }
        
        // Route to appropriate push method
        if (arguments.local) {
            pushLocal(arguments.registry, arguments.image, arguments.username, arguments.password, arguments.tag, arguments.build, arguments.namespace);
        } else {
            pushRemote(arguments.servers, arguments.registry, arguments.image, arguments.username, arguments.password, arguments.tag, arguments.build, arguments.namespace);
        }
    }
    
    // =============================================================================
    // LOCAL PUSH
    // =============================================================================
    
    private function pushLocal(string registry, string customImage, string username, string password, string tag, boolean build, string namespace) {
        detailOutput.header("Wheels Docker Push - Local");

        // Check if Docker is installed locally
        if (!isDockerInstalled()) {
            error("Docker is not installed or not accessible. Please ensure Docker Desktop or Docker Engine is running.");
        }

        // Get project name
        local.projectName = getProjectName();
        local.deployConfig = getDeployConfig();
        local.baseImageName = (structKeyExists(local.deployConfig, "image") && len(trim(local.deployConfig.image))) ? local.deployConfig.image : local.projectName;
        local.localImageName = local.projectName & ":latest";
        
        if (!checkLocalImageExists(local.localImageName)) {
            // Check if it was built with the custom image name
            if (checkLocalImageExists(local.baseImageName & ":latest")) {
                local.localImageName = local.baseImageName & ":latest";
            }
        }
        
        detailOutput.statusInfo("Project: " & local.projectName);
        detailOutput.statusInfo("Registry: " & arguments.registry);
        detailOutput.line();
        
        // Build image if requested
        if (arguments.build) {
            detailOutput.statusInfo("Building image before push...");
            buildLocalImage();
        }
        
        // Check if local image exists
        if (!checkLocalImageExists(local.localImageName)) {
            detailOutput.statusInfo("Local image '#local.localImageName#' not found.");
            local.answer = ask("Would you like to build it now? (y/n)");
            if (lCase(local.answer) == "y") {
                buildLocalImage();
            } else {
                error("Image not found. Build the image first with: wheels docker build --local");
            }
        }
        
        detailOutput.statusSuccess("Found local image: " & local.localImageName);
        
        // Determine final image name based on registry and user input
        local.finalImage = determineImageName(
            arguments.registry,
            arguments.customImage,
            local.projectName,
            arguments.tag,
            arguments.username,
            arguments.namespace
        );
        
        detailOutput.statusInfo("Target image: " & local.finalImage);
        detailOutput.line();
        
        // Tag the image if needed
        if (local.finalImage != local.localImageName) {
            detailOutput.statusInfo("Tagging image: " & local.localImageName & " -> " & local.finalImage);
            try {
                runLocalCommand(["docker", "tag", local.localImageName, local.finalImage]);
                detailOutput.statusSuccess("Image tagged successfully");
            } catch (any e) {
                error("Failed to tag image: " & e.message);
            }
        }
        
        // Login to registry if password provided, otherwise assume already logged in
        if (len(trim(arguments.password))) {
            var loginResult = loginToRegistry(
                registry=arguments.registry, 
                image=local.finalImage, 
                username=arguments.username, 
                password=arguments.password, 
                isLocal=true
            );
        } else {
            detailOutput.statusWarning("No password provided, attempting to push with existing credentials...");
        }
        
        // Push the image
        detailOutput.statusInfo("Pushing image to " & arguments.registry & "...");
        
        try {
            runLocalCommand(["docker", "push", local.finalImage]);
            detailOutput.line();
            detailOutput.statusSuccess("Image pushed successfully to " & arguments.registry & "!");
            detailOutput.line();
            detailOutput.statusInfo("Image: " & local.finalImage);
            detailOutput.statusInfo("Pull with: docker pull " & local.finalImage);
            detailOutput.line();
        } catch (any e) {
            detailOutput.statusFailed("Failed to push image: " & e.message);
            detailOutput.line();
            detailOutput.output("You may need to login first.");
            detailOutput.output("Try running: wheels docker login --registry=" & arguments.registry & " --username=" & arguments.username);
            detailOutput.output("Or provide a password/token with --password");
            error("Push failed");
        }
    }
    
    /**
     * Build the local image
     */
    private function buildLocalImage() {
        detailOutput.statusInfo("Building Docker image...");
        detailOutput.line();
        
        // Check for docker-compose file
        local.useCompose = hasDockerComposeFile();
        
        if (local.useCompose) {
            runLocalCommand(["docker", "compose", "build"]);
        } else {
            local.projectName = getProjectName();
            runLocalCommand(["docker", "build", "-t", local.projectName & ":latest", "."]);
        }
        detailOutput.line();
        detailOutput.statusSuccess("Build completed successfully");
    }
    
    private function hasDockerComposeFile() {
        var composeFiles = ["docker-compose.yml", "docker-compose.yaml"];
        for (var composeFile in composeFiles) {
            if (fileExists(getCWD() & "/" & composeFile)) {
                return true;
            }
        }
        return false;
    }
    
    // =============================================================================
    // REMOTE PUSH
    // =============================================================================
    
    private function pushRemote(string serverNumbers, string registry, string image, string username, string password, string tag, boolean build, string namespace) {
        // Check for deploy-servers file
        var textConfigPath = fileSystemUtil.resolvePath("deploy-servers.txt");
        var jsonConfigPath = fileSystemUtil.resolvePath("deploy-servers.json");
        var ymlConfigPath = fileSystemUtil.resolvePath("config/deploy.yml");
        var allServers = [];
        var serversToPush = [];
        var projectName = getProjectName();

        if (len(trim(arguments.serverNumbers)) == 0 && fileExists(ymlConfigPath)) {
            var deployConfig = getDeployConfig();
            if (arrayLen(deployConfig.servers)) {
                detailOutput.identical("Found config/deploy.yml, loading server configuration");
                allServers = deployConfig.servers;
                serversToPush = allServers;
            }
        }

        if (arrayLen(serversToPush) == 0) {
            if (fileExists(textConfigPath)) {
                detailOutput.identical("Found deploy-servers.txt, loading server configuration");
                allServers = loadServersFromTextFile("deploy-servers.txt");
                serversToPush = filterServers(allServers, arguments.serverNumbers);
            } else if (fileExists(jsonConfigPath)) {
                detailOutput.identical("Found deploy-servers.json, loading server configuration");
                allServers = loadServersFromConfig("deploy-servers.json");
                serversToPush = filterServers(allServers, arguments.serverNumbers);
            } else {
                error("No server configuration found. Use 'wheels docker init' or create deploy-servers.txt.");
            }
        }

        if (arrayLen(serversToPush) == 0) {
            error("No servers configured for pushing");
        }

        detailOutput.line();
        detailOutput.statusInfo("Pushing Docker images from #arrayLen(serversToPush)# server(s)...");
        
        // Push from all selected servers
        pushFromServers(serversToPush, arguments.registry, arguments.image, arguments.username, arguments.password, arguments.tag, arguments.namespace);

        detailOutput.line();
        detailOutput.success("Push operations completed on all servers!");
    }

    /**
     * Filter servers based on comma-separated list
     */
    private function filterServers(required array allServers, string serverNumbers="") {
        if (!len(trim(arguments.serverNumbers))) {
            return arguments.allServers;
        }

        var selectedServers = [];
        var numbers = listToArray(arguments.serverNumbers);

        for (var numStr in numbers) {
            var num = val(trim(numStr));
            if (num > 0 && num <= arrayLen(arguments.allServers)) {
                arrayAppend(selectedServers, arguments.allServers[num]);
            }
        }

        if (arrayLen(selectedServers) == 0) {
            return arguments.allServers;
        }

        detailOutput.statusSuccess("Selected #arrayLen(selectedServers)# of #arrayLen(arguments.allServers)# server(s)");
        return selectedServers;
    }

    /**
     * Push from multiple servers
     */
    private function pushFromServers(required array servers, string registry, string image, string username, string password, string tag, string namespace="") {
        var successCount = 0;
        var failureCount = 0;

        for (var i = 1; i <= arrayLen(servers); i++) {
            var serverConfig = servers[i];
            detailOutput.header("Pushing from server #i# of #arrayLen(servers)#: #serverConfig.host#");

            try {
                pushFromServer(serverConfig, arguments.registry, arguments.image, arguments.username, arguments.password, arguments.tag, arguments.namespace);
                successCount++;
                detailOutput.statusSuccess("Push from #serverConfig.host# completed successfully");
            } catch (any e) {
                failureCount++;
                detailOutput.statusFailed("Failed to push from #serverConfig.host#: #e.message#");
            }
        }

        detailOutput.line();
        detailOutput.output("Push Operations Summary:");
        detailOutput.statusSuccess("   Successful: #successCount#");
        if (failureCount > 0) {
            detailOutput.statusFailed("   Failed: #failureCount#");
        }
    }

    /**
     * Push from a single server
     */
    private function pushFromServer(required struct serverConfig, string registry, string image, string username, string password, string tag, string namespace="") {
        var local = {};
        local.host = arguments.serverConfig.host;
        local.user = arguments.serverConfig.user;
        local.port = structKeyExists(arguments.serverConfig, "port") ? arguments.serverConfig.port : 22;

        // Check SSH connection
        if (!testSSHConnection(local.host, local.user, local.port)) {
            error("SSH connection failed to #local.host#");
        }
        detailOutput.statusSuccess("SSH connection successful");

        detailOutput.statusInfo("Registry: " & arguments.registry);
        
        // Determine final image name
        local.projectName = getProjectName();
        local.finalImage = determineImageName(
            arguments.registry,
            arguments.image,
            local.projectName,
            arguments.tag,
            arguments.username,
            arguments.namespace
        );

        detailOutput.statusInfo("Target image: " & local.finalImage);
        
        // Tag the image on the server if it's different (e.g. if tagging project name to full name)
        if (local.finalImage != arguments.image) {
            detailOutput.statusInfo("Tagging image on server: " & arguments.image & " -> " & local.finalImage).toConsole();
            local.tagCmd = "docker tag " & arguments.image & " " & local.finalImage;
            executeRemoteCommand(local.host, local.user, local.port, local.tagCmd);
        }
        
        // Use the final image for the rest of the operation
        arguments.image = local.finalImage;
        
        // Get login command for registry
        local.loginCmd = "";
        if (len(trim(arguments.password))) {
             var loginResult = loginToRegistry(
                registry=arguments.registry, 
                image=arguments.image, 
                username=arguments.username, 
                password=arguments.password, 
                isLocal=false
            );
            local.loginCmd = loginResult.command;
        }
        
        // Execute login on remote server
        if (len(local.loginCmd)) {
            detailOutput.statusInfo("Logging in to registry on remote server...");
            executeRemoteCommand(local.host, local.user, local.port, local.loginCmd);
            detailOutput.statusSuccess("Login successful");
        } else {
            detailOutput.skip("No password provided, skipping login on remote server...");
        }
        
        // Push the image
        detailOutput.statusInfo("Pushing image from remote server...");
        local.pushCmd = "docker push " & arguments.image;
        executeRemoteCommand(local.host, local.user, local.port, local.pushCmd);
        detailOutput.success("Image pushed successfully from #local.host#!");
    }

}