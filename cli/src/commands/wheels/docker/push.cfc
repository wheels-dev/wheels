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

        // Load defaults from config if available
        var configPath = fileSystemUtil.resolvePath("docker-config.json");
        if (fileExists(configPath)) {
            try {
                var config = deserializeJSON(fileRead(configPath));
                
                if (!len(trim(arguments.registry)) && structKeyExists(config, "registry")) {
                    arguments.registry = config.registry;
                    print.cyanLine("Using registry from config: #arguments.registry#").toConsole();
                }
                
                if (!len(trim(arguments.username)) && structKeyExists(config, "username")) {
                    arguments.username = config.username;
                    print.cyanLine("Using username from config: #arguments.username#").toConsole();
                }
                
                if (!len(trim(arguments.image)) && structKeyExists(config, "image")) {
                    arguments.image = config.image;
                }
            } catch (any e) {
                // Ignore config errors
            }
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
        print.line();
        print.boldMagentaLine("Wheels Docker Push - Local");
        print.line();

        // Check if Docker is installed locally
        if (!isDockerInstalled()) {
            error("Docker is not installed or not accessible. Please ensure Docker Desktop or Docker Engine is running.");
        }

        // Get project name
        local.projectName = getProjectName();
        local.localImageName = local.projectName & ":latest";
        if(!checkLocalImageExists(local.projectName)){
            local.localImageName = local.projectName & "-app:latest";
        }
        
        print.cyanLine("Project: " & local.projectName).toConsole();
        print.cyanLine("Registry: " & arguments.registry).toConsole();
        print.line();
        
        // Build image if requested
        if (arguments.build) {
            print.yellowLine("Building image before push...").toConsole();
            buildLocalImage();
        }
        
        // Check if local image exists
        if (!checkLocalImageExists(local.localImageName)) {
            print.yellowLine("Local image '#local.localImageName#' not found.").toConsole();
            print.line("Would you like to build it now? (y/n)").toConsole();
            local.answer = ask("");
            if (lCase(local.answer) == "y") {
                buildLocalImage();
            } else {
                error("Image not found. Build the image first with: wheels docker build --local");
            }
        }
        
        print.greenLine("Found local image: " & local.localImageName).toConsole();
        
        // Determine final image name based on registry and user input
        local.finalImage = determineImageName(
            arguments.registry,
            arguments.customImage,
            local.projectName,
            arguments.tag,
            arguments.username,
            arguments.namespace
        );
        
        print.cyanLine("Target image: " & local.finalImage).toConsole();
        print.line();
        
        // Tag the image if needed
        if (local.finalImage != local.localImageName) {
            print.yellowLine("Tagging image: " & local.localImageName & " -> " & local.finalImage).toConsole();
            try {
                runLocalCommand(["docker", "tag", local.localImageName, local.finalImage]);
                print.greenLine("Image tagged successfully").toConsole();
            } catch (any e) {
                error("Failed to tag image: " & e.message);
            }
        }
        
        // Login to registry if password provided, otherwise assume already logged in
        if (len(trim(arguments.password))) {
            loginToRegistry(
                registry=arguments.registry, 
                image=local.finalImage, 
                username=arguments.username, 
                password=arguments.password, 
                isLocal=true
            );
        } else {
            print.yellowLine("No password provided, attempting to push with existing credentials...").toConsole();
        }
        
        // Push the image
        print.yellowLine("Pushing image to " & arguments.registry & "...").toConsole();
        
        try {
            runLocalCommand(["docker", "push", local.finalImage]);
            print.line();
            print.boldGreenLine("Image pushed successfully to " & arguments.registry & "!").toConsole();
            print.line();
            print.yellowLine("Image: " & local.finalImage).toConsole();
            print.yellowLine("Pull with: docker pull " & local.finalImage).toConsole();
            print.line();
        } catch (any e) {
            print.redLine("Failed to push image: " & e.message).toConsole();
            print.line();
            print.yellowLine("You may need to login first.").toConsole();
            print.line("Try running: wheels docker login --registry=" & arguments.registry & " --username=" & arguments.username).toConsole();
            print.line("Or provide a password/token with --password").toConsole();
            error("Push failed");
        }
    }
    
    /**
     * Build the local image
     */
    private function buildLocalImage() {
        print.yellowLine("Building Docker image...").toConsole();
        print.line();
        
        // Check for docker-compose file
        local.useCompose = hasDockerComposeFile();
        
        if (local.useCompose) {
            runLocalCommand(["docker", "compose", "build"]);
        } else {
            local.projectName = getProjectName();
            runLocalCommand(["docker", "build", "-t", local.projectName & ":latest", "."]);
        }
        
        print.line();
        print.greenLine("Build completed successfully").toConsole();
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
        var allServers = [];
        var serversToPush = [];

        if (fileExists(textConfigPath)) {
            print.cyanLine("Found deploy-servers.txt, loading server configuration").toConsole();
            allServers = loadServersFromTextFile("deploy-servers.txt");
            serversToPush = filterServers(allServers, arguments.serverNumbers);
        } else if (fileExists(jsonConfigPath)) {
            print.cyanLine("Found deploy-servers.json, loading server configuration").toConsole();
            allServers = loadServersFromConfig("deploy-servers.json");
            serversToPush = filterServers(allServers, arguments.serverNumbers);
        } else {
            error("No server configuration found. Create deploy-servers.txt or deploy-servers.json in your project root.");
        }

        if (arrayLen(serversToPush) == 0) {
            error("No servers configured for pushing");
        }

        print.line().boldCyanLine("Pushing Docker images from #arrayLen(serversToPush)# server(s)...").toConsole();

        // Push from all selected servers
        pushFromServers(serversToPush, arguments.registry, arguments.image, arguments.username, arguments.password, arguments.tag);

        print.line().boldGreenLine("Push operations completed on all servers!").toConsole();
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

        print.greenLine("Selected #arrayLen(selectedServers)# of #arrayLen(arguments.allServers)# server(s)").toConsole();
        return selectedServers;
    }

    /**
     * Push from multiple servers
     */
    private function pushFromServers(required array servers, string registry, string image, string username, string password, string tag) {
        var successCount = 0;
        var failureCount = 0;

        for (var i = 1; i <= arrayLen(servers); i++) {
            var serverConfig = servers[i];
            print.line().boldCyanLine("---------------------------------------").toConsole();
            print.boldCyanLine("Pushing from server #i# of #arrayLen(servers)#: #serverConfig.host#").toConsole();
            print.line().boldCyanLine("---------------------------------------").toConsole();

            try {
                pushFromServer(serverConfig, arguments.registry, arguments.image, arguments.username, arguments.password, arguments.tag);
                successCount++;
                print.greenLine("Push from #serverConfig.host# completed successfully").toConsole();
            } catch (any e) {
                failureCount++;
                print.redLine("Failed to push from #serverConfig.host#: #e.message#").toConsole();
            }
        }

        print.line().toConsole();
        print.boldCyanLine("Push Operations Summary:").toConsole();
        print.greenLine("   Successful: #successCount#").toConsole();
        if (failureCount > 0) {
            print.redLine("   Failed: #failureCount#").toConsole();
        }
    }

    /**
     * Push from a single server
     */
    private function pushFromServer(required struct serverConfig, string registry, string image, string username, string password, string tag) {
        var local = {};
        local.host = arguments.serverConfig.host;
        local.user = arguments.serverConfig.user;
        local.port = structKeyExists(arguments.serverConfig, "port") ? arguments.serverConfig.port : 22;

        // Check SSH connection
        if (!testSSHConnection(local.host, local.user, local.port)) {
            error("SSH connection failed to #local.host#");
        }
        print.greenLine("SSH connection successful").toConsole();

        print.cyanLine("Registry: " & arguments.registry).toConsole();
        print.cyanLine("Image: " & arguments.image).toConsole();
        
        // Apply additional tag if specified
        if (len(trim(arguments.tag))) {
            print.yellowLine("Tagging image with additional tag: " & arguments.tag).toConsole();
            local.tagCmd = "docker tag " & arguments.image & " " & arguments.tag;
            executeRemoteCommand(local.host, local.user, local.port, local.tagCmd);
            arguments.image = arguments.tag;
        }
        
        // Get login command for registry
        local.loginCmd = "";
        if (len(trim(arguments.password))) {
             local.loginCmd = loginToRegistry(
                registry=arguments.registry, 
                image=arguments.image, 
                username=arguments.username, 
                password=arguments.password, 
                isLocal=false
            );
        }
        
        // Execute login on remote server
        if (len(local.loginCmd)) {
            print.yellowLine("Logging in to registry on remote server...").toConsole();
            executeRemoteCommand(local.host, local.user, local.port, local.loginCmd);
            print.greenLine("Login successful").toConsole();
        } else {
            print.yellowLine("No password provided, skipping login on remote server...").toConsole();
        }
        
        // Push the image
        print.yellowLine("Pushing image from remote server...").toConsole();
        local.pushCmd = "docker push " & arguments.image;
        executeRemoteCommand(local.host, local.user, local.port, local.pushCmd);
        
        print.boldGreenLine("Image pushed successfully from #local.host#!").toConsole();
    }

    // =============================================================================
    // HELPER FUNCTIONS
    // =============================================================================

    private function loadServersFromTextFile(required string textFile) {
        var filePath = fileSystemUtil.resolvePath(arguments.textFile);
        var fileContent = fileRead(filePath);
        var lines = listToArray(fileContent, chr(10));
        var servers = [];

        for (var line in lines) {
            line = trim(line);
            if (len(line) == 0 || left(line, 1) == "##") continue;
            
            var parts = listToArray(line, " " & chr(9), true);
            if (arrayLen(parts) < 2) continue;

            arrayAppend(servers, {
                "host": trim(parts[1]),
                "user": trim(parts[2]),
                "port": arrayLen(parts) >= 3 ? val(trim(parts[3])) : 22
            });
        }

        return servers;
    }

    private function loadServersFromConfig(required string configFile) {
        var configPath = fileSystemUtil.resolvePath(arguments.configFile);
        var configContent = fileRead(configPath);
        var config = deserializeJSON(configContent);
        return config.servers;
    }

    private function testSSHConnection(string host, string user, numeric port) {
        print.yellowLine("Testing SSH connection to " & arguments.host & "...").toConsole();
        var result = runProcess([
            "ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=10",
            "-p", arguments.port, arguments.user & "@" & arguments.host, "echo connected"
        ]);
        return (result.exitCode eq 0);
    }

    private function executeRemoteCommand(string host, string user, numeric port, string cmd) {
        var result = runProcess([
            "ssh", "-o", "BatchMode=yes", "-p", arguments.port,
            arguments.user & "@" & arguments.host, arguments.cmd
        ]);

        if (result.exitCode neq 0) {
            error("Remote command failed: " & arguments.cmd);
        }

        return result;
    }

    private function runProcess(array cmd) {
        var local = {};
        local.javaCmd = createObject("java","java.util.ArrayList").init();
        for (var c in arguments.cmd) {
            local.javaCmd.add(c & "");
        }

        local.pb = createObject("java","java.lang.ProcessBuilder").init(local.javaCmd);
        local.pb.redirectErrorStream(true);
        local.proc = local.pb.start();

        local.isr = createObject("java","java.io.InputStreamReader").init(local.proc.getInputStream(), "UTF-8");
        local.br = createObject("java","java.io.BufferedReader").init(local.isr);
        local.outputParts = [];

        while (true) {
            local.line = local.br.readLine();
            if (isNull(local.line)) break;
            arrayAppend(local.outputParts, local.line);
            print.line(local.line).toConsole();
        }

        local.exitCode = local.proc.waitFor();
        local.output = arrayToList(local.outputParts, chr(10));

        return { exitCode: local.exitCode, output: local.output };
    }
}