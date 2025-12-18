/**
 * Base component for Docker commands
 */
component extends="../base" {

    /**
     * Login to container registry
     * 
     * @registry Registry type: dockerhub, ecr, gcr, acr, ghcr, private
     * @image Image name (used for extracting region/registry info for some providers)
     * @username Registry username
     * @password Registry password
     * @isLocal Whether to execute login locally or return command string
     */
    public function loginToRegistry(
        required string registry, 
        string image="", 
        string username="", 
        string password="", 
        boolean isLocal=true
    ) {
        var local = {};
        
        switch(lCase(arguments.registry)) {
            case "dockerhub":
                if (!len(trim(arguments.username))) {
                    error("Docker Hub username is required. Use --username=<your-dockerhub-username>");
                }
                
                print.yellowLine("Logging in to Docker Hub...").toConsole();
                
                if (!len(trim(arguments.password))) {
                    print.line("Enter Docker Hub password or access token:");
                    arguments.password = ask("");
                }
                
                if (arguments.isLocal) {
                    local.loginCmd = ["docker", "login", "-u", arguments.username, "--password-stdin"];
                    local.result = runLocalCommandWithInput(local.loginCmd, arguments.password);
                } else {
                    return "echo '" & arguments.password & "' | docker login -u " & arguments.username & " --password-stdin";
                }
                break;
                
            case "ecr":
                print.yellowLine("Logging in to AWS ECR...").toConsole();
                print.cyanLine("Note: AWS CLI must be configured with valid credentials").toConsole();
                
                // Extract region from image name
                if (!len(trim(arguments.image))) {
                    error("AWS ECR requires image path to determine region. Use --image=123456789.dkr.ecr.region.amazonaws.com/repo:tag");
                }
                local.region = extractAWSRegion(arguments.image);
                
                if (arguments.isLocal) {
                    // Get ECR login token
                    local.ecrCmd = ["aws", "ecr", "get-login-password", "--region", local.region];
                    local.tokenResult = runLocalCommand(local.ecrCmd, false);
                    
                    // Extract registry URL from image
                    local.registryUrl = listFirst(arguments.image, "/");
                    
                    // Login to ECR
                    local.loginCmd = ["docker", "login", "--username", "AWS", "--password-stdin", local.registryUrl];
                    local.result = runLocalCommandWithInput(local.loginCmd, local.tokenResult.output);
                } else {
                    return "aws ecr get-login-password --region " & local.region & " | docker login --username AWS --password-stdin " & listFirst(arguments.image, "/");
                }
                break;
                
            case "gcr":
                print.yellowLine("Logging in to Google Container Registry...").toConsole();
                print.cyanLine("Note: gcloud CLI must be configured").toConsole();
                
                if (arguments.isLocal) {
                    runLocalCommand(["gcloud", "auth", "configure-docker"]);
                } else {
                    return "gcloud auth configure-docker";
                }
                break;
                
            case "acr":
                print.yellowLine("Logging in to Azure Container Registry...").toConsole();
                print.cyanLine("Note: Azure CLI must be configured").toConsole();
                
                // Extract registry name from image
                if (!len(trim(arguments.image))) {
                    error("Azure ACR requires image path to determine registry. Use --image=registry.azurecr.io/image:tag");
                }
                local.registryName = listFirst(arguments.image, ".");
                
                if (arguments.isLocal) {
                    runLocalCommand(["az", "acr", "login", "--name", local.registryName]);
                } else {
                    return "az acr login --name " & local.registryName;
                }
                break;
                
            case "ghcr":
                if (!len(trim(arguments.username))) {
                    error("GitHub username is required. Use --username=<your-github-username>");
                }
                
                print.yellowLine("Logging in to GitHub Container Registry...").toConsole();
                
                if (!len(trim(arguments.password))) {
                    print.line("Enter GitHub Personal Access Token:");
                    arguments.password = ask("");
                }
                
                if (arguments.isLocal) {
                    local.loginCmd = ["docker", "login", "ghcr.io", "-u", arguments.username, "--password-stdin"];
                    local.result = runLocalCommandWithInput(local.loginCmd, arguments.password);
                } else {
                    return "echo '" & arguments.password & "' | docker login ghcr.io -u " & arguments.username & " --password-stdin";
                }
                break;
                
            case "private":
                if (!len(trim(arguments.username))) {
                    error("Registry username is required. Use --username=<registry-username>");
                }
                
                print.yellowLine("Logging in to private registry...").toConsole();
                
                if (!len(trim(arguments.password))) {
                    print.line("Enter registry password:");
                    arguments.password = ask("");
                }
                
                local.registryUrl = "";
                if (len(trim(arguments.image))) {
                    local.registryUrl = listFirst(arguments.image, "/");
                } else {
                     error("Private registry requires image path to determine registry URL. Use --image=registry.example.com:port/image:tag");
                }
                
                if (arguments.isLocal) {
                    local.loginCmd = ["docker", "login", local.registryUrl, "-u", arguments.username, "--password-stdin"];
                    local.result = runLocalCommandWithInput(local.loginCmd, arguments.password);
                } else {
                    return "echo '" & arguments.password & "' | docker login " & local.registryUrl & " -u " & arguments.username & " --password-stdin";
                }
                break;
        }
        
        print.greenLine("Login successful").toConsole();
        return "";
    }

    /**
     * Extract AWS region from ECR image path
     */
    public function extractAWSRegion(string imagePath) {
        // Format: 123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
        var parts = listToArray(arguments.imagePath, ".");
        if (arrayLen(parts) >= 4) {
            return parts[4]; // us-east-1
        }
        return "us-east-1"; // default
    }

    /**
     * Check if Docker is installed locally
     */
    public function isDockerInstalled() {
        try {
            var result = runLocalCommand(["docker", "--version"], false);
            return (result.exitCode eq 0);
        } catch (any e) {
            return false;
        }
    }

    /**
     * Check if a local Docker image exists
     */
    public function checkLocalImageExists(required string imageName) {
        try {
            local.result = runLocalCommand(["docker", "image", "inspect", arguments.imageName], false);
            return (local.result.exitCode eq 0);
        } catch (any e) {
            return false;
        }
    }

    /**
     * Get project name from current directory
     */
    public function getProjectName() {
        var cwd = getCWD();
        var dirName = listLast(cwd, "\/");
        dirName = lCase(dirName);
        dirName = reReplace(dirName, "[^a-z0-9\-]", "-", "all");
        dirName = reReplace(dirName, "\-+", "-", "all");
        dirName = reReplace(dirName, "^\-|\-$", "", "all");
        return len(dirName) ? dirName : "wheels-app";
    }

    /**
     * Determine the final image name based on registry and parameters
     */
    public function determineImageName(
        required string registry,
        required string customImage,
        required string projectName,
        required string tag,
        required string username,
        required string namespace
    ) {
        // If custom image is specified, use it
        if (len(trim(arguments.customImage))) {
            return arguments.customImage;
        }
        
        // Use namespace if provided, otherwise use username
        local.prefix = len(trim(arguments.namespace)) ? arguments.namespace : arguments.username;
        
        // Build image name based on registry type
        switch(lCase(arguments.registry)) {
            case "dockerhub":
                if (!len(trim(local.prefix))) {
                    error("Docker Hub requires --username or --namespace parameter");
                }
                return local.prefix & "/" & arguments.projectName & ":" & arguments.tag;
                
            case "ecr":
                error("AWS ECR requires full image path. Use --image=123456789.dkr.ecr.region.amazonaws.com/repo:tag");
                
            case "gcr":
                error("GCR requires full image path. Use --image=gcr.io/project-id/image:tag");
                
            case "acr":
                error("Azure ACR requires full image path. Use --image=registry.azurecr.io/image:tag");
                
            case "ghcr":
                if (!len(trim(local.prefix))) {
                    error("GitHub Container Registry requires --username or --namespace parameter");
                }
                return "ghcr.io/" & lCase(local.prefix) & "/" & arguments.projectName & ":" & arguments.tag;
                
            case "private":
                error("Private registry requires full image path. Use --image=registry.example.com:port/image:tag");
                
            default:
                error("Unsupported registry type");
        }
    }

    /**
     * Run a local system command
     */
    public function runLocalCommand(array cmd, boolean showOutput=true) {
        var local = {};
        local.javaCmd = createObject("java","java.util.ArrayList").init();
        for (var c in arguments.cmd) {
            local.javaCmd.add(c & "");
        }

        local.pb = createObject("java","java.lang.ProcessBuilder").init(local.javaCmd);
        
        // Set working directory to current directory
        local.currentDir = createObject("java", "java.io.File").init(getCWD());
        local.pb.directory(local.currentDir);
        
        local.pb.redirectErrorStream(true);
        local.proc = local.pb.start();

        local.isr = createObject("java","java.io.InputStreamReader").init(local.proc.getInputStream(), "UTF-8");
        local.br = createObject("java","java.io.BufferedReader").init(local.isr);
        local.outputParts = [];

        while (true) {
            local.line = local.br.readLine();
            if (isNull(local.line)) break;
            arrayAppend(local.outputParts, local.line);
            if (arguments.showOutput) {
                print.line(local.line).toConsole();
            }
        }

        local.exitCode = local.proc.waitFor();
        local.output = arrayToList(local.outputParts, chr(10));
        
        if (local.exitCode neq 0 && arguments.showOutput) {
            error("Command failed with exit code: " & local.exitCode);
        }

        return { exitCode: local.exitCode, output: local.output };
    }
    
    /**
     * Run a local command with stdin input (for passwords)
     */
    public function runLocalCommandWithInput(array cmd, string input) {
        var local = {};
        local.javaCmd = createObject("java","java.util.ArrayList").init();
        for (var c in arguments.cmd) {
            local.javaCmd.add(c & "");
        }

        local.pb = createObject("java","java.lang.ProcessBuilder").init(local.javaCmd);
        local.currentDir = createObject("java", "java.io.File").init(getCWD());
        local.pb.directory(local.currentDir);
        local.pb.redirectErrorStream(true);
        local.proc = local.pb.start();

        // Write input to stdin
        local.os = local.proc.getOutputStream();
        local.osw = createObject("java","java.io.OutputStreamWriter").init(local.os, "UTF-8");
        local.osw.write(arguments.input);
        local.osw.flush();
        local.osw.close();

        // Read output
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
        
        if (local.exitCode neq 0) {
            error("Login failed with exit code: " & local.exitCode);
        }

        return { exitCode: local.exitCode };
    }

    /**
     * Run a local system command interactively (inherits IO)
     * Useful for long-running commands or those needing TTY (like logs -f)
     * This prevents hanging by connecting subprocess IO directly to the console
     */
    public function runInteractiveCommand(array cmd, boolean inheritInput=false) {
        var local = {};
        local.javaCmd = createObject("java","java.util.ArrayList").init();
        for (var c in arguments.cmd) {
            local.javaCmd.add(c & "");
        }

        local.pb = createObject("java","java.lang.ProcessBuilder").init(local.javaCmd);
        
        // Set working directory to current directory
        local.currentDir = createObject("java", "java.io.File").init(getCWD());
        local.pb.directory(local.currentDir);
        
        // Inherit Output and Error streams
        var Redirect = createObject("java", "java.lang.ProcessBuilder$Redirect");
        local.pb.redirectOutput(Redirect.INHERIT);
        local.pb.redirectError(Redirect.INHERIT);
        
        // Conditionally inherit Input
        // Only inherit input if explicitly requested (e.g. for interactive shells)
        // Otherwise leave as PIPE to avoid CommandBox shell corruption
        if (arguments.inheritInput) {
            local.pb.redirectInput(Redirect.INHERIT);
        }
        
        try {
            local.proc = local.pb.start();
            local.exitCode = local.proc.waitFor();
        } catch (java.lang.InterruptedException e) {
            // User interrupted (Ctrl+C)
            local.exitCode = 130; // Standard exit code for SIGINT
            
            // Ensure process is destroyed
            if (structKeyExists(local, "proc")) {
                local.proc.destroy();
            }
            
            // Clear the interrupted status of the current thread to prevent side effects in CommandBox
            createObject("java", "java.lang.Thread").currentThread().interrupt();
            // Actually, we want to clear it, so Thread.interrupted() does that.
            // But waitFor() throws exception and clears status.
            // Re-interrupting might cause CommandBox to think it's still interrupted.
            // Let's just print a message.
            print.line().toConsole();
            print.yellowLine("Command interrupted by user.").toConsole();
        } catch (any e) {
            // Check for UserInterruptException (CommandBox specific)
            if (findNoCase("UserInterruptException", e.message) || (structKeyExists(e, "type") && findNoCase("UserInterruptException", e.type))) {
                local.exitCode = 130;
                if (structKeyExists(local, "proc")) {
                    local.proc.destroy();
                }
                print.line().toConsole();
                print.yellowLine("Command interrupted by user.").toConsole();
            } else {
                local.exitCode = 1;
                print.redLine("Error executing command: #e.message#").toConsole();
            }
        }
        
        return { exitCode: local.exitCode };
    }

    /**
     * Check if docker-compose file exists
     */
    public function hasDockerComposeFile() {
        var composeFiles = ["docker-compose.yml", "docker-compose.yaml"];
        for (var composeFile in composeFiles) {
            if (fileExists(getCWD() & "/" & composeFile)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Get exposed port from Dockerfile
     */
    public function getDockerExposedPort() {
        var dockerfilePath = getCWD() & "/Dockerfile";
        if (!fileExists(dockerfilePath)) {
            return "";
        }
        
        var content = fileRead(dockerfilePath);
        var lines = listToArray(content, chr(10));
        
        for (var line in lines) {
            if (reFindNoCase("^EXPOSE\s+[0-9]+", trim(line))) {
                return listLast(trim(line), " ");
            }
        }
        
        return "";
    }

    /**
     * Reconstruct arguments to handle key=value pairs passed as keys
     */
    public function reconstructArgs(required struct args) {
        var newArgs = duplicate(arguments.args);
        
        // Check for args in format "key=value" which CommandBox sometimes passes as keys with empty values
        for (var key in newArgs) {
            if (find("=", key)) {
                var parts = listToArray(key, "=");
                if (arrayLen(parts) >= 2) {
                    var paramName = parts[1];
                    var paramValue = right(key, len(key) - len(paramName) - 1);
                    newArgs[paramName] = paramValue;
                }
            }
        }
        
        return newArgs;
    }

    // =============================================================================
    // SHARED HELPER FUNCTIONS (Moved from deploy.cfc)
    // =============================================================================

    public function getSSHOptions() {
        return [
            "-o", "BatchMode=yes",
            "-o", "PreferredAuthentications=publickey",
            "-o", "StrictHostKeyChecking=no",
            "-o", "ConnectTimeout=10",
            "-o", "ServerAliveInterval=15",
            "-o", "ServerAliveCountMax=3"
        ];
    }

    public function testSSHConnection(string host, string user, numeric port) {
        var local = {};
        print.yellowLine("Testing SSH connection to " & arguments.host & "...").toConsole();
        var sshCmd = ["ssh", "-p", arguments.port];
        sshCmd.addAll(getSSHOptions());
        sshCmd.addAll([arguments.user & "@" & arguments.host, "echo connected"]);
        
        local.result = runLocalCommand(sshCmd);
        return (local.result.exitCode eq 0 and findNoCase("connected", local.result.output));
    }

    public function executeRemoteCommand(string host, string user, numeric port, string cmd) {
        var local = {};
        var sshCmd = ["ssh", "-p", arguments.port];
        sshCmd.addAll(getSSHOptions());
        sshCmd.addAll([arguments.user & "@" & arguments.host, arguments.cmd]);
        
        local.result = runLocalCommand(sshCmd);

        if (local.result.exitCode neq 0) {
            error("Remote command failed: " & arguments.cmd & " (Exit code: " & local.result.exitCode & ")");
        }

        return local.result;
    }

    /**
     * Load servers from simple text file
     * Format: host username [port]
     */
    public function loadServersFromTextFile(required string textFile) {
        var filePath = fileSystemUtil.resolvePath(arguments.textFile);

        if (!fileExists(filePath)) {
            error("Text file not found: #filePath#");
        }

        try {
            var fileContent = fileRead(filePath);
            var lines = listToArray(fileContent, chr(10));
            var servers = [];

            for (var lineNum = 1; lineNum <= arrayLen(lines); lineNum++) {
                var line = trim(lines[lineNum]);

                // Skip empty lines and comments
                if (len(line) == 0 || left(line, 1) == "##") {
                    continue;
                }

                var parts = listToArray(line, " " & chr(9), true);

                if (arrayLen(parts) < 2) {
                    print.yellowLine(" Skipping invalid line #lineNum#: #line#").toConsole();
                    continue;
                }

                var serverConfig = {
                    "host": trim(parts[1]),
                    "user": trim(parts[2]),
                    "port": arrayLen(parts) >= 3 ? val(trim(parts[3])) : 22
                };

                var projectName = getProjectName();
                serverConfig.remoteDir = "/home/#serverConfig.user#/#projectName#";
                serverConfig.imageName = projectName;

                arrayAppend(servers, serverConfig);
            }

            if (arrayLen(servers) == 0) {
                error("No valid servers found in text file");
            }

            print.greenLine("Loaded #arrayLen(servers)# server(s) from text file").toConsole();
            return servers;

        } catch (any e) {
            error("Error reading text file: #e.message#");
        }
    }

    /**
     * Load servers configuration from JSON file
     */
    public function loadServersFromConfig(required string configFile) {
        var configPath = fileSystemUtil.resolvePath(arguments.configFile);

        if (!fileExists(configPath)) {
            error("Config file not found: #configPath#");
        }

        try {
            var configContent = fileRead(configPath);
            var config = deserializeJSON(configContent);

            if (!structKeyExists(config, "servers") || !isArray(config.servers)) {
                error("Invalid config file format. Expected { ""servers"": [ ... ] }");
            }

            if (arrayLen(config.servers) == 0) {
                error("No servers defined in config file");
            }

            for (var i = 1; i <= arrayLen(config.servers); i++) {
                var serverConfig = config.servers[i];
                if (!structKeyExists(serverConfig, "host") || !len(trim(serverConfig.host))) {
                    error("Server #i# is missing required 'host' field");
                }
                if (!structKeyExists(serverConfig, "user") || !len(trim(serverConfig.user))) {
                    error("Server #i# is missing required 'user' field");
                }
                
                var projectName = getProjectName();
                if (!structKeyExists(serverConfig, "port")) {
                    serverConfig.port = 22;
                }
                if (!structKeyExists(serverConfig, "remoteDir")) {
                    serverConfig.remoteDir = "/home/#serverConfig.user#/#projectName#";
                }
                if (!structKeyExists(serverConfig, "imageName")) {
                    serverConfig.imageName = projectName;
                }
            }

            print.greenLine("Loaded #arrayLen(config.servers)# server(s) from config file").toConsole();
            return config.servers;

        } catch (any e) {
            error("Error parsing config file: #e.message#");
        }
    }

}
