/**
 * Login to a container registry
 *
 * {code:bash}
 * wheels docker login --registry=dockerhub --username=myuser
 * wheels docker login --registry=ecr --image=123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
 * {code}
 */
component extends="DockerCommand" {

    /**
     * @registry Registry type: dockerhub, ecr, gcr, acr, ghcr, private (default: dockerhub)
     * @username Registry username (required for dockerhub, ghcr, private)
     * @password Registry password or token (optional, will prompt if empty)
     * @image Image name (optional, but required for ECR/ACR to determine region/registry)
     * @local Execute login locally (default: true)
     */
    function run(
        string registry="dockerhub",
        string username="",
        string password="",
        string image="",
        boolean local=true
    ) {
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
        loginToRegistry(
            registry=arguments.registry,
            image=arguments.image,
            username=arguments.username,
            password=arguments.password,
            isLocal=arguments.local
        );

        // Save configuration for push command
        var config = {
            "registry": arguments.registry,
            "username": arguments.username,
            "image": arguments.image
        };
        
        try {
            var configPath = fileSystemUtil.resolvePath("docker-config.json");
            fileWrite(configPath, serializeJSON(config));
            print.greenLine("Configuration saved to docker-config.json").toConsole();
        } catch (any e) {
            print.yellowLine("Warning: Could not save configuration: #e.message#").toConsole();
        }
    }
}
