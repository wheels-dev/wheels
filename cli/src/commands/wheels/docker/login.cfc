/**
 * Login to a container registry
 *
 * {code:bash}
 * wheels docker login --registry=dockerhub --username=myuser
 * wheels docker login --registry=ecr --image=123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
 * {code}
 */
component extends="DockerCommand" {

    property name="detailOutput" inject="DetailOutputService@wheels-cli";
    
    /**
     * @registry Registry type: dockerhub, ecr, gcr, acr, ghcr, private (default: dockerhub)
     * @username Registry username (required for dockerhub, ghcr, private)
     * @password Registry password or token (optional, will prompt if empty)
     * @image Image name (optional, but required for ECR/ACR to determine region/registry)
     * @namespace Registry namespace/username prefix (default: same as username)
     * @local Execute login locally (default: true)
     */
    function run(
        string registry="dockerhub",
        string username="",
        string password="",
        string image="",
        string namespace="",
        boolean local=true
    ) {
        //ensure we are in a Wheels app
        requireWheelsApp(getCWD());
        // Reconstruct arguments for handling --key=value style
        arguments = reconstructArgs(arguments);

        // Validate registry type
        var supportedRegistries = ["dockerhub", "ecr", "gcr", "acr", "ghcr", "private"];
        if (!arrayContains(supportedRegistries, lCase(arguments.registry))) {
            error("Unsupported registry: #arguments.registry#. Supported: #arrayToList(supportedRegistries)#");
        }
        
        // Check if Docker is installed locally
        if (arguments.local && !isDockerInstalled()) {
            error("Docker is not installed or not accessible. Please ensure Docker Desktop or Docker Engine is running.");
        }
        
        // Call loginToRegistry from base component
        var loginResult = loginToRegistry(
            registry=arguments.registry,
            image=arguments.image,
            username=arguments.username,
            password=arguments.password,
            isLocal=arguments.local
        );

        // Update arguments from interactive results for saving
        arguments.username = loginResult.username;
        arguments.image = loginResult.image;
        if (len(trim(loginResult.registryUrl)) && !len(trim(arguments.image))) {
            arguments.image = loginResult.registryUrl & "/" & getProjectName();
        }

        // Save configuration for push command
        var config = {
            "registry": arguments.registry,
            "username": arguments.username,
            "image": arguments.image,
            "namespace": arguments.namespace
        };
        
        try {
            var configPath = fileSystemUtil.resolvePath("docker-config.json");
            fileWrite(configPath, serializeJSON(config));
            detailOutput.statusSuccess("Configuration saved to docker-config.json");
        } catch (any e) {
            detailOutput.statusWarning("Warning: Could not save configuration: #e.message#");
        }
    }
}