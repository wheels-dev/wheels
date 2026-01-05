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
        local.command = "";
        local.username = arguments.username;
        local.password = arguments.password;
        local.image = arguments.image;
        local.registryUrl = "";
        
        switch(lCase(arguments.registry)) {
            case "dockerhub":
                if (!len(trim(local.username))) {
                    print.line("Enter Docker Hub username:");
                    local.username = ask("");
                }
                
                print.yellowLine("Logging in to Docker Hub...").toConsole();
                
                if (!len(trim(local.password))) {
                    print.line("Enter Docker Hub password or access token:");
                    local.password = ask(message="", mask="*");
                }
                
                if (arguments.isLocal) {
                    local.execCmd = ["docker", "login", "-u", local.username, "--password-stdin"];
                    local.result = runLocalCommandWithInput(local.execCmd, local.password);
                    local.command = "";
                } else {
                    local.command = "echo '" & local.password & "' | docker login -u " & local.username & " --password-stdin";
                }
                break;
                
            case "ecr":
                print.yellowLine("Logging in to AWS ECR...").toConsole();
                print.cyanLine("Note: AWS CLI must be configured with valid credentials").toConsole();
                
                // Extract region from image name
                if (!len(trim(arguments.image))) {
                    error("AWS ECR requires image name to determine region. Use --image=123456789.dkr.ecr.region.amazonaws.com/repo:tag");
                }
                
                var region = extractAWSRegion(arguments.image);
                print.cyanLine("Detected region: " & region).toConsole();
                
                if (arguments.isLocal) {
                    // aws ecr get-login-password --region region | docker login --username AWS --password-stdin account.dkr.ecr.region.amazonaws.com
                    // This is complex to run as a single array command due to pipes. 
                    // Best to run AWS command to get password, then docker login?
                    // Or rely on shell=true if possible? CommandBox doesn't expose shell=true easily in generic calls.
                    // Let's print command for user to run manually if it fails?
                    // Or execute via shell wrapper?
                    // Windows: cmd /c "aws ... | docker login ..."
                    
                    var registryUrl = listFirst(arguments.image, "/");
                    
                    if (server.os.name contains "Windows") {
                        local.loginCmd = ["cmd", "/c", "aws ecr get-login-password --region " & region & " | docker login --username AWS --password-stdin " & registryUrl];
                    } else {
                        local.loginCmd = ["bash", "-c", "aws ecr get-login-password --region " & region & " | docker login --username AWS --password-stdin " & registryUrl];
                    }
                    
                    local.result = runLocalCommand(local.loginCmd);
                } else {
                    // Remote command
                    return "aws ecr get-login-password --region " & region & " | docker login --username AWS --password-stdin " & listFirst(arguments.image, "/");
                }
                break;
                
            case "gcr":
                print.yellowLine("Logging in to Google Container Registry...").toConsole();
                local.keyFile = "";
                
                if (fileExists(getCWD() & "/gcr-key.json")) {
                    local.keyFile = getCWD() & "/gcr-key.json";
                    print.cyanLine("Found service account key: gcr-key.json").toConsole();
                } else {
                    print.line("Enter path to service account key file (JSON):");
                    local.keyFile = ask(message="");
                }
                
                if (arguments.isLocal) {
                    if (server.os.name contains "Windows") {
                        local.loginCmd = ["cmd", "/c", "type " & local.keyFile & " | docker login -u _json_key --password-stdin https://gcr.io"];
                    } else {
                        local.loginCmd = ["bash", "-c", "cat " & local.keyFile & " | docker login -u _json_key --password-stdin https://gcr.io"];
                    }
                    local.result = runLocalCommand(local.loginCmd);
                } else {
                    // Start reading...
                    var keyContent = fileRead(local.keyFile);
                    // Compress JSON slightly to start
                    keyContent = replace(keyContent, chr(10), "", "all");
                    keyContent = replace(keyContent, chr(13), "", "all");
                    // Escape single quotes
                    keyContent = replace(keyContent, "'", "'\''", "all");
                    
                    return "echo '" & keyContent & "' | docker login -u _json_key --password-stdin https://gcr.io";
                }
                break;
                
            case "acr":
                // 1. Resolve URL first
                local.registryUrl = "";
                if (len(trim(local.image)) && find("/", local.image)) {
                    local.registryUrl = listFirst(local.image, "/");
                } else {
                    var deployConfig = getDeployConfig();
                    if (structKeyExists(deployConfig, "image") && len(trim(deployConfig.image)) && find("/", deployConfig.image)) {
                        local.image = deployConfig.image;
                        local.registryUrl = listFirst(local.image, "/");
                    } else {
                        print.line("Enter Azure ACR Registry URL (e.g. myacr.azurecr.io):");
                        local.registryUrl = ask(message="");
                        if (!len(trim(local.registryUrl))) {
                             error("Azure ACR requires a registry URL.");
                        }
                    }
                }

                // 2. Resolve Username
                if (!len(trim(local.username))) {
                    print.line("Enter Azure ACR username:");
                    local.username = ask("");
                }

                print.yellowLine("Logging in to Azure Container Registry: #local.registryUrl#").toConsole();
                
                // 3. Resolve Password
                 if (!len(trim(local.password))) {
                    print.line("Enter ACR password:");
                    local.password = ask(message="", mask="*");
                }
                
                if (arguments.isLocal) {
                    local.execCmd = ["docker", "login", local.registryUrl, "-u", local.username, "--password-stdin"];
                    local.result = runLocalCommandWithInput(local.execCmd, local.password);
                    local.command = "";
                } else {
                    local.command = "echo '" & local.password & "' | docker login " & local.registryUrl & " -u " & local.username & " --password-stdin";
                }
                break;
                
            case "ghcr":
                if (!len(trim(local.username))) {
                    print.line("Enter GitHub username:");
                    local.username = ask("");
                }
                print.yellowLine("Logging in to GitHub Container Registry...").toConsole();
                
                if (!len(trim(local.password))) {
                    print.line("Enter Personal Access Token (PAT) with write:packages scope:");
                    local.password = ask(message="", mask="*");
                }
                
                if (arguments.isLocal) {
                    local.execCmd = ["docker", "login", "ghcr.io", "-u", local.username, "--password-stdin"];
                    local.result = runLocalCommandWithInput(local.execCmd, local.password);
                    local.command = "";
                } else {
                    local.command = "echo '" & local.password & "' | docker login ghcr.io -u " & local.username & " --password-stdin";
                }
                break;
                
            case "private":
                // 1. Resolve URL first
                local.registryUrl = "";
                if (len(trim(local.image)) && find("/", local.image)) {
                    local.registryUrl = listFirst(local.image, "/");
                } else {
                    var deployConfig = getDeployConfig();
                    if (structKeyExists(deployConfig, "image") && len(trim(deployConfig.image)) && find("/", deployConfig.image)) {
                        local.image = deployConfig.image;
                        local.registryUrl = listFirst(local.image, "/");
                    } else {
                        print.line("Enter Private Registry URL (e.g. 192.168.1.10:5000 or registry.example.com):");
                        local.registryUrl = ask(message="");
                        if (!len(trim(local.registryUrl))) {
                             error("Private registry URL is required.");
                        }
                    }
                }

                // 2. Resolve Username
                if (!len(trim(local.username))) {
                    print.line("Enter registry username:");
                    local.username = ask("");
                }
                
                print.yellowLine("Logging in to private registry: #local.registryUrl#").toConsole();
                
                // 3. Resolve Password
                if (!len(trim(local.password))) {
                    print.line("Enter registry password:");
                    local.password = ask(message="", mask="*");
                }
                
                if (arguments.isLocal) {
                    local.execCmd = ["docker", "login", local.registryUrl, "-u", local.username, "--password-stdin"];
                    local.result = runLocalCommandWithInput(local.execCmd, local.password);
                    local.command = "";
                } else {
                    local.command = "echo '" & local.password & "' | docker login " & local.registryUrl & " -u " & local.username & " --password-stdin";
                }
                break;
        }
        
        if (arguments.isLocal) {
            print.greenLine("Login successful").toConsole();
        }
        
        return {
            "command": local.command,
            "username": local.username,
            "password": local.password,
            "image": local.image,
            "registryUrl": local.registryUrl
        };
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
     * Get project name from deploy.yml, box.json (slug/name), or current directory
     */
    public function getProjectName() {
        // 1. Try to read config/deploy.yml first (user's preferred source)
        try {
            var deployConfig = getDeployConfig();
            if (structKeyExists(deployConfig, "name") && len(trim(deployConfig.name))) {
                return trim(deployConfig.name);
            }
        } catch (any e) {}

        // 2. Try to read box.json for unique identity
        try {
            var boxJsonPath = getCWD() & "/box.json";
            if (fileExists(boxJsonPath)) {
                var boxJson = deserializeJSON(fileRead(boxJsonPath));
                
                // Prioritize 'slug'
                if (structKeyExists(boxJson, "slug") && len(trim(boxJson.slug))) {
                     return trim(boxJson.slug);
                }
                
                // Fallback to 'name', slugified
                if (structKeyExists(boxJson, "name") && len(trim(boxJson.name))) {
                     var pName = lCase(trim(boxJson.name));
                     pName = reReplace(pName, "[^a-z0-9\-]", "-", "all");
                     pName = reReplace(pName, "\-+", "-", "all");
                     pName = reReplace(pName, "^\-|\-$", "", "all");
                     if (len(pName)) return pName;
                }
            }
        } catch (any e) {
            // Ignore errors (missing file, invalid JSON), fall back to directory name
        }

        var cwd = getCWD();
        var dirName = listLast(cwd, "\/");
        dirName = lCase(dirName);
        dirName = reReplace(dirName, "[^a-z0-9\-]", "-", "all");
        dirName = reReplace(dirName, "\-+", "-", "all");
        dirName = reReplace(dirName, "^\-|\-$", "", "all");
        return len(dirName) ? dirName : "wheels-app";
    }

    /**
     * Read and parse config/deploy.yml
     * Returns a struct with 'name', 'image', and 'servers' array
     */
    public function getDeployConfig() {
        var configPath = fileSystemUtil.resolvePath("config/deploy.yml");
        var config = { "name": "", "image": "", "servers": [] };

        if (!fileExists(configPath)) {
            return config;
        }

        try {
            var content = fileRead(configPath);
            var lines = listToArray(content, chr(10));
            var currentServer = {};

            for (var line in lines) {
                var trimmedLine = trim(line);
                if (!len(trimmedLine) || left(trimmedLine, 1) == "##") continue;

                // Simple YAML parser for the specific format we generate
                if (find("name:", trimmedLine) == 1) {
                    config.name = trim(replace(trimmedLine, "name:", ""));
                } else if (find("image:", trimmedLine) == 1) {
                    config.image = trim(replace(trimmedLine, "image:", ""));
                } else if (find("- host:", trimmedLine)) {
                    // New server entry
                    if (!structIsEmpty(currentServer)) {
                        arrayAppend(config.servers, currentServer);
                    }
                    currentServer = { "host": trim(replace(trimmedLine, "- host:", "")), "port": 22 };
                } else if (find("user:", trimmedLine) && !structIsEmpty(currentServer)) {
                    currentServer.user = trim(replace(trimmedLine, "user:", ""));
                } else if (find("port:", trimmedLine) && !structIsEmpty(currentServer)) {
                    currentServer.port = val(trim(replace(trimmedLine, "port:", "")));
                } else if (find("role:", trimmedLine) && !structIsEmpty(currentServer)) {
                    currentServer.role = trim(replace(trimmedLine, "role:", ""));
                }
            }
            // Append last server
            if (!structIsEmpty(currentServer)) {
                arrayAppend(config.servers, currentServer);
            }
        } catch (any e) {
            // Log error or ignore
        }

        return config;
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
        // Use namespace if provided, otherwise use username
        local.prefix = len(trim(arguments.namespace)) ? arguments.namespace : arguments.username;

        // If custom image is specified
        if (len(trim(arguments.customImage))) {
            local.img = arguments.customImage;
            
            // If it's a naked image name (no slash) and we have a prefix, apply it (for Docker Hub/GHCR)
            if (!find("/", local.img) && len(trim(local.prefix)) && !listFindNoCase("ecr,gcr,acr", arguments.registry)) {
                local.img = local.prefix & "/" & local.img;
            }
            
            // If it doesn't have a tag, append the provided tag
            if (!find(":", local.img)) {
                local.img &= ":" & arguments.tag;
            }
            
            return local.img;
        }
        
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
                local.registryUrl = "";
                // Try from deploy.yml
                var deployConfig = getDeployConfig();
                if (structKeyExists(deployConfig, "image") && len(trim(deployConfig.image))) {
                    local.registryUrl = listFirst(deployConfig.image, "/");
                } else {
                    print.line("Enter Azure ACR Registry URL (e.g. myacr.azurecr.io):");
                    local.registryUrl = ask("");
                    if (!len(trim(local.registryUrl))) {
                        error("Azure ACR requires a registry URL to determine image path.");
                    }
                }
                return local.registryUrl & "/" & arguments.projectName & ":" & arguments.tag;
                
            case "ghcr":
                if (!len(trim(local.prefix))) {
                    error("GitHub Container Registry requires --username or --namespace parameter");
                }
                return "ghcr.io/" & lCase(local.prefix) & "/" & arguments.projectName & ":" & arguments.tag;
                
            case "private":
                local.registryUrl = "";
                // Try from deploy.yml
                var deployConfig = getDeployConfig();
                if (structKeyExists(deployConfig, "image") && len(trim(deployConfig.image))) {
                    local.registryUrl = listFirst(deployConfig.image, "/");
                } else {
                    print.line("Enter Private Registry URL (e.g. 192.168.1.10:5000 or registry.example.com):");
                    local.registryUrl = ask("");
                    if (!len(trim(local.registryUrl))) {
                        error("Private registry requires a registry URL to determine image path.");
                    }
                }
                
                local.finalImg = local.registryUrl & "/";
                if (len(trim(local.prefix))) {
                    local.finalImg &= local.prefix & "/";
                }
                local.finalImg &= arguments.projectName & ":" & arguments.tag;
                return local.finalImg;
                
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
        local.output = arrayToList(local.outputParts, chr(10));
        
        if (local.exitCode neq 0) {
            error("Command failed with exit code: " & local.exitCode);
        }

        return { exitCode: local.exitCode, output: local.output };
    }
    
    /**
     * Run an interactive command (inheriting stdin/stdout)
     * Note: This implementation in CommandBox 5+ can use run() with .toConsole()
     * But for true interactivity (SSH), we need Java ProcessBuilder with inheritance
     */
    public function runInteractiveCommand(array cmd, boolean inheritInput=false) {
        // For simple output streaming without input interaction
        // return runLocalCommand(arguments.cmd, true);

        // For true interactive shell (e.g. ssh, docker exec -it)
        var local = {};
        local.javaCmd = createObject("java","java.util.ArrayList").init();
        for (var c in arguments.cmd) {
            local.javaCmd.add(c & "");
        }

        local.pb = createObject("java","java.lang.ProcessBuilder").init(local.javaCmd);
        local.currentDir = createObject("java", "java.io.File").init(getCWD());
        local.pb.directory(local.currentDir);
        
        // Inherit IO - this allows the command to take over the console
        local.pb.inheritIO();
        
        local.proc = local.pb.start();
        local.exitCode = local.proc.waitFor();
        
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
