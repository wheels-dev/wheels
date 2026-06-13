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

    /**
     * Idempotent network create — `docker network create` exits nonzero
     * when the network already exists, so deploy/setup guard it with an
     * inspect probe (exit 0 only when the network is present). Ruby Kamal
     * rescues the "already exists" error instead; a shell guard is the
     * commands-are-strings equivalent (#2957 DEP-5c).
     */
    public string function ensure_network(required string name) {
        return "docker network inspect #arguments.name# >/dev/null 2>&1 || "
             & create_network(arguments.name);
    }
}
