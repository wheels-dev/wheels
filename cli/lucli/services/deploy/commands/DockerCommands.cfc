/**
 * Low-level docker invocations.
 * Source of truth: Kamal 2.4.0 lib/kamal/commands/docker.rb
 */
component extends="Base" {
    public DockerCommands function init(required any config) {
        variables.config = arguments.config;
        return this;
    }

    public string function installed() { return "docker -v"; }
    public string function running()   { return "docker version"; }

    public string function network_exists(required string name) {
        return "docker network ls --filter name=#arguments.name# --format {{.Name}}";
    }

    public string function create_network(required string name) {
        return docker("network", "create", arguments.name);
    }
}
