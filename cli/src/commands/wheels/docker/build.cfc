/**
 * Unified Docker build command for Wheels apps
 *
 * {code:bash}
 * wheels docker build --local
 * wheels docker build --local --nocache
 * wheels docker build --remote
 * wheels docker build --remote --servers=1,3
 * {code}
 */
component extends="DockerCommand" {

    property name="detailOutput" inject="DetailOutputService@wheels-cli";

    /**
     * @local Build Docker image on local machine
     * @remote Build Docker image on remote server(s)
     * @servers Comma-separated list of server numbers to build on (e.g., "1,3,5") - for remote only
     * @nocache Build without using cache
     * @pull Always attempt to pull a newer version of the base image
     */
    function run(
        boolean local=false,
        boolean remote=false,
        string servers="",
        boolean nocache=false,
        boolean pull=false
    ) {
        // Ensure we are in a Wheels app
        requireWheelsApp(getCWD());

        // Check if Docker config exists (created by wheels docker init)
        if (!hasDockerConfig()) {
            detailOutput.error("Docker configuration not found. Please run 'wheels docker init' first.");
            detailOutput.output("This command creates the necessary Docker files (Dockerfile, docker-compose.yml, etc.)");
            return;
        }

        // Reconstruct arguments for handling --key=value style
        arguments=reconstructArgs(arguments);
        
        // set local as default if neither specified
        if (!arguments.local && !arguments.remote) {
            arguments.local=true;
        }
        
        if (arguments.local && arguments.remote) {
            detailOutput.error("Cannot specify both --local and --remote. Please choose one.");
            return;
        }
        
        // Route to appropriate build method
        if (arguments.local) {
            buildLocal(arguments.nocache, arguments.pull);
        } else {
            buildRemote(arguments.servers, arguments.nocache, arguments.pull);
        }
    }
    
    // =============================================================================
    // LOCAL BUILD
    // =============================================================================
    
    private function buildLocal(boolean nocache, boolean pull) {
        detailOutput.header("Wheels Docker Local Build");
        
        // Check if Docker is installed locally
        if (!isDockerInstalled()) {
            detailOutput.error("Docker is not installed or not accessible. Please ensure Docker Desktop or Docker Engine is running.");
            return;
        }

        // Check for docker-compose file
        local.useCompose = hasDockerComposeFile();
        
        if (local.useCompose) {
            detailOutput.statusSuccess("Found docker-compose file, will build using docker-compose");
            
            // Build command array
            local.buildCmd = ["docker", "compose", "build"];
            
            if (arguments.nocache) {
                arrayAppend(local.buildCmd, "--no-cache");
            }
            
            if (arguments.pull) {
                arrayAppend(local.buildCmd, "--pull");
            }
            
            detailOutput.statusInfo("Building services with docker-compose...");
            detailOutput.statusInfo("Executing: " & arrayToList(local.buildCmd, " "));
            runLocalCommand(local.buildCmd);
            
            detailOutput.line();
            detailOutput.statusSuccess("Docker Compose services built successfully!");
            detailOutput.line();
            detailOutput.output("View images with: docker images");
            detailOutput.output("Start services with: wheels docker deploy --local");
            detailOutput.line();
            
        } else {
            // Check for Dockerfile
            local.dockerfilePath = getCWD() & "/Dockerfile";
            if (!fileExists(local.dockerfilePath)) {
                detailOutput.error("No Dockerfile or docker-compose.yml found in current directory");
                return;
            }
            
            detailOutput.statusSuccess("Found Dockerfile, will build using standard docker build");
            
            var config = resolveConfig();
            
            detailOutput.statusInfo("Building Docker image: " & config.image);
            
            // Build command array
            local.buildCmd = ["docker", "build", "-t", config.image];
            
            if (arguments.nocache) {
                arrayAppend(local.buildCmd, "--no-cache");
            }
            
            if (arguments.pull) {
                arrayAppend(local.buildCmd, "--pull");
            }
            
            arrayAppend(local.buildCmd, ".");
            
            detailOutput.statusInfo("Executing: " & arrayToList(local.buildCmd, " "));

            runLocalCommand(local.buildCmd);
            
            detailOutput.line();
            detailOutput.statusSuccess("Docker image built successfully!");
            detailOutput.line();
            detailOutput.output("View image with: docker images " & config.image);
            detailOutput.output("Run container with: wheels docker deploy --local");
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
    // REMOTE BUILD
    // =============================================================================
    
    private function buildRemote(string serverNumbers, boolean nocache, boolean pull) {
        var config = resolveConfig();
        
        // Check for deploy-servers file (text or json) in current directory
        var textConfigPath = fileSystemUtil.resolvePath("deploy-servers.txt");
        var jsonConfigPath = fileSystemUtil.resolvePath("deploy-servers.json");
        var ymlConfigPath = fileSystemUtil.resolvePath("config/deploy.yml");
        var allServers = [];
        var serversToBuild = [];
        var projectName = config.name;

        if (len(trim(arguments.serverNumbers)) == 0 && fileExists(ymlConfigPath)) {
            var deployConfig = readDeployConfig(ymlConfigPath);
            if (arrayLen(deployConfig.servers)) {
                detailOutput.identical("Found config/deploy.yml, loading server configuration");
                allServers = deployConfig.servers;
                
                // Add default remoteDir if not present
                for (var s in allServers) {
                    if (!structKeyExists(s, "remoteDir")) {
                        s.remoteDir = "/home/#s.user#/#projectName#";
                    }
                    if (!structKeyExists(s, "port")) {
                        s.port = 22;
                    }
                    if (!structKeyExists(s, "imageName")) {
                        s.imageName = config.image;
                    }
                }
                serversToBuild = allServers;
            }
        } 
        
        if (arrayLen(serversToBuild) == 0) {
            if (fileExists(textConfigPath)) {
                detailOutput.identical("Found deploy-servers.txt, loading server configuration");
                allServers = loadServersFromTextFile("deploy-servers.txt");
                serversToBuild = filterServers(allServers, arguments.serverNumbers);
            } else if (fileExists(jsonConfigPath)) {
                detailOutput.identical("Found deploy-servers.json, loading server configuration");
                allServers = loadServersFromConfig("deploy-servers.json");
                serversToBuild = filterServers(allServers, arguments.serverNumbers);
            } else {
                detailOutput.error("No server configuration found. Use 'wheels docker init' or create deploy-servers.txt.");
                return;
            }
        }

        if (arrayLen(serversToBuild) == 0) {
            detailOutput.error("No servers configured for building");
            return;
        }

        detailOutput.line();
        detailOutput.statusInfo("Building Docker images on #arrayLen(serversToBuild)# server(s)...");

        // Build on all selected servers
        buildOnServers(serversToBuild, arguments.nocache, arguments.pull);

        detailOutput.line();
        detailOutput.success("Build operations completed on all servers!");
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
            detailOutput.statusFailed("No valid servers selected, using all servers");
            return arguments.allServers;
        }

        detailOutput.statusSuccess("Selected #arrayLen(selectedServers)# of #arrayLen(arguments.allServers)# server(s)");
        return selectedServers;
    }

    /**
     * Build on multiple servers sequentially
     */
    private function buildOnServers(required array servers, boolean nocache, boolean pull) {
        var successCount = 0;
        var failureCount = 0;
        var serverConfig = {};

        for (var i = 1; i <= arrayLen(servers); i++) {
            serverConfig = servers[i];
            detailOutput.header("Building on server #i# of #arrayLen(servers)#: #serverConfig.host#");

            try {
                buildOnServer(serverConfig, arguments.nocache, arguments.pull);
                successCount++;
                detailOutput.statusSuccess("Build on #serverConfig.host# completed successfully");
            } catch (any e) {
                failureCount++;
                detailOutput.statusFailed("Failed to build on #serverConfig.host#: #e.message#");
            }
        }

        detailOutput.line();
        detailOutput.statusInfo("Build Operations Summary:");
        detailOutput.statusSuccess("   Successful: #successCount#");
        if (failureCount > 0) {
            detailOutput.statusFailed("   Failed: #failureCount#");
        }
    }

    /**
     * Build on a single server
     */
    private function buildOnServer(required struct serverConfig, boolean nocache, boolean pull) {
        var local = {};
        local.host = arguments.serverConfig.host;
        local.user = arguments.serverConfig.user;
        local.port = structKeyExists(arguments.serverConfig, "port") ? arguments.serverConfig.port : 22;
        local.imageName = structKeyExists(arguments.serverConfig, "imageName") ? arguments.serverConfig.imageName : config.image;
        local.remoteDir = structKeyExists(arguments.serverConfig, "remoteDir") ? arguments.serverConfig.remoteDir : "/home/#local.user#/#local.imageName#";

        var config = resolveConfig();
        
        // Use image name from config or server config
        local.baseImageName = len(local.imageName) ? local.imageName : config.image;
        local.imageTag = local.baseImageName & ":" & config.tag;

        // Check SSH connection
        if (!testSSHConnection(local.host, local.user, local.port)) {
            detailOutput.error("SSH connection failed to #local.host#. Check credentials and access.");
            return;
        }
        detailOutput.statusSuccess("SSH connection successful");

        // Check if remote directory exists
        detailOutput.statusInfo("Checking remote directory...");
        local.checkDirCmd = "test -d " & local.remoteDir;
        local.dirExists = false;
        
        try {
            executeRemoteCommand(local.host, local.user, local.port, local.checkDirCmd);
            local.dirExists = true;
            detailOutput.statusSuccess("Remote directory exists");
        } catch (any e) {
            detailOutput.statusInfo("Remote directory does not exist, uploading source code...");
            uploadSourceCode(local.host, local.user, local.port, local.remoteDir);
        }

        // Check if docker-compose is being used on the remote server
        local.checkComposeCmd = "test -f " & local.remoteDir & "/docker-compose.yml || test -f " & local.remoteDir & "/docker-compose.yaml";
        local.useCompose = false;

        try {
            executeRemoteCommand(local.host, local.user, local.port, local.checkComposeCmd);
            local.useCompose = true;
            detailOutput.statusSuccess("Found docker-compose file on remote server");
        } catch (any e) {
            detailOutput.statusInfo("No docker-compose file found, checking for Dockerfile...");
            
            // Check if Dockerfile exists
            local.checkDockerfileCmd = "test -f " & local.remoteDir & "/Dockerfile";
            try {
                executeRemoteCommand(local.host, local.user, local.port, local.checkDockerfileCmd);
                detailOutput.statusSuccess("Found Dockerfile on remote server");
            } catch (any e2) {
                error("No Dockerfile or docker-compose.yml found on remote server in: " & local.remoteDir);
            }
        }

        if (local.useCompose) {
            // Build using docker-compose
            detailOutput.statusInfo("Building with docker-compose...");
            
            local.buildCmd = "cd " & local.remoteDir & " && ";
            
            // Check if user can run docker without sudo
            local.buildCmd &= "if groups | grep -q docker && [ -w /var/run/docker.sock ]; then ";
            local.buildCmd &= "docker compose build";
            
            if (arguments.nocache) {
                local.buildCmd &= " --no-cache";
            }
            
            if (arguments.pull) {
                local.buildCmd &= " --pull";
            }
            
            local.buildCmd &= "; else sudo docker compose build";
            
            if (arguments.nocache) {
                local.buildCmd &= " --no-cache";
            }
            
            if (arguments.pull) {
                local.buildCmd &= " --pull";
            }
            
            local.buildCmd &= "; fi";

            executeRemoteCommand(local.host, local.user, local.port, local.buildCmd);
            detailOutput.statusSuccess("Docker Compose build completed");
            
        } else {
            // Build using standard docker build
            detailOutput.statusInfo("Building Docker image...");
            
            // Determine tag
            local.projectName = getProjectName();
            local.deployConfig = getDeployConfig();
            local.baseImageName = (structKeyExists(local.deployConfig, "image") && len(trim(local.deployConfig.image))) ? local.deployConfig.image : local.imageName;

            local.imageTag = local.baseImageName & ":" & config.tag;
            detailOutput.create("Building image: " & local.imageTag);
            
            local.buildCmd = "cd " & local.remoteDir & " && ";
            
            // Check if user can run docker without sudo
            local.buildCmd &= "if groups | grep -q docker && [ -w /var/run/docker.sock ]; then ";
            local.buildCmd &= "docker build -t " & local.imageTag;
            
            if (arguments.nocache) {
                local.buildCmd &= " --no-cache";
            }
            
            if (arguments.pull) {
                local.buildCmd &= " --pull";
            }
            
            local.buildCmd &= " .";
            local.buildCmd &= "; else sudo docker build -t " & local.imageTag;
            
            if (arguments.nocache) {
                local.buildCmd &= " --no-cache";
            }
            
            if (arguments.pull) {
                local.buildCmd &= " --pull";
            }
            
            local.buildCmd &= " .";
            local.buildCmd &= "; fi";

            executeRemoteCommand(local.host, local.user, local.port, local.buildCmd);
            detailOutput.create("Docker image built: " & local.imageTag);
        }

        detailOutput.success("Build operations on #local.host# completed!");
    }
    
    /**
     * Upload source code to remote server
     */
    private function uploadSourceCode(string host, string user, numeric port, string remoteDir) {
        var local = {};
        
        detailOutput.statusInfo("Creating deployment directory on remote server...");
        
        // Create remote directory
        local.createDirCmd = "sudo mkdir -p " & arguments.remoteDir & " && sudo chown -R $USER:$USER " & arguments.remoteDir;
        
        try {
            executeRemoteCommand(arguments.host, arguments.user, arguments.port, local.createDirCmd);
        } catch (any e) {
            detailOutput.statusInfo("Note: Creating directory without sudo...");
            executeRemoteCommand(arguments.host, arguments.user, arguments.port, "mkdir -p " & arguments.remoteDir);
        }
        
        // Create tarball and upload
        local.timestamp = dateFormat(now(), "yyyymmdd") & timeFormat(now(), "HHmmss");
        local.tarFile = getTempFile(getTempDirectory(), "buildsrc_") & ".tar.gz";
        local.remoteTar = "/tmp/buildsrc_" & local.timestamp & ".tar.gz";

        detailOutput.statusInfo("Creating source tarball...");
        runProcess(["tar", "-czf", local.tarFile, "-C", getCWD(), "."]);

        detailOutput.statusInfo("Uploading source code to remote server...");
        runProcess(["scp", "-P", arguments.port, local.tarFile, arguments.user & "@" & arguments.host & ":" & local.remoteTar]);
        fileDelete(local.tarFile);
        
        detailOutput.statusInfo("Extracting source code...");
        local.extractCmd = "tar -xzf " & local.remoteTar & " -C " & arguments.remoteDir & " && rm " & local.remoteTar;
        executeRemoteCommand(arguments.host, arguments.user, arguments.port, local.extractCmd);
        
        detailOutput.statusSuccess("Source code uploaded successfully");
    }

    /**
     * Load servers from simple text file
     */
    private function loadServersFromTextFile(required string textFile) {
        var filePath = fileSystemUtil.resolvePath(arguments.textFile);

        if (!fileExists(filePath)) {
            detailOutput.error("Text file not found: #filePath#");
            return;
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

            return servers;

        } catch (any e) {
            error("Error reading text file: #e.message#");
        }
    }

    /**
     * Load servers configuration from JSON file
     */
    private function loadServersFromConfig(required string configFile) {
        var configPath = fileSystemUtil.resolvePath(arguments.configFile);

        if (!fileExists(configPath)) {
            detailOutput.error("Config file not found: #configPath#");
            return;
        }

        try {
            var configContent = fileRead(configPath);
            var config = deserializeJSON(configContent);

            if (!structKeyExists(config, "servers") || !isArray(config.servers)) {
                detailOutput.error("Invalid config file format. Expected { ""servers"": [ ... ] }");
                return;
            }

            var projectName = getProjectName();
            for (var i = 1; i <= arrayLen(config.servers); i++) {
                var serverConfig = config.servers[i];
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

            return config.servers;

        } catch (any e) {
            error("Error parsing config file: #e.message#");
        }
    }

    // =============================================================================
    // HELPER FUNCTIONS
    // =============================================================================

    private function testSSHConnection(string host, string user, numeric port) {
        var local = {};
        detailOutput.statusInfo("Testing SSH connection to " & arguments.host & "...");
        local.result = runProcess([
            "ssh",
            "-o", "BatchMode=yes",
            "-o", "PreferredAuthentications=publickey",
            "-o", "StrictHostKeyChecking=no",
            "-o", "ConnectTimeout=10",
            "-p", arguments.port,
            arguments.user & "@" & arguments.host,
            "echo connected"
        ]);
        return (local.result.exitCode eq 0 and findNoCase("connected", local.result.output));
    }

    private function executeRemoteCommand(string host, string user, numeric port, string cmd) {
        var local = {};
        detailOutput.statusInfo("Running: ssh -p " & arguments.port & " " & arguments.user & "@" & arguments.host & " " & arguments.cmd);

        local.result = runProcess([
            "ssh",
            "-o", "BatchMode=yes",
            "-o", "PreferredAuthentications=publickey",
            "-o", "StrictHostKeyChecking=no",
            "-o", "ServerAliveInterval=30",
            "-o", "ServerAliveCountMax=3",
            "-p", arguments.port,
            arguments.user & "@" & arguments.host,
            arguments.cmd
        ]);

        if (local.result.exitCode neq 0) {
            detailOutput.error("Remote command failed: " & arguments.cmd);
            setExitCode(1);
        }

        return local.result;
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
            detailOutput.output(local.line);
        }

        local.exitCode = local.proc.waitFor();
        local.output = arrayToList(local.outputParts, chr(10));

        return { exitCode: local.exitCode, output: local.output };
    }

}